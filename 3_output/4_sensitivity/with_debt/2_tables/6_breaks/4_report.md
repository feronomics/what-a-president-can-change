# Structural change in state volatility: 2016 audit

## Data and hypotheses

Incluye el servicio de la deuda pública: 16 grupos disponibles. The 2006–2025 window compares two equal ten-year periods (2006–2015 and 2016–2025) and reduces the possible influence of SARIMA initialization and the rolling index window in the earliest years. This potential initialization influence has not been established empirically. Models still use their complete active histories, not a separate 2004–2005 training sample. Monthly observations: January 2006–December 2025 (240 observations). The index measures the standard deviation of model residuals; this analysis tests changes in the LEVEL or TREND of that index, not the variance of its disturbances.

The January 2016 split is the nominated year boundary: 120 pre-break months and 120 post-break months. September 2016 is an additional date sensitivity. Dates were nominated after inspecting the data, so these are conditional tests, not confirmatory tests of an independently prespecified or unknown break.

Mean specification: restricted y ~ 1; unrestricted y ~ post. Trend specification: restricted y ~ time; unrestricted y ~ time * post, with time measured in years and zero in the first post-break month. Chow F compares restricted/unrestricted residual sums of squares. The trend test jointly tests a change in intercept and slope; significance does not alone imply a fall in the mean.

Classical Chow assumes independent, homoskedastic disturbances. Twelve-month rolling indices overlap and can be serially correlated. Separate Newey–West HAC Wald chi-square tests use Bartlett weights, lags 12 and 24, no prewhitening and an n/(n-k) correction. HAC intervals use normal asymptotics. None of these calculations propagate first-stage SARIMA estimation uncertainty.

## Mean comparisons (non-overlapping periods)

| Definition | First post month | Pre mean | Post mean | Change | Change (%) |
|---|---|---:|---:|---:|---:|
| current | 2016-01-01 | 0.821729 | 0.706641 | -0.115088 | -14.01% |
| current | 2016-09-01 | 0.828630 | 0.690533 | -0.138096 | -16.67% |
| annual_ministry | 2016-01-01 | 0.840564 | 0.670489 | -0.170075 | -20.23% |
| annual_ministry | 2016-09-01 | 0.847899 | 0.649957 | -0.197941 | -23.34% |

## Tests

| Definition | Split | Specification | Test | Statistic | df | p-value |
|---|---|---|---|---:|---|---:|
| current | 2016-01-01 | mean | Chow F (iid errors) | 11.3949 | 1, 238 | 0.00085992 |
| current | 2016-01-01 | mean | HAC Wald chi-square (lag 12) | 3.8272 | 1 | 0.050428 |
| current | 2016-01-01 | mean | HAC Wald chi-square (lag 24) | 3.6860 | 1 | 0.054872 |
| current | 2016-01-01 | trend | Chow F (iid errors) | 4.4202 | 2, 236 | 0.013044 |
| current | 2016-01-01 | trend | HAC Wald chi-square (lag 12) | 9.6301 | 2 | 0.0081067 |
| current | 2016-01-01 | trend | HAC Wald chi-square (lag 24) | 11.0295 | 2 | 0.0040269 |
| current | 2016-09-01 | mean | Chow F (iid errors) | 16.6795 | 1, 238 | 6.0486e-05 |
| current | 2016-09-01 | mean | HAC Wald chi-square (lag 12) | 5.2958 | 1 | 0.021377 |
| current | 2016-09-01 | mean | HAC Wald chi-square (lag 24) | 4.9708 | 1 | 0.025779 |
| current | 2016-09-01 | trend | Chow F (iid errors) | 4.6870 | 2, 236 | 0.010089 |
| current | 2016-09-01 | trend | HAC Wald chi-square (lag 12) | 11.3075 | 2 | 0.0035043 |
| current | 2016-09-01 | trend | HAC Wald chi-square (lag 24) | 12.2221 | 2 | 0.0022182 |
| annual_ministry | 2016-01-01 | mean | Chow F (iid errors) | 45.2129 | 1, 238 | 1.2995e-10 |
| annual_ministry | 2016-01-01 | mean | HAC Wald chi-square (lag 12) | 12.4786 | 1 | 0.00041165 |
| annual_ministry | 2016-01-01 | mean | HAC Wald chi-square (lag 24) | 11.2508 | 1 | 0.00079589 |
| annual_ministry | 2016-01-01 | trend | Chow F (iid errors) | 9.5990 | 2, 236 | 9.82e-05 |
| annual_ministry | 2016-01-01 | trend | HAC Wald chi-square (lag 12) | 17.0630 | 2 | 0.00019716 |
| annual_ministry | 2016-01-01 | trend | HAC Wald chi-square (lag 24) | 20.2934 | 2 | 3.9205e-05 |
| annual_ministry | 2016-09-01 | mean | Chow F (iid errors) | 65.2934 | 1, 238 | 3.2456e-14 |
| annual_ministry | 2016-09-01 | mean | HAC Wald chi-square (lag 12) | 18.3533 | 1 | 1.835e-05 |
| annual_ministry | 2016-09-01 | mean | HAC Wald chi-square (lag 24) | 16.0757 | 1 | 6.086e-05 |
| annual_ministry | 2016-09-01 | trend | Chow F (iid errors) | 12.7572 | 2, 236 | 5.4845e-06 |
| annual_ministry | 2016-09-01 | trend | HAC Wald chi-square (lag 12) | 20.5040 | 2 | 3.5288e-05 |
| annual_ministry | 2016-09-01 | trend | HAC Wald chi-square (lag 24) | 21.6952 | 2 | 1.9451e-05 |

## Weighting definitions

current: monthly execution-weighted program indices pooled across ministries. annual_ministry: monthly ministry indices weighted by each ministry's total annual execution, with available ministries renormalized. Both definitions use the same fitted-program sample. Unusable log observations are missing; programs retain their valid histories. Annual weights include all source spending, while pooled monthly weights use fitted programs. This sensitivity distinguishes changes in volatility from changes in spending composition.

## Interpretation

current: the post-2016 average is lower by 14.01%. The lag-12 HAC level-change test has p = 0.050428; do not reject equal levels at the conventional 5% threshold, conditional on this date and specification.

The joint level-and-trend HAC test for current has p = 0.0081067. This is a joint test of intercept and slope changes, not a test that the full post-period mean is lower.

annual_ministry: the post-2016 average is lower by 20.23%. The lag-12 HAC level-change test has p = 0.00041165; reject equal levels at the conventional 5% threshold, conditional on this date and specification.

The joint level-and-trend HAC test for annual_ministry has p = 0.00019716. This is a joint test of intercept and slope changes, not a test that the full post-period mean is lower.

Do not switch aggregation definitions solely to obtain a desired decline. Keep the production definition explicit, report the alternative as sensitivity, and distinguish a local 2016 drop from a persistent full-period average shift. A global unknown-break procedure would need search-adjusted inference with serial-dependence treatment.

## Method references

- [strucchange: Chow and structural-change tests](https://search.r-project.org/CRAN/refmans/strucchange/html/sctest.formula.html)
- [sandwich: Newey–West HAC specification](https://sandwich.r-forge.r-project.org/reference/NeweyWest.html)

Reproduce by running 2_scripts/0_master.R. Numerical results are in 1_series.csv, 2_tests.csv and 3_means.csv; figure: 3_output/4_sensitivity/with_debt/3_graphs/6_breaks/1_comparacion.png.
