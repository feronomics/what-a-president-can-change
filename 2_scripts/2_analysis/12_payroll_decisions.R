## Date created:        23 October 2026
## Title:               Build the complete payroll discrepancy review register
## Project:             Que todo cambie para que nada cambie
## Affiliation:         ASIES
## Purpose:             List every unresolved amount or name case for coauthor decisions.
## Inputs:              Saved payroll comparisons and current monthly program labels.
## Outputs:             Review registers only; no data changes or model execution.
## -------------------------------------------------------------------------
library(dplyr)
source("2_scripts/99_helpers/99_payroll_helpers.R")
out <- "3_output/2_tables/11_payroll_review"
blank <- read.csv(file.path(out,"19_missing_harmonized_names.csv"),check.names=FALSE,na.strings="NA")
monthly <- readxl::read_xlsx("1_databases/programs/unified/SICOIN_consolidated.xlsx",sheet="SICOIN")
aliases <- bind_rows(lapply(c("Programa","Programa_Estandarizado","Programa_Final"),function(col) {
 monthly %>% transmute(Ministerio,Anio=.data[["Año"]],key=payroll_key(.data[[col]]),candidate=Programa_Final)
})) %>% distinct()
# The register proposes only exact spelling-normalized aliases in the same year.
# It never assigns or changes a name in any source file.
keys <- c("Ministerio","Anio","Unidad_ejecutora","Secretaria","Cod_prog","Nombre_prog")
cases <- blank %>% group_by(across(all_of(keys))) %>%
 summarise(rows=n(),execution=sum(Devengado),
   personnel=sum(Devengado[Cod_grupo==0]),.groups="drop") %>%
 arrange(Ministerio,Cod_prog,Nombre_prog,Anio,Unidad_ejecutora)
cases$candidate <- ""
cases$candidate_amount <- ""
for (i in seq_len(nrow(cases))) {
 a <- aliases %>% filter(
  Ministerio==cases$Ministerio[i],Anio==cases$Anio[i],
  key==payroll_key(cases$Nombre_prog[i])
 ) %>% distinct(candidate)
 cases$candidate[i] <- if(nrow(a)) paste(a$candidate,collapse=" | ") else "Sin coincidencia exacta por nombre"
}
groups <- cases %>% distinct(Ministerio,Cod_prog,Nombre_prog) %>%
 arrange(Ministerio,Cod_prog,Nombre_prog) %>%
 mutate(case_id=sprintf("B%03d",row_number()))
cases <- cases %>% left_join(groups,by=c("Ministerio","Cod_prog","Nombre_prog")) %>%
 mutate(Decision="",Nombre_acordado="",Justificacion="",Responsable="")
write.csv(cases,file.path(out,"26_name_decisions.csv"),row.names=FALSE,fileEncoding="UTF-8")
amounts <- read.csv(file.path(out,"18_harmonized_amount_check.csv"),check.names=FALSE)
amounts <- amounts %>% filter(is.na(within_half_pct)|!within_half_pct) %>%
 mutate(case_id=sprintf("A%02d",row_number()),Decision="",Nombre_acordado="",Justificacion="",Responsable="")
source_programs <- read.csv(file.path(out,"13_consolidated_summary.csv"),check.names=FALSE)
amounts$source_programs <- ""
for (i in seq_len(nrow(amounts))) {
 a <- source_programs %>% filter(Ministerio==amounts$Ministerio[i],
   Anio==amounts$Anio[i],Programa_Final==amounts$Programa_Final[i]) %>%
   distinct(Cod_prog,Nombre_prog)
 amounts$source_programs[i] <- paste(paste0(a$Cod_prog," · ",a$Nombre_prog),collapse="; ")
}
write.csv(amounts,file.path(out,"27_amount_decisions.csv"),row.names=FALSE,fileEncoding="UTF-8")
cat(nrow(amounts),"amount cases;",nrow(cases),"program-year/unit name cases;",nrow(groups),"name groups.\n")
