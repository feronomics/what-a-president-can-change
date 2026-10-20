## Date created:        20 October 2026
## Project:             Que todo cambie para que nada cambie
## Affiliation:         Asociación de Investigación y Estudios Sociales (ASIES)
## Title:               Comparable early-government budget composition
## Purpose:             Compare program shares at equivalent horizons without inferring presidential intent.
## Inputs:              Consolidated monthly SICOIN data; Programa_Final identities.
## Outputs:             3_output/{2_tables,3_graphs}/7_priorities.
## Execution:           Single 2_scripts/0_master.R; all paths relative to project.
## Method:              Half the L1 change in annual ministry-program shares; all 16 groups.
## Limits:              First observed label is not verified creation; changes are not identified transfers.
## -------------------------------------------------------------------------

if (!exists("config") || !exists("save_plot")) {
  stop("Run 2_scripts/0_master.R first.")
}

# Aggregate monthly execution flows and December budget stocks separately.
raw <- readxl::read_xlsx(config$unified_file, sheet = "SICOIN") %>%
  mutate(year = as.integer(.data[["Año"]]), month = recode_month(Mes), Programa = Programa_Final)
annual <- raw %>%
  group_by(Ministerio, Programa, year) %>%
  summarise(execution = sum(Ejecutado), assigned = sum(Asignado[month == 12]), current_budget = sum(Vigente[month == 12]), .groups = "drop")
first <- raw %>%
  filter(Ejecutado > 0 | Asignado > 0 | Vigente > 0) %>%
  group_by(Ministerio, Programa) %>%
  summarise(first_year = min(year), .groups = "drop")
first_name <- first %>%
  group_by(Programa) %>%
  summarise(first_name_year = min(first_year), .groups = "drop")
terms <- data.frame(president = c("Colom", "Pérez Molina", "Morales", "Giammattei", "Arévalo"), start = c(2008L, 2012L, 2016L, 2020L, 2024L))
results <- list()
contributions <- list()
for (i in seq_len(nrow(terms))) {
  term <- terms[i, ]
  for (metric in c("execution", "assigned", "current_budget")) {
    data <- annual %>%
      filter(year %in% c(term$start - 1L, term$start + 1L)) %>%
      transmute(Ministerio, Programa, period = ifelse(year < term$start, "baseline", "year2"), amount = .data[[metric]]) %>%
      tidyr::pivot_wider(names_from = period, values_from = amount, values_fill = 0) %>%
      left_join(first, by = c("Ministerio", "Programa")) %>%
      left_join(first_name, by = "Programa") %>%
      mutate(
        share_before = baseline / sum(baseline), share_after = year2 / sum(year2), change = share_after - share_before,
        new_observed = first_year >= term$start & first_year <= term$start + 1L,
        prior_elsewhere = first_name_year < term$start,
        explicit_emergency = grepl("DESASTR|CALAMIDAD|RECONSTRU|EMERGEN|COVID", iconv(Programa, to = "ASCII//TRANSLIT"))
      )
    results[[length(results) + 1L]] <- data.frame(
      president = term$president, baseline = term$start - 1L, year2 = term$start + 1L, metric = metric,
      composition_change_pct = 50 * sum(abs(data$change)),
      new_share_pct = 100 * sum(data$share_after[data$new_observed %in% TRUE]),
      new_explicit_emergency_pct = 100 * sum(data$share_after[data$new_observed %in% TRUE & data$explicit_emergency]),
      new_prior_elsewhere_pct = 100 * sum(data$share_after[data$new_observed %in% TRUE & data$prior_elsewhere]),
      new_programs = sum(data$new_observed %in% TRUE & data$year2 > 0),
      negative_before = sum(data$baseline < 0), negative_after = sum(data$year2 < 0)
    )
    data$president <- term$president
    data$metric <- metric
    data$baseline_year <- term$start - 1L
    data$comparison_year <- term$start + 1L
    contributions[[length(contributions) + 1L]] <- data
  }
}
results <- bind_rows(results)
contributions <- dplyr::bind_rows(contributions)
audit <- list(results = results, contributions = contributions, first = first)

# Save evidence and draw the main comparison with a common two-year horizon.
folder <- "7_priorities"
# The public summary is computed from monetary increases/cuts below.
save_table(audit$contributions, folder, "2_programas")
save_table(audit$first, folder, "3_aparicion")
# Export every program with explicit years, money, percentage shares and changes.
# A gain in share is not the same as growth in its nominal monetary amount.
program_report <- contributions %>%
  dplyr::transmute(
    Presidente = president,
    Ministerio,
    Programa,
    Medida = dplyr::recode(
      metric,
      execution = "Gasto ejecutado",
      assigned = "Presupuesto asignado",
      current_budget = "Presupuesto vigente"
    ),
    Anio_inicial = baseline_year,
    Anio_final = comparison_year,
    Monto_inicial = baseline,
    Monto_final = year2,
    Cambio_monto = year2 - baseline,
    Participacion_inicial_pct = 100 * share_before,
    Participacion_final_pct = 100 * share_after,
    Cambio_participacion_pp = 100 * change,
    Primera_aparicion = first_year,
    Primera_aparicion_en_ventana = new_observed,
    Nombre_observado_antes_en_otro_ministerio = prior_elsewhere
  ) %>%
  dplyr::arrange(Anio_inicial, Medida, dplyr::desc(Cambio_participacion_pp), Ministerio, Programa)
save_table(program_report, folder, "5_cambios")

# Select both gainers and losers mechanically, including existing programs.
# Each administration gets one figure: budget and execution in horizontal panels.
top_programs <- program_report %>%
  dplyr::filter(Medida != "Presupuesto asignado") %>%
  dplyr::group_by(Presidente, Medida) %>%
  dplyr::group_modify(function(data, key) {
    gains <- data %>%
      dplyr::filter(Cambio_participacion_pp > 0) %>%
      dplyr::arrange(dplyr::desc(Cambio_participacion_pp), Ministerio, Programa) %>%
      dplyr::slice_head(n = 5L)
    losses <- data %>%
      dplyr::filter(Cambio_participacion_pp < 0) %>%
      dplyr::arrange(Cambio_participacion_pp, Ministerio, Programa) %>%
      dplyr::slice_head(n = 5L)
    dplyr::bind_rows(gains, losses)
  }) %>%
  dplyr::ungroup()
save_table(top_programs, folder, "6_destacados")
# Compare original nominal amounts. No inflation adjustment or changing shares.
# A fixed baseline denominator makes administrations of different sizes comparable.
spending_changes <- program_report %>%
  dplyr::filter(Medida == "Gasto ejecutado") %>%
  dplyr::group_by(Presidente) %>%
  dplyr::mutate(
    Gasto_total_inicial = sum(Monto_inicial),
    Cambio_pct_gasto_inicial = 100 * Cambio_monto / Gasto_total_inicial
  ) %>%
  dplyr::ungroup()
summary <- spending_changes %>%
  dplyr::group_by(Presidente, Anio_inicial, Anio_final) %>%
  dplyr::summarise(
    Gasto_total_inicial = dplyr::first(Gasto_total_inicial),
    Gasto_total_final = sum(Monto_final),
    Aumentos = sum(pmax(Cambio_monto, 0)),
    Recortes = sum(pmin(Cambio_monto, 0)),
    .groups = "drop"
  ) %>%
  dplyr::mutate(
    Aumentos_pct = 100 * Aumentos / Gasto_total_inicial,
    Recortes_pct = 100 * Recortes / Gasto_total_inicial,
    Cambio_neto = Aumentos + Recortes
  ) %>%
  dplyr::arrange(Anio_inicial)
save_table(summary, folder, "1_resumen")
save_table(spending_changes, folder, "9_montos")
summary$label <- factor(
  paste0(summary$Presidente, "\n", summary$Anio_inicial, " → ", summary$Anio_final),
  levels = paste0(summary$Presidente, "\n", summary$Anio_inicial, " → ", summary$Anio_final)
)
summary_bars <- summary %>%
  tidyr::pivot_longer(c(Aumentos_pct, Recortes_pct), names_to = "type", values_to = "value") %>%
  dplyr::mutate(type = factor(
    ifelse(type == "Aumentos_pct", "Aumentos en unos programas", "Recortes en otros programas"),
    levels = c("Aumentos en unos programas", "Recortes en otros programas")
  ))
p <- ggplot2::ggplot(summary_bars, ggplot2::aes(label, value, fill = type)) +
  ggplot2::geom_hline(yintercept = 0, color = "#64748b") +
  ggplot2::geom_col(width = 0.6) +
  ggplot2::geom_text(
    ggplot2::aes(label = sprintf("%+.1f%%", value), vjust = ifelse(value >= 0, -0.5, 1.4)),
    size = 4.5, fontface = "bold", show.legend = FALSE
  ) +
  ggplot2::scale_fill_manual(values = c(
    "Aumentos en unos programas" = "#176b87",
    "Recortes en otros programas" = "#b45309"
  )) +
  ggplot2::scale_y_continuous(
    labels = function(x) paste0(x, "%"),
    expand = ggplot2::expansion(mult = c(0.15, 0.15))
  ) +
  ggplot2::labs(
    title = "¿Cuánto aumentó y cuánto se recortó el gasto en los programas?",
    subtitle = "Aumentos y recortes por separado · del año anterior al gobierno a su segundo año",
    x = NULL,
    y = "Monto de los aumentos o recortes\ncomo % del gasto total del año anterior al gobierno",
    fill = NULL,
    caption = paste(
      "Azul: suma de los aumentos; naranja: suma de los recortes. Ambos se comparan con el mismo gasto inicial.",
      "Los aumentos pueden incluir crecimiento del gasto total: no se supone que fueron financiados por los recortes.",
      "Montos originales, sin ajuste por inflación. Fuente: SICOIN, 16 grupos disponibles."
    )
  )
save_plot(p, folder, "1_resumen", width = 13, height = 8, center_title = TRUE)

# Each president: nominal amounts before/after and the largest monetary changes.
# Program selection uses monetary increases and cuts, never share changes.
selected_programs <- spending_changes %>%
  dplyr::group_by(Presidente) %>%
  dplyr::group_modify(function(data, key) {
    dplyr::bind_rows(
      data %>% dplyr::filter(Cambio_monto > 0) %>%
        dplyr::arrange(dplyr::desc(Cambio_monto), Ministerio, Programa) %>% dplyr::slice_head(n = 5L),
      data %>% dplyr::filter(Cambio_monto < 0) %>%
        dplyr::arrange(Cambio_monto, Ministerio, Programa) %>% dplyr::slice_head(n = 5L)
    )
  }) %>% dplyr::ungroup()
save_table(selected_programs, folder, "10_destacados")
format_amount <- function(x) {
  format(round(x / 1e6, 1), big.mark = ",", decimal.mark = ".", trim = TRUE, scientific = FALSE)
}
for (i in seq_len(nrow(terms))) {
  selected <- selected_programs %>%
    dplyr::filter(Presidente == terms$president[i]) %>%
    dplyr::mutate(group = factor(
      ifelse(Cambio_monto > 0, "Mayores aumentos", "Mayores recortes"),
      levels = c("Mayores aumentos", "Mayores recortes")
    )) %>%
    dplyr::arrange(group, dplyr::desc(abs(Cambio_monto)), Ministerio, Programa)
  selected$label <- paste0(
    short_labels(paste(selected$Ministerio, selected$Programa, sep = " · "), 67L),
    "\n", selected$Anio_inicial, ": ", format_amount(selected$Monto_inicial),
    " → ", selected$Anio_final, ": ", format_amount(selected$Monto_final), " millones"
  )
  selected$label <- factor(selected$label, levels = rev(selected$label))
  p <- ggplot2::ggplot(selected, ggplot2::aes(Cambio_monto / 1e6, label, fill = group)) +
    ggplot2::geom_vline(xintercept = 0, color = "#64748b") +
    ggplot2::geom_col(width = 0.65) +
    ggplot2::geom_text(
      ggplot2::aes(label = sprintf("%+.1f", Cambio_monto / 1e6), hjust = ifelse(Cambio_monto > 0, -0.15, 1.15)),
      size = 3.5, show.legend = FALSE
    ) +
    ggplot2::facet_grid(group ~ ., scales = "free_y", space = "free_y") +
    ggplot2::scale_fill_manual(values = c("Mayores aumentos" = "#176b87", "Mayores recortes" = "#b45309"), guide = "none") +
    ggplot2::scale_x_continuous(expand = ggplot2::expansion(mult = c(0.2, 0.2))) +
    ggplot2::labs(
      title = paste("Aumentos y recortes por programa ·", terms$president[i]),
      subtitle = sprintf("%d → %d · debajo de cada programa: monto antes → monto después", terms$start[i] - 1L, terms$start[i] + 1L),
      x = "Aumento (+) o recorte (−) del gasto ejecutado, en millones de quetzales",
      y = NULL,
      caption = "Cinco mayores aumentos y cinco mayores recortes. Montos originales, sin ajuste por inflación. Fuente: SICOIN, 16 grupos disponibles. Todos los programas: 9_montos.csv."
    )
  slug <- c("colom", "perez", "morales", "giammattei", "arevalo")[i]
  save_plot(p, folder, paste0(i + 1L, "_", slug), width = 17, height = 10, center_title = TRUE)
}
for (name in c("2_programas.png", "1_composicion.png")) {
  file <- file.path(config$output_dir, "3_graphs", folder, name)
  if (file.exists(file)) unlink(file)
}
for (name in c("7_matriz.csv", "7_cada100.csv", "1_comparacion.csv", "8_aumentos_recortes.csv")) {
  file <- file.path(config$output_dir, "2_tables", folder, name)
  if (file.exists(file)) unlink(file)
}
stopifnot(all(abs(summary$Cambio_neto - (summary$Gasto_total_final - summary$Gasto_total_inicial)) < 0.01))

stopifnot(all(audit$results$negative_before == 0), all(audit$results$negative_after == 0))
stopifnot(all(audit$results$composition_change_pct >= 0 & audit$results$composition_change_pct <= 100))
cat("Comparable-window review saved.\n")
