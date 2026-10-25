## Date created:        13 October 2026
## Original analysis:   21 May 2026 (Fernando Sáenz)
## Last modification:   20 October 2026
## Project:             Que todo cambie para que nada cambie
## Affiliation:         Asociación de Investigación y Estudios Sociales (ASIES)
## Title:               Master pipeline
## Purpose:             Single master: preprocess programs/payroll, then run analyses 1–8.
## Inputs / outputs:    Monthly programs and annual payroll -> consolidated data, 40 plots, tables.
## Execution:           Run 2_scripts/0_master.R from R or Rscript.
## Method provenance:   Refactored from volatility_all_ministries_FIXED.R.
## -------------------------------------------------------------------------

# ======================== USER / PROJECT FOLDER =============================
# This is the ONLY place to enter a computer-specific project path.
# COAUTHOR: replace "coauthor" with the exact value returned by
# Sys.info()[["user"]] on YOUR computer, then replace the project path with
# the full path to YOUR copy of the project folder (not 2_scripts).
# Use forward slashes in paths, including on Windows.
# For more collaborators, add another else-if branch here.
username <- Sys.info()[["user"]]

if (username == "fsaen") {
  project <- "C:/Users/fsaen/OneDrive - Universidad Rafael Landivar/ASIES/2026/What is a president able to change"
} else if (username == "coauthor") {
  # COAUTHOR: EDIT YOUR USERNAME ABOVE AND YOUR PROJECT PATH BELOW.
  project <- "C:/Users/coauthor/ROUTE/TO/PROJECT/"
} else {
  stop("Username '", username, "' is not configured. Add your username and project-folder path in 2_scripts/0_master.R.")
}

if (!dir.exists(project)) {
  stop(
    "Project folder does not exist: ", project,
    ". Update your project path in 2_scripts/0_master.R."
  )
}

setwd(project)

if (!file.exists(file.path("2_scripts", "0_master.R"))) {
  stop("project must point to the project root containing 1_databases and 2_scripts.")
}

# All paths below and in the stage scripts are RELATIVE to project.
# The R working directory remains at the project root after the pipeline runs.
# UTF-8 is needed for accented column names and the public-debt filename.
if (.Platform$OS.type == "windows" && identical(Sys.getlocale("LC_CTYPE"), "C")) {
  Sys.setlocale("LC_CTYPE", "English_United States.utf8")
}

# ======================== CHECK AND LOAD PACKAGES ===========================
# Check dependencies before reading or overwriting any project data.
required_packages <- c("dplyr", "tidyr", "zoo", "readxl", "writexl", "ggplot2", "scales")
missing_packages <- required_packages[!vapply(required_packages, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing_packages)) {
  stop(
    "Install missing packages before running: install.packages(c(",
    paste(sprintf('"%s"', missing_packages), collapse = ", "), "))"
  )
}

# Load dplyr so the %>% pipe is available in all scripts and helper functions.
library(dplyr)

# ======================== SHARED PATHS AND SETTINGS =========================
# One master, two preprocessing stages: monthly program data and annual payroll
# remain at their own frequencies. Analysis 4 links them at the program level.
config <- list(
  input_dir = file.path("1_databases", "programs", "by ministry"),
  unified_file = file.path("1_databases", "programs", "unified", "SICOIN_consolidated.xlsx"),
  output_dir = "3_output",
  include_public_debt = FALSE,

  # Harmonized names ONLY for every analysis.
  program_column = "Programa_Final",
  min_obs = 36L,
  rolling_window = 12L,
  volatility_threshold = 0.5,
  payroll_input_dir = file.path("1_databases", "payroll", "by ministry"),
  payroll_unified_file = file.path("1_databases", "payroll", "unified", "payroll_consolidated.xlsx")
)

# ======================== LOAD SHARED HELPERS ===============================
# Keep intermediate objects together in one environment shared by the stages.
pipeline_env <- new.env(parent = globalenv())
pipeline_env$config <- config

source(
  file.path("2_scripts", "99_helpers", "99_helpers.R"),
  local = pipeline_env
)
source(
  file.path("2_scripts", "99_helpers", "99_payroll_helpers.R"),
  local = pipeline_env
)

# ======================== PREPROCESS BOTH DATASETS ==========================
# Programs stay monthly; payroll stays annual. Each gets its own workbook.
for (script in c("0_correct_sources.R", "1_append_databases.R", "2_append_payroll.R")) {
  source(
    file.path("2_scripts", "1_preprocessing", script),
    local = pipeline_env
  )
}

# ======================== RUN ANALYSES IN ORDER =============================
# Volatility is computed first, so later descriptive/payroll analyses can use it.
for (script in c(
  "1_volatility_index.R", "2_state_level.R", "3_ministry_level.R",
  "4_determinants.R", "5_program_level.R", "6_structural_break.R", "7_budget_composition.R",
  "8_debt_sensitivity.R"
)) {
  source(
    file.path("2_scripts", "2_analysis", script),
    local = pipeline_env
  )
}

message("Full pipeline completed. All results: ", config$output_dir)
