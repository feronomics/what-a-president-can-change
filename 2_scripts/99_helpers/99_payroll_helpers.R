## Date created:        20 October 2026
## Last modification:   20 October 2026
## Project:             Que todo cambie para que nada cambie
## Affiliation:         Asociación de Investigación y Estudios Sociales (ASIES)
## Title:               Annual payroll helpers
## Purpose:             Validate annual sources, link harmonized programs, build predictors.
## Inputs / outputs:    Function definitions for the annual payroll stages of the master pipeline.
## Execution:           Loaded by the single entry point, 0_master.R.
## Methods:             Exact aliases, approved name equivalents and minor spelling fixes.
## -------------------------------------------------------------------------

# Normalize label formatting for EXACT linkage: case, accents and punctuation.
# Input: labels. Return: comparable keys; this does not infer program equivalence.
payroll_key <- function(x) {
  # Formatting normalization, not substantive program-name harmonization.
  gsub("[^A-Z0-9]", "", toupper(iconv(as.character(x), to = "ASCII//TRANSLIT")))
}

# Confirm that an input has integer years and no monthly/date column.
# Inputs: worksheet data and its label. Stop when the frequency is unsuitable.
validate_annual <- function(data, label) {
  require_columns(
    data,
    "Anio",
    label
  )
  if (anyNA(data$Anio) || any(!is.finite(data$Anio)) ||
    any(data$Anio != as.integer(data$Anio))) {
    stop("Invalid annual years: ", label)
  }

  if (any(payroll_key(names(data)) %in% c("MES", "MONTH", "FECHA", "DATE"))) {
    stop("Monthly/date column found; inspect temporal frequency before appending: ", label)
  }
}

# Read and append annual payroll sources while retaining file provenance.
# Input: master configuration. Return: named sheets for one consolidated workbook.
# Recalculate personnel shares from group 000 and reconcile supplied summaries;
# preserve Secretariat counts separately because they are not spending.
read_payroll_sources <- function(config) {
  # Find annual spending workbooks; ignore Excel's temporary lock files.
  files <- sort(Sys.glob(file.path(config$payroll_input_dir, "*_gasto_por_grupo.xlsx")))
  files <- files[!startsWith(basename(files), "~$")]
  if (!length(files)) {
    stop("No annual payroll spending workbooks found.")
  }

  # Collect detail, summaries and provenance independently before appending.
  detail <- list()
  summaries <- list()
  sources <- list()

  for (i in seq_along(files)) {
    file <- files[i]
    ministry <- sub("_gasto_por_grupo.xlsx", "", basename(file), fixed = TRUE)
    sheets <- readxl::excel_sheets(file)
    if (!all(c("detalle", "resumen_planilla") %in% sheets)) {
      stop("Missing payroll sheets: ", file)
    }

    # Read detail and supplied summaries, then validate required fields.
    detail_data <- readxl::read_xlsx(
      file,
      sheet = "detalle",
      guess_max = 100000L
    )
    summary_data <- readxl::read_xlsx(
      file,
      sheet = "resumen_planilla",
      guess_max = 100000L
    )
    validate_annual(detail_data, file)
    validate_annual(summary_data, file)
    require_columns(
      detail_data,
      c(
        if (ministry != "Secretarias") "Entidad",
        "Cod_prog", "Nombre_prog", "Programa_Final", "Tipo", "Cod_grupo",
        "Nombre_grupo", "Asignado", "Vigente", "Comprometido", "Devengado"
      ),
      file
    )
    require_columns(
      summary_data,
      c("Cod_prog", "Nombre_prog", "Devengado_total", "Serv_personales", "pct_planilla"),
      file
    )
    for (column in c("Asignado", "Vigente", "Comprometido", "Devengado")) {
      if (!is.numeric(detail_data[[column]]) || any(!is.finite(detail_data[[column]]))) {
        stop("Invalid ", column, ": ", file)
      }
    }

    if (anyNA(detail_data$Nombre_prog) || anyNA(detail_data$Cod_grupo) || anyNA(detail_data$Cod_prog)) {
      stop("Missing payroll keys: ", file)
    }

    # Preserve leading-zero codes and verify that group 000 means personnel.
    detail_data$Cod_prog <- as.character(detail_data$Cod_prog)
    detail_data$Cod_grupo <- sprintf(
      "%03d",
      as.integer(detail_data$Cod_grupo)
    )
    if (anyNA(detail_data$Cod_grupo) || any(!grepl("^[0-9]{3}$", detail_data$Cod_grupo))) {
      stop("Invalid group code: ", file)
    }

    if (any(detail_data$Cod_grupo == "000" & payroll_key(detail_data$Nombre_grupo) != "SERVICIOSPERSONALES")) {
      stop("Group 000 disagrees with personnel label: ", file)
    }

    # Keep Secretariat institutions separate before summing program amounts.
    # Ministry workbooks do not have these fields; missing values are intentional.
    for (column in c("Unidad_ejecutora", "Secretaria")) {
      if (!column %in% names(detail_data)) {
        detail_data[[column]] <- NA_character_
      }
      if (!column %in% names(summary_data)) {
        summary_data[[column]] <- NA_character_
      }
      detail_data[[column]] <- as.character(detail_data[[column]])
      summary_data[[column]] <- as.character(summary_data[[column]])
    }
    summary_data$Cod_prog <- as.character(summary_data$Cod_prog)

    # Record where every row came from before combining ministries.
    detail_data$Ministerio <- ministry
    summary_data$Ministerio <- ministry

    detail_data$Archivo_Origen <- basename(file)
    summary_data$Archivo_Origen <- basename(file)

    detail[[i]] <- detail_data
    summaries[[i]] <- summary_data
    sources[[i]] <- data.frame(
      Archivo_Origen = basename(file),
      Ministerio = ministry,
      kind = "annual_spending",
      detail_rows = nrow(detail_data),
      summary_rows = nrow(summary_data),
      first_year = min(detail_data$Anio),
      last_year = max(detail_data$Anio),
      has_month_column = FALSE
    )
    message("Annual payroll: ", ministry, " (", min(detail_data$Anio), "-", max(detail_data$Anio), ")")
  }

  detail <- dplyr::bind_rows(detail)
  summaries <- dplyr::bind_rows(summaries)

  # Source names and executing units are part of the annual record identity.
  # Preserve the supplied final name for audited linkage to the monthly data.
  keys <- c(
    "Ministerio", "Anio", "Unidad_ejecutora", "Secretaria",
    "Cod_prog", "Nombre_prog", "Programa_Final", "Archivo_Origen"
  )

  # Aggregate detail to source program-years and calculate personnel shares.
  annual <- detail %>%
    dplyr::group_by(dplyr::across(dplyr::all_of(keys))) %>%
    dplyr::summarise(
      Devengado_total = sum(Devengado),
      Serv_personales = sum(Devengado[Cod_grupo == "000"]),
      has_personnel_group = any(Cod_grupo == "000"),
      .groups = "drop"
    ) %>%
    dplyr::mutate(
      pct_planilla = ifelse(
        Devengado_total > 0,
        100 * Serv_personales / Devengado_total,
        NA_real_
      )
    )

  # Reconcile recalculated amounts with the supplied annual summaries.
  if (anyDuplicated(summaries[keys])) {
    stop("Duplicate keys in supplied payroll summary.")
  }

  reconciled <- dplyr::full_join(
    annual,
    summaries,
    by = keys,
    suffix = c("_calc", "_source")
  )
  if (anyNA(reconciled$Devengado_total_calc) || anyNA(reconciled$Devengado_total_source)) {
    stop("Detail/summary keys do not reconcile.")
  }

  # Summary sheets round monetary amounts; retain precise detail amounts.
  reconciled$total_difference <- reconciled$Devengado_total_calc - reconciled$Devengado_total_source
  reconciled$personnel_difference <- reconciled$Serv_personales_calc - reconciled$Serv_personales_source
  tolerance <- pmax(2, abs(reconciled$Devengado_total_source) * 1e-8)
  if (any(abs(reconciled$total_difference) > tolerance) ||
    any(abs(reconciled$personnel_difference) > tolerance)) {
    stop("Payroll detail/summary amounts do not reconcile.")
  }

  # Preserve Secretariat counts/rosters separately from monetary data.
  auxiliary <- list()
  secretarias <- file.path(config$payroll_input_dir, "secretarias_por_ano.xlsx")
  if (file.exists(secretarias)) {
    for (sheet in readxl::excel_sheets(secretarias)) {
      data <- readxl::read_xlsx(
        secretarias,
        sheet = sheet
      )
      validate_annual(data, paste("Secretarias", sheet))
      data$Archivo_Origen <- basename(secretarias)
      auxiliary[[paste0("secretarias_", sheet)]] <- data
    }
  }

  # Reject unexpected workbooks instead of silently excluding them.
  recognized <- c(basename(files), if (file.exists(secretarias)) {
    basename(secretarias)
  })
  extra <- setdiff(basename(Sys.glob(file.path(config$payroll_input_dir, "*.xlsx"))), recognized)
  extra <- extra[!startsWith(extra, "~$")]
  if (length(extra)) {
    stop("Unrecognized payroll workbook(s): ", paste(extra, collapse = ", "))
  }

  c(list(
    detalle = detail,
    anual = annual,
    resumen_origen = summaries,
    fuentes = dplyr::bind_rows(sources),
    conciliacion = reconciled
  ), auxiliary)
}

# Link annual payroll rows to harmonized programs without multiplying rows.
# Inputs: annual payroll and the existing program-name crosswalk.
# Return: every payroll row, its harmonized identity if unique, and match status.
# Ambiguous/unmatched labels remain missing; do not allocate their spending.
link_payroll_exact <- function(annual, programs) {
  # Collect existing source-name aliases and their harmonized identities.
  alias_columns <- intersect(c("Programa", "Programa_Estandarizado", "Programa_Final"), names(programs))
  aliases <- dplyr::bind_rows(lapply(alias_columns, function(column) {
    data.frame(
      Ministerio = programs$Ministerio,
      Anio = programs[["Año"]],
      alias_key = payroll_key(programs[[column]]),
      Programa_Final = programs$Programa_Final
    )
  })) %>%
    dplyr::distinct() %>%
    dplyr::filter(!is.na(alias_key), alias_key != "")

  # Identify aliases that refer to exactly one program in a ministry-year.
  by_year <- aliases %>%
    dplyr::group_by(Ministerio, Anio, alias_key) %>%
    dplyr::summarise(
      candidates = dplyr::n_distinct(Programa_Final),
      final_year = dplyr::first(Programa_Final),
      .groups = "drop"
    )

  # Prepare a fallback only for aliases unique across the entire history.
  across_years <- aliases %>%
    dplyr::group_by(Ministerio, alias_key) %>%
    dplyr::summarise(
      candidates_all = dplyr::n_distinct(Programa_Final),
      final_all = dplyr::first(Programa_Final),
      .groups = "drop"
    )

  # Attach unique matches and explicitly label ambiguous/unmatched rows.
  linked <- annual %>%
    dplyr::mutate(alias_key = payroll_key(Nombre_prog)) %>%
    dplyr::left_join(
      by_year,
      by = c("Ministerio", "Anio", "alias_key")
    ) %>%
    dplyr::left_join(
      across_years,
      by = c("Ministerio", "alias_key")
    ) %>%
    dplyr::mutate(
      link_method = dplyr::case_when(
        candidates == 1L ~ "exact_alias_year",
        is.na(candidates) & candidates_all == 1L ~ "unique_alias_all_years",
        candidates > 1L | candidates_all > 1L ~ "ambiguous",
        TRUE ~ "unmatched"
      ),
      Programa_Final = dplyr::case_when(
        link_method == "exact_alias_year" ~ final_year,
        link_method == "unique_alias_all_years" ~ final_all,
        TRUE ~ NA_character_
      )
    )
  if (nrow(linked) != nrow(annual)) {
    stop("Linkage multiplied payroll rows.")
  }

  linked
}

# Expand only explicit abbreviations and one verified spelling error.
# Keep every program number, conjunction and scope word: 11/12 never becomes 13/14.
# This key is used ONLY for linkage, never to rewrite source or final names.
payroll_minor_label <- function(x) {
  label <- toupper(iconv(as.character(x), to = "ASCII//TRANSLIT"))
  label <- gsub("\\b(PRG|PROG)\\.?\\b", "PROGRAMAS", label)
  label <- gsub("\\bACTIVIDADADES\\b", "ACTIVIDADES", label)

  label
}

# Apply the six name equivalences approved by the author on 20 October 2026.
# These are ministry-specific name decisions, NOT verified code equivalences.
# Source labels/codes/amounts remain intact; targets must exist in monthly data.
payroll_approved_names <- function(linked, programs) {
  rules <- tibble::tribble(
    ~Ministerio, ~source_name, ~target_name,
    "MCD",
    "FOMENTO AL DEPORTE NO FEDERADO Y A LA RECREACION",
    "FOMENTO AL DEPORTE NO FEDERADO Y LA RECREACION",
    "MCD",
    "RESTAURACION, PRESERVACION Y PROTECCION DEL PATRIMONIO CULTURAL Y NATURAL",
    "PROTECCION, RESTAURACION Y PRESERVACION DEL PATRIMONIO CULTURAL Y NATURAL",
    "MINFIN",
    "SERVICIOS DE IMPRENTA",
    "SERVICIOS DE IMPRESION",
    "MINGOB",
    "SERVICIOS MIGRATORIOS Y EXTRANJERIA",
    "SERVICIOS DE MIGRACION Y EXTRANJERIA",
    "MINTRAB",
    "RECREACION DE LOS TRABAJADORES DEL ESTADO",
    "SERVICIOS DE RECREACION A LOS TRABAJADORES DEL ESTADO",
    "MSPAS",
    "SERVICIO DE FORMACION DEL RECURSO HUMANO",
    "SERVICIOS DE FORMACION DEL RECURSO HUMANO"
  )

  for (i in seq_len(nrow(rules))) {
    # Resolve the approved spelling to the exact existing monthly final label.
    targets <- unique(programs$Programa_Final[
      programs$Ministerio == rules$Ministerio[i] &
        payroll_key(programs$Programa_Final) == payroll_key(rules$target_name[i])
    ])
    if (length(targets) != 1L) {
      stop("Approved payroll target missing or ambiguous: ", rules$target_name[i])
    }

    rows <- which(
      linked$Ministerio == rules$Ministerio[i] &
        payroll_key(linked$Nombre_prog) == payroll_key(rules$source_name[i]) &
        linked$link_method == "unmatched"
    )
    linked$Programa_Final[rows] <- targets
    linked$link_method[rows] <- "approved_name_equivalence"
  }

  linked
}

# Retain exact links, apply approved names, then try minor spelling fixes.
# Ambiguous exact aliases cannot be overridden by the fallback.
# Final identities always come unchanged from the monthly Programa_Final column.
link_payroll_programs <- function(annual, programs) {
  # Current files provide an explicit final name. Validate it against the same
  # ministry and year, rather than replacing it using the original label.
  if ("Programa_Final" %in% names(annual)) {
    return(link_payroll_supplied(annual, programs))
  }

  linked <- link_payroll_exact(annual, programs)
  linked <- payroll_approved_names(linked, programs)
  pending <- which(linked$link_method == "unmatched")

  if (!length(pending)) {
    return(linked)
  }

  # Apply the same conservative comparison spelling on both sides of the join.
  comparison_annual <- annual[pending, ]
  comparison_annual$Nombre_prog <- payroll_minor_label(comparison_annual$Nombre_prog)
  comparison_programs <- programs
  alias_columns <- intersect(
    c("Programa", "Programa_Estandarizado", "Programa_Final"),
    names(programs)
  )

  # Preserve Programa_Final as the output identity; expand source aliases only.
  # Include a normalized copy of the final label as another source alias.
  comparison_programs$Programa <- payroll_minor_label(programs$Programa_Final)
  comparison_programs$Programa_Estandarizado <- payroll_minor_label(programs$Programa_Final)
  comparison_sources <- lapply(alias_columns, function(column) {
    copy <- comparison_programs
    copy$Programa <- payroll_minor_label(programs[[column]])

    copy
  })
  comparison_programs <- dplyr::bind_rows(comparison_sources)
  fallback <- link_payroll_exact(comparison_annual, comparison_programs)
  accepted <- which(!is.na(fallback$Programa_Final))
  rows <- pending[accepted]

  # Record the corrected comparison key and method alongside the untouched name.
  linked$Programa_Final[rows] <- fallback$Programa_Final[accepted]
  linked$link_method[rows] <- paste0("minor_spelling_", fallback$link_method[accepted])
  linked$alias_key[rows] <- fallback$alias_key[accepted]
  linked$candidates[rows] <- fallback$candidates[accepted]
  linked$final_year[rows] <- fallback$final_year[accepted]
  linked$candidates_all[rows] <- fallback$candidates_all[accepted]
  linked$final_all[rows] <- fallback$final_all[accepted]

  linked
}

# Prepare one observation per harmonized program for determinants analysis.
# Inputs: program data, volatility diagnostics, linked payroll and configuration.
# Return: model covariates, annual name-history evidence and linked annual totals.
# Keep payroll at annual frequency; source aliases are predictor/linkage evidence only.
payroll_program_covariates <- function(programs, diagnostics, linked, config) {
  # Construct monthly dates for program lifespan and naming-history measures.
  programs$fecha <- as.Date(sprintf(
    "%04d-%02d-01",
    as.integer(programs[["Año"]]),
    recode_month(programs$Mes)
  ))
  if (anyNA(programs$fecha)) {
    stop("Invalid date in consolidated programs.")
  }

  departments <- c(
    "ALTAVERAPAZ", "BAJAVERAPAZ", "CHIMALTENANGO", "CHIQUIMULA", "ELPROGRESO",
    "ESCUINTLA", "GUATEMALA", "HUEHUETENANGO", "IZABAL", "JALAPA", "JUTIAPA", "PETEN",
    "QUETZALTENANGO", "QUICHE", "RETALHULEU", "SACATEPEQUEZ", "SANMARCOS", "SANTAROSA",
    "SOLOLA", "SUCHITEPEQUEZ", "TOTONICAPAN", "ZACAPA"
  )
  programs$department_key <- payroll_key(programs$Depto)

  # Original labels are used ONLY as crosswalk evidence/predictor provenance;
  # every observation and analytical grouping uses harmonized Programa_Final.

  # Track source-label sets by year within each harmonized program.
  name_history <- programs %>%
    dplyr::filter(Ejecutado > 0) %>%
    dplyr::transmute(
      Ministerio,
      original_key = payroll_key(.data[["Programa"]]),
      Programa = Programa_Final,
      Anio = .data[["Año"]]
    ) %>%
    dplyr::distinct()
  names_by_year <- name_history %>%
    dplyr::group_by(Ministerio, Programa, Anio) %>%
    dplyr::summarise(
      signature = paste(sort(unique(original_key)), collapse = "|"),
      .groups = "drop"
    )

  # Flag changes in the observed label set between active years.
  renaming <- names_by_year %>%
    dplyr::group_by(Ministerio, Programa) %>%
    dplyr::summarise(
      name_change = as.integer(dplyr::n_distinct(signature) > 1L),
      name_sets = dplyr::n_distinct(signature),
      .groups = "drop"
    )

  # Count named departments with positive execution; retain regional-label flags.
  geography <- programs %>%
    dplyr::group_by(Ministerio, Programa = Programa_Final) %>%
    dplyr::summarise(
      department_count = dplyr::n_distinct(department_key[Ejecutado > 0 & department_key %in% departments]),
      non_department_labels = any(Ejecutado > 0 & !department_key %in% departments),
      execution = sum(Ejecutado),
      .groups = "drop"
    )

  # Calculate inclusive observed lifespan without splitting harmonized names.
  life <- program_lifetimes(programs, "Programa_Final") %>%
    dplyr::select(Ministerio, Programa, duration_months, active_months)

  # Sum linked payroll amounts by harmonized program and year.
  linked_year <- linked %>%
    dplyr::filter(!is.na(Programa_Final)) %>%
    dplyr::group_by(Ministerio, Programa = Programa_Final, Anio) %>%
    dplyr::summarise(
      Devengado_total = sum(Devengado_total),
      Serv_personales = sum(Serv_personales),
      .groups = "drop"
    )

  # Calculate expenditure-weighted payroll shares across available linked years.
  amounts <- linked_year %>%
    dplyr::group_by(Ministerio, Programa) %>%
    dplyr::summarise(
      payroll_total = sum(Serv_personales),
      payroll_denominator = sum(Devengado_total),
      payroll_years = dplyr::n_distinct(Anio),
      payroll_first_year = min(Anio),
      payroll_last_year = max(Anio),
      .groups = "drop"
    ) %>%
    dplyr::mutate(payroll_pct = ifelse(payroll_denominator > 0,
      100 * payroll_total / payroll_denominator, NA_real_
    ))

  # Join predictors to volatility and explain each model-sample exclusion.
  data <- diagnostics %>%
    dplyr::left_join(
      geography,
      by = c("Ministerio", "Programa")
    ) %>%
    dplyr::left_join(
      life,
      by = c("Ministerio", "Programa")
    ) %>%
    dplyr::left_join(
      renaming,
      by = c("Ministerio", "Programa")
    ) %>%
    dplyr::left_join(
      amounts,
      by = c("Ministerio", "Programa")
    ) %>%
    dplyr::mutate(
      longevity_years = duration_months / 12,
      payroll_10pp = payroll_pct / 10,
      volatile = dplyr::case_when(
        flag != "OK" | is.na(index_total) ~ NA_integer_,
        index_total > config$volatility_threshold ~ 1L,
        index_total < config$volatility_threshold ~ 0L,
        TRUE ~ NA_integer_
      ),
      exclusion = dplyr::case_when(
        flag != "OK" | is.na(index_total) ~ "no_valid_volatility",
        index_total == config$volatility_threshold ~ "exact_threshold",
        is.na(payroll_years) ~ "no_linked_payroll",
        !is.finite(payroll_pct) | payroll_pct < 0 | payroll_pct > 100 ~ "invalid_payroll_share",
        !is.finite(longevity_years) | is.na(name_change) ~ "missing_predictor",
        TRUE ~ "included"
      )
    )
  list(
    data = data,
    name_history = names_by_year,
    annual_linked = linked_year
  )
}

# Validate the supplied final names without forcing unresolved equivalences.
# A nonempty name absent in the monthly year stays unmatched (e.g. MIDES N7).
# The original source label and all amounts remain available in the link table.
link_payroll_supplied <- function(annual, programs) {
  targets <- programs %>%
    dplyr::transmute(
      Ministerio,
      Anio = .data[["Año"]],
      supplied_key = payroll_key(Programa_Final),
      monthly_final = Programa_Final
    ) %>%
    dplyr::distinct() %>%
    dplyr::group_by(Ministerio, Anio, supplied_key) %>%
    dplyr::summarise(
      target_count = dplyr::n_distinct(monthly_final),
      target_name = dplyr::first(monthly_final),
      .groups = "drop"
    )

  linked <- annual %>%
    dplyr::mutate(
      Programa_Final_Fuente = Programa_Final,
      supplied_key = payroll_key(Programa_Final)
    ) %>%
    dplyr::left_join(targets, by = c("Ministerio", "Anio", "supplied_key")) %>%
    dplyr::mutate(
      Programa_Final = dplyr::if_else(target_count == 1L, target_name, NA_character_),
      link_method = dplyr::case_when(
        target_count == 1L ~ "supplied_final_year",
        is.na(supplied_key) | supplied_key == "" ~ "unmatched",
        TRUE ~ "supplied_final_without_monthly_year"
      )
    )

  # Only blank source names may use the previously approved alias rules.
  # Never override a supplied nonempty name with an unapproved equivalence.
  pending <- which(is.na(linked$Programa_Final_Fuente) | trimws(linked$Programa_Final_Fuente) == "")
  if (length(pending)) {
    fallback_data <- annual[pending, setdiff(names(annual), "Programa_Final"), drop = FALSE]
    fallback <- link_payroll_programs(fallback_data, programs)
    linked$Programa_Final[pending] <- fallback$Programa_Final
    linked$link_method[pending] <- fallback$link_method
  }

  if (nrow(linked) != nrow(annual)) {
    stop("Supplied-name linkage multiplied payroll rows.")
  }
  linked
}
