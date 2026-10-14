## Date created:        13 October 2026
## Original analysis:   21 May 2026 (Fernando Sáenz)
## Last modification:   13 October 2026
## Project:             Que todo cambie para que nada cambie
## Affiliation:         Asociación de Investigación y Estudios Sociales (ASIES)
## Title:               Consolidated volatility analysis
## Purpose:             Read unified data, loop over ministries/programs, and write one results workbook.
## Inputs / outputs:    unified/SICOIN_consolidated.xlsx -> 3_output/1_volatility-index/volatility_index.xlsx.
## Execution:           Run 2_scripts/0_master.R from R or Rscript.
## Method provenance:   Refactored from volatility_all_ministries_FIXED.R.
## -------------------------------------------------------------------------


if (!exists("config") || !exists("fit_volatility")) stop("Run 2_scripts/0_master.R first.")
raw <- readxl::read_xlsx(config$unified_file, sheet = "SICOIN")
require_columns(raw, c("Ministerio", "Archivo_Origen", "Año", "Mes", config$program_column,
                      "Asignado", "Vigente", "Ejecutado"), "Unified database")
raw$Programa_Analisis <- raw[[config$program_column]]
month <- recode_month(raw$Mes)
year <- suppressWarnings(as.integer(raw[["Año"]]))
raw$fecha <- as.Date(sprintf("%04d-%02d-01", year, month), format = "%Y-%m-%d")
if (anyNA(raw$fecha)) stop("Invalid year/month values in the unified database.")
if (anyNA(raw$Programa_Analisis) || any(trimws(raw$Programa_Analisis) == "")) {
  stop("Missing program labels in ", config$program_column)
}
for (column in c("Asignado", "Vigente", "Ejecutado")) {
  if (!is.numeric(raw[[column]]) || any(!is.finite(raw[[column]]))) {
    stop(column, " must contain finite numeric amounts; resolve missing/invalid amounts before analysis.")
  }
}
results <- list()
for (ministry in unique(raw$Ministerio)) {
  message("Analyzing ", ministry)
  monthly <- raw |>
    dplyr::filter(Ministerio == ministry) |>
    dplyr::group_by(Programa = Programa_Analisis, fecha) |>
    dplyr::summarise(dplyr::across(c(Asignado, Vigente, Ejecutado), sum), .groups = "drop")
  monthly <- tidyr::complete(monthly, Programa,
             fecha = seq(min(monthly$fecha), max(monthly$fecha), by = "month"),
             fill = list(Asignado = 0, Vigente = 0, Ejecutado = 0))
  for (program in unique(monthly$Programa)) {
    series <- monthly[monthly$Programa == program, ]
    series <- series[order(series$fecha), ]
    fitted <- fit_volatility(series$Ejecutado, series$fecha, program,
                              config$min_obs, config$rolling_window)
    fitted$Ministerio <- ministry
    results[[length(results) + 1L]] <- fitted
  }
}
program_results <- dplyr::bind_rows(results) |>
  dplyr::select(Ministerio, dplyr::everything())
ministry_index <- aggregate_ministry_index(program_results)
# Include every ministry and the full source calendar, even if all fits fail.
calendar <- tidyr::expand_grid(Ministerio = sort(unique(raw$Ministerio)),
                               date = seq(min(raw$fecha), max(raw$fecha), by = "month"))
ministry_index <- dplyr::left_join(calendar, ministry_index, by = c("Ministerio", "date"))
ministry_wide <- ministry_index |>
  dplyr::select(Ministerio, date, volatility_index) |>
  tidyr::pivot_wider(names_from = Ministerio, values_from = volatility_index) |>
  dplyr::arrange(date)
diagnostics <- program_results |>
  dplyr::group_by(Ministerio, Programa) |>
  dplyr::summarise(first_month = min(date), last_month = max(date),
                   observations = dplyr::n(), index_total = dplyr::first(index_total),
                   flag = dplyr::first(flag), .groups = "drop")
sources <- raw |>
  dplyr::group_by(Ministerio, Archivo_Origen) |>
  dplyr::summarise(rows = dplyr::n(), first_month = min(fecha), last_month = max(fecha), .groups = "drop")
metadata <- data.frame(setting = c("program_column", "min_obs", "rolling_window", "model", "transformation"),
                       value = c(config$program_column, config$min_obs, config$rolling_window,
                                 "SARIMA(1,1,0)(1,1,0)[12]", "log1p(Ejecutado)"))
for (folder in c("1_volatility-index", "2_tables", "3_graphs")) {
  dir.create(file.path(config$output_dir, folder), recursive = TRUE, showWarnings = FALSE)
}
writexl::write_xlsx(list(ministry_index = ministry_wide, ministry_index_long = ministry_index,
                        program_results = program_results, diagnostics = diagnostics,
                        sources = sources, settings = metadata),
                   file.path(config$output_dir, "1_volatility-index", "volatility_index.xlsx"))
message("Programs: ", nrow(diagnostics), "; fitted: ", sum(diagnostics$flag == "OK"),
        "; skipped: ", sum(diagnostics$flag != "OK"))

