## Date created:        23 October 2026
## Project:             Que todo cambie para que nada cambie
## Affiliation:         Asociación de Investigación y Estudios Sociales (ASIES)
## Title:               Read-only audit of known source and consolidated databases
## Purpose:             Check consistency, keys, coverage and suspicious values.
## Inputs:              Only the 16 program and 15 payroll/roster workbooks already in use.
## Outputs:             3_output/2_tables/9_data_audit; source files remain unchanged.
## Execution:           Run from the project root; this audit is not part of the master.
## Limits:              Flags require source verification; accounting adjustments may be valid.
## -------------------------------------------------------------------------

library(dplyr)
source("2_scripts/99_helpers/99_helpers.R")
source("2_scripts/99_helpers/99_payroll_helpers.R")

out <- "3_output/2_tables/9_data_audit"
dir.create(out, recursive = TRUE, showWarnings = FALSE)
export <- function(x, name) {
  write.csv(x, file.path(out, paste0(name, ".csv")), row.names = FALSE, fileEncoding = "UTF-8")
}

# Explicit allowlist: never discover or open new database files.
ministries <- c("MAGA", "MARN", "MCD", "MEM", "MICIVI", "MIDES", "MINDEF",
                "MINECO", "MINEDUC", "MINEX", "MINFIN", "MINGOB", "MINTRAB", "MSPAS")
debt_files <- Sys.glob("1_databases/programs/by ministry/SICOIN_Deuda*FINAL.xlsx")
stopifnot(length(debt_files) == 1L)
program_names <- c(
  basename(debt_files),
  paste0("SICOIN_", ministries[ministries != "MINEDUC"], "_Unificado_2004_2025_FINAL.xlsx"),
  "SICOIN_MINEDUC_2004_2025_FINAL.xlsx",
  "SICOIN_Secretarias_Unificado_2004_2025_FINAL.xlsx"
)
sources <- lapply(program_names, function(name) {
  x <- readxl::read_xlsx(file.path("1_databases/programs/by ministry", name), sheet = "SICOIN")
  x$Ministerio <- sub("^SICOIN_(.+?)_(Unificado_)?[0-9]{4}.*$", "\\1", name, perl = TRUE)
  if (!"Archivo_Origen" %in% names(x)) x$Archivo_Origen <- name
  x
})
programs <- bind_rows(sources)
unified <- readxl::read_xlsx("1_databases/programs/unified/SICOIN_consolidated.xlsx", sheet = "SICOIN")

# Compare each entire source slice with the matching consolidated slice.
reconciliation <- bind_rows(lapply(seq_along(sources), function(i) {
  x <- sources[[i]]
  y <- unified %>% filter(Ministerio == x$Ministerio[1])
  data.frame(
    file = program_names[i], source_rows = nrow(x), consolidated_rows = nrow(y),
    identical_values_and_order = isTRUE(all.equal(as.data.frame(x), as.data.frame(y[names(x)]), check.attributes = FALSE)),
    execution_difference = sum(y$Ejecutado) - sum(x$Ejecutado),
    assigned_difference = sum(y$Asignado) - sum(x$Asignado),
    current_difference = sum(y$Vigente) - sum(x$Vigente)
  )
}))
export(reconciliation, "1_program_reconciliation")

# Source row numbers refer to Excel rows, including the header.
programs <- programs %>%
  group_by(Ministerio) %>%
  mutate(excel_row = row_number() + 1L) %>%
  ungroup() %>%
  mutate(month = recode_month(Mes), year = as.integer(.data[["Año"]]))
source_profile <- programs %>%
  group_by(Ministerio, Archivo_Origen) %>%
  summarise(
    rows = n(), first_year = min(year), last_year = max(year),
    observed_months = n_distinct(paste(year, month)),
    missing_months = sum(is.na(month)), missing_final_names = sum(is.na(Programa_Final) | trimws(Programa_Final) == ""),
    missing_department = sum(is.na(Depto) | trimws(Depto) == ""),
    execution_negative = sum(Ejecutado < 0),
    assigned_negative = sum(Asignado < 0), current_negative = sum(Vigente < 0),
    missing_or_nonfinite_amounts = sum(!is.finite(Ejecutado) | !is.finite(Asignado) | !is.finite(Vigente)),
    .groups = "drop"
  )
export(source_profile, "2_program_profile")
original_columns <- setdiff(names(unified), c("Ministerio", "Archivo_Origen"))
duplicate_rows <- programs %>%
  group_by(across(all_of(c("Archivo_Origen", original_columns)))) %>%
  filter(n() > 1L) %>%
  ungroup()
export(duplicate_rows, "3_exact_duplicates")

# Original-name keys identify potentially repeated source records; final names may
# legitimately merge multiple original labels, so audit those collisions separately.
key <- c("Ministerio", "year", "month", "Entidad", "Depto", "Programa")
duplicate_keys <- programs %>%
  group_by(across(all_of(key))) %>%
  filter(n() > 1L) %>%
  ungroup()
export(duplicate_keys, "4_repeated_keys")
negative <- programs %>% filter(Ejecutado < 0 | Asignado < 0 | Vigente < 0)
export(negative, "5_negative_amounts")

coverage <- programs %>%
  count(Ministerio, year, month, name = "rows")
missing_months <- bind_rows(lapply(split(coverage, coverage$Ministerio), function(x) {
  # Audit only the observed life of each ministry, not years before it exists.
  dates <- x$year * 12L + x$month - 1L
  span <- min(dates):max(dates)
  absent <- setdiff(span, dates)
  data.frame(Ministerio = rep(x$Ministerio[1], length(absent)),
             year = absent %/% 12L, month = absent %% 12L + 1L)
}))
export(missing_months, "6_missing_months")
export(coverage, "7_month_coverage")
annual <- programs %>%
  group_by(Ministerio, year) %>%
  summarise(execution = sum(Ejecutado), rows = n(), programs = n_distinct(Programa_Final), .groups = "drop") %>%
  group_by(Ministerio) %>%
  arrange(year, .by_group = TRUE) %>%
  mutate(growth_pct = 100 * (execution / lag(execution) - 1)) %>%
  ungroup()
export(annual, "8_annual_trends")

# Report formatting differences without silently changing identities.
labels <- programs %>% distinct(Ministerio, Programa_Final) %>%
  mutate(normalized = payroll_key(Programa_Final)) %>%
  group_by(Ministerio, normalized) %>% filter(n() > 1L) %>% ungroup()
export(labels, "9_label_variants")

# Payroll: read only the 14 known annual spending workbooks and the existing roster.
# Reconstruct the current 15-group payroll data with the same validated reader.
# This includes Secretariat units and preserves the supplied final program names.
reconstructed <- read_payroll_sources(list(
  payroll_input_dir = "1_databases/payroll/by ministry"
))
detail <- reconstructed$detalle
summaries <- reconstructed$resumen_origen
payroll_detail <- split(detail, detail$Ministerio)
payroll_summary <- split(summaries, summaries$Ministerio)
payroll_ministries <- names(payroll_detail)
payroll_file <- "1_databases/payroll/unified/payroll_consolidated.xlsx"
detail_saved <- readxl::read_xlsx(payroll_file, sheet = "detalle", guess_max = 100000L)
summaries_saved <- readxl::read_xlsx(payroll_file, sheet = "resumen_origen", guess_max = 100000L)
payroll_reconciliation <- bind_rows(lapply(payroll_ministries, function(m) {
  d <- payroll_detail[[m]]
  y <- detail_saved %>% filter(Ministerio == m)
  s <- payroll_summary[[m]]
  z <- summaries_saved %>% filter(Ministerio == m)
  data.frame(Ministerio = m, source_rows = nrow(d), consolidated_rows = nrow(y),
    identical_detail = isTRUE(all.equal(as.data.frame(d), as.data.frame(y[names(d)]), check.attributes = FALSE)),
    identical_summary = isTRUE(all.equal(as.data.frame(s), as.data.frame(z[names(s)]), check.attributes = FALSE)))
}))
export(payroll_reconciliation, "10_payroll_reconciliation")
payroll_duplicates <- detail %>%
  group_by(across(everything())) %>% filter(n() > 1L) %>% ungroup()
export(payroll_duplicates, "11_payroll_duplicates")
payroll_key_duplicates <- detail %>%
  group_by(Ministerio, Anio, Entidad, Cod_prog, Tipo, Cod_grupo) %>%
  filter(n() > 1L) %>% ungroup()
export(payroll_key_duplicates, "12_payroll_repeated_keys")
payroll_profile <- detail %>%
  group_by(Ministerio) %>%
  summarise(rows = n(), first_year = min(Anio), last_year = max(Anio),
    negative_execution = sum(Devengado < 0), negative_assigned = sum(Asignado < 0),
    negative_current = sum(Vigente < 0),
    missing_amounts = sum(!is.finite(Devengado) | !is.finite(Asignado) | !is.finite(Vigente)),
    missing_keys = sum(is.na(Cod_prog) | is.na(Cod_grupo) | is.na(Nombre_prog)),
    .groups = "drop")
export(payroll_profile, "13_payroll_profile")
payroll_annual <- detail %>%
  group_by(Ministerio, Anio, Unidad_ejecutora, Secretaria, Cod_prog, Nombre_prog, Programa_Final, Archivo_Origen) %>%
  summarise(Devengado_total = sum(Devengado), Serv_personales = sum(Devengado[Cod_grupo == "000"]), .groups = "drop") %>%
  mutate(pct_planilla = ifelse(Devengado_total > 0, 100 * Serv_personales / Devengado_total, NA_real_))
check <- full_join(payroll_annual, summaries,
  by = c("Ministerio", "Anio", "Unidad_ejecutora", "Secretaria", "Cod_prog", "Nombre_prog", "Programa_Final", "Archivo_Origen"), suffix = c("_calc", "_source")) %>%
  mutate(total_difference = Devengado_total_calc - Devengado_total_source,
    personnel_difference = Serv_personales_calc - Serv_personales_source,
    share_difference = pct_planilla_calc - pct_planilla_source)
export(check, "14_payroll_summary_check")
export(payroll_annual %>% filter(pct_planilla < 0 | pct_planilla > 100), "15_invalid_payroll_shares")

# Cross-database execution totals should be compared before interpreting payroll
# shares; a match is not assumed merely because ministry and year coincide.
monthly_totals <- programs %>% filter(Ministerio %in% payroll_ministries) %>%
  group_by(Ministerio, Anio = year) %>% summarise(monthly_execution = sum(Ejecutado), .groups = "drop")
payroll_totals <- detail %>% group_by(Ministerio, Anio) %>%
  summarise(payroll_database_execution = sum(Devengado), .groups = "drop")
cross <- full_join(monthly_totals, payroll_totals, by = c("Ministerio", "Anio")) %>%
  mutate(difference = payroll_database_execution - monthly_execution,
    difference_pct = 100 * difference / monthly_execution)
export(cross, "16_cross_database_totals")

# Verify every saved payroll sheet that has a directly reconstructed counterpart.
annual_saved <- readxl::read_xlsx(payroll_file, sheet = "anual", guess_max = 100000L)
annual_compare <- full_join(payroll_annual, annual_saved,
  by = c("Ministerio", "Anio", "Unidad_ejecutora", "Secretaria", "Cod_prog", "Nombre_prog", "Programa_Final", "Archivo_Origen"), suffix = c("_calc", "_saved"))
export(annual_compare, "17_payroll_annual_check")
roster_path <- "1_databases/payroll/by ministry/secretarias_por_ano.xlsx"
roster_checks <- if (file.exists(roster_path)) bind_rows(lapply(readxl::excel_sheets(roster_path), function(sheet) {
  x <- readxl::read_xlsx(roster_path, sheet = sheet)
  x$Archivo_Origen <- basename(roster_path)
  y <- readxl::read_xlsx(payroll_file, sheet = paste0("secretarias_", sheet))
  data.frame(sheet = sheet, source_rows = nrow(x), saved_rows = nrow(y),
    identical_values = isTRUE(all.equal(as.data.frame(x), as.data.frame(y[names(x)]), check.attributes = FALSE)))
 })) else data.frame(
  sheet = character(), source_rows = integer(),
  saved_rows = integer(), identical_values = logical()
)
export(roster_checks, "18_roster_check")
print(reconciliation)
print(source_profile)
print(payroll_reconciliation)
cat("Exact duplicate rows:", nrow(duplicate_rows), "; repeated program keys:", nrow(duplicate_keys), "\n")
cat("Payroll duplicate rows:", nrow(payroll_duplicates), "; repeated keys:", nrow(payroll_key_duplicates), "\n")
cat("Negative monthly rows:", nrow(negative), "; missing ministry-months:", nrow(missing_months), "\n")
print(cross %>% arrange(desc(abs(difference_pct))) %>% head(20))
print(check %>% summarise(max_total_difference = max(abs(total_difference)), max_personnel_difference = max(abs(personnel_difference)), max_share_difference = max(abs(share_difference), na.rm = TRUE)))

# Quantify near-duplicate MCD/MEM records with full source precision.
# Only these already-approved source files are reopened; no new input is read.
paired <- bind_rows(lapply(c("MCD", "MEM"), function(m) {
  name <- paste0("SICOIN_", m, "_Unificado_2004_2025_FINAL.xlsx")
  x <- readxl::read_xlsx(file.path("1_databases/programs/by ministry", name), sheet = "SICOIN")
  x$excel_row <- seq_len(nrow(x)) + 1L
  x$Ministerio <- m
  x %>%
    filter((Ministerio == "MCD" & .data[["Año"]] >= 2024) |
           (Ministerio == "MEM" & .data[["Año"]] == 2008 & Mes == "FEBRERO")) %>%
    group_by(Ministerio, .data[["Año"]], Mes, Entidad, Depto, Programa) %>%
    summarise(
      copies = n(), source_rows = paste(excel_row, collapse = ";"),
      execution_min = min(Ejecutado), execution_max = max(Ejecutado),
      execution_sum = sum(Ejecutado),
      assigned_range = max(Asignado) - min(Asignado),
      current_range = max(Vigente) - min(Vigente),
      .groups = "drop"
    ) %>%
    mutate(execution_range = execution_max - execution_min)
}))
export(paired, "19_paired_records")
print(paired %>% group_by(Ministerio, .data[["Año"]]) %>%
  summarise(keys = n(), min_copies = min(copies), max_copies = max(copies),
    max_execution_range = max(execution_range), max_assigned_range = max(assigned_range),
    max_current_range = max(current_range), execution_as_stored = sum(execution_sum),
    one_record_lower = sum(execution_min), one_record_upper = sum(execution_max),
    .groups = "drop"), width = 180)
# Detect complete duplicated halves only when a month has an even row count.
# Corrected months need not have an even number of legitimate source records.
x <- readxl::read_xlsx(
  "1_databases/programs/by ministry/SICOIN_MCD_Unificado_2004_2025_FINAL.xlsx",
  sheet = "SICOIN"
)
x$excel_row <- seq_len(nrow(x)) + 1L
recent <- x[x[["Año"]] >= 2024, ]
groups <- split(recent, paste(recent[["Año"]], recent$Mes))
result <- bind_rows(lapply(groups, function(data) {
  identical_halves <- FALSE

  if (nrow(data) %% 2L == 0L) {
    half <- nrow(data) %/% 2L
    columns <- setdiff(names(data), "excel_row")
    first <- as.data.frame(data[seq_len(half), columns])
    second <- as.data.frame(data[half + seq_len(half), columns])
    identical_halves <- isTRUE(all.equal(first, second, check.attributes = FALSE))
  }

  data.frame(
    year = data[["Año"]][1],
    month = data$Mes[1],
    rows = nrow(data),
    duplicated_complete_block = identical_halves,
    execution = sum(data$Ejecutado)
  )
}))
export(result, "20_mcd_blocks")
print(result)
