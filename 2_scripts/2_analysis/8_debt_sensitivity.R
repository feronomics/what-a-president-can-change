## Date created:        21 October 2026
## Project:             Que todo cambie para que nada cambie
## Affiliation:         Asociación de Investigación y Estudios Sociales (ASIES)
## Title:               Public-debt sensitivity analysis
## Purpose:             Repeat debt-sensitive analyses with public debt included.
## Inputs:              Existing consolidated data and fitted volatility workbook.
## Outputs:             3_output/4_sensitivity/with_debt/{2_tables,3_graphs}.
## Execution:           Called by the single 2_scripts/0_master.R after stage 7.
## Methods:             Identical definitions, periods and models; only scope changes.
## -------------------------------------------------------------------------

# Keep alternative settings and intermediate objects separate from main results.
# Reload helpers here so their output paths use this environment's config.
sensitivity_env <- new.env(parent = environment())
sensitivity_env$config <- config
sensitivity_env$config$include_public_debt <- TRUE
sensitivity_env$config$output_dir <- file.path(config$output_dir, "4_sensitivity", "with_debt")
sensitivity_env$config$volatility_file <- file.path(config$output_dir, "1_volatility-index", "volatility_index.xlsx")

source("2_scripts/99_helpers/99_helpers.R", local = sensitivity_env)

# Reuse the saved full-scope model results; no SARIMA refitting is required.
sensitivity_env$raw <- readxl::read_xlsx(config$unified_file, sheet = "SICOIN")
sensitivity_env$raw$Programa_Analisis <- sensitivity_env$raw[[config$program_column]]
sensitivity_env$raw$fecha <- as.Date(sprintf(
  "%04d-%02d-01",
  as.integer(sensitivity_env$raw[["Año"]]),
  recode_month(sensitivity_env$raw$Mes)
))
sensitivity_env$program_results <- readxl::read_xlsx(
  sensitivity_env$config$volatility_file,
  sheet = "program_results"
)
sensitivity_env$program_results$date <- as.Date(sensitivity_env$program_results$date)
sensitivity_env$diagnostics <- readxl::read_xlsx(
  sensitivity_env$config$volatility_file,
  sheet = "diagnostics"
)

# Repeat all outputs that previously excluded debt, using the same stage scripts.
# Ministry and payroll analyses already use full scope and need no duplicate run.
for (script in c(
  "2_state_level.R", "5_program_level.R",
  "6_structural_break.R", "7_budget_composition.R"
)) {
  source(file.path("2_scripts", "2_analysis", script), local = sensitivity_env)
}

# Put the main and alternative estimates side by side in auditable CSVs.
# Preserve all test specifications and dates instead of selecting significant ones.
comparison_dir <- file.path(config$output_dir, "4_sensitivity")
for (item in list(
  c("6_breaks/3_means.csv", "1_means.csv"),
  c("6_breaks/2_tests.csv", "2_tests.csv"),
  c("7_priorities/1_resumen.csv", "3_governments.csv")
)) {
  main <- read.csv(file.path(config$output_dir, "2_tables", item[1]))
  alternative <- read.csv(file.path(sensitivity_env$config$output_dir, "2_tables", item[1]))
  main$scope <- "without_debt"
  alternative$scope <- "with_debt"

  utils::write.csv(
    dplyr::bind_rows(main, alternative),
    file.path(comparison_dir, item[2]),
    row.names = FALSE,
    fileEncoding = "UTF-8"
  )
}

message("Debt sensitivity results: ", sensitivity_env$config$output_dir)
