## Date created:        13 October 2026
## Last modification:   20 October 2026
## Author / provenance: Fernando Sáenz (original volatility analysis, 21 May 2026)
## Project:             Que todo cambie para que nada cambie
## Affiliation:         Asociación de Investigación y Estudios Sociales (ASIES)
## Title:               Payroll and volatility determinants
## Purpose:             Correlation, program personnel shares, and four-predictor logistic regression.
## Inputs:              Saved annual payroll; harmonized monthly programs and volatility diagnostics.
## Outputs:             3_output/3_graphs/4_determinants (4 PNGs); supporting tables/model.
## Execution:           Run 2_scripts/0_master.R; payroll retains annual frequency.
## Unit of analysis:    One harmonized ministry-program; never repeated annual payroll by month.
## Threshold:           config$volatility_threshold (0.5); equality remains unclassified.
## -------------------------------------------------------------------------

# ======================== READ AND LINK BOTH DATASETS =======================
# Monthly model results supply volatility; payroll amounts remain annual.
if (!exists("config") || !exists("link_payroll_programs")) {
  stop("Run 2_scripts/0_master.R.")
}

# Locate and validate the saved inputs produced by the preceding stages.
volatility_file <- file.path(config$output_dir, "1_volatility-index", "volatility_index.xlsx")
for (input in c(config$unified_file, volatility_file, config$payroll_unified_file)) {
  if (!file.exists(input)) {
    stop("Missing input: ", input, ". Run 2_scripts/0_master.R to generate all required inputs.")
  }
}

programs <- readxl::read_xlsx(
  config$unified_file,
  sheet = "SICOIN"
)
require_columns(
  programs,
  c("Ministerio", "Año", "Mes", "Depto", "Programa", "Programa_Final", "Ejecutado"),
  "Programs"
)
annual <- readxl::read_xlsx(
  config$payroll_unified_file,
  sheet = "anual"
)
diagnostics <- readxl::read_xlsx(
  volatility_file,
  sheet = "diagnostics"
)
if (anyDuplicated(diagnostics[c("Ministerio", "Programa")])) {
  stop("Duplicate volatility identities.")
}

# Link annual payroll and construct program-level predictors.
linked <- link_payroll_programs(annual, programs)
prepared <- payroll_program_covariates(programs, diagnostics, linked, config)
covariates <- prepared$data
folder <- "4_determinants"
save_table(
  covariates,
  folder,
  "1_covariables"
)
save_table(
  linked,
  folder,
  "2_enlaces"
)

# Report the number of matched records and the spending they cover.
coverage <- linked %>%
  dplyr::group_by(Ministerio, Anio) %>%
  dplyr::summarise(
    source_programs = dplyr::n(),
    matched_programs = sum(!is.na(Programa_Final)),
    spending = sum(Devengado_total),
    matched_spending = sum(Devengado_total[!is.na(Programa_Final)]),
    .groups = "drop"
  ) %>%
  dplyr::mutate(matched_spending_pct = 100 * safe_ratio(matched_spending, spending))
save_table(
  coverage,
  folder,
  "3_cobertura"
)
save_table(
  covariates %>%
    dplyr::count(Ministerio, exclusion, name = "programs"),
  folder,
  "8_exclusiones"
)
save_table(
  prepared$name_history,
  folder,
  "10_renombres"
)

# ======================== 1. CORRELATION ====================================
# Cross-sectional correlation: one point per linked harmonized program.
# Percent personnel = SUM(personnel) / SUM(total) across that program's linked
# annual observations, not an unweighted average of annual percentages.
sample <- covariates %>%
  dplyr::filter(exclusion == "included")
if (nrow(sample) < 6L || dplyr::n_distinct(sample$volatile) != 2L) {
  stop("Insufficient complete programs or only one volatility class; inspect exclusions.")
}

# Calculate both linear (Pearson) and rank-based (Spearman) associations.
correlations <- dplyr::bind_rows(lapply(c("pearson", "spearman"), function(method) {
  test <- stats::cor.test(
    sample$payroll_pct,
    sample$index_total,
    method = method,
    exact = FALSE
  )
  data.frame(
    method = method,
    estimate = unname(test$estimate),
    p_value = test$p.value,
    n = nrow(sample)
  )
}))
save_table(
  correlations,
  folder,
  "4_correlacion"
)
p <- ggplot2::ggplot(sample, ggplot2::aes(payroll_pct, index_total)) +
  ggplot2::geom_hline(
    yintercept = config$volatility_threshold,
    linetype = "dashed",
    color = "#94a3b8"
  ) +
  ggplot2::geom_point(
    color = "#176b87",
    alpha = 0.65,
    size = 2
  ) +
  ggplot2::geom_smooth(
    method = "lm",
    formula = y ~ x,
    color = "#b45309",
    linewidth = 0.8
  ) +
  ggplot2::labs(
    title = "Servicios personales y volatilidad",
    subtitle = sprintf(
      "Un punto por programa armonizado · n = %d · Pearson r = %.3f · Spearman ρ = %.3f",
      nrow(sample),
      correlations$estimate[1],
      correlations$estimate[2]
    ),
    x = "Gasto en servicios personales (% del devengado)",
    y = "Índice total de volatilidad",
    caption = "SICOIN. Planilla: años con vínculo válido; índice: vida activa completa. Asociación descriptiva."
  )
save_plot(
  p,
  folder,
  "1_correlacion",
  width = 12,
  height = 7
)

# ======================== 2. PAYROLL BY VOLATILITY CLASS ====================
# Use the same complete program sample as the regression for comparability.
# Show every observation, the median and interquartile range; no missing rows.
comparison <- sample %>%
  dplyr::mutate(
    stability = factor(
      ifelse(volatile == 0, "Estables", "Volátiles"),
      levels = c("Estables", "Volátiles")
    )
  )
class_summary <- comparison %>%
  dplyr::group_by(stability) %>%
  dplyr::summarise(
    n = dplyr::n(),
    median_payroll = stats::median(payroll_pct),
    q25 = stats::quantile(payroll_pct, 0.25),
    q75 = stats::quantile(payroll_pct, 0.75),
    .groups = "drop"
  )
save_table(comparison, folder, "5_planilla")
save_table(class_summary, folder, "9_resumen")

p <- ggplot2::ggplot(comparison, ggplot2::aes(stability, payroll_pct, fill = stability)) +
  ggplot2::geom_boxplot(
    width = 0.45,
    alpha = 0.25,
    outlier.shape = NA,
    linewidth = 0.7
  ) +
  ggplot2::geom_point(
    ggplot2::aes(color = stability),
    position = ggplot2::position_jitter(width = 0.13, height = 0, seed = 2026),
    alpha = 0.6,
    size = 2
  ) +
  ggplot2::geom_text(
    data = class_summary,
    ggplot2::aes(y = 107, label = sprintf("Mediana: %.1f%% · n = %d", median_payroll, n)),
    size = 4,
    fontface = "bold"
  ) +
  ggplot2::scale_fill_manual(values = c("Estables" = "#176b87", "Volátiles" = "#c46b32")) +
  ggplot2::scale_color_manual(values = c("Estables" = "#176b87", "Volátiles" = "#c46b32")) +
  ggplot2::scale_y_continuous(
    limits = c(0, 112),
    breaks = seq(0, 100, 25),
    labels = function(x) paste0(x, "%")
  ) +
  ggplot2::guides(fill = "none", color = "none") +
  ggplot2::labs(
    title = "Planilla en programas estables y volátiles",
    subtitle = sprintf("%d programas · cada punto representa un programa armonizado", nrow(comparison)),
    x = NULL,
    y = "Servicios personales (% del devengado)",
    caption = sprintf(
      "SICOIN. Estables: índice total < %s; volátiles: > %s. Cajas: mediana y 50%% central. Muestra completa del modelo; asociación descriptiva.",
      config$volatility_threshold,
      config$volatility_threshold
    )
  )
save_plot(p, folder, "2_planilla", width = 10, height = 7, center_title = TRUE)

# ======================== 3. LOGISTIC REGRESSION ============================
# Binary outcome: full-series volatility above the master's threshold.
# Four predictors: personnel share (per 10 pp), inclusive lifespan (years),
# observed name-change indicator, and number of named departments.
# Name-change evidence compares sets of source aliases BETWEEN YEARS within a
# harmonized identity; it never splits programs or uses original labels as units.
# It is an observed-label-change proxy, not a certified administrative event.
model_formula <- volatile ~ payroll_10pp + longevity_years + name_change + department_count

# Check that the four predictors are identifiable before estimating coefficients.
design <- stats::model.matrix(model_formula, sample)
if (qr(design)$rank != ncol(design)) {
  stop("Logistic design is rank-deficient; inspect covariates.")
}

# Collect estimation warnings so they can be recorded with the model settings.
model_warnings <- character()
model <- withCallingHandlers(
  stats::glm(
    model_formula,
    family = stats::binomial(link = "logit"),
    data = sample
  ),
  warning = function(w) {
    model_warnings <<- c(model_warnings, conditionMessage(w))
    invokeRestart("muffleWarning")
  }
)
if (!isTRUE(model$converged) || any(!is.finite(stats::coef(model)))) {
  stop("Logistic model did not converge to finite estimates; inspect predictors and class separation.")
}

# Extract coefficients and construct odds ratios with 95% Wald intervals.
coefficient_matrix <- summary(model)$coefficients
coefficients <- data.frame(
  term = rownames(coefficient_matrix),
  estimate = coefficient_matrix[, 1],
  std_error = coefficient_matrix[, 2],
  z = coefficient_matrix[, 3],
  p_value = coefficient_matrix[, 4],
  row.names = NULL
)
coefficients$odds_ratio <- exp(coefficients$estimate)
coefficients$or_lower <- exp(coefficients$estimate - stats::qnorm(0.975) * coefficients$std_error)
coefficients$or_upper <- exp(coefficients$estimate + stats::qnorm(0.975) * coefficients$std_error)
if (any(!is.finite(coefficients$or_upper))) {
  stop("Unbounded Wald interval; investigate separation.")
}

save_table(
  coefficients,
  folder,
  "6_logit"
)

# Save model settings, sample size, convergence and any estimation warnings.
model_info <- data.frame(
  setting = c(
    "formula", "unit", "n", "stable", "volatile", "threshold",
    "AIC", "converged", "name_change_definition", "payroll_period", "warnings"
  ),
  value = c(
    paste(deparse(model_formula), collapse = ""), "one harmonized ministry-program",
    nrow(sample), sum(sample$volatile == 0), sum(sample$volatile == 1), config$volatility_threshold,
    stats::AIC(model), model$converged, "source-alias set differs across observed active years",
    "available uniquely linked annual observations", paste(model_warnings, collapse = "; ")
  )
)
save_table(
  model_info,
  folder,
  "7_modelo"
)
model_path <- file.path(config$output_dir, "2_tables", folder, "6_logit.rds")
saveRDS(model, model_path)

# ======================== 4. ADJUSTED PROBABILITY CURVE =====================
# Marginal standardization: at each payroll share, predict every sample program
# with its own observed longevity, name-change and department count, then average.
# Use the delta method and the full coefficient covariance matrix for pointwise
# 95% intervals on the logit of the average probability; these are not causal effects.
payroll_grid <- seq(min(sample$payroll_pct), max(sample$payroll_pct), length.out = 201L)
curve <- dplyr::bind_rows(lapply(payroll_grid, function(share) {
  newdata <- sample
  newdata$payroll_10pp <- share / 10
  design <- stats::model.matrix(stats::delete.response(stats::terms(model)), newdata)
  design <- design[, names(stats::coef(model)), drop = FALSE]
  probabilities <- stats::plogis(drop(design %*% stats::coef(model)))
  probability <- mean(probabilities)
  gradient <- colMeans(design * (probabilities * (1 - probabilities)))
  variance <- drop(t(gradient) %*% stats::vcov(model) %*% gradient)
  se_logit <- sqrt(max(0, variance)) / (probability * (1 - probability))

  data.frame(
    payroll_pct = share,
    probability = probability,
    lower = stats::plogis(stats::qlogis(probability) - stats::qnorm(0.975) * se_logit),
    upper = stats::plogis(stats::qlogis(probability) + stats::qnorm(0.975) * se_logit)
  )
}))
stopifnot(all(is.finite(as.matrix(curve))))
save_table(curve, folder, "11_probabilidad")

p <- ggplot2::ggplot(curve, ggplot2::aes(payroll_pct, probability)) +
  ggplot2::geom_ribbon(
    ggplot2::aes(ymin = lower, ymax = upper),
    fill = "#176b87",
    alpha = 0.18
  ) +
  ggplot2::geom_line(color = "#176b87", linewidth = 1.2) +
  ggplot2::geom_rug(
    data = sample,
    ggplot2::aes(x = payroll_pct),
    inherit.aes = FALSE,
    sides = "b",
    alpha = 0.25
  ) +
  ggplot2::scale_x_continuous(
    limits = c(0, 100),
    breaks = seq(0, 100, 25),
    labels = function(x) paste0(x, "%")
  ) +
  ggplot2::scale_y_continuous(
    limits = c(0, 1),
    breaks = seq(0, 1, 0.25),
    labels = scales::label_percent(accuracy = 1)
  ) +
  ggplot2::labs(
    title = "Planilla y probabilidad ajustada de volatilidad",
    subtitle = sprintf("Regresión logística · %d programas · banda de confianza puntual del 95%%", nrow(sample)),
    x = "Servicios personales (% del devengado)",
    y = "Probabilidad de ser volátil",
    caption = paste(
      "SICOIN. Predicciones promediadas sobre la longevidad, cambios de nombre y departamentos observados.",
      "Marcas inferiores: planilla observada. Asociación ajustada, no efecto causal."
    )
  )
save_plot(p, folder, "3_probabilidad", width = 10, height = 7, center_title = TRUE)

# Label predictors with their measurement units for the coefficient plot.
labels <- c(
  payroll_10pp = "Servicios personales (+10 puntos porcentuales)",
  longevity_years = "Longevidad (+1 año)", name_change = "Cambio de nombre observado (sí vs. no)",
  department_count = "Departamentos (+1)"
)

# Plot predictor odds ratios; leave the intercept in the table, not in this plot.
effects <- coefficients[coefficients$term != "(Intercept)", ]
effects$label <- factor(
  unname(labels[effects$term]),
  levels = rev(unname(labels))
)
p <- ggplot2::ggplot(effects, ggplot2::aes(odds_ratio, label)) +
  ggplot2::geom_vline(
    xintercept = 1,
    color = "#94a3b8",
    linetype = "dashed"
  ) +
  ggplot2::geom_segment(
    ggplot2::aes(x = or_lower, xend = or_upper, yend = label),
    linewidth = 0.7,
    color = "#176b87"
  ) +
  ggplot2::geom_point(
    color = "#176b87",
    size = 3
  ) +
  ggplot2::scale_x_log10() +
  ggplot2::labs(
    title = "Determinantes de la volatilidad",
    subtitle = sprintf(
      "Regresión logística · volátil > %s · n = %d programas · IC de Wald 95%%",
      config$volatility_threshold,
      nrow(sample)
    ),
    x = "Razón de momios (escala logarítmica)",
    y = NULL,
    caption = "SICOIN. Asociaciones ajustadas; no efectos causales. Nombres armonizados; cambio de nombre = proxy observado."
  )
save_plot(
  p,
  folder,
  "4_logit",
  width = 13,
  height = 6
)

# Supersede the previous stage's pending status only once all analyses exist.
pending <- file.path(config$output_dir, "2_tables", folder, "2_pendientes.csv")
if (file.exists(pending)) {
  unlink(pending)
}

message(
  "Payroll analyses completed: ", nrow(sample), " programs; stable = ",
  sum(sample$volatile == 0), "; volatile = ", sum(sample$volatile == 1), "."
)
if (length(model_warnings)) {
  warning(paste(unique(model_warnings), collapse = "; "))
}
