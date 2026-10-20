## Date created:        13 October 2026
## Last modification:   20 October 2026
## Author / provenance: Fernando Sáenz (original volatility analysis, 21 May 2026)
## Project:             Que todo cambie para que nada cambie
## Affiliation:         Asociación de Investigación y Estudios Sociales (ASIES)
## Title:               State-level analysis
## Purpose:             Eight descriptive plots for the 16 observed source groups.
## Inputs:              Consolidated SICOIN data and volatility results.
## Outputs:             3_output/3_graphs/2_state; supporting CSVs in 2_tables/2_state.
## Execution:           Run 2_scripts/0_master.R; all paths relative to project.
## Methods:             See inline comments and README for definitions/coverage.
## -------------------------------------------------------------------------

# ======================== PREPARE STATE-LEVEL DATA ==========================
# This shared list is reused by the later ministry and program plots.
if (!exists("program_results") || !exists("diagnostics")) {
  stop("Run 0_master.R first.")
}

analysis <- prepare_analysis(raw, program_results, diagnostics, config)
folder <- "2_state"
caption <- "Fuente: bases SICOIN consolidadas. Estado = 16 grupos disponibles."
annual <- analysis$state_annual

# 1. One image with two panels: nominal amount and annual growth rate.
p <- spending_plot(annual)
save_plot(
  p,
  folder,
  "1_gasto",
  width = 14,
  height = 7
)
save_table(
  annual,
  folder,
  "1_gasto"
)

# 2. Count ministry-program identities with positive execution in each year.
p <- ggplot2::ggplot(analysis$state_counts, ggplot2::aes(year, programs)) +
  ggplot2::geom_line(
    color = "#176b87",
    linewidth = 1
  ) +
  ggplot2::geom_point(color = "#176b87") +
  year_axis() +
  ggplot2::labs(
    title = "Programas activos por año",
    subtitle = "Programa final · ejecución positiva",
    x = NULL,
    y = "Número de programas",
    caption = caption
  )
save_plot(
  p,
  folder,
  "2_programas"
)
save_table(
  analysis$state_counts,
  folder,
  "2_programas"
)

# 3. Pool fitted programs across the state each month; average monthly state
# indices within each year. This is not a new SARIMA on total state spending.
state_volatility <- analysis$state_volatility %>%
  dplyr::filter(year >= 2005)

# Compare the displayed annual values, giving each available year equal weight.
# Both requested windows include 2015; these are descriptive reference means,
# not an estimated break date or a statistical structural-break test.
period_means <- dplyr::bind_rows(lapply(c(2005L, 2015L), function(first_year) {
  last_year <- first_year + 10L
  values <- state_volatility %>%
    dplyr::filter(year >= first_year, year <= last_year, is.finite(volatility))
  data.frame(
    period = paste0(first_year, "–", last_year),
    first_year = first_year,
    last_year = last_year,
    years_available = nrow(values),
    mean_volatility = safe_mean(values$volatility)
  )
}))
save_table(period_means, folder, "9_promedios")

# Test the monthly index directly, independently of the annual plot values.
# Compute here on every run so the figure never reads stale stage-6 results.
state_test_programs <- program_results
state_test_programs$Ministerio <- "Estado"
state_test_data <- aggregate_ministry_index(state_test_programs) %>%
  dplyr::transmute(date, value = volatility_index) %>%
  dplyr::filter(
    date >= as.Date("2005-01-01"),
    date <= as.Date("2025-12-01"),
    is.finite(value)
  ) %>%
  dplyr::arrange(date)
state_break_tests <- dplyr::bind_rows(lapply(c("mean", "trend"), function(specification) {
  test_fixed_break(state_test_data, as.Date("2016-01-01"), specification)
}))
save_table(state_break_tests, folder, "10_quiebre")
chow <- state_break_tests %>%
  dplyr::filter(specification == "trend", test == "Chow F (iid errors)")
hac <- state_break_tests %>%
  dplyr::filter(specification == "trend", test == "HAC Wald chi-square (lag 12)")
mean_hac <- state_break_tests %>%
  dplyr::filter(specification == "mean", test == "HAC Wald chi-square (lag 12)")
test_label <- sprintf(
  "Quiebre evaluado: enero de 2016 · nivel y tendencia\nChow: F(%d, %d) = %.2f; p %s · HAC(12): p = %.3f",
  chow$df1, chow$df2, chow$statistic,
  if (chow$p_value < 0.001) "< 0.001" else sprintf("= %.3f", chow$p_value),
  hac$p_value
)

p <- ggplot2::ggplot(state_volatility, ggplot2::aes(year, volatility)) +
  ggplot2::geom_line(
    color = "#b45309",
    linewidth = 1
  ) +
  ggplot2::geom_point(color = "#b45309") +
  ggplot2::annotate(
    "label",
    x = 2005.3,
    y = Inf,
    label = test_label,
    hjust = 0,
    vjust = 1.2,
    size = 3.4,
    fill = "white",
    color = "#334155",
    linewidth = 0.2
  ) +
  ggplot2::geom_segment(
    data = period_means,
    ggplot2::aes(
      x = first_year, xend = last_year,
      y = mean_volatility, yend = mean_volatility, color = period
    ),
    inherit.aes = FALSE,
    linewidth = 1,
    linetype = "dashed"
  ) +
  ggplot2::scale_color_manual(
    values = c("2005–2015" = "#176b87", "2015–2025" = "#7c3aed"),
    labels = sprintf("Media %s: %.3f", period_means$period, period_means$mean_volatility),
    name = NULL
  ) +
  ggplot2::scale_x_continuous(
    limits = c(2005, 2025),
    breaks = seq(2005, 2025, 5)
  ) +
  ggplot2::labs(
    title = "Volatilidad del Estado",
    subtitle = "Promedio anual del índice mensual ponderado por ejecución",
    x = NULL,
    y = "Índice de volatilidad",
    caption = paste(
      caption,
      sprintf("Pruebas sobre %d meses; HAC ajusta por autocorrelación. Cambio solo de nivel: HAC p = %.3f.", nrow(state_test_data), mean_hac$p_value),
      "Medias anuales: 2015 se incluye en ambas ventanas. Fecha evaluada, no estimada."
    )
  )
save_plot(
  p,
  folder,
  "3_volatilidad",
  center_title = TRUE
)
save_table(
  state_volatility,
  folder,
  "3_volatilidad"
)

# 4. Harmonized names only; one histogram for all source groups.
p <- ggplot2::ggplot(analysis$lifetimes, ggplot2::aes(duration_months)) +
  ggplot2::geom_histogram(
    binwidth = 12,
    boundary = 0,
    fill = "#176b87",
    color = "white"
  ) +
  ggplot2::scale_x_continuous(breaks = seq(0, 264, 48)) +
  ggplot2::labs(
    title = "Duración de programas",
    subtitle = "Nombres armonizados · primer a último mes positivo; incluye pausas interiores",
    x = "Duración (meses)",
    y = "Cantidad de programas",
    caption = paste(caption, "Duraciones observadas en 2004–2025.")
  )
save_plot(
  p,
  folder,
  "4_duracion"
)
save_table(
  analysis$lifetimes,
  folder,
  "4_duracion"
)

# 5. Rates share one comparable percentage axis; budget stocks use December.
p <- ggplot2::ggplot(budget_long(annual), ggplot2::aes(year, percent, color = measure)) +
  ggplot2::geom_hline(
    yintercept = 0,
    color = "#cbd5e1"
  ) +
  ggplot2::geom_line(linewidth = 1) +
  ggplot2::geom_point(size = 1.5) +
  year_axis() +
  ggplot2::scale_color_manual(values = c("#b45309", "#176b87")) +
  ggplot2::labs(
    title = "Ejecución y modificación del presupuesto",
    subtitle = "Ejecución anual; presupuesto asignado y vigente al cierre de diciembre",
    x = NULL,
    y = "Porcentaje (%)",
    color = NULL,
    caption = caption
  )
save_plot(
  p,
  folder,
  "5_presupuesto"
)

# 6–7. Classification uses index_total for the complete active program history.
# Denominators include ALL programs/spending, showing unclassified coverage.
colors <- stats::setNames(
  c("#176b87", "#b45309", "#8b5cf6", "#94a3b8"),
  levels(analysis$shares$category)
)
for (type in c("program_pct", "spending_pct")) {
  shares <- analysis$shares
  shares$percent <- shares[[type]]
  p <- ggplot2::ggplot(shares, ggplot2::aes(category, percent, fill = category)) +
    ggplot2::geom_col(width = 0.65) +
    ggplot2::geom_text(
      ggplot2::aes(label = sprintf(
        "%.1f%%",
        percent
      )),
      vjust = -0.5,
      size = 4
    ) +
    ggplot2::scale_fill_manual(
      values = colors,
      guide = "none"
    ) +
    ggplot2::scale_y_continuous(expand = ggplot2::expansion(mult = c(0, 0.15))) +
    ggplot2::labs(
      title = if (type == "program_pct") {
        "Programas según volatilidad"
      } else {
        "Gasto según volatilidad de programas"
      },
      subtitle = "Clasificación por índice total del programa · 2004–2025",
      x = NULL,
      y = "Porcentaje del total (%)",
      caption = paste(caption, "Incluye programas sin índice.")
    )
  save_plot(
    p,
    folder,
    if (type == "program_pct") {
      "6_estabilidad"
    } else {
      "7_gasto"
    }
  )
}

save_table(
  analysis$shares,
  folder,
  "6_proporciones"
)

# 8. Smallest whole-series residual SD among successfully fitted programs.
top <- analysis$classes %>%
  dplyr::filter(flag == "OK", is.finite(index_total)) %>%
  dplyr::arrange(index_total, Ministerio, Programa) %>%
  dplyr::slice_head(n = 10)
top$label <- short_labels(paste(top$Ministerio, top$Programa, sep = " · "), 68L)
top$label <- factor(
  top$label,
  levels = rev(top$label)
)
p <- ggplot2::ggplot(top, ggplot2::aes(index_total, label)) +
  ggplot2::geom_col(
    fill = "#176b87",
    width = 0.7
  ) +
  ggplot2::labs(
    title = "Los 10 programas más estables",
    subtitle = "Menor índice total entre programas con ajuste válido",
    x = "Índice de volatilidad total",
    y = NULL,
    caption = caption
  )
save_plot(
  p,
  folder,
  "8_top10",
  width = 14,
  height = 7
)
save_table(
  top %>%
    dplyr::select(-label),
  folder,
  "8_top10"
)
message("State plots saved: 8.")
