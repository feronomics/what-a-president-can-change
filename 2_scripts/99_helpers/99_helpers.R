## Date created:        13 October 2026
## Original analysis:   21 May 2026 (Fernando Sáenz)
## Last modification:   20 October 2026
## Project:             Que todo cambie para que nada cambie
## Affiliation:         Asociación de Investigación y Estudios Sociales (ASIES)
## Title:               Shared analysis functions
## Purpose:             Validation, SARIMA fitting, aggregation, covariates, and plot/table utilities.
## Inputs / outputs:    Function definitions; called by stages to prepare data and save PNG/CSV outputs.
## Execution:           Run 2_scripts/0_master.R from R or Rscript.
## Method provenance:   Refactored from volatility_all_ministries_FIXED.R.
## -------------------------------------------------------------------------

# Check that the next stage has every required input column.
# Inputs: a data frame, required names, and a label for error messages.
# Stop with an explanation when columns are missing; otherwise continue.
require_columns <- function(data, columns, label) {
  missing <- setdiff(columns, names(data))
  if (length(missing)) {
    stop(label, ": missing columns: ", paste(missing, collapse = ", "))
  }
}

# Exclude the public-debt source group for state and spending-comparison scope.
# Normalize accents/punctuation only for this exact ministry identity; do not
# remove unrelated program labels or modify raw source workbooks/model fits.
without_public_debt <- function(data) {
  require_columns(data, "Ministerio", "Debt-exclusion input")
  ministry_key <- gsub(
    "[^A-Z0-9]", "",
    toupper(iconv(as.character(data$Ministerio), to = "ASCII//TRANSLIT"))
  )
  data[ministry_key != "DEUDAPUBLICA" & !is.na(ministry_key), , drop = FALSE]
}

# Convert Spanish month labels to integers 1-12.
# Input: month names. Return: month numbers; unknown labels become NA.
recode_month <- function(month) {
  months <- c(
    "ENERO", "FEBRERO", "MARZO", "ABRIL", "MAYO", "JUNIO",
    "JULIO", "AGOSTO", "SEPTIEMBRE", "OCTUBRE", "NOVIEMBRE", "DICIEMBRE"
  )
  match(toupper(trimws(as.character(month))), months)
}

# Fit the seasonal model for ONE harmonized program's monthly execution.
# Inputs: amounts, matching dates, label, minimum observations, rolling window.
# Return: active-month rows with fitted values, residuals and volatility;
# unusable series retain missing indices and an explicit skip reason.
fit_volatility <- function(values, dates, program, min_obs = 36L, window = 12L) {
  # Retain the original active-life rule: trim outside first/last positive
  # execution; preserve interior zeros, including pauses and returns.
  active <- which(!is.na(values) & values > 0)
  if (length(active)) {
    keep <- seq.int(min(active), max(active))
    values <- values[keep]
    dates <- dates[keep]
  }

  # Initialize missing results so skipped programs remain in the output.
  n <- length(values)
  result <- data.frame(
    date = dates,
    Programa = program,
    Ejecutado = values,
    ypred = NA_real_,
    noise = NA_real_,
    index = NA_real_,
    index_total = NA_real_,
    log_valid = is.finite(values) & values > -1,
    rolling_residuals = NA_integer_,
    flag = NA_character_
  )
  skip <- function(reason) {
    result$flag <- reason
    result
  }

  if (any(!is.finite(values))) {
    return(skip("SKIPPED: non-finite execution"))
  }

  if (n < min_obs) {
    return(skip(paste0("SKIPPED: only ", n, " observations (min = ", min_obs, ")")))
  }

  # Preserve the full monthly calendar and raw amounts. Only the unusable log
  # observations become missing; one accounting correction does not drop a program.
  log_values <- rep(NA_real_, n)
  log_values[result$log_valid] <- log1p(values[result$log_valid])
  if (sum(result$log_valid) < min_obs) {
    return(skip(paste0("SKIPPED: only ", sum(result$log_valid), " valid log observations (min = ", min_obs, ")")))
  }

  if (stats::sd(values) == 0) {
    return(skip("SKIPPED: zero/constant series"))
  }

  # Fit SARIMA to log execution using the actual first active month.
  series <- stats::ts(
    log_values,
    start = c(
      as.integer(format(min(dates), "%Y")),
      as.integer(format(min(dates), "%m"))
    ),
    frequency = 12
  )
  model <- tryCatch(
    stats::arima(
      series,
      order = c(1, 1, 0),
      seasonal = list(
        order = c(1, 1, 0),
        period = 12
      )
    ),
    error = function(e) {
      e
    }
  )
  if (inherits(model, "error")) {
    return(skip(paste("SKIPPED: SARIMA error:", conditionMessage(model))))
  }

  if (!is.null(model$code) && model$code != 0) {
    return(skip("SKIPPED: SARIMA failed to converge"))
  }

  # Calculate fitted log execution and trailing residual standard deviations.
  residuals <- as.numeric(model$residuals)
  stopifnot(length(residuals) == n)
  residuals[!result$log_valid] <- NA_real_
  result$ypred <- as.numeric(series) - residuals
  result$noise <- residuals
  result$index <- as.numeric(zoo::rollapply(
    residuals,
    width = window,
    FUN = function(x) {
      if (sum(is.finite(x)) >= 2L) stats::sd(x, na.rm = TRUE) else NA_real_
    },
    align = "right",
    fill = NA
  ))
  # Record window coverage: twelve calendar months can contain fewer usable
  # residuals. Match the original missing-residual SD convention transparently.
  result$rolling_residuals <- as.integer(zoo::rollapply(
    as.integer(is.finite(residuals)),
    width = window,
    FUN = sum,
    align = "right",
    fill = NA
  ))
  result$index_total <- stats::sd(residuals, na.rm = TRUE)
  result$flag <- "OK"
  result
}

# Combine valid program indices into an execution-weighted ministry index.
# Input: program-month model results. Return: ministry-month index and coverage.
# No available index or zero total execution produces NA rather than false zero.
aggregate_ministry_index <- function(program_results) {
  valid <- dplyr::filter(program_results, flag == "OK")
  if (!nrow(valid)) {
    return(data.frame(
      Ministerio = character(),
      date = as.Date(character()),
      volatility_index = numeric(),
      programs_with_index = integer()
    ))
  }

  valid %>%
    dplyr::group_by(Ministerio, date) %>%
    dplyr::summarise(

      # Preserve original weights: denominator includes all fitted programs,
      # including programs whose rolling index is not yet available.
      volatility_index = if (sum(Ejecutado, na.rm = TRUE) == 0 || all(is.na(index))) {
        NA_real_
      } else {
        sum(Ejecutado / sum(Ejecutado, na.rm = TRUE) * index, na.rm = TRUE)
      },
      programs_with_index = sum(!is.na(index)),
      .groups = "drop"
    )
}

# ======================== DESCRIPTIVE ANALYSIS ==============================
# Program identity is always Ministerio + label, never label alone.
# Active program = strictly positive execution. Duration = inclusive calendar
# span between first/last positive month; interior pauses remain included.
# Annual execution is a SUM of monthly flows. Assigned/current budgets are
# STOCKS: use December totals, never sum the twelve monthly budget snapshots.
# Monetary plots use nominal input units, scaled by 1e9; no currency assumption.

# Average available observations; return NA when all values are missing.
safe_mean <- function(x) {
  if (all(is.na(x))) {
    NA_real_
  } else {
    mean(x, na.rm = TRUE)
  }
}

# Divide vectors without converting zero/invalid denominators into infinities.
# A scalar denominator is repeated to match the numerator's length.
safe_ratio <- function(numerator, denominator) {
  denominator <- rep_len(denominator, length(numerator))
  ifelse(is.finite(denominator) & denominator != 0, numerator / denominator, NA_real_)
}

# Shorten labels for plots and add suffixes if shortened labels collide.
# Inputs: complete labels and maximum width. Return: unique display labels.
short_labels <- function(x, width = 45L) {
  labels <- trimws(gsub("\\s+", " ", as.character(x)))
  labels <- ifelse(nchar(labels) > width, paste0(substr(labels, 1, width - 1L), "…"), labels)
  make.unique(labels, sep = " · ")
}

# Measure observed life from the first to last positive-execution month.
# Inputs: dated rows and harmonized program column. Return: dates, active-month
# count and inclusive duration; pauses inside the observed life are retained.
program_lifetimes <- function(raw, column) {
  raw %>%
    dplyr::filter(Ejecutado > 0, !is.na(.data[[column]]), trimws(.data[[column]]) != "") %>%
    dplyr::group_by(Ministerio, Programa = .data[[column]]) %>%
    dplyr::summarise(
      first_month = min(fecha),
      last_month = max(fecha),
      active_months = dplyr::n_distinct(fecha),
      .groups = "drop"
    ) %>%
    dplyr::mutate(
      duration_months =
        (as.integer(format(last_month, "%Y")) - as.integer(format(first_month, "%Y"))) * 12L +
          as.integer(format(last_month, "%m")) - as.integer(format(first_month, "%m")) + 1L
    )
}

# Construct annual execution, growth and budget rates for the requested groups.
# Execution is a monthly FLOW to sum; budgets are December STOCK snapshots.
# Inputs: monthly group totals and grouping columns. Return: annual indicators.
annual_accounts <- function(monthly, groups) {
  # Sum monthly execution flows within each observed year.
  execution <- monthly %>%
    dplyr::group_by(dplyr::across(dplyr::all_of(c(groups, "year")))) %>%
    dplyr::summarise(
      Ejecutado = sum(Ejecutado),
      months = dplyr::n_distinct(month),
      .groups = "drop"
    )

  # Take year-end budgets instead of adding monthly stock snapshots.
  december <- monthly %>%
    dplyr::filter(month == 12L) %>%
    dplyr::select(dplyr::all_of(c(groups, "year", "Asignado", "Vigente")))
  dplyr::left_join(
    execution,
    december,
    by = c(groups, "year")
  ) %>%
    dplyr::group_by(dplyr::across(dplyr::all_of(groups))) %>%
    dplyr::arrange(year, .by_group = TRUE) %>%
    dplyr::mutate(
      growth_pct = 100 * safe_ratio(Ejecutado - dplyr::lag(Ejecutado), dplyr::lag(Ejecutado)),
      execution_pct = 100 * safe_ratio(Ejecutado, Vigente),
      modification_pct = 100 * safe_ratio(Vigente - Asignado, Asignado)
    ) %>%
    dplyr::ungroup()
}

# Build the shared datasets for state, ministry and program plots.
# Inputs: consolidated rows, program-month results, diagnostics and configuration.
# Return: a named list of accounts, program counts, indices, durations and shares.
prepare_analysis <- function(raw, program_results, diagnostics, config) {
  raw$year <- as.integer(raw[["Año"]])
  raw$month <- recode_month(raw$Mes)
  raw$Programa <- raw[[config$program_column]]

  # Aggregate source rows into ministry-month budget and execution totals.
  ministry_monthly <- raw %>%
    dplyr::group_by(Ministerio, year, month) %>%
    dplyr::summarise(
      dplyr::across(c(Asignado, Vigente, Ejecutado), sum),
      .groups = "drop"
    )
  state_monthly <- ministry_monthly %>%
    dplyr::group_by(year, month) %>%
    dplyr::summarise(
      dplyr::across(c(Asignado, Vigente, Ejecutado), sum),
      .groups = "drop"
    )

  # State is the observed 16 groups; not a claim of full public-sector coverage.
  state_monthly$group <- "Estado"
  state_annual <- annual_accounts(state_monthly, "group")
  ministry_annual <- annual_accounts(ministry_monthly, "Ministerio")

  # Count only harmonized programs with positive execution in that year.
  active <- raw %>%
    dplyr::filter(Ejecutado > 0) %>%
    dplyr::distinct(Ministerio, Programa, year)
  ministry_counts <- active %>%
    dplyr::count(Ministerio, year, name = "programs")
  ministry_counts <- dplyr::left_join(
    ministry_annual[c("Ministerio", "year")],
    ministry_counts,
    by = c("Ministerio", "year")
  ) %>%
    dplyr::mutate(programs = tidyr::replace_na(programs, 0L))
  state_counts <- ministry_counts %>%
    dplyr::group_by(year) %>%
    dplyr::summarise(
      programs = sum(programs),
      .groups = "drop"
    )

  # Average the ministry monthly indices to produce annual plot values.
  monthly_index <- aggregate_ministry_index(program_results)
  monthly_index$year <- as.integer(format(monthly_index$date, "%Y"))
  ministry_volatility <- monthly_index %>%
    dplyr::group_by(Ministerio, year) %>%
    dplyr::summarise(
      volatility = safe_mean(volatility_index),
      indexed_months = sum(!is.na(volatility_index)),
      .groups = "drop"
    )
  ministry_volatility <- dplyr::left_join(
    ministry_annual[c("Ministerio", "year")],
    ministry_volatility,
    by = c("Ministerio", "year")
  )

  # Pool fitted programs to compute the execution-weighted state index.
  state_programs <- program_results
  state_programs$Ministerio <- "Estado"
  state_index <- aggregate_ministry_index(state_programs)
  state_index$year <- as.integer(format(state_index$date, "%Y"))
  state_volatility <- state_index %>%
    dplyr::group_by(year) %>%
    dplyr::summarise(
      volatility = safe_mean(volatility_index),
      indexed_months = sum(!is.na(volatility_index)),
      .groups = "drop"
    )
  state_volatility <- dplyr::left_join(
    state_annual["year"],
    state_volatility,
    by = "year"
  )

  # Classify complete program histories using the master's threshold.
  program_spending <- raw %>%
    dplyr::group_by(Ministerio, Programa) %>%
    dplyr::summarise(
      execution = sum(Ejecutado),
      .groups = "drop"
    )
  threshold_label <- format(config$volatility_threshold, trim = TRUE, scientific = FALSE)
  category_levels <- c(
    paste0("Estable (<", threshold_label, ")"),
    paste0("Volátil (>", threshold_label, ")"),
    paste0("Igual a ", threshold_label), "Sin índice"
  )
  classes <- dplyr::left_join(
    program_spending,
    diagnostics,
    by = c("Ministerio", "Programa")
  ) %>%
    dplyr::mutate(category = dplyr::case_when(
      flag != "OK" | is.na(index_total) ~ "Sin índice",
      index_total < config$volatility_threshold ~ category_levels[1],
      index_total > config$volatility_threshold ~ category_levels[2],
      TRUE ~ category_levels[3]
    ))

  # Keep unclassified programs in the program/spending denominators.
  shares <- classes %>%
    dplyr::group_by(category) %>%
    dplyr::summarise(
      programs = dplyr::n(),
      execution = sum(execution),
      .groups = "drop"
    ) %>%
    tidyr::complete(
      category = category_levels,
      fill = list(
        programs = 0L,
        execution = 0
      )
    ) %>%
    dplyr::mutate(
      program_pct = 100 * programs / sum(programs),
      spending_pct = 100 * safe_ratio(execution, sum(execution)),
      category = factor(
        category,
        levels = category_levels
      )
    )

  # Prepare observed durations and annual indices for program heatmaps.
  lifetimes <- program_lifetimes(raw, config$program_column)
  program_results$year <- as.integer(format(program_results$date, "%Y"))
  program_year <- program_results %>%
    dplyr::group_by(Ministerio, Programa, year) %>%
    dplyr::summarise(
      volatility = safe_mean(index),
      .groups = "drop"
    )
  list(
    raw = raw,
    state_annual = state_annual,
    ministry_annual = ministry_annual,
    state_counts = state_counts,
    ministry_counts = ministry_counts,
    state_volatility = state_volatility,
    ministry_volatility = ministry_volatility,
    lifetimes = lifetimes,
    classes = classes,
    shares = shares,
    program_year = program_year
  )
}

# Return the common fonts, colors and layout settings for exported plots.
plot_style <- function() {
  ggplot2::theme_minimal(base_size = 12, base_family = "sans") +

    ggplot2::theme(
      plot.title = ggplot2::element_text(face = "bold", size = 17),
      plot.subtitle = ggplot2::element_text(color = "#475569", size = 10),
      plot.caption = ggplot2::element_text(color = "#64748b", size = 9, hjust = 0),
      panel.grid.minor = ggplot2::element_blank(),
      strip.text = ggplot2::element_text(face = "bold"),
      legend.position = "bottom",
      plot.margin = ggplot2::margin(16, 20, 16, 16)
    )
}

# Bartlett Newey-West covariance for monthly OLS residuals, without new packages.
# Inputs: fitted lm and lag truncation. Return: coefficient covariance matrix.
# No prewhitening; multiply by n/(n-k) for the residual degrees-of-freedom correction.
break_hac_covariance <- function(model, lag = 12L) {
  design <- stats::model.matrix(model)
  n <- nrow(design)
  k <- ncol(design)
  scores <- design * as.numeric(stats::residuals(model))
  meat <- crossprod(scores)

  for (j in seq_len(min(lag, n - 1L))) {
    covariance <- crossprod(
      scores[(j + 1L):n, , drop = FALSE],
      scores[seq_len(n - j), , drop = FALSE]
    )
    meat <- meat + (1 - j / (lag + 1)) * (covariance + t(covariance))
  }

  bread <- solve(crossprod(design))
  bread %*% meat %*% bread * n / (n - k)
}

# Test a fixed-date change in level, or jointly in level and linear trend.
# Return: classical Chow F and separate HAC Wald tests (12 and 24 months).
# The date is a supplied hypothesis, not an estimated/data-selected breakpoint.
test_fixed_break <- function(data, break_date, specification = "mean") {
  data$post <- as.integer(data$date >= break_date)
  data$time <- (
    as.integer(format(data$date, "%Y")) * 12L +
      as.integer(format(data$date, "%m")) -
      as.integer(format(break_date, "%Y")) * 12L -
      as.integer(format(break_date, "%m"))
  ) / 12

  if (specification == "mean") {
    restricted <- stats::lm(value ~ 1, data)
    unrestricted <- stats::lm(value ~ post, data)
    terms <- "post"
  } else {
    restricted <- stats::lm(value ~ time, data)
    unrestricted <- stats::lm(value ~ time * post, data)
    terms <- c("post", "time:post")
  }

  comparison <- stats::anova(restricted, unrestricted)
  result <- data.frame(
    specification = specification,
    break_date = as.character(break_date),
    n = nrow(data),
    pre_n = sum(data$post == 0),
    post_n = sum(data$post == 1),
    test = "Chow F (iid errors)",
    statistic = comparison$F[2],
    df1 = comparison$Df[2],
    df2 = stats::df.residual(unrestricted),
    p_value = comparison$`Pr(>F)`[2],
    level_change = stats::coef(unrestricted)["post"],
    level_lower = NA_real_,
    level_upper = NA_real_,
    row.names = NULL
  )

  for (lag in c(12L, 24L)) {
    covariance <- break_hac_covariance(unrestricted, lag)
    positions <- match(terms, names(stats::coef(unrestricted)))
    change <- stats::coef(unrestricted)[positions]
    wald <- drop(t(change) %*% solve(covariance[positions, positions, drop = FALSE], change))
    level_se <- sqrt(covariance["post", "post"])
    robust <- result[1, ]
    robust$test <- paste0("HAC Wald chi-square (lag ", lag, ")")
    robust$statistic <- wald
    robust$df1 <- length(terms)
    robust$df2 <- NA_real_
    robust$p_value <- stats::pchisq(wald, df = length(terms), lower.tail = FALSE)
    robust$level_lower <- robust$level_change - stats::qnorm(0.975) * level_se
    robust$level_upper <- robust$level_change + stats::qnorm(0.975) * level_se
    result <- dplyr::bind_rows(result, robust)
  }

  result
}

# Return the shared calendar-axis breaks used by the time-series plots.
year_axis <- function() {
  ggplot2::scale_x_continuous(breaks = seq(2004, 2025, 3))
}

# Export one numbered PNG to the analysis-specific graph folder.
# Inputs: plot, folder, short filename and dimensions in inches.
# Render a temporary image before replacing the existing OneDrive output.
save_plot <- function(plot, folder, name, width = 12, height = 7, center_title = FALSE) {
  path <- file.path(config$output_dir, "3_graphs", folder)
  dir.create(path, recursive = TRUE, showWarnings = FALSE)
  if (!is.null(plot$labels$caption)) {
    plot$labels$caption <- paste(strwrap(plot$labels$caption, width = 110), collapse = "\n")
  }

  # Render a fresh file first; OneDrive can reject ragg writes directly to an
  # existing image. Copy only after successful rendering, and fail on errors.
  temporary_plot <- tempfile(
    pattern = paste0(".", name, "_"),
    tmpdir = path,
    fileext = ".png"
  )
  on.exit(unlink(temporary_plot), add = TRUE)
  # Apply optional title alignment after the shared theme so it takes precedence.
  styled_plot <- plot + plot_style()
  if (center_title) {
    styled_plot <- styled_plot + ggplot2::theme(
      plot.title.position = "plot",
      plot.title = ggplot2::element_text(hjust = 0.5),
      plot.subtitle = ggplot2::element_text(hjust = 0.5)
    )
  }

  ggplot2::ggsave(
    temporary_plot,
    styled_plot,
    width = width,
    height = height,
    units = "in",
    dpi = 180,
    bg = "white"
  )
  if (!file.exists(temporary_plot) || file.info(temporary_plot)$size == 0) {
    stop("Could not render plot: ", name)
  }

  # Same-directory rename also replaces OneDrive placeholders that reject a
  # direct overwrite. Fall back to copying if the filesystem cannot rename.
  destination <- file.path(path, paste0(name, ".png"))
  if (!file.rename(temporary_plot, destination) &&
    !file.copy(temporary_plot, destination, overwrite = TRUE)) {
    stop("Could not save plot: ", name)
  }
}

# Export a supporting data frame as a UTF-8 CSV in its analysis folder.
save_table <- function(data, folder, name) {
  path <- file.path(config$output_dir, "2_tables", folder)
  dir.create(path, recursive = TRUE, showWarnings = FALSE)
  utils::write.csv(
    data,
    file.path(path, paste0(name, ".csv")),
    row.names = FALSE,
    fileEncoding = "UTF-8"
  )
}

# Reshape annual execution/modification percentages for a two-series plot.
# Input: annual accounts. Return: year, rate label and percentage in long form.
budget_long <- function(data) {
  data %>%
    dplyr::select(dplyr::any_of("Ministerio"), year, execution_pct, modification_pct) %>%
    tidyr::pivot_longer(
      c(execution_pct, modification_pct),
      names_to = "measure",
      values_to = "percent"
    ) %>%
    dplyr::mutate(measure = ifelse(measure == "execution_pct", "Ejecución / vigente", "(Vigente − asignado) / asignado"))
}

# Build the spending-level and annual-growth panels; return an unsaved plot.
# The state view puts the two measures horizontally with separate vertical scales.
spending_plot <- function(annual, by_ministry = FALSE) {
  measures <- c("Monto (miles de millones)", "Crecimiento interanual (%)")
  data <- annual %>%
    dplyr::mutate(amount = Ejecutado / 1e9) %>%
    dplyr::select(dplyr::any_of("Ministerio"), year, amount, growth_pct) %>%
    tidyr::pivot_longer(
      c(amount, growth_pct),
      names_to = "measure",
      values_to = "value"
    ) %>%
    dplyr::mutate(measure = factor(
      ifelse(measure == "amount", measures[1], measures[2]),
      levels = measures
    ))
  p <- ggplot2::ggplot(data, ggplot2::aes(year, value, color = measure)) +
    ggplot2::geom_hline(
      data = data[data$measure == measures[2], ],
      mapping = ggplot2::aes(yintercept = 0),
      color = "#cbd5e1"
    ) +
    ggplot2::geom_line(
      linewidth = 0.85,
      na.rm = TRUE
    ) +
    ggplot2::geom_point(
      size = if (by_ministry) {
        1
      } else {
        2
      },
      na.rm = TRUE
    ) +
    ggplot2::scale_color_manual(
      values = stats::setNames(c("#176b87", "#b45309"), measures),
      guide = "none"
    ) +
    year_axis() +
    ggplot2::labs(
      title = if (by_ministry) {
        "Gasto y crecimiento por ministerio"
      } else {
        "Gasto público y crecimiento"
      },
      subtitle = "Ejecución anual nominal y variación respecto del año anterior · 2004–2025",
      x = NULL,
      y = NULL,
      caption = paste(
        "Fuente: SICOIN. Monto en miles de millones de unidades monetarias; crecimiento en %.",
        "El primer año observado de cada grupo no tiene tasa de crecimiento."
      )
    )
  if (by_ministry) {
    p +
      ggplot2::facet_wrap(ggplot2::vars(Ministerio, measure), ncol = 4, scales = "free_y")
  } else {
    p +
      ggplot2::facet_wrap(~measure, ncol = 2, scales = "free_y")
  }
}

# Select one debt scope consistently for all inputs to an analysis.
# Stage 8 enables debt in its own environment; main results exclude it.
analysis_scope <- function(data) {
  if (isTRUE(config$include_public_debt)) {
    return(data)
  }

  without_public_debt(data)
}

# Keep scope in chart notes; titles remain comparable across variants.
scope_note <- function() {
  if (isTRUE(config$include_public_debt)) {
    return("Incluye el servicio de la deuda pública: 16 grupos disponibles.")
  }

  "Se excluye el servicio de la deuda pública: 15 grupos disponibles."
}
