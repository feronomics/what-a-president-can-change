## Date created:        23 October 2026
## Title:               Recheck newly replaced payroll harmonization
## Project:             Que todo cambie para que nada cambie
## Affiliation:         ASIES
## Purpose:             Compare latest files with the saved review, without adopting them.
## Inputs:              Fifteen root payroll files; saved prior summaries; monthly SICOIN.
## Outputs:             3_output/2_tables/13_payroll_harmonization_check.
## Execution:           Independent read-only review; not called by the master.
## -------------------------------------------------------------------------
library(dplyr)
source("2_scripts/99_helpers/99_payroll_helpers.R")
out <- "3_output/2_tables/13_payroll_harmonization_check"
dir.create(out,recursive=TRUE,showWarnings=FALSE)
save_check <- function(x,name) {
 write.csv(x,file.path(out,paste0(name,".csv")),row.names=FALSE,fileEncoding="UTF-8")
}
ministries <- c("MAGA","MARN","MCD","MEM","MICIVI","MIDES","MINDEF","MINECO",
 "MINEDUC","MINEX","MINFIN","MINGOB","MINTRAB","MSPAS","Secretarias")
details <- list()
summaries <- list()
for (m in ministries) {
 file <- file.path("1_databases",paste0(m,"_gasto_por_grupo.xlsx"))
 if (!file.exists(file)) {
   file <- file.path("1_databases", "payroll", "by ministry", paste0(m, "_gasto_por_grupo.xlsx"))
 }
 d <- readxl::read_xlsx(file,sheet="detalle",guess_max=100000L)
 s <- readxl::read_xlsx(file,sheet="resumen_planilla",guess_max=100000L)
 d$Ministerio <- m
 s$Ministerio <- m
 d$Cod_prog <- as.character(as.integer(d$Cod_prog))
 s$Cod_prog <- as.character(as.integer(s$Cod_prog))
 d$Cod_grupo <- as.integer(d$Cod_grupo)
 details[[m]] <- d
 summaries[[m]] <- s
}
latest <- bind_rows(details)
supplied <- bind_rows(summaries)
before_profile <- read.csv("3_output/2_tables/11_payroll_review/15_quality.csv",fileEncoding="UTF-8")
quality <- latest %>% group_by(Ministerio) %>% summarise(
 rows=n(),blank_final=sum(is.na(Programa_Final)|trimws(Programa_Final)==""),
 positive_blank=sum((is.na(Programa_Final)|trimws(Programa_Final)=="")&Devengado>0),
 blank_execution=sum(Devengado[is.na(Programa_Final)|trimws(Programa_Final)==""]),
 duplicate_excess=sum(duplicated(as.data.frame(pick(everything())))),.groups="drop") %>%
 left_join(before_profile %>% select(Ministerio,before_blank=blank_final),by="Ministerio")
save_check(quality,"1_name_coverage")

# Compare program amounts and name assignments to the prior saved review.
new_program <- latest %>% group_by(Ministerio,Anio,Cod_prog,Nombre_prog) %>%
 summarise(
 execution=sum(Devengado),personnel=sum(Devengado[Cod_grupo==0]),
 final_names=paste(sort(unique(Programa_Final[!is.na(Programa_Final)&trimws(Programa_Final)!=""])),collapse=" | "),
 .groups="drop")
before_min <- read.csv("3_output/2_tables/11_payroll_review/13_consolidated_summary.csv",fileEncoding="UTF-8",check.names=FALSE) %>%
 transmute(Ministerio,Anio,Cod_prog=as.character(Cod_prog),Nombre_prog,
 execution=Devengado_total_calc,personnel=Serv_personales_calc,Programa_Final)
before_sec <- read.csv("3_output/2_tables/11_payroll_review/20_secretariat_summary_check.csv",fileEncoding="UTF-8",check.names=FALSE) %>%
 transmute(Ministerio,Anio,Cod_prog=as.character(Cod_prog),Nombre_prog,
 execution=Devengado_total_calc,personnel=Serv_personales_calc,Programa_Final)
before_program <- bind_rows(before_min,before_sec) %>%
 group_by(Ministerio,Anio,Cod_prog,Nombre_prog) %>% summarise(
 execution=sum(execution),personnel=sum(personnel),
 final_names=paste(sort(unique(Programa_Final[!is.na(Programa_Final)&trimws(Programa_Final)!=""])),collapse=" | "),.groups="drop")
comparison <- full_join(before_program,new_program,
 by=c("Ministerio","Anio","Cod_prog","Nombre_prog"),suffix=c("_before","_now")) %>%
 mutate(execution_change=execution_now-execution_before,
 personnel_change=personnel_now-personnel_before,
 label_changed=coalesce(final_names_before,"<missing>")!=coalesce(final_names_now,"<missing>"))
save_check(comparison,"2_before_vs_latest")
save_check(comparison %>% filter(label_changed),"3_label_changes")

monthly <- readxl::read_xlsx("1_databases/programs/unified/SICOIN_consolidated.xlsx",sheet="SICOIN")
monthly_program <- monthly %>% group_by(Ministerio,Anio=.data[["Año"]],Programa_Final) %>%
 summarise(monthly_execution=sum(Ejecutado),.groups="drop")
new_labels <- latest %>% filter(!is.na(Programa_Final),trimws(Programa_Final)!="") %>%
 group_by(Ministerio,Anio,Programa_Final) %>%
 summarise(new_execution=sum(Devengado),.groups="drop")
label_check <- full_join(new_labels,monthly_program %>% filter(Ministerio %in% ministries),
 by=c("Ministerio","Anio","Programa_Final")) %>%
 mutate(difference=new_execution-monthly_execution,
 difference_pct=100*difference/monthly_execution,
 comparable=!is.na(new_execution)&!is.na(monthly_execution),
 within_half_pct=comparable&abs(difference)<=pmax(0.5,abs(monthly_execution)*0.005))
save_check(label_check,"4_program_amounts")
remaining <- label_check %>%
 filter(!is.na(new_execution), !within_half_pct)
save_check(remaining,"5_remaining_amount_discrepancies")
save_check(latest %>% filter(is.na(Programa_Final)|trimws(Programa_Final)==""),"6_still_missing_names")
monthly_only <- label_check %>% filter(is.na(new_execution),!is.na(monthly_execution))
save_check(monthly_only,"7_monthly_without_payroll_name")

# Verify labels are present in the correct ministry and year, not merely somewhere.
known_names <- monthly %>% distinct(Ministerio,Anio=.data[["Año"]],Programa_Final)
unknown_labels <- anti_join(
 latest %>% distinct(Ministerio,Anio,Cod_prog,Nombre_prog,Programa_Final) %>% filter(!is.na(Programa_Final),trimws(Programa_Final)!=""),
 known_names,by=c("Ministerio","Anio","Programa_Final"))
save_check(unknown_labels,"8_names_without_monthly_counterpart")

# Secretariat metadata were a separate issue in the previous review.
sec_quality <- details$Secretarias %>% group_by(Anio) %>% summarise(
 rows=n(),missing_unit=sum(is.na(Unidad_ejecutora)|trimws(Unidad_ejecutora)==""),
 missing_institution=sum(is.na(Secretaria)|trimws(Secretaria)==""),
 missing_final=sum(is.na(Programa_Final)|trimws(Programa_Final)==""),.groups="drop")
save_check(sec_quality,"9_secretariat_metadata")
keys <- c("Ministerio","Anio","Cod_prog","Nombre_prog","Programa_Final")
calc <- latest %>% group_by(across(all_of(keys))) %>% summarise(
 total=sum(Devengado),personnel=sum(Devengado[Cod_grupo==0]),.groups="drop")
src <- supplied %>% group_by(across(all_of(keys))) %>% summarise(
 total=sum(Devengado_total),personnel=sum(Serv_personales),.groups="drop")
summary_check <- full_join(calc,src,by=keys,suffix=c("_calc","_source")) %>%
 mutate(total_difference=total_calc-total_source,personnel_difference=personnel_calc-personnel_source)
save_check(summary_check,"10_internal_summary_check")
old_cases <- read.csv("3_output/2_tables/11_payroll_review/27_amount_decisions.csv",fileEncoding="UTF-8",check.names=FALSE)
old_case_status <- old_cases %>% select(case_id,Ministerio,Anio,Programa_Final) %>%
 left_join(label_check,by=c("Ministerio","Anio","Programa_Final"))
save_check(old_case_status,"11_previous_nine_cases")
print(quality,n=15,width=170)
print(comparison %>% summarise(rows=n(),changed_labels=sum(label_changed),changed_amounts=sum(abs(execution_change)>0.011,na.rm=TRUE),
 unmatched_before=sum(is.na(execution_now)),unmatched_now=sum(is.na(execution_before))))
print(remaining,n=40,width=190)
print(sec_quality %>% filter(missing_unit>0|missing_institution>0|missing_final>0),n=22)
print(old_case_status %>% select(case_id,Ministerio,Anio,within_half_pct,difference),width=160)
stopifnot(all(abs(summary_check$total_difference)<0.01),all(abs(summary_check$personnel_difference)<0.01))
