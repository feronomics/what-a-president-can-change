## Date created:        20 October 2026
## Last modification:   20 October 2026
## Project:             Que todo cambie para que nada cambie
## Affiliation:         Asociación de Investigación y Estudios Sociales (ASIES)
## Title:               Consolidate annual payroll databases
## Purpose:             Append annual detail and summaries; validate frequency and totals.
## Inputs:              1_databases/payroll/by ministry/*_gasto_por_grupo.xlsx.
## Scope:               14 ministry spending files plus Secretariat spending by executing unit.
## Output:              1_databases/payroll/unified/payroll_consolidated.xlsx.
## Execution:           Run the complete pipeline: 2_scripts/0_master.R.
## Frequency:           Annual Anio; never interpolate/repeat payroll into monthly rows.
## -------------------------------------------------------------------------

# ======================== READ AND VALIDATE ANNUAL DATA =====================
# The helper checks annual frequency and reconciles detail with source summaries.
if (!exists("config") || !exists("read_payroll_sources")) {
  stop("Run 2_scripts/0_master.R.")
}

payroll_sheets <- read_payroll_sources(config)

# ======================== SAVE THE PAYROLL WORKBOOK =========================
# Detail, annual totals, reconciliation and Secretariat rosters stay on separate sheets.
dir.create(dirname(config$payroll_unified_file), recursive = TRUE, showWarnings = FALSE)

# Write the consolidated workbook after every required table is ready.
writexl::write_xlsx(
  payroll_sheets,
  config$payroll_unified_file
)
message(
  "Saved annual payroll: ", nrow(payroll_sheets$detalle), " detail rows; ",
  nrow(payroll_sheets$anual), " source program-years; ", nrow(payroll_sheets$fuentes), " source groups."
)
rm(payroll_sheets)
