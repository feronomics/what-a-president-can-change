## Date created:        20 October 2026
## Last modification:   20 October 2026
## Project:             Que todo cambie para que nada cambie
## Affiliation:         Asociación de Investigación y Estudios Sociales (ASIES)
## Title:               Fixed-date structural-break tests and weighting sensitivity
## Purpose:             Test the nominated 2016 change and compare monthly and annual spending weights.
## Inputs:              Saved program/monthly ministry indices and consolidated SICOIN data.
## Outputs:             3_output/{2_tables,3_graphs}/6_breaks; reproducible Markdown report.
## Execution:           Loaded by the single 2_scripts/0_master.R after analyses 1–5.
## Methods:             Chow F; Newey-West Wald (lags 12/24); level and level/trend models.
## Interpretation:      Conditional fixed-date tests, not an unknown-break/date-search test.
## -------------------------------------------------------------------------

if (!exists("config") || !exists("test_fixed_break")) {
  stop("Run 2_scripts/0_master.R first.")
}
folder <- "6_breaks"
volatility_file <- file.path(config$output_dir, "1_volatility-index", "volatility_index.xlsx")

# ======================== RECONSTRUCT BOTH AGGREGATIONS ====================
# Reuse fitted results; do not re-estimate models or change the production index.
break_programs <- readxl::read_xlsx(volatility_file, sheet = "program_results")
break_programs$date <- as.Date(break_programs$date)
break_ministries <- readxl::read_xlsx(volatility_file, sheet = "ministry_index_long")
break_ministries$date <- as.Date(break_ministries$date)
break_raw <- readxl::read_xlsx(config$unified_file, sheet = "SICOIN")
# Exclude debt before pooling and before constructing annual ministry weights.
break_programs <- without_public_debt(break_programs)
break_ministries <- without_public_debt(break_ministries)
break_raw <- without_public_debt(break_raw)

# Current definition: pool fitted programs using their execution in each month.
pooled <- break_programs
pooled$Ministerio <- "Estado"
current <- aggregate_ministry_index(pooled) %>%
  dplyr::transmute(date, current = volatility_index)

# Sensitivity definition: ministry monthly indices weighted by ministry
# ANNUAL execution (all source programs). Available ministries are renormalized.
annual_weights <- break_raw %>%
  dplyr::group_by(Ministerio, year = .data[["Año"]]) %>%
  dplyr::summarise(annual_execution = sum(Ejecutado), .groups = "drop")
annual_series <- break_ministries %>%
  dplyr::filter(is.finite(volatility_index)) %>%
  dplyr::mutate(year = as.integer(format(date, "%Y"))) %>%
  dplyr::left_join(annual_weights, by = c("Ministerio", "year"))
if (anyNA(annual_series$annual_execution)) {
  stop("Missing annual execution weights in the aggregation audit.")
}
annual_series <- annual_series %>%
  dplyr::filter(is.finite(volatility_index)) %>%
  dplyr::group_by(date) %>%
  dplyr::summarise(
    annual_ministry = stats::weighted.mean(volatility_index, annual_execution),
    .groups = "drop"
  )
series <- dplyr::full_join(current, annual_series, by = "date") %>%
  dplyr::filter(date >= as.Date("2005-01-01"), date <= as.Date("2025-12-01")) %>%
  dplyr::arrange(date)
expected_dates <- seq(as.Date("2005-01-01"), as.Date("2025-12-01"), by = "month")
stopifnot(identical(series$date, expected_dates))
stopifnot(all(is.finite(series$current)), all(is.finite(series$annual_ministry)))
save_table(series, folder, "1_series")

# ======================== CHOW AND AUTOCORRELATION-ROBUST TESTS =============
# January is the user-nominated year boundary. September provides an additional date sensitivity; it is not independently prespecified.
# These dates are nominated hypotheses, not dates estimated by these tests.
# Both dates were motivated by the earlier figure, so inference is conditional.
results <- list()
summaries <- list()
position <- 1L
for (definition in c("current", "annual_ministry")) {
  data <- data.frame(date = series$date, value = series[[definition]])
  for (break_date_text in c("2016-01-01", "2016-09-01")) {
    break_date <- as.Date(break_date_text)
    before <- data$value[data$date < break_date]
    after <- data$value[data$date >= break_date]
    summaries[[position]] <- data.frame(
      definition = definition,
      break_date = break_date_text,
      pre_n = length(before),
      post_n = length(after),
      pre_mean = mean(before),
      post_mean = mean(after),
      change = mean(after) - mean(before),
      percent_change = 100 * (mean(after) / mean(before) - 1)
    )
    for (specification in c("mean", "trend")) {
      tests <- test_fixed_break(data, break_date, specification)
      tests$definition <- definition
      results[[length(results) + 1L]] <- tests
    }
    position <- position + 1L
  }
}
tests <- dplyr::bind_rows(results)
means <- dplyr::bind_rows(summaries)
save_table(tests, folder, "2_tests")
save_table(means, folder, "3_means")

# ======================== COMPARE MONTHLY SERIES VISUALLY ==================
# Keep the two definitions separate; the alternative is an audit, not a replacement.
long <- series %>%
  tidyr::pivot_longer(-date, names_to = "definition", values_to = "value")
panel_names <- c(
  current = "Actual: ejecución mensual de programas",
  annual_ministry = "Sensibilidad: pesos anuales por ministerio"
)
long$panel <- factor(panel_names[long$definition], levels = panel_names)
segments <- means %>%
  dplyr::filter(break_date == "2016-01-01") %>%
  dplyr::select(definition, pre_mean, post_mean) %>%
  tidyr::pivot_longer(c(pre_mean, post_mean), names_to = "period", values_to = "mean") %>%
  dplyr::mutate(
    start = as.Date(ifelse(period == "pre_mean", "2005-01-01", "2016-01-01")),
    end = as.Date(ifelse(period == "pre_mean", "2015-12-01", "2025-12-01")),
    panel = factor(panel_names[definition], levels = panel_names)
  )
p <- ggplot2::ggplot(long, ggplot2::aes(date, value)) +
  ggplot2::geom_line(color = "#94a3b8", linewidth = 0.45) +
  ggplot2::geom_segment(
    data = segments,
    ggplot2::aes(x = start, xend = end, y = mean, yend = mean),
    inherit.aes = FALSE,
    color = "#176b87",
    linewidth = 1
  ) +
  ggplot2::geom_vline(
    xintercept = as.Date("2016-01-01"),
    linetype = "dashed",
    color = "#b45309"
  ) +
  ggplot2::facet_wrap(~panel, ncol = 1, scales = "fixed") +
  ggplot2::scale_x_date(
    breaks = as.Date(paste0(seq(2005, 2025, 5), "-01-01")),
    date_labels = "%Y"
  ) +
  ggplot2::labs(
    title = "Volatilidad estatal: dos formas de ponderar",
    subtitle = "Gris: índice mensual · azul: medias antes y después de enero de 2016",
    x = NULL,
    y = "Índice de volatilidad",
    caption = "Sin servicio de la deuda pública. Ambos índices usan los mismos ajustes SARIMA; solo cambia la ponderación. Fecha evaluada: enero de 2016."
  )
save_plot(p, folder, "1_comparacion", width = 13, height = 9, center_title = TRUE)

# ======================== WRITE A SELF-CONTAINED REPORT ====================
# Classical F assumes iid errors. Prefer the HAC sensitivity for overlapping
# rolling indices. Neither procedure accounts for uncertainty from fitting SARIMA.
report_dir <- file.path(config$output_dir, "2_tables", folder)
report <- c(
  "# Structural change in state volatility: 2016 audit",
  "",
  "## Data and hypotheses",
  "",
  "Scope: 15 observed source groups, excluding public-debt service before calculating indices, totals and weights. Monthly observations: January 2005–December 2025 (252 observations). The index measures the standard deviation of model residuals; this analysis tests changes in the LEVEL or TREND of that index, not the variance of its disturbances.",
  "",
  "The January 2016 split is the nominated year boundary: 132 pre-break months and 120 post-break months. September 2016 is an additional date sensitivity. Dates were nominated after inspecting the data, so these are conditional tests, not confirmatory tests of an independently prespecified or unknown break.",
  "",
  "Mean specification: restricted y ~ 1; unrestricted y ~ post. Trend specification: restricted y ~ time; unrestricted y ~ time * post, with time measured in years and zero in the first post-break month. Chow F compares restricted/unrestricted residual sums of squares. The trend test jointly tests a change in intercept and slope; significance does not alone imply a fall in the mean.",
  "",
  "Classical Chow assumes independent, homoskedastic disturbances. Twelve-month rolling indices overlap and can be serially correlated. Separate Newey–West HAC Wald chi-square tests use Bartlett weights, lags 12 and 24, no prewhitening and an n/(n-k) correction. HAC intervals use normal asymptotics. None of these calculations propagate first-stage SARIMA estimation uncertainty.",
  "",
  "## Mean comparisons (non-overlapping periods)",
  "",
  "| Definition | First post month | Pre mean | Post mean | Change | Change (%) |",
  "|---|---|---:|---:|---:|---:|"
)
for (i in seq_len(nrow(means))) {
  row <- means[i, ]
  report <- c(report, sprintf(
    "| %s | %s | %.6f | %.6f | %+.6f | %+.2f%% |",
    row$definition, row$break_date, row$pre_mean, row$post_mean, row$change, row$percent_change
  ))
}
report <- c(report, "", "## Tests", "",
  "| Definition | Split | Specification | Test | Statistic | df | p-value |",
  "|---|---|---|---|---:|---|---:|")
for (i in seq_len(nrow(tests))) {
  row <- tests[i, ]
  report <- c(report, sprintf(
    "| %s | %s | %s | %s | %.4f | %s | %.5g |",
    row$definition, row$break_date, row$specification, row$test, row$statistic,
    if (is.na(row$df2)) as.character(row$df1) else paste(row$df1, row$df2, sep = ", "),
    row$p_value
  ))
}
report <- c(report, "", "## Weighting definitions", "",
  "current: monthly execution-weighted program indices pooled across ministries. annual_ministry: monthly ministry indices weighted by each ministry's total annual execution, with available ministries renormalized. Both definitions use the same fitted-program sample. Unusable log observations are missing; programs retain their valid histories. Annual weights include all source spending, while pooled monthly weights use fitted programs. This sensitivity distinguishes changes in volatility from changes in spending composition.",
  "", "## Interpretation", ""
)
for (definition in c("current", "annual_ministry")) {
  row <- means %>% dplyr::filter(.data$definition == .env$definition, break_date == "2016-01-01")
  robust <- tests %>% dplyr::filter(.data$definition == .env$definition, break_date == "2016-01-01", specification == "mean", test == "HAC Wald chi-square (lag 12)")
  report <- c(report, sprintf(
    "%s: the post-2016 average is %s by %.2f%%. The lag-12 HAC level-change test has p = %.5g; %s at the conventional 5%% threshold, conditional on this date and specification.",
    definition, ifelse(row$change < 0, "lower", "higher"), abs(row$percent_change), robust$p_value,
    ifelse(robust$p_value < 0.05, "reject equal levels", "do not reject equal levels")
  ), "")
  trend <- tests %>%
    dplyr::filter(.data$definition == .env$definition, break_date == "2016-01-01", specification == "trend", test == "HAC Wald chi-square (lag 12)")
  report <- c(report, sprintf(
    "The joint level-and-trend HAC test for %s has p = %.5g. This is a joint test of intercept and slope changes, not a test that the full post-period mean is lower.",
    definition, trend$p_value
  ), "")
}
report <- c(report,
  "Do not switch aggregation definitions solely to obtain a desired decline. Keep the production definition explicit, report the alternative as sensitivity, and distinguish a local 2016 drop from a persistent full-period average shift. A global unknown-break procedure would need search-adjusted inference with serial-dependence treatment.",
  "", "## Method references", "",
  "- [strucchange: Chow and structural-change tests](https://search.r-project.org/CRAN/refmans/strucchange/html/sctest.formula.html)",
  "- [sandwich: Newey–West HAC specification](https://sandwich.r-forge.r-project.org/reference/NeweyWest.html)",
  "", "Reproduce by running 2_scripts/0_master.R. Numerical results are in 1_series.csv, 2_tests.csv and 3_means.csv; figure: 3_output/3_graphs/6_breaks/1_comparacion.png."
)
writeLines(report, file.path(report_dir, "4_report.md"), useBytes = TRUE)
print(means)
print(tests %>% dplyr::filter(break_date == "2016-01-01", specification == "mean"))
message("Structural-break tests and report saved in ", report_dir)
