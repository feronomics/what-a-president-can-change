## Date created:        13 October 2026
## Last modification:   20 October 2026
## Author / provenance: Fernando Sáenz (original volatility analysis, 21 May 2026)
## Project:             Que todo cambie para que nada cambie
## Affiliation:         Asociación de Investigación y Estudios Sociales (ASIES)
## Title:               Program-level volatility
## Purpose:             One heatmap per ministry listing every final program and its annual volatility.
## Inputs:              Consolidated SICOIN data and volatility results.
## Outputs:             3_output/3_graphs/5_program; label dictionaries and annual indices in 2_tables/5_program.
## Execution:           Run 2_scripts/0_master.R; all paths relative to project.
## Methods:             See inline comments and README for definitions/coverage.
## -------------------------------------------------------------------------

# ======================== PREPARE PROGRAM HEATMAPS ==========================
# Export one image per ministry, using harmonized program labels throughout.
if (!exists("analysis")) {
  stop("Run 0_master.R first.")
}

folder <- "5_program"
ministries <- sort(unique(analysis$classes$Ministerio))
# Keep existing file numbers for the retained ministries; skip the debt output.
program_classes <- without_public_debt(analysis$classes)
program_year <- without_public_debt(analysis$program_year)
for (i in seq_along(ministries)) {
  ministry <- ministries[i]
  if (!ministry %in% program_classes$Ministerio) {
    next
  }

  # Build the label dictionary first so each plotted row has a full-name reference.
  dictionary <- program_classes %>%
    dplyr::filter(Ministerio == ministry) %>%
    dplyr::arrange(Programa) %>%
    dplyr::select(Ministerio, Programa, index_total, flag)
  dictionary$label <- short_labels(dictionary$Programa, 56L)

  # Display 2005–2025 and all programs; grey cells mean no valid index,
  # including skipped fits, pre/post-active-life years and rolling warm-up.
  grid <- tidyr::expand_grid(
    Programa = dictionary$Programa,
    year = 2005:2025
  ) %>%
    dplyr::left_join(
      program_year %>%
        dplyr::filter(Ministerio == ministry),
      by = c("Programa", "year")
    ) %>%
    dplyr::left_join(
      dictionary[c("Programa", "label")],
      by = "Programa"
    )
  grid$label <- factor(
    grid$label,
    levels = rev(dictionary$label)
  )

  # Use a common color scale so the same color means the same volatility everywhere.
  p <- ggplot2::ggplot(grid, ggplot2::aes(year, label, fill = volatility)) +
    ggplot2::geom_tile(
      color = "white",
      linewidth = 0.15
    ) +

    # sigma controls color spacing only; it is not the classification threshold.
    ggplot2::scale_fill_viridis_c(
      option = "C",
      na.value = "#e2e8f0",
      limits = c(0, max(program_year$volatility, na.rm = TRUE)),
      trans = scales::pseudo_log_trans(sigma = 0.05),
      breaks = c(0, 0.1, 0.5, 1, 5, 10),
      labels = c("0", "0.1", "0.5", "1", "5", "10"),
      guide = ggplot2::guide_colorbar(barwidth = grid::unit(14, "cm"), barheight = grid::unit(0.4, "cm"))
    ) +
    ggplot2::scale_x_continuous(
      breaks = seq(2005, 2025, 5),
      expand = c(0, 0)
    ) +
    ggplot2::labs(
      title = paste("Volatilidad de programas ·", ministry),
      subtitle = "Programa final · promedio anual del índice mensual · color en escala pseudologarítmica común",
      x = NULL,
      y = NULL,
      fill = "Índice",
      caption = "Fuente: SICOIN. Se excluye el servicio de la deuda pública. Gris = sin índice disponible. Nombres completos en la tabla de etiquetas."
    ) +
    ggplot2::theme(axis.text.y = ggplot2::element_text(size = 9))

  # Create short, numbered output names without accents or filename punctuation.
  slug <- tolower(iconv(ministry, to = "ASCII//TRANSLIT"))
  slug <- gsub("[^a-z0-9_]+", "", slug)
  name <- paste0(i, "_", slug)
  save_plot(
    p,
    folder,
    name,
    width = 15,
    height = max(5, 2.5 + nrow(dictionary) * 0.27)
  )
  save_table(
    dictionary,
    folder,
    name
  )
}

save_table(
  program_year %>%
    dplyr::filter(year >= 2005),
  folder,
  "0_indices"
)
# Remove the previously generated debt-only figure and its label dictionary.
for (file in c(
  file.path(config$output_dir, "3_graphs", folder, "1_deuda_publica.png"),
  file.path(config$output_dir, "2_tables", folder, "1_deuda_publica.csv")
)) {
  if (file.exists(file)) unlink(file)
}
message("Program heatmaps saved: ", dplyr::n_distinct(program_classes$Ministerio), ".")
