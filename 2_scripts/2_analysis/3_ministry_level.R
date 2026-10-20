## Date created:        13 October 2026
## Last modification:   20 October 2026
## Author / provenance: Fernando Sáenz (original volatility analysis, 21 May 2026)
## Project:             Que todo cambie para que nada cambie
## Affiliation:         Asociación de Investigación y Estudios Sociales (ASIES)
## Title:               Ministry-level analysis
## Purpose:             Six faceted comparisons; spending and growth in separate images.
## Inputs:              Consolidated SICOIN data and volatility results.
## Outputs:             3_output/3_graphs/3_ministry; CSVs in 2_tables/3_ministry.
## Execution:           Run 2_scripts/0_master.R; all paths relative to project.
## Methods:             See inline comments and README for definitions/coverage.
## -------------------------------------------------------------------------

# ======================== PREPARE MINISTRY COMPARISONS ======================
# Annual data were prepared in the preceding state-level script.
if (!exists("analysis")) {
  stop("Run 0_master.R first.")
}

folder <- "3_ministry"
annual <- analysis$ministry_annual

# Own y scales preserve patterns despite large outliers; volatility stays fixed.
facets <- ggplot2::facet_wrap(~Ministerio, ncol = 4, scales = "free_y")
caption <- "Fuente: SICOIN. Incluye ministerios, Secretarías y deuda pública."

# 1. Spending amounts only, one panel per ministry.
p <- ggplot2::ggplot(annual, ggplot2::aes(year, Ejecutado / 1e9)) +
  ggplot2::geom_line(
    color = "#176b87",
    linewidth = 0.8
  ) +
  facets +
  year_axis() +
  ggplot2::labs(
    title = "Gasto público por ministerio",
    subtitle = "Ejecución anual nominal · escalas verticales propias",
    x = NULL,
    y = "Miles de millones de unidades monetarias",
    caption = caption
  )
save_plot(
  p,
  folder,
  "1_gasto",
  width = 15,
  height = 12
)
save_table(
  annual,
  folder,
  "1_gasto"
)

# 2. Growth rates only; first observed year has no annual comparison.
p <- ggplot2::ggplot(annual, ggplot2::aes(year, growth_pct)) +
  ggplot2::geom_hline(
    yintercept = 0,
    color = "#cbd5e1"
  ) +
  ggplot2::geom_line(
    color = "#b45309",
    linewidth = 0.8,
    na.rm = TRUE
  ) +
  facets +
  year_axis() +
  ggplot2::labs(
    title = "Crecimiento del gasto por ministerio",
    subtitle = "Variación interanual de la ejecución nominal · escalas verticales propias",
    x = NULL,
    y = "Crecimiento interanual (%)",
    caption = paste(caption, "El primer año observado no tiene tasa de crecimiento.")
  )
save_plot(
  p,
  folder,
  "2_crecimiento",
  width = 15,
  height = 12
)
save_table(
  annual[c("Ministerio", "year", "growth_pct")],
  folder,
  "2_crecimiento"
)

# 3. Count harmonized programs with positive execution in each ministry-year.
p <- ggplot2::ggplot(analysis$ministry_counts, ggplot2::aes(year, programs)) +
  ggplot2::geom_line(
    color = "#176b87",
    linewidth = 0.8
  ) +
  facets +
  year_axis() +
  ggplot2::labs(
    title = "Programas activos por ministerio",
    subtitle = "Programa final con ejecución positiva · escalas verticales propias",
    x = NULL,
    y = "Número de programas",
    caption = caption
  )
save_plot(
  p,
  folder,
  "3_programas",
  width = 15,
  height = 12
)
save_table(
  analysis$ministry_counts,
  folder,
  "3_programas"
)

# 4. Compare annual volatility with the same vertical scale across ministries.
p <- ggplot2::ggplot(analysis$ministry_volatility, ggplot2::aes(year, volatility)) +
  ggplot2::geom_line(
    color = "#b45309",
    linewidth = 0.8
  ) +
  ggplot2::facet_wrap(~Ministerio, ncol = 4, scales = "fixed") +
  year_axis() +
  ggplot2::labs(
    title = "Volatilidad por ministerio",
    subtitle = "Promedio anual del índice mensual · misma escala en todos los paneles",
    x = NULL,
    y = "Índice de volatilidad",
    caption = caption
  )
save_plot(
  p,
  folder,
  "4_volatilidad",
  width = 15,
  height = 12
)
save_table(
  analysis$ministry_volatility,
  folder,
  "4_volatilidad"
)

# 5. Show observed durations of harmonized programs, including interior pauses.
p <- ggplot2::ggplot(analysis$lifetimes, ggplot2::aes(duration_months)) +
  ggplot2::geom_histogram(
    binwidth = 12,
    boundary = 0,
    fill = "#176b87",
    color = "white"
  ) +
  facets +
  ggplot2::scale_x_continuous(breaks = seq(0, 264, 66)) +
  ggplot2::labs(
    title = "Duración de programas por ministerio",
    subtitle = "Programa final · primer a último mes positivo · escalas verticales propias",
    x = "Duración (meses)",
    y = "Cantidad de programas",
    caption = paste(caption, "Duración observada en 2004–2025.")
  )
save_plot(
  p,
  folder,
  "5_duracion",
  width = 15,
  height = 12
)
save_table(
  analysis$lifetimes,
  folder,
  "5_duracion"
)

# 6. Plot execution and modification percentages using December budget stocks.
p <- ggplot2::ggplot(budget_long(annual), ggplot2::aes(year, percent, color = measure)) +
  ggplot2::geom_hline(
    yintercept = 0,
    color = "#cbd5e1"
  ) +
  ggplot2::geom_line(linewidth = 0.75) +
  facets +
  year_axis() +
  ggplot2::scale_color_manual(values = c("#b45309", "#176b87")) +
  ggplot2::labs(
    title = "Ejecución y modificación por ministerio",
    subtitle = "Ejecución anual y presupuestos de diciembre · escalas verticales propias",
    x = NULL,
    y = "Porcentaje (%)",
    color = NULL,
    caption = caption
  )
save_plot(
  p,
  folder,
  "6_presupuesto",
  width = 15,
  height = 12
)
message("Ministry plots saved: 6.")
