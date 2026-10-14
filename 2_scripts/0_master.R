## Date created:        13 October 2026
## Original analysis:   21 May 2026 (Fernando Sáenz)
## Last modification:   13 October 2026
## Project:             Que todo cambie para que nada cambie
## Affiliation:         Asociación de Investigación y Estudios Sociales (ASIES)
## Title:               Master pipeline
## Purpose:             Configure paths, consolidate data, compute volatility, and run analyses 2–5.
## Inputs / outputs:    16 SICOIN workbooks -> unified data -> volatility, 30 plots, and CSV tables.
## Execution:           Run 2_scripts/0_master.R from R or Rscript.
## Method provenance:   Refactored from volatility_all_ministries_FIXED.R.
## -------------------------------------------------------------------------


# ======================== USER / PROJECT FOLDER =============================
# This is the ONLY place to enter a computer-specific project path.
# COAUTHOR: replace "coauthor" with the exact value returned by
# Sys.info()[["user"]] on YOUR computer, then replace the pilot path with
# the full path to YOUR copy of the project folder (not 2_scripts).
# Use forward slashes in paths, including on Windows.
# For more collaborators, add another else-if branch here.
username <- Sys.info()[["user"]]

if (username == "fsaen") {
  pilot <- "C:/Users/fsaen/OneDrive - Universidad Rafael Landivar/ASIES/2026/What is a president able to change"
} else if (username == "coauthor") {
  # COAUTHOR: EDIT YOUR USERNAME ABOVE AND YOUR PROJECT PATH BELOW.
  pilot <- "C:/Users/coauthor/ROUTE/TO/PROJECT/"
} else {
  stop("Username '", username, "' is not configured. Add your username and project-folder path in 2_scripts/0_master.R.")
}

if (!dir.exists(pilot)) {
  stop("Project folder does not exist: ", pilot,
       ". Update your pilot path in 2_scripts/0_master.R.")
}
setwd(pilot)
if (!file.exists(file.path("2_scripts", "0_master.R"))) {
  stop("pilot must point to the project root containing 1_databases and 2_scripts.")
}
# All paths below and in the stage scripts are RELATIVE to pilot.
# The R working directory remains at the project root after the pipeline runs.
# UTF-8 is needed for accented column names and the public-debt filename.
if (.Platform$OS.type == "windows" && identical(Sys.getlocale("LC_CTYPE"), "C")) {
  Sys.setlocale("LC_CTYPE", "English_United States.utf8")
}
required_packages <- c("dplyr", "tidyr", "zoo", "readxl", "writexl", "ggplot2", "scales")
missing_packages <- required_packages[!vapply(required_packages, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing_packages)) {
  stop("Install missing packages before running: install.packages(c(",
       paste(sprintf('"%s"', missing_packages), collapse = ", "), "))")
}

config <- list(
  input_dir = file.path("1_databases", "by ministry"),
  unified_file = file.path("1_databases", "unified", "SICOIN_consolidated.xlsx"),
  output_dir = "3_output",
  program_column = "Programa_Final", # Harmonized names ONLY for every analysis.
  min_obs = 36L,
  rolling_window = 12L,
  volatility_threshold = 0.5
)
pipeline_env <- new.env(parent = globalenv())
pipeline_env$config <- config
source(file.path("2_scripts", "99_helpers", "99_helpers.R"), local = pipeline_env)
source(file.path("2_scripts", "1_preprocessing", "1_append_databases.R"), local = pipeline_env)
source(file.path("2_scripts", "2_analysis", "1_volatility_index.R"), local = pipeline_env)
for (script in c("2_state_level.R", "3_ministry_level.R", "4_determinants.R", "5_program_level.R")) {
  source(file.path("2_scripts", "2_analysis", script), local = pipeline_env)
}
message("Pipeline completed. Results: ", file.path(config$output_dir, "1_volatility-index", "volatility_index.xlsx"))

