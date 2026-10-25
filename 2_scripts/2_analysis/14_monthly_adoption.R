## Date created:        24 October 2026
## Project:             Que todo cambie para que nada cambie
## Affiliation:         Asociación de Investigación y Estudios Sociales (ASIES)
## Title:               Verify adoption of the revised monthly sources
## Purpose:             Verify source/consolidated agreement, CONAP and nine cases.
## Inputs:              Active monthly/payroll workbooks; saved review case list.
## Outputs:             3_output/2_tables/16_monthly_adoption.
## Execution:           Independent validation after 2_scripts/0_master.R.
## Scope:               Read-only checks; does not repair unresolved source labels.
## -------------------------------------------------------------------------

library(dplyr)

out <- file.path("3_output", "2_tables", "16_monthly_adoption")
dir.create(out, recursive = TRUE, showWarnings = FALSE)

save_check <- function(data, filename) {
  write.csv(
    data,
    file.path(out, filename),
    row.names = FALSE,
    fileEncoding = "UTF-8"
  )
}

# Compare every active source value and its row order with the saved append.
monthly <- readxl::read_xlsx(
  "1_databases/programs/unified/SICOIN_consolidated.xlsx",
  sheet = "SICOIN",
  guess_max = 100000L
)
source_files <- Sys.glob("1_databases/programs/by ministry/SICOIN_*FINAL.xlsx")
source_checks <- lapply(source_files, function(path) {
  data <- readxl::read_xlsx(path, sheet = "SICOIN", guess_max = 100000L)
  ministry <- sub("^SICOIN_(.+?)_(Unificado_)?[0-9]{4}.*$", "\\1", basename(path), perl = TRUE)
  if (!"Archivo_Origen" %in% names(data)) {
    data$Archivo_Origen <- basename(path)
  }

  saved <- monthly %>% filter(Ministerio == ministry)
  same <- isTRUE(all.equal(
    as.data.frame(data),
    as.data.frame(saved[names(data)]),
    check.attributes = FALSE
  ))

  data.frame(
    Ministerio = ministry,
    source_rows = nrow(data),
    consolidated_rows = nrow(saved),
    all_values_and_order_equal = same
  )
}) %>% bind_rows()

save_check(source_checks, "4_source_validation.csv")
stopifnot(nrow(source_checks) == 16L)
stopifnot(all(source_checks$all_values_and_order_equal))
stopifnot(nrow(monthly) == 306632L)

# Recheck the same nine identities against actual active annual payroll totals.
# These are total expenditure comparisons, not personnel-only comparisons.
cases <- read.csv(
  "3_output/2_tables/15_monthly_review/5_nine_cases.csv",
  fileEncoding = "UTF-8"
) %>% select(case_id, Ministerio, Anio, Programa_Final)

payroll <- readxl::read_xlsx(
  "1_databases/payroll/unified/payroll_consolidated.xlsx",
  sheet = "anual",
  guess_max = 100000L
)
annual_monthly <- monthly %>%
  group_by(Ministerio, Anio = .data[["Año"]], Programa_Final) %>%
  summarise(monthly_execution = sum(Ejecutado), .groups = "drop")

annual_payroll <- payroll %>%
  group_by(Ministerio, Anio, Programa_Final) %>%
  summarise(payroll_execution = sum(Devengado_total), .groups = "drop")

case_check <- cases %>%
  left_join(annual_monthly, by = c("Ministerio", "Anio", "Programa_Final")) %>%
  left_join(annual_payroll, by = c("Ministerio", "Anio", "Programa_Final")) %>%
  mutate(
    difference = payroll_execution - monthly_execution,
    matches_to_cent = !is.na(difference) & abs(difference) < 0.011
  )

save_check(case_check, "5_nine_cases.csv")
stopifnot(nrow(case_check) == 9L, all(case_check$matches_to_cent))

# CONAP now has all twelve months, including the supplied second semester.
conap <- monthly %>%
  filter(
    Ministerio == "Secretarias",
    .data[["Año"]] == 2011,
    grepl("CONSEJO NACIONAL DE AREAS PROTEGIDAS|CONAP", Entidad)
  ) %>%
  group_by(Mes) %>%
  summarise(rows = n(), execution = sum(Ejecutado), .groups = "drop")

save_check(conap, "6_conap_2011.csv")
stopifnot(nrow(conap) == 12L)
stopifnot(abs(sum(conap$execution) - 89580207.52) < 0.011)

# Preserve evidence of the unresolved zero-value repetitions in MICIVI.
micivi <- monthly %>% filter(Ministerio == "MICIVI")
duplicate_rows <- micivi[duplicated(as.data.frame(micivi)), ]
save_check(duplicate_rows, "7_retained_micivi_duplicates.csv")
stopifnot(nrow(duplicate_rows) == 30L)
stopifnot(all(duplicate_rows$Ejecutado == 0))

message("Adoption verified: 16 sources; 306,632 rows; 9/9 cases matched; CONAP complete.")
