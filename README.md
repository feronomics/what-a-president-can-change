# Que todo cambie para que nada cambie

## Project identification

- Working folder title: **What is a president able to change**.
- Project title recorded in the original script: **Que todo cambie para que nada cambie**.
- Author of the original analysis: **Fernando Sáenz** (21 May 2026).
- Affiliation recorded in the original script: **Asociación de Investigación y Estudios Sociales (ASIES)**.
- Pipeline reorganization: 13 October 2026.
- Additional authors, a formal project identifier, and data-cleaning credits are not specified in the supplied files and should be completed by the project team. A computer username in an old file path is not treated as an authorship record.

## Data provenance

The immediate inputs are the 16 cleaned `SICOIN_*_FINAL.xlsx` workbooks supplied in `1_databases/programs/by ministry`, using their `SICOIN` worksheet. Their filenames identify the 2004–2025 release. SICOIN refers to Guatemala's Sistema de Contabilidad Integrada, documented by the Ministerio de Finanzas Públicas in its [official SICOIN manual](https://sicoindes.minfin.gob.gt/sicoinweb/downloads/manualSICOIN3.pdf). These workbooks are local cleaned extracts rather than a direct connection to SICOIN.

The supplied script describes them as final V4 databases and identifies `Programa_Final` as the harmonized program label. The project does not contain an extraction URL, download date, original query, cleaning code, or a complete crosswalk of program-name changes. Those details should be added by the data producers; the new pipeline does not reconstruct or certify them. Source workbooks are retained unchanged.

The single master, `0_master.R`, runs two preprocessing stages: monthly program data and annual payroll data. The program stage reads `programs/by ministry` and writes `programs/unified/SICOIN_consolidated.xlsx`. The payroll stage reads `payroll/by ministry` and writes `payroll/unified/payroll_consolidated.xlsx`. All paths remain relative to `project` and are configured once in `0_master.R`.

## Data contents

The 16 source groups are MAGA, MARN, MCD, MEM, MICIVI, MIDES, MINDEF, MINECO, MINEDUC, MINEX, MINFIN, MINGOB, MINTRAB, MSPAS, Secretarias, and Deuda Pública. The last two are source groups, so “ministry” in the code is a convenient grouping label rather than a claim that every workbook represents a ministry.

Each source worksheet has these columns:

| Column | Use |
| --- | --- |
| `Año`, `Mes` | Year and Spanish calendar-month label |
| `Entidad`, `Depto` | Entity and department/source grouping labels, preserved as supplied |
| `Programa` | Original program label |
| `Programa_Estandarizado` | Intermediate standardized program label |
| `Programa_Final` | Final harmonized program label used for analysis |
| `Asignado` | Assigned budget amount |
| `Vigente` | Current budget amount |
| `Ejecutado` | Executed amount used in the volatility calculation |

Preprocessing appends all source rows with `dplyr::bind_rows()` without aggregating or removing duplicates. It adds `Ministerio` (source group derived from the filename) and `Archivo_Origen` (source filename). The unified workbook has a single `SICOIN` sheet. Analysis sums amounts within source group, final program, and month, across the remaining source dimensions.

`Ejecutado` contains monthly execution amounts. The analysis uses these monthly values as supplied.

## Volatility index

For each source group and `Programa_Final`, the analysis:

1. Aggregates observations by month and fills absent program-month combinations with zero over that source group's observed calendar.
2. Trims the series to its first and last strictly positive execution month. Interior zeros remain. Entirely zero series are skipped.
3. Requires at least 36 monthly observations and fits **SARIMA(1,1,0)(1,1,0)[12]** to `log(1 + Ejecutado)` using `stats::arima()`.
4. Computes each program's monthly index as the sample standard deviation of its model residuals over a trailing 12-month window. The first 11 active months have no rolling index.
5. Computes the source-group index as an execution-weighted sum of program indices: `sum((Ejecutado / sum(Ejecutado)) * index, na.rm = TRUE)`, among successfully fitted programs in that month.

The index describes variability of the part of log execution left unexplained by the specified model. Higher values indicate greater residual volatility. It is not a percentage, a direct measure of presidential influence, or a causal estimate. `index_total` is the residual standard deviation over the whole active program series and is repeated in the program output. `ypred` is the fitted value on the log scale; `noise` is the log-scale residual.

The model specification, active-life rule, minimum length, and weighting denominator come from the original script. The denominator includes fitted programs whose rolling index is not yet available; their missing terms are omitted from the numerator, so partial coverage can lower the aggregate. The new long-format output reports `programs_with_index` to make that coverage visible. No reweighting over available indices is performed.

Two safeguards are explicit in this version: a month with no available program indices or zero total execution returns a missing value instead of false zero volatility, and invalid log inputs or nonconverged fits are flagged. Skipped programs remain in the consolidated results and diagnostics, but are excluded from ministry weighting. Negative execution above -1 is mathematically admissible and retained; verify any negative amounts before interpreting execution shares as weights. Invalid dates, missing program names, or missing/non-finite budget amounts stop the pipeline rather than silently discarding data.

## Repository structure

```text
What is a president able to change/
├── README.md
├── 1_databases/
│   ├── programs/
│   │   ├── by ministry/             # 16 program source workbooks
│   │   └── unified/
│   │       └── SICOIN_consolidated.xlsx
│   └── payroll/
│       ├── by ministry/             # 14 annual spending files + Secretariat roster file
│       └── unified/
│           └── payroll_consolidated.xlsx
├── 2_scripts/
│   ├── 0_master.R
│   ├── 1_preprocessing/
│   │   ├── 1_append_databases.R
│   │   └── 2_append_payroll.R
│   ├── 2_analysis/
│   │   ├── 1_volatility_index.R
│   │   ├── 2_state_level.R
│   │   ├── 3_ministry_level.R
│   │   ├── 4_determinants.R
│   │   └── 5_program_level.R
│   └── 99_helpers/
│       ├── 99_helpers.R
│       └── 99_payroll_helpers.R
├── 3_output/
│   ├── 1_volatility-index/
│   │   └── volatility_index.xlsx   # One consolidated results workbook
│   ├── 2_tables/                   # Supporting CSVs, grouped by script
│   │   ├── 2_state/
│   │   ├── 3_ministry/
│   │   ├── 4_determinants/
│   │   └── 5_program/
│   └── 3_graphs/                   # One PNG per analysis or ministry
│       ├── 2_state/
│       ├── 3_ministry/
│       ├── 4_determinants/          # 3 annual-payroll analysis plots
│       └── 5_program/
└── archive/
    └── volatility_all_ministries_FIXED.R.txt # Original script for reference
```

`3_output` is at the project root. Each analysis script has its own graphs and supporting tables folder. Plot filenames are short and numbered. The pipeline uses packages installed in your normal R library.

## Running the pipeline

**Coauthors must configure their username and project-folder path in `2_scripts/0_master.R` before running the pipeline.** This is the only file that should contain a computer-specific path. In its `USER / PROJECT FOLDER` section:

1. Run `Sys.info()[["user"]]` in R to see your exact username.
2. Replace `"coauthor"` in the `else if` condition with that username.
3. Replace the placeholder `project` path with the full path to your local project folder, containing `1_databases` and `2_scripts`. Use forward slashes even on Windows.
4. Additional collaborators should add an `else if` branch with their own username and project path in the same master script.

The configuration follows this structure (the master already contains Fernando's actual project path):

```r
username <- Sys.info()[["user"]]

if (username == "fsaen") {
  project <- "C:/Users/fsaen/ROUTE/TO/PROJECT"
} else if (username == "coauthor") {
  # COAUTHOR: replace both the username above and the path below.
  project <- "C:/Users/coauthor/ROUTE/TO/PROJECT/"
}
```

The master automatically selects the matching branch and calls `setwd(project)`. **All script, input, and output paths thereafter are relative to that project folder.** Do not add personal paths to preprocessing, analysis, or helpers. An unconfigured username or nonexistent project folder stops execution with instructions to update the master. After running, R's working directory remains at the project root.

Use R with `dplyr`, `tidyr`, `zoo`, `readxl`, `writexl`, `ggplot2`, and `scales` installed. If they are already installed, simply run this from the project root:

```r
source("2_scripts/0_master.R")
```

Or from a terminal at the project root:

```text
Rscript --vanilla 2_scripts/0_master.R
```

You can also open and run `0_master.R` in your R editor, or invoke it by its full path from another working directory. The username configuration determines the project folder in every case. The master checks your normally installed dependencies, loads helpers, writes the unified workbook, and then reads that saved workbook for the analysis. It does not install packages automatically. All analyses use `Programa_Final`; do not change the program column to original labels. Set `min_obs`, `rolling_window`, and `volatility_threshold` in `0_master.R` to change the other analysis settings. The stage scripts expect the configuration/helpers supplied by the master.

One master runs everything: `0_master.R` loads both helper scripts, appends programs, appends annual payroll, then runs analysis scripts 1–5 in numerical order, including the updated `4_determinants.R`. There is no second entry point or pipeline-mode option. Payroll stays annual; it is never expanded into monthly observations. The master can be invoked by full path from another working directory.

Scripts use the `%>%` pipe, loaded through `dplyr` in the master. Functions document their purpose, inputs and returned results; comments and blank lines separate validation, transformation, modeling and export steps. Substantial calls and plot layers are written across separate lines for readability.

Each run overwrites the generated outputs; preserve a copy elsewhere if retaining a previous run is necessary. A validation failure stops execution, so an existing output workbook may belong to an earlier successful run. No additional packages or local package library are required for the payroll stages.

## Results workbook

| Worksheet | Contents |
| --- | --- |
| `ministry_index` | One row per month, one volatility column per source group |
| `ministry_index_long` | Source group, month, index, and number of available program indices |
| `program_results` | All program-month results, execution, fitted values, residuals, rolling index, total index, and status |
| `diagnostics` | One row per program with active dates, observation count, total index, and fit/skip status |
| `sources` | Source filenames, input row counts, and observed date coverage |
| `settings` | Program column, observation threshold, rolling window, model, and transformation |

Missing numeric results appear as blank Excel cells. Review `diagnostics` before interpreting ministry indices; a completed run can contain skipped programs.

## Additional analyses and plots

The single master runs `1_append_databases.R` and `2_append_payroll.R`, then `1_volatility_index.R`, `2_state_level.R`, `3_ministry_level.R`, `4_determinants.R`, and `5_program_level.R`. Shared utilities are in `99_helpers.R`; annual validation, linkage, and predictor construction are in `99_payroll_helpers.R`.

Each requested bullet produces one PNG, except ministry spending/growth (two separate images) and the program-level request (one image per source group). Ministry comparisons use panels within a single image. Ministry panels use their own vertical scales so large outliers do not flatten the other series; the volatility figure retains a shared vertical scale. Read the axis values when comparing magnitudes across panels. Supporting data are saved as numbered UTF-8 CSVs in the corresponding `3_output/2_tables` folder. Original source data remain unchanged.

| Script / graph folder | Numbered plots |
| --- | --- |
| `2_state_level.R` / `3_graphs/2_state` | `1_gasto`, `2_programas`, `3_volatilidad`, `4_duracion`, `5_presupuesto`, `6_estabilidad`, `7_gasto`, `8_top10` |
| `3_ministry_level.R` / `3_graphs/3_ministry` | `1_gasto`, `2_crecimiento`, `3_programas`, `4_volatilidad`, `5_duracion`, `6_presupuesto` |
| `4_determinants.R` / `3_graphs/4_determinants` | `1_correlacion`, `2_planilla`, `3_logit` |
| `5_program_level.R` / `3_graphs/5_program` | 16 numbered heatmaps, named by source group, such as `10_mineduc` and `13_mingob` |

Definitions used in these analyses:

- **Spending growth:** the state graph 1 shows annual total execution (nominal input units divided by one billion) and year-over-year growth in two horizontal panels within one image. Ministry analysis uses two separate images: `1_gasto` for amounts and `2_crecimiento` for growth rates, each with one panel per ministry. Growth is `100 * (execution_this_year / execution_previous_year - 1)`; the first observed year has no rate, and a zero prior-year denominator yields a missing rate. The accompanying tables include both measures. No inflation adjustment or assumed currency conversion is applied.
- **Program counts:** a program is active in a year if it has at least one record with positive execution. Its identity is source group plus `Programa_Final`, so identically named programs in different groups remain distinct. Zero-only rows are not counted as active programs.
- **State coverage:** “Estado” means the sum of the 16 supplied groups, including Secretariats and public debt; it does not establish complete coverage of all public-sector institutions.
- **Annual volatility:** average of available monthly indices within a year. The state monthly index pools successfully fitted programs across source groups and weights them by execution, using the same missing-index convention as the ministry index. It does not fit a new SARIMA model to aggregate state execution. Coverage counts are included in the tables.
- **Duration:** inclusive months between first and last positive execution, including interior pauses. These are observed durations within 2004–2025; programs may have begun earlier or continued later. All analyses use harmonized names (`Programa_Final`) exclusively. The state duration plot is a single histogram; ministry histograms also use harmonized names. Programs with no positive execution have no active duration and are omitted from histograms.
- **Budget execution/modification:** annual execution is the sum of monthly execution flows. Assigned and current budgets use the aggregate **December snapshot**, rather than adding monthly budget stocks. Execution rate is `100 * annual execution / December Vigente`; modification rate is `100 * (December Vigente - December Asignado) / December Asignado`. Zero denominators yield missing values. Large modification percentages are retained rather than capped.
- **Threshold comparisons:** use the program's **`index_total`**, the residual standard deviation across its whole active series, with the configured threshold of 0.5. `<0.5` is stable and `>0.5` is volatile. Values exactly equal to the threshold are shown separately. Both denominators include all programs/all supplied execution over 2004–2025, with a visible “Sin índice” category for skipped programs. The plotted spending shares use the original total execution, including any negative adjustments.
- **Top ten:** the ten smallest valid `index_total` values, regardless of whether they fall below 0.5. This is a relative ranking, not an assertion that these programs pass the threshold.
- **Program heatmaps:** one row per final program and one column per year, showing average available monthly rolling volatility. All programs are listed; unavailable values are grey. Color uses a common pseudologarithmic scale across ministries so differences remain visible despite large outliers. Long labels are abbreviated and made unique; full names and fit status are in the corresponding CSV dictionary.

## Annual payroll data and determinants

**Frequency confirmed by inspection of every worksheet:** the 14 `*_gasto_por_grupo.xlsx` workbooks have `Anio` and no month/date field. They contain annual spending, not monthly payroll. Coverage is 2004–2025, except MIDES (2012–2025). The workbook `secretarias_por_ano.xlsx` contains annual Secretariat counts, rosters, and changes, **not expenditure**; it is preserved as auxiliary sheets and is excluded from payroll percentages. There is no payroll spending workbook for Secretariats or public debt.

Each spending workbook contains `detalle` (year, entity, program code/name, expenditure type/group, assigned/current budget, and `Devengado`) and `resumen_planilla` (annual program spending, personnel spending, and supplied percentages). Preprocessing appends all detail rows with source/ministry provenance, preserves the supplied summaries separately, and recalculates annual totals from detail. **Servicios personales** is spending group `000`, checked against its label. Payroll share is `100 * personnel Devengado / total Devengado`, with nonpositive denominators left missing. Group codes remain character strings. These data measure personnel expenditure, not employee headcounts.

The consolidated workbook contains `detalle`, `anual`, `resumen_origen`, `fuentes`, `conciliacion`, and three `secretarias_*` auxiliary sheets. Detail totals are reconciled to the supplied annual summaries, allowing small rounding differences; the precise detail amounts are retained. All three source Secretariat sheets are preserved without pretending their counts are monetary spending.

**Linkage:** annual payroll program labels are matched within ministry/year to the existing original/standardized/final-name crosswalk in the monthly database. Formatting normalization removes case, accent, and punctuation differences; a match must identify exactly one `Programa_Final`. A cross-year alias is accepted only when it is unique across the full crosswalk and there is no year-specific match. No fuzzy matches or shared program-code assumptions are used. Original labels serve only as linkage evidence; every analysis still has harmonized ministry-program identities. Broad headings such as “GASTOS DE FUNCIONAMIENTO” are retained as unmatched instead of being allocated to several programs. `2_enlaces.csv` and `3_cobertura.csv` expose unmatched rows and their expenditure coverage. Absence of a match is not treated as zero personnel spending.

`4_determinants.R` implements the three requested bullets, with one plot each:

1. **Correlation:** a scatterplot of the program's personnel-spending share and `index_total`, with Pearson and Spearman coefficients. One observation is one linked harmonized ministry-program. Its personnel share is calculated from the sums of payroll and total expenditure across available linked years, not an unweighted average of percentages. The volatility index remains the program's full active-history index; the available payroll years are explicit in the covariate table, so the two time windows can differ.
2. **Personnel share by program:** a single figure listing all harmonized programs in **MINEDUC and MINGOB**, the examples requested, with abbreviated labels and a full-name dictionary. These are configurable in `payroll_ministries` in the master; the code does not assert they are the two most stable ministries. Unmatched programs are marked N/D. True zero personnel shares are retained as zero.
3. **Logistic regression:** `volatile ~ payroll_10pp + longevity_years + name_change + department_count`, estimated with binomial maximum likelihood. The outcome is 1 for `index_total > 0.5` and 0 for `<0.5`; equality and missing indices are excluded. `payroll_10pp` measures increases of 10 percentage points; longevity is the inclusive observed active span in years. The odds-ratio plot shows Wald 95% intervals. Model coefficients, exclusions, settings, warnings, and the fitted R model are saved. The script checks class variation, design rank, convergence, and finite estimates/intervals.

To implement the requested name-change predictor, `name_change` indicates whether the **set of normalized source aliases changes across active years within one harmonized program**. This is a documented proxy for an observed label change, not proof of a formal administrative renaming. It does not create separate program identities or bring back original-name histograms. Its year-by-year evidence is saved in `10_renombres.csv`.

Department count is the number of named Guatemalan departments with positive execution across the harmonized program's history. Multiregional, exterior, and debt labels are flagged and are not counted as additional departments; named coverage is a lower bound where these labels occur. The model uses this observed count without allocating multiregional spending to invented departments.

The main model and correlations use complete programs with valid indices and linked, valid payroll shares. They are descriptive associations, not causal estimates. Personnel amounts cover linked years only; unavailable early disaggregation and missing institutions can affect sample composition. Standard model errors/intervals assume independent program observations; they are not clustered by ministry. Program life spans are truncated by the observed 2004–2025 window.

Supporting CSVs in `3_output/2_tables/4_determinants` include `1_covariables`, `2_enlaces`, `3_cobertura`, `4_correlacion`, `5_planilla`, `6_logit`, `7_modelo`, `8_exclusiones`, `9_diccionario`, and `10_renombres`. `6_logit.rds` stores the fitted model. The previous `2_pendientes.csv` is removed after the three analyses succeed.

## Validation of the supplied release

The complete pipeline was run successfully. The unified workbook contains **307,954 rows** from **16 source workbooks**, with every original row and column checked against its source after saving. Results cover **264 calendar months (2004–2025)** and **318 program series**: **196 fitted successfully** and **122 were skipped**. Of the skipped programs, 37 contain execution values at or below -1 in their active series, for which the log transformation is undefined; these amounts were preserved and flagged. Other skip reasons are recorded in `diagnostics`.

Verification checked saved workbook dimensions, recomputed ministry weights from saved program results, compared the helper's residuals with a direct SARIMA fit, and checked short/constant series, active-life trimming, and missing/zero-execution aggregate behavior.

The additional analyses generated **30 PNGs** (8 state, 6 ministry comparisons, 16 program heatmaps). Validation reconciled annual execution to the consolidated rows, checked December budget totals, active program counts, durations using harmonized program names, percentage denominators, and available covariates. Ministry-year tables follow each source group's actual coverage rather than inventing observations before its first recorded year. The classification threshold for all analyses is 0.5, configured once in `0_master.R`; plot labels are generated from that setting. Fitted programs account for 82.24% of supplied execution and the remaining 17.76% belongs to programs without an index.

The payroll analysis adds **3 PNGs**, for **33 plots from the single master pipeline**. Its consolidated workbook contains **11,967 detail rows** and **1,354 annual source program records** from **14 ministries**. **1,047 records link unambiguously** to **162 harmonized programs**, covering **55.27% of payroll-source spending**; 307 source records remain unmatched. The complete-case correlation/regression sample contains **111 programs** (52 stable and 59 volatile). Among all 318 program identities, 85 have valid volatility but no linked payroll and 122 have no valid volatility index. These are sample exclusions, not zero payroll amounts.

Payroll validation compared every detail row with its source, recomputed annual totals and personnel shares, checked Secretariat exclusion, tested that ambiguous aliases stay unmatched, and reproduced the saved regression coefficients and correlations from exported covariates. The logistic model converged with all four requested predictors. Images were visually checked for legibility and missing-data labels.
