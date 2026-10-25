## Date created:        23 October 2026
## Project:             Que todo cambie para que nada cambie
## Affiliation:         Asociación de Investigación y Estudios Sociales (ASIES)
## Title:               Correct confirmed source errors
## Purpose:             Correct duplicates/MINTRAB amount and recover three verified months.
## Inputs:              Existing monthly program and annual payroll source workbooks.
## Outputs:             Corrected sources; original backups in archive; row-level change log.
## Execution:           Single master, before both append stages; safe to run again.
## Scope:               Leave CONAP and unresolved payroll gaps unchanged.
## -------------------------------------------------------------------------

# Do not collapse rows merely because their names or codes match.
# Money is compared at its reported cent precision; preserve retained values.
clean_source_rows <- function(data) {
  conap <- rep(FALSE, nrow(data))
  for (column in names(data)[vapply(data, is.character, logical(1))]) {
    label <- payroll_key(data[[column]])
    conap <- conap | (!is.na(label) & grepl("CONAP|CONSEJONACIONALDEAREASPROTEGIDAS", label))
  }

  keys <- as.data.frame(data)
  for (column in intersect(c("Asignado", "Vigente", "Ejecutado", "Devengado",
                             "Devengado_total", "Serv_personales"), names(keys))) {
    keys[[column]] <- round(keys[[column]], 2)
  }

  # The October 24 monthly delivery lost region numbers in some MICIVI rows.
  # Apparent repetitions with that incomplete geography remain unresolved:
  # retain them until their original regional identities can be checked.
  # Their zero amounts do not affect spending sums; automatic removal would
  # hide a source-label problem rather than establish true duplication.
  unresolved_region <- rep(FALSE, nrow(data))
  if ("Depto" %in% names(data)) {
    unresolved_region <- !is.na(data$Depto) &
      payroll_key(data$Depto) == "MULTIDEPARTAMENTALREGION"
  }

  remove <- duplicated(keys) & !conap & !unresolved_region
  list(data = data[!remove, , drop = FALSE], removed = which(remove))
}

# Use only the source patterns already used by the two preprocessing stages.
files <- c(
  Sys.glob(file.path(config$input_dir, "SICOIN_*_FINAL.xlsx")),
  Sys.glob(file.path(config$payroll_input_dir, "*_gasto_por_grupo.xlsx"))
)
files <- files[!startsWith(basename(files), "~$")]
plans <- list()
changes <- list()

# Prepare every change before writing any workbook.
for (file in files) {
  sheets <- setNames(lapply(readxl::excel_sheets(file), function(sheet) {
    readxl::read_xlsx(file, sheet = sheet)
  }), readxl::excel_sheets(file))
  changed <- FALSE

  for (sheet in intersect(names(sheets), c("SICOIN", "detalle", "resumen_planilla"))) {
    original <- sheets[[sheet]]
    fixed <- clean_source_rows(original)

    if (length(fixed$removed)) {
      removed <- original[fixed$removed, , drop = FALSE]
      removed$source_file <- basename(file)
      removed$source_sheet <- sheet
      removed$original_excel_row <- fixed$removed + 1L
      removed$action <- "remove_identical_record"
      changes[[length(changes) + 1L]] <- removed
      changed <- TRUE
    }

    # The supplied report identifies this exact amount, month and program.
    # A corrected file is accepted unchanged; any other value requires review.
    if (grepl("^SICOIN_MINTRAB_", basename(file)) && sheet == "SICOIN") {
      d <- fixed$data
      target <- d[["Año"]] == 2005 & recode_month(d$Mes) == 5L &
        payroll_key(d$Depto) == "GUATEMALA" &
        grepl("RECREACION", payroll_key(d$Programa_Final))
      target[is.na(target)] <- FALSE
      stopifnot(sum(target) == 1L)
      old <- d$Ejecutado[target]

      if (abs(old - 7052675.82) < 0.01) {
        log <- d[target, , drop = FALSE]
        log$source_file <- basename(file)
        log$source_sheet <- sheet
        log$original_excel_row <- which(!seq_len(nrow(original)) %in% fixed$removed)[which(target)] + 1L
        log$action <- "correct_execution_from_supplied_report"
        log$corrected_execution <- 528851.91
        changes[[length(changes) + 1L]] <- log
        fixed$data$Ejecutado[target] <- 528851.91
        changed <- TRUE
      } else if (abs(old - 528851.91) >= 0.01) {
        stop("Unexpected MINTRAB May 2005 amount: ", old)
      }
    }

    sheets[[sheet]] <- fixed$data
  }

  if (changed) {
    plans[[file]] <- sheets
  }
}

# Preserve the exact original workbook before its first correction.
backup_dir <- file.path("archive", "2026-10-23_source_corrections")
dir.create(backup_dir, recursive = TRUE, showWarnings = FALSE)
for (file in names(plans)) {
  backup <- file.path(backup_dir, basename(file))
  if (!file.exists(backup) && !file.copy(file, backup)) {
    stop("Could not back up source workbook: ", file)
  }
}

for (file in names(plans)) {
  writexl::write_xlsx(plans[[file]], file)
}

# Keep the first correction log when later runs find nothing else to change.
if (length(changes)) {
  log_dir <- file.path(config$output_dir, "2_tables", "9_data_audit")
  dir.create(log_dir, recursive = TRUE, showWarnings = FALSE)
  write.csv(
    dplyr::bind_rows(changes),
    file.path(log_dir, paste0("21_corrections_", format(Sys.time(), "%Y%m%d_%H%M%S"), ".csv")),
    row.names = FALSE,
    fileEncoding = "UTF-8"
  )
}

message("Source corrections: ", length(plans), " workbooks changed; CONAP retained before the recovery stage.")

# ======================== RECOVER VERIFIED MISSING MONTHS ==================
# Import only the three verified blocks preserved in a permanent correction CSV.
# MIDES payroll and CONAP are deliberately outside this monthly-data repair.
recovery_file <- file.path("1_databases", "corrections", "1_recovered_months.csv")
if (!file.exists(recovery_file)) {
  stop("Missing permanent recovery data: ", recovery_file)
}

reference <- read.csv(
  recovery_file,
  check.names = FALSE,
  fileEncoding = "UTF-8",
  stringsAsFactors = FALSE
)
recovery_blocks <- data.frame(
  Ministerio = c("MEM", "MINTRAB", "MINTRAB"),
  year = c(2008L, 2006L, 2006L),
  month = c(1L, 5L, 6L),
  expected_rows = c(7L, 51L, 51L)
)
recovered <- list()
recovery_backup <- file.path("archive", "2026-10-23_recovered_months")
dir.create(recovery_backup, recursive = TRUE, showWarnings = FALSE)

for (ministry in unique(recovery_blocks$Ministerio)) {
  source_name <- paste0("SICOIN_", ministry, "_Unificado_2004_2025_FINAL.xlsx")
  source_file <- file.path(config$input_dir, source_name)
  source_sheets <- setNames(lapply(readxl::excel_sheets(source_file), function(sheet) {
    readxl::read_xlsx(source_file, sheet = sheet)
  }), readxl::excel_sheets(source_file))
  data <- source_sheets$SICOIN
  provenance_changed <- FALSE

  # Retain PDF provenance for recovered observations in the individual workbook.
  # Existing rows keep their original ministry-file provenance.
  if (!"Archivo_Origen" %in% names(data)) {
    data$Archivo_Origen <- source_name
  }

  for (i in which(recovery_blocks$Ministerio == ministry)) {
    target_year <- recovery_blocks$year[i]
    target_month <- recovery_blocks$month[i]
    block <- reference %>%
      dplyr::filter(
        Ministerio == ministry,
        .data[["Año"]] == target_year,
        recode_month(Mes) == target_month
      ) %>%
      dplyr::select(-Ministerio)

    stopifnot(nrow(block) == recovery_blocks$expected_rows[i])
    stopifnot(!anyNA(block$Programa_Final))
    stopifnot(all(vapply(block[c("Asignado", "Vigente", "Ejecutado")], function(x) {
      all(is.finite(x))
    }, logical(1))))

    present <- data %>%
      dplyr::filter(.data[["Año"]] == target_year, recode_month(Mes) == target_month)

    if (nrow(present)) {
      # Never append twice or overwrite a partially present/conflicting month.
      sort_records <- function(x) {
        # A redelivered workbook may omit historical PDF provenance while
        # keeping every substantive field unchanged. Verify data separately.
        compare_columns <- setdiff(names(block), "Archivo_Origen")
        x <- as.data.frame(x[compare_columns])
        x[do.call(order, lapply(x, as.character)), , drop = FALSE]
      }
      if (!isTRUE(all.equal(
        sort_records(present), sort_records(block), check.attributes = FALSE
      ))) {
        stop("Existing records conflict with recovery block: ", ministry, " ", target_year, "-", target_month)
      }

      # Restore the already verified PDF source for the recovered months.
      # Match on substantive values so source row order is immaterial.
      compare_columns <- setdiff(names(block), "Archivo_Origen")
      source_index <- which(data[["Año"]] == target_year &
        recode_month(data$Mes) == target_month)
      matched <- dplyr::left_join(
        data[source_index, compare_columns, drop = FALSE],
        block,
        by = compare_columns
      )
      stopifnot(nrow(matched) == length(source_index))
      stopifnot(!anyNA(matched$Archivo_Origen))
      if (!identical(data$Archivo_Origen[source_index], matched$Archivo_Origen)) {
        data$Archivo_Origen[source_index] <- matched$Archivo_Origen
        provenance_changed <- TRUE
      }
    } else {
      data <- dplyr::bind_rows(data, block)
      log <- block
      log$Ministerio <- ministry
      log$recovery_workbook <- basename(recovery_file)
      log$target_file <- source_name
      recovered[[length(recovered) + 1L]] <- log
    }
  }

  if (nrow(data) != nrow(source_sheets$SICOIN) || provenance_changed) {
    backup <- file.path(recovery_backup, source_name)
    if (!file.exists(backup) && !file.copy(source_file, backup)) {
      stop("Could not back up recovery input: ", source_file)
    }

    source_sheets$SICOIN <- data
    writexl::write_xlsx(source_sheets, source_file)
  }
}

if (length(recovered)) {
  log_dir <- file.path(config$output_dir, "2_tables", "10_fixed_review")
  dir.create(log_dir, recursive = TRUE, showWarnings = FALSE)
  write.csv(
    dplyr::bind_rows(recovered),
    file.path(log_dir, "5_recovered_rows.csv"),
    row.names = FALSE,
    fileEncoding = "UTF-8"
  )
}
message("Recovered monthly records: ", sum(vapply(recovered, nrow, integer(1))), ".")
