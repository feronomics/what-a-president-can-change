## Date created:        23 October 2026
## Project:             Que todo cambie para que nada cambie
## Affiliation:         Asociación de Investigación y Estudios Sociales (ASIES)
## Title:               Compare current and newly supplied annual payroll databases
## Purpose:             Quantify coverage, identity, amount and personnel-share changes.
## Inputs:              Existing payroll/by ministry and 16 new workbooks at 1_databases root.
## Outputs:             3_output/2_tables/11_payroll_review; no source or model changes.
## Execution:           Independent review, never called by the master.
## Limits:              Monetary comparisons cannot validate unseen original SICOIN PDFs.
## -------------------------------------------------------------------------
library(dplyr)
source("2_scripts/99_helpers/99_helpers.R")
source("2_scripts/99_helpers/99_payroll_helpers.R")
out <- "3_output/2_tables/11_payroll_review"
dir.create(out,recursive=TRUE,showWarnings=FALSE)
save_review <- function(x,name) {
  write.csv(x,file.path(out,paste0(name,".csv")),row.names=FALSE,fileEncoding="UTF-8")
}
ministries <- c("MAGA","MARN","MCD","MEM","MICIVI","MIDES","MINDEF","MINECO",
                "MINEDUC","MINEX","MINFIN","MINGOB","MINTRAB","MSPAS")
old_details <- list()
new_details <- list()
new_summaries <- list()
files <- list()
for (m in c(ministries,"Secretarias")) {
  name <- paste0(m,"_gasto_por_grupo.xlsx")
  file <- file.path("1_databases",name)
  d <- readxl::read_xlsx(file,sheet="detalle")
  s <- readxl::read_xlsx(file,sheet="resumen_planilla")
  d$Ministerio <- m
  s$Ministerio <- m
  d$Cod_prog <- as.character(as.integer(d$Cod_prog))
  d$Cod_grupo <- sprintf("%03d",as.integer(d$Cod_grupo))
  s$Cod_prog <- as.character(as.integer(s$Cod_prog))
  new_details[[m]] <- d
  new_summaries[[m]] <- s
  files[[m]] <- data.frame(file=name,rows=nrow(d),summary_rows=nrow(s),
    first_year=min(d$Anio),last_year=max(d$Anio),columns=paste(names(d),collapse=";"))
  if (m %in% ministries) {
    old <- readxl::read_xlsx(file.path("1_databases/payroll/by ministry",name),sheet="detalle")
    old$Ministerio <- m
    old$Cod_prog <- as.character(as.integer(old$Cod_prog))
    old$Cod_grupo <- sprintf("%03d",as.integer(old$Cod_grupo))
    old_details[[m]] <- old
  }
}
old <- bind_rows(old_details)
new_all <- bind_rows(new_details)
new <- new_all %>% filter(Ministerio %in% ministries)
new_summary_all <- bind_rows(new_summaries)
save_review(bind_rows(files),"1_inventory")

# Independently recompute amounts from detail rather than trust supplied summaries.
annual_totals <- function(x) {
  x %>% group_by(Ministerio,Anio) %>%
    summarise(rows=n(),programs=n_distinct(paste(Cod_prog,Nombre_prog)),
      assigned=sum(Asignado),current_budget=sum(Vigente),execution=sum(Devengado),
      personnel=sum(Devengado[Cod_grupo=="000"]),.groups="drop") %>%
    mutate(personnel_pct=ifelse(execution>0,100*personnel/execution,NA_real_))
}
old_annual <- annual_totals(old)
new_annual <- annual_totals(new_all)
annual <- full_join(old_annual,new_annual,by=c("Ministerio","Anio"),suffix=c("_old","_new")) %>%
 mutate(execution_change=execution_new-execution_old,
   execution_change_pct=ifelse(execution_old!=0,100*execution_change/execution_old,NA_real_),
   personnel_change=personnel_new-personnel_old,
   personnel_share_change_pp=personnel_pct_new-personnel_pct_old)
save_review(annual,"2_annual_comparison")
ministry <- annual %>% group_by(Ministerio) %>%
 summarise(old_rows=sum(rows_old),new_rows=sum(rows_new),old_execution=sum(execution_old),
   new_execution=sum(execution_new),old_personnel=sum(personnel_old),
   new_personnel=sum(personnel_new),.groups="drop") %>%
 mutate(execution_change=new_execution-old_execution,
   execution_change_pct=100*execution_change/old_execution,
   personnel_change=new_personnel-old_personnel,
   old_personnel_pct=100*old_personnel/old_execution,
   new_personnel_pct=100*new_personnel/new_execution,
   share_change_pp=new_personnel_pct-old_personnel_pct)
save_review(ministry,"3_ministry_totals")

# Compare program definitions directly by ministry-year; changes in this identity
# prevent treating all old/new program rows as observations of the same program.
identity <- function(x) {
 x %>% distinct(Ministerio,Anio,Cod_prog,Nombre_prog)
}
old_id <- identity(old)
new_id <- identity(new)
identity_changes <- bind_rows(
 anti_join(old_id,new_id,by=names(old_id)) %>% mutate(side="old_only"),
 anti_join(new_id,old_id,by=names(old_id)) %>% mutate(side="new_only"))
save_review(identity_changes,"4_program_identity_changes")
identity_profile <- identity_changes %>%
 count(Ministerio,Anio,side,name="program_identities")
save_review(identity_profile,"5_identity_profile")

# Match rows using amounts that should have been unchanged even when program
# labels were wrong. Multiple rows sharing a signature are explicitly ambiguous.
fingerprint <- function(x) {
 paste(x$Ministerio,x$Anio,x$Cod_grupo,sprintf("%.2f",x$Asignado),
       sprintf("%.2f",x$Vigente),sep="|")
}
old$key <- fingerprint(old)
new$key <- fingerprint(new)
old$signature_count <- ave(seq_len(nrow(old)),old$key,FUN=length)
new$signature_count <- ave(seq_len(nrow(new)),new$key,FUN=length)
stable_fields <- full_join(
 old %>% count(key,name="old_count"),
 new %>% count(key,name="new_count"),by="key") %>%
 mutate(old_count=coalesce(old_count,0L),new_count=coalesce(new_count,0L))
save_review(stable_fields %>% filter(old_count!=new_count),"6_row_signature_differences")
unique_match <- inner_join(
 old %>% filter(signature_count==1L),
 new %>% filter(signature_count==1L),
 by="key",suffix=c("_old","_new")) %>%
 mutate(execution_change=Devengado_new-Devengado_old,
   old_matches_new_committed=abs(Devengado_old-Comprometido)<0.011,
   old_matches_new_execution=abs(Devengado_old-Devengado_new)<0.011,
   code_changed=Cod_prog_old!=Cod_prog_new,
   name_changed=Nombre_prog_old!=Nombre_prog_new)
save_review(unique_match,"7_unique_row_matches")
match_profile <- unique_match %>% group_by(Ministerio_old) %>%
 summarise(unique_rows=n(),changed_execution=sum(abs(execution_change)>0.011),
   old_equals_new_committed=sum(old_matches_new_committed),
   old_equals_new_execution=sum(old_matches_new_execution),
   code_changed=sum(code_changed),name_changed=sum(name_changed),.groups="drop")
save_review(match_profile,"8_row_match_profile")

# Compare annual sums to all currently corrected monthly sources.
monthly <- readxl::read_xlsx("1_databases/programs/unified/SICOIN_consolidated.xlsx",sheet="SICOIN")
monthly_annual <- monthly %>% group_by(Ministerio,Anio=.data[["Año"]]) %>%
 summarise(monthly_execution=sum(Ejecutado),.groups="drop")
cross <- annual %>% left_join(monthly_annual,by=c("Ministerio","Anio")) %>%
 mutate(old_difference=execution_old-monthly_execution,
        new_difference=execution_new-monthly_execution,
        old_difference_pct=100*old_difference/monthly_execution,
        new_difference_pct=100*new_difference/monthly_execution)
save_review(cross,"9_monthly_reconciliation")

# Recompute program summaries, respecting separate Secretariat executing units.
program_keys <- c("Ministerio","Anio","Cod_prog","Nombre_prog","Programa_Final")
new_program <- new %>%
 group_by(across(all_of(program_keys))) %>%
 summarise(Devengado_total=sum(Devengado),
   Serv_personales=sum(Devengado[Cod_grupo=="000"]),.groups="drop") %>%
 mutate(pct_planilla=ifelse(Devengado_total>0,100*Serv_personales/Devengado_total,NA_real_))
supplied <- new_summary_all %>% filter(Ministerio %in% ministries)
summary_check <- full_join(new_program,supplied,by=program_keys,suffix=c("_calc","_source")) %>%
 mutate(total_difference=Devengado_total_calc-Devengado_total_source,
   personnel_difference=Serv_personales_calc-Serv_personales_source,
   share_difference=pct_planilla_calc-pct_planilla_source)
save_review(summary_check,"10_summary_reconciliation")

# Check consistency of all 14 individual ministries against the new consolidated.
consolidated_file <- "1_databases/payroll_consolidated_corregido.xlsx"
con_detail <- readxl::read_xlsx(consolidated_file,sheet="detalle",guess_max=100000L)
con_detail$Cod_prog <- as.character(as.integer(con_detail$Cod_prog))
con_detail$Cod_grupo <- sprintf("%03d",as.integer(con_detail$Cod_grupo))
con_annual <- readxl::read_xlsx(consolidated_file,sheet="anual")
con_annual$Cod_prog <- as.character(as.integer(con_annual$Cod_prog))
con_coverage <- con_detail %>% group_by(Ministerio) %>% summarise(rows=n(),.groups="drop")
save_review(con_coverage,"11_consolidated_coverage")
con_checks <- bind_rows(lapply(ministries,function(m) {
 a <- new_details[[m]]
 b <- con_detail %>% filter(Ministerio==m)
 common <- names(a)
 totals <- b %>% summarise(previous_execution=sum(Devengado_version_anterior),committed=sum(Comprometido))
 data.frame(Ministerio=m,individual_rows=nrow(a),consolidated_rows=nrow(b),
   identical_common_values=isTRUE(all.equal(as.data.frame(a),as.data.frame(b[common]),check.attributes=FALSE)),
   old_execution=sum(old_details[[m]]$Devengado),
   previous_execution_in_new_file=totals$previous_execution,
   new_committed=totals$committed)
}))
save_review(con_checks,"12_individual_vs_consolidated")
con_summary_check <- full_join(new_program,con_annual,by=program_keys,suffix=c("_calc","_consolidated")) %>%
 mutate(total_difference=Devengado_total_calc-Devengado_total_consolidated,
   personnel_difference=Serv_personales_calc-Serv_personales_consolidated,
   share_difference=pct_planilla_calc-pct_planilla_consolidated)
save_review(con_summary_check,"13_consolidated_summary")
save_review(con_annual %>% count(Enlace_Programa_Final,name="rows"),"14_label_mapping_methods")

# Profile remaining source problems without changing any record.
quality <- bind_rows(lapply(names(new_details),function(m) {
 d <- new_details[[m]]
 numeric_cols <- c("Asignado","Vigente","Comprometido","Devengado")
 data.frame(Ministerio=m,rows=nrow(d),exact_duplicate_excess=sum(duplicated(as.data.frame(d))),
   negative_execution=sum(d$Devengado<0),missing_amounts=sum(!is.finite(as.matrix(d[numeric_cols]))),
   blank_final=sum(is.na(d$Programa_Final)|trimws(d$Programa_Final)==""),
   invalid_years=sum(is.na(d$Anio)|d$Anio!=as.integer(d$Anio)))
}))
save_review(quality,"15_quality")
# Preserve the supplied explanations as claims, separate from our own verification.
save_review(readxl::read_xlsx(consolidated_file,sheet="notas"),"16_supplied_notes")
print(ministry,width=200,n=20)
print(match_profile,width=180,n=20)
print(con_checks)
print(cross %>% filter(Ministerio %in% ministries) %>%
 summarise(old_total=sum(execution_old),new_total=sum(execution_new),
   old_personnel=sum(personnel_old),new_personnel=sum(personnel_new),
   old_within_half_pct=sum(abs(old_difference_pct)<=0.5),
   new_within_half_pct=sum(abs(new_difference_pct)<=0.5),comparisons=n(),
   max_new_difference_pct=max(abs(new_difference_pct))))
print(quality)
print(summary_check %>% summarise(
 max_total_diff=max(abs(total_difference),na.rm=TRUE),
 max_personnel_diff=max(abs(personnel_difference),na.rm=TRUE),
 missing_pairs=sum(is.na(Devengado_total_calc)|is.na(Devengado_total_source))))

# Measure personnel-share changes only where old/new source program identities
# genuinely coincide; collapsed old program labels cannot be compared one to one.
old_program <- old %>%
 group_by(Ministerio,Anio,Cod_prog,Nombre_prog) %>%
 summarise(old_execution=sum(Devengado),
   old_personnel=sum(Devengado[Cod_grupo=="000"]),.groups="drop") %>%
 mutate(old_share=ifelse(old_execution>0,100*old_personnel/old_execution,NA_real_))
common_program <- inner_join(
 old_program,
 new_program,
 by=c("Ministerio","Anio","Cod_prog","Nombre_prog")
) %>% mutate(share_change_pp=pct_planilla-old_share,
             execution_change=Devengado_total-old_execution)
save_review(common_program,"17_common_program_changes")
new_label_totals <- new_program %>%
 filter(!is.na(Programa_Final),trimws(Programa_Final)!="") %>%
 group_by(Ministerio,Anio,Programa_Final) %>%
 summarise(new_execution=sum(Devengado_total),.groups="drop")
monthly_labels <- monthly %>%
 group_by(Ministerio,Anio=.data[["Año"]],Programa_Final) %>%
 summarise(monthly_execution=sum(Ejecutado),.groups="drop")
label_check <- left_join(new_label_totals,monthly_labels,
 by=c("Ministerio","Anio","Programa_Final")) %>%
 mutate(difference=new_execution-monthly_execution,
   difference_pct=100*difference/monthly_execution,
   within_half_pct=abs(difference)<=pmax(0.5,abs(monthly_execution)*0.005))
save_review(label_check,"18_harmonized_amount_check")
blank_labels <- new_all %>% filter(is.na(Programa_Final)|trimws(Programa_Final)=="")
save_review(blank_labels,"19_missing_harmonized_names")

# Check the new Secretariat file on its own executing-unit/program keys.
secretariat_keys <- c("Anio","Unidad_ejecutora","Secretaria","Cod_prog","Nombre_prog","Programa_Final")
sec_calc <- new_details$Secretarias %>% group_by(across(all_of(secretariat_keys))) %>%
 summarise(Devengado_total=sum(Devengado),
   Serv_personales=sum(Devengado[Cod_grupo=="000"]),.groups="drop") %>%
 mutate(pct_planilla=ifelse(Devengado_total>0,100*Serv_personales/Devengado_total,NA_real_))
sec_check <- full_join(sec_calc,new_summaries$Secretarias,by=secretariat_keys,
 suffix=c("_calc","_source")) %>%
 mutate(total_difference=Devengado_total_calc-Devengado_total_source,
   personnel_difference=Serv_personales_calc-Serv_personales_source)
save_review(sec_check,"20_secretariat_summary_check")
national <- ministry %>% filter(Ministerio %in% ministries) %>%
 summarise(old_execution=sum(old_execution),new_execution=sum(new_execution),
   old_personnel=sum(old_personnel),new_personnel=sum(new_personnel)) %>%
 mutate(execution_change_pct=100*(new_execution/old_execution-1),
   personnel_change_pct=100*(new_personnel/old_personnel-1),
   old_personnel_share=100*old_personnel/old_execution,
   new_personnel_share=100*new_personnel/new_execution,
   share_change_pp=new_personnel_share-old_personnel_share)
save_review(national,"21_national_same_scope")
program_counts <- bind_rows(
 old_id %>% count(Ministerio,Anio,name="programs") %>% mutate(version="old"),
 new_id %>% count(Ministerio,Anio,name="programs") %>% mutate(version="new")
)
save_review(program_counts,"22_program_counts")

# Count changed amounts without confusing small rounding differences with change.
validation <- data.frame(
 old_detail_rows=nrow(old),new_detail_rows=nrow(new),
 new_secretariat_rows=nrow(new_details$Secretarias),
 old_program_years=nrow(old_id),new_program_years=nrow(new_id),
 uniquely_matched_rows=nrow(unique_match),
 changed_execution_rows=sum(abs(unique_match$execution_change)>0.011),
 corrected_code_rows=sum(unique_match$code_changed),
 corrected_name_rows=sum(unique_match$name_changed),
 current_monthly_matches_within_half_pct=sum(abs(cross$new_difference_pct[cross$Ministerio %in% ministries])<=0.5),
 comparison_ministry_years=sum(cross$Ministerio %in% ministries),
 assigned_harmonized_execution_pct=100*sum(new_program$Devengado_total[!is.na(new_program$Programa_Final)]) / sum(new_program$Devengado_total),
 rows_with_blank_final_and_positive_execution=sum(is.na(new_all$Programa_Final)&new_all$Devengado>0)
)
save_review(validation,"23_validation_summary")
print(national,width=180)
print(validation,width=180)
print(common_program %>% filter(!is.na(share_change_pp)) %>%
 summarise(common_program_years=n(),median_abs_share_change=median(abs(share_change_pp)),
   max_abs_share_change=max(abs(share_change_pp)),
   over_one_pp=sum(abs(share_change_pp)>1)),width=180)
print(common_program %>% arrange(desc(abs(share_change_pp))) %>%
 select(Ministerio,Anio,Nombre_prog,old_share,pct_planilla,share_change_pp) %>% head(10),width=160)
print(label_check %>% filter(!within_half_pct | is.na(within_half_pct)) %>% head(12),width=160)

# The annual Secretariat source can corroborate the known CONAP 2011 gap,
# but it cannot supply the missing monthly distribution.
conap_annual <- new_details$Secretarias %>%
 filter(
   Anio == 2011,
   grepl("CONAP|CONSEJONACIONALDEAREASPROTEGIDAS", payroll_key(Secretaria))
 ) %>%
 group_by(Anio, Secretaria) %>%
 summarise(
   execution = sum(Devengado),
   personnel = sum(Devengado[Cod_grupo == "000"]),
   .groups = "drop"
 )
save_review(conap_annual, "24_conap_annual_only")

# Fail visibly if comparison results do not support the reported checks.
stopifnot(
 all(con_checks$identical_common_values),
 all(quality$exact_duplicate_excess == 0L),
 all(quality$missing_amounts == 0L),
 all(abs(summary_check$total_difference) < 0.01),
 all(abs(summary_check$personnel_difference) < 0.01),
 all(abs(con_summary_check$total_difference) < 0.01),
 all(abs(sec_check$total_difference) < 0.01),
 nrow(old_id) == 1354L,
 nrow(new_id) == 2475L
)
