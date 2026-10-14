## Date created:        13 October 2026
## Last modification:   13 October 2026
## Author / provenance: Fernando Sáenz (original volatility analysis, 21 May 2026)
## Project:             Que todo cambie para que nada cambie
## Affiliation:         Asociación de Investigación y Estudios Sociales (ASIES)
## Title:               Volatility determinants
## Purpose:             Prepare available program covariates; omit payroll-dependent analyses.
## Inputs:              Consolidated SICOIN data and volatility results.
## Outputs:             3_output/2_tables/4_determinants; no plots until personnel data are added.
## Execution:           Run 2_scripts/0_master.R; all paths relative to pilot.
## Methods:             See inline comments and README for definitions/coverage.
## -------------------------------------------------------------------------


if (!exists("analysis")) stop("Run 0_master.R first.")
# USER INSTRUCTION: omit analyses requiring personnel/payroll expenditure.
# The correlation, payroll share in stable ministries, and specified logistic
# regression ALL need those data. Do not estimate a substitute regression.
# Available variables below are saved to support future linkage.
raw_available <- analysis$raw
departments <- c("ALTA VERAPAZ", "BAJA VERAPAZ", "CHIMALTENANGO", "CHIQUIMULA",
  "EL PROGRESO", "ESCUINTLA", "GUATEMALA", "HUEHUETENANGO", "IZABAL", "JALAPA",
  "JUTIAPA", "PETEN", "QUETZALTENANGO", "QUICHE", "RETALHULEU", "SACATEPEQUEZ",
  "SAN MARCOS", "SANTA ROSA", "SOLOLA", "SUCHITEPEQUEZ", "TOTONICAPAN", "ZACAPA")
raw_available$department_key <- toupper(trimws(iconv(raw_available$Depto, to = "ASCII//TRANSLIT")))
features <- raw_available |> dplyr::group_by(Ministerio, Programa) |>
  dplyr::summarise(department_count = dplyr::n_distinct(department_key[Ejecutado > 0 & department_key %in% departments]),
    non_department_labels = any(Ejecutado > 0 & !department_key %in% departments),
    .groups = "drop")
covariates <- analysis$classes |>
  dplyr::left_join(analysis$lifetimes |> dplyr::select(-first_month, -last_month),
                   by = c("Ministerio", "Programa")) |>
  dplyr::left_join(features, by = c("Ministerio", "Programa")) |>
  dplyr::mutate(volatile = dplyr::case_when(
    flag != "OK" | is.na(index_total) ~ NA_integer_,
    index_total > config$volatility_threshold ~ 1L,
    index_total < config$volatility_threshold ~ 0L,
    TRUE ~ NA_integer_))
# Department count is only observed named departments, not a fabricated
# allocation of multiregional/exterior/debt labels. It is a lower bound when
# non_department_labels is TRUE. Only harmonized program names are used;
# original-name counts and name-change proxies are excluded.
save_table(covariates, "4_determinants", "1_covariables")
graph_folder <- file.path(config$output_dir, "3_graphs", "4_determinants")
dir.create(graph_folder, recursive = TRUE, showWarnings = FALSE)
status <- data.frame(analysis = c("Correlación planilla-volatilidad", "Planilla en ministerios estables",
                                "Regresión logística especificada"),
                     status = "Omitido: no hay gasto de servicios personales; pendiente de nueva base")
save_table(status, "4_determinants", "2_pendientes")
message("Determinants: saved available covariates; 3 payroll-dependent analyses omitted.")

