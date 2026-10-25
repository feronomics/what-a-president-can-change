# Structural change in state volatility: 2016 audit

## Data and hypotheses

Se excluye el servicio de la deuda pública: 15 grupos disponibles. The 2006–2025 window compares two equal ten-year periods (2006–2015 and 2016–2025) and reduces the possible influence of SARIMA initialization and the rolling index window in the earliest years. This potential initialization influence has not been established empirically. Models still use their complete active histories, not a separate 2004–2005 training sample. Monthly observations: January 2006–December 2025 (240 observations). The index measures the standard deviation of model residuals; this analysis tests changes in the LEVEL or TREND of that index, not the variance of its disturbances.

The January 2016 split is the nominated year boundary: 120 pre-break months and 120 post-break months. September 2016 is an additional date sensitivity. Dates were nominated after inspecting the data, so these are conditional tests, not confirmatory tests of an independently prespecified or unknown break.

Mean specification: restricted y ~ 1; unrestricted y ~ post. Trend specification: restricted y ~ time; unrestricted y ~ time * post, with time measured in years and zero in the first post-break month. Chow F compares restricted/unrestricted residual sums of squares. The trend test jointly tests a change in intercept and slope; significance does not alone imply a fall in the mean.

Classical Chow assumes independent, homoskedastic disturbances. Twelve-month rolling indices overlap and can be serially correlated. Separate Newey–West HAC Wald chi-square tests use Bartlett weights, lags 12 and 24, no prewhitening and an n/(n-k) correction. HAC intervals use normal asymptotics. None of these calculations propagate first-stage SARIMA estimation uncertainty.

## Mean comparisons (non-overlapping periods)

| Definition | First post month | Pre mean | Post mean | Change | Change (%) |
|---|---|---:|---:|---:|---:|
| current | 2016-01-01 | 0.963674 | 0.765203 | -0.198470 | -20.60% |
| current | 2016-09-01 | 0.967623 | 0.746514 | -0.221109 | -22.85% |
| annual_ministry | 2016-01-01 | 0.982775 | 0.718091 | -0.264683 | -26.93% |
| annual_ministry | 2016-09-01 | 0.986598 | 0.694817 | -0.291781 | -29.57% |

## Tests

| Definition | Split | Specification | Test | Statistic | df | p-value |
|---|---|---|---|---:|---|---:|
| current | 2016-01-01 | mean | Chow F (iid errors) | 22.9071 | 1, 238 | 2.9865e-06 |
| current | 2016-01-01 | mean | HAC Wald chi-square (lag 12) | 8.1529 | 1 | 0.0042993 |
| current | 2016-01-01 | mean | HAC Wald chi-square (lag 24) | 8.1073 | 1 | 0.0044087 |
| current | 2016-01-01 | trend | Chow F (iid errors) | 7.1922 | 2, 236 | 0.00092889 |
| current | 2016-01-01 | trend | HAC Wald chi-square (lag 12) | 21.2005 | 2 | 2.491e-05 |
| current | 2016-01-01 | trend | HAC Wald chi-square (lag 24) | 25.6975 | 2 | 2.6294e-06 |
| current | 2016-09-01 | mean | Chow F (iid errors) | 28.9616 | 1, 238 | 1.7659e-07 |
| current | 2016-09-01 | mean | HAC Wald chi-square (lag 12) | 10.0381 | 1 | 0.0015334 |
| current | 2016-09-01 | mean | HAC Wald chi-square (lag 24) | 10.0042 | 1 | 0.0015619 |
| current | 2016-09-01 | trend | Chow F (iid errors) | 7.7968 | 2, 236 | 0.00052608 |
| current | 2016-09-01 | trend | HAC Wald chi-square (lag 12) | 25.0079 | 2 | 3.712e-06 |
| current | 2016-09-01 | trend | HAC Wald chi-square (lag 24) | 29.1361 | 2 | 4.7116e-07 |
| annual_ministry | 2016-01-01 | mean | Chow F (iid errors) | 74.1283 | 1, 238 | 1.0157e-15 |
| annual_ministry | 2016-01-01 | mean | HAC Wald chi-square (lag 12) | 22.4818 | 1 | 2.1214e-06 |
| annual_ministry | 2016-01-01 | mean | HAC Wald chi-square (lag 24) | 20.2464 | 1 | 6.8082e-06 |
| annual_ministry | 2016-01-01 | trend | Chow F (iid errors) | 17.2177 | 2, 236 | 1.0474e-07 |
| annual_ministry | 2016-01-01 | trend | HAC Wald chi-square (lag 12) | 37.9476 | 2 | 5.7516e-09 |
| annual_ministry | 2016-01-01 | trend | HAC Wald chi-square (lag 24) | 42.7213 | 2 | 5.2867e-10 |
| annual_ministry | 2016-09-01 | mean | Chow F (iid errors) | 95.9542 | 1, 238 | 2.9754e-19 |
| annual_ministry | 2016-09-01 | mean | HAC Wald chi-square (lag 12) | 31.4709 | 1 | 2.0246e-08 |
| annual_ministry | 2016-09-01 | mean | HAC Wald chi-square (lag 24) | 28.7348 | 1 | 8.2998e-08 |
| annual_ministry | 2016-09-01 | trend | Chow F (iid errors) | 20.6695 | 2, 236 | 5.3497e-09 |
| annual_ministry | 2016-09-01 | trend | HAC Wald chi-square (lag 12) | 42.6634 | 2 | 5.4421e-10 |
| annual_ministry | 2016-09-01 | trend | HAC Wald chi-square (lag 24) | 45.8269 | 2 | 1.1189e-10 |

## Weighting definitions

current: monthly execution-weighted program indices pooled across ministries. annual_ministry: monthly ministry indices weighted by each ministry's total annual execution, with available ministries renormalized. Both definitions use the same fitted-program sample. Unusable log observations are missing; programs retain their valid histories. Annual weights include all source spending, while pooled monthly weights use fitted programs. This sensitivity distinguishes changes in volatility from changes in spending composition.

## Interpretation

current: the post-2016 average is lower by 20.60%. The lag-12 HAC level-change test has p = 0.0042993; reject equal levels at the conventional 5% threshold, conditional on this date and specification.

The joint level-and-trend HAC test for current has p = 2.491e-05. This is a joint test of intercept and slope changes, not a test that the full post-period mean is lower.

annual_ministry: the post-2016 average is lower by 26.93%. The lag-12 HAC level-change test has p = 2.1214e-06; reject equal levels at the conventional 5% threshold, conditional on this date and specification.

The joint level-and-trend HAC test for annual_ministry has p = 5.7516e-09. This is a joint test of intercept and slope changes, not a test that the full post-period mean is lower.

Do not switch aggregation definitions solely to obtain a desired decline. Keep the production definition explicit, report the alternative as sensitivity, and distinguish a local 2016 drop from a persistent full-period average shift. A global unknown-break procedure would need search-adjusted inference with serial-dependence treatment.

## Method references

- [strucchange: Chow and structural-change tests](https://search.r-project.org/CRAN/refmans/strucchange/html/sctest.formula.html)
- [sandwich: Newey–West HAC specification](https://sandwich.r-forge.r-project.org/reference/NeweyWest.html)

Reproduce by running 2_scripts/0_master.R. Numerical results are in 1_series.csv, 2_tests.csv and 3_means.csv; figure: 3_output/3_graphs/6_breaks/1_comparacion.png.
