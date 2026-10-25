## Date created:        13 October 2026
## Original analysis:   21 May 2026 (Fernando Sáenz)
## Last modification:   20 October 2026
## Project:             Que todo cambie para que nada cambie
## Affiliation:         Asociación de Investigación y Estudios Sociales (ASIES)
## Title:               Append ministry databases
## Purpose:             Bind source rows without aggregation; preserve original columns and provenance.
## Inputs / outputs:    1_databases/programs/by ministry -> 1_databases/programs/unified/SICOIN_consolidated.xlsx.
## Execution:           Run 2_scripts/0_master.R from R or Rscript.
## Method provenance:   Refactored from volatility_all_ministries_FIXED.R.
## -------------------------------------------------------------------------

# ======================== LOCATE PROGRAM WORKBOOKS ==========================
# Use paths from the master instead of defining another working directory.
if (!exists("config")) {
  stop("Run 2_scripts/0_master.R first.")
}

# Sys.glob also discovers Windows OneDrive reparse-point files that list.files
# can omit. Source identifiers keep similarly named programs distinct.
source_files <- sort(Sys.glob(file.path(config$input_dir, "SICOIN_*_FINAL.xlsx")))
if (!length(source_files)) {
  stop("No SICOIN_*_FINAL.xlsx workbooks found in ", config$input_dir)
}

# ======================== READ AND IDENTIFY SOURCE ROWS =====================
# Validate each ministry file and attach its ministry/filename to every row.
source_rows <- lapply(source_files, function(path) {
  raw <- readxl::read_xlsx(
    path,
    sheet = "SICOIN"
  )
  require_columns(
    raw,
    c(
      "Año", "Mes", "Entidad", "Depto", "Programa",
      config$program_column, "Asignado", "Vigente", "Ejecutado"
    ),
    basename(path)
  )
  if ("Ministerio" %in% names(raw)) {
    stop("Reserved provenance columns in ", path)
  }

  raw$Ministerio <- sub("^SICOIN_(.+?)_(Unificado_)?[0-9]{4}.*$", "\\1", basename(path), perl = TRUE)
  if (!"Archivo_Origen" %in% names(raw)) {
    raw$Archivo_Origen <- basename(path)
  }
  if (anyNA(raw$Archivo_Origen) || any(trimws(raw$Archivo_Origen) == "")) {
    stop("Missing source provenance in ", path)
  }
  message("Appending ", raw$Ministerio[1], ": ", nrow(raw), " rows")
  raw
})

# ======================== APPEND AND SAVE ===================================
# Append rows without aggregating, removing duplicates or changing source amounts.
consolidated <- dplyr::bind_rows(source_rows)
stopifnot(nrow(consolidated) == sum(vapply(source_rows, nrow, integer(1))))
dir.create(dirname(config$unified_file), recursive = TRUE, showWarnings = FALSE)

# Write the consolidated workbook after every required table is ready.
writexl::write_xlsx(
  list(SICOIN = consolidated),
  config$unified_file
)
message("Saved consolidated database: ", nrow(consolidated), " rows.")
rm(source_rows, consolidated)
