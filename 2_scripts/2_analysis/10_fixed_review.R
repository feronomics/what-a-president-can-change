## Date created:        23 October 2026
## Project:             Que todo cambie para que nada cambie
## Affiliation:         Asociación de Investigación y Estudios Sociales (ASIES)
## Title:               Compare supplied corrected database with pipeline inputs
## Purpose:             Identify unchanged, added, removed and modified records.
## Inputs:              SICOIN_consolidated_corregido.xlsx and current consolidated SICOIN.
## Outputs:             3_output/2_tables/10_fixed_review.
## Execution:           Independent read-only comparison from project root.
## Methods:             Multiset comparison of every field; money at cent precision.
## -------------------------------------------------------------------------
library(dplyr)
source("2_scripts/99_helpers/99_helpers.R")
source("2_scripts/99_helpers/99_payroll_helpers.R")
out <- "3_output/2_tables/10_fixed_review"
dir.create(out,recursive=TRUE,showWarnings=FALSE)
save_review <- function(x,name) {
  write.csv(x,file.path(out,paste0(name,".csv")),row.names=FALSE,fileEncoding="UTF-8")
}
current <- readxl::read_xlsx("1_databases/programs/unified/SICOIN_consolidated.xlsx",sheet="SICOIN")
fixed <- readxl::read_xlsx("1_databases/SICOIN_consolidated_corregido.xlsx",sheet="SICOIN")
stopifnot(setequal(names(current),names(fixed)))
columns <- names(current)
fixed <- fixed[columns]

# Preserve repeated records as separate occurrences when comparing the two sets.
signature <- function(data) {
  x <- as.data.frame(data[columns])
  for (col in c("Asignado","Vigente","Ejecutado")) {
    x[[col]] <- sprintf("%.2f",round(x[[col]],2))
  }
  x[] <- lapply(x,function(v) ifelse(is.na(v),"<NA>",as.character(v)))
  do.call(paste,c(x,sep="\034"))
}
a <- signature(current)
b <- signature(fixed)
a_id <- paste(a,ave(seq_along(a),a,FUN=seq_along),sep="\035")
b_id <- paste(b,ave(seq_along(b),b,FUN=seq_along),sep="\035")
current_only <- current[!a_id %in% b_id,]
fixed_only <- fixed[!b_id %in% a_id,]
save_review(current_only,"1_current_only")
save_review(fixed_only,"2_fixed_only")
save_review(data.frame(dataset=c("current","fixed"),rows=c(nrow(current),nrow(fixed)),
  identical_record_occurrences=c(sum(a_id %in% b_id),sum(b_id %in% a_id)),
  unmatched_record_occurrences=c(nrow(current_only),nrow(fixed_only))),"3_counts")
summary <- bind_rows(
 current_only %>% mutate(side="current_only"),
 fixed_only %>% mutate(side="fixed_only")
) %>% group_by(side,Ministerio,.data[["Año"]],Mes,Entidad,Archivo_Origen) %>%
 summarise(rows=n(),execution=sum(Ejecutado),assigned=sum(Asignado),current_budget=sum(Vigente),.groups="drop")
save_review(summary,"4_differences")
print(data.frame(current=nrow(current),fixed=nrow(fixed),current_only=nrow(current_only),fixed_only=nrow(fixed_only)))
print(summary,n=100,width=180)
