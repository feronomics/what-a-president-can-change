# Structural change in state volatility: 2016 audit

## Data and hypotheses

Scope: 15 observed source groups, excluding public-debt service before calculating indices, totals and weights. The 2006–2025 window compares two equal ten-year periods (2006–2015 and 2016–2025) and reduces the possible influence of SARIMA initialization and the rolling index window in the earliest years. This potential initialization influence has not been established empirically. Models still use their complete active histories, not a separate 2004–2005 training sample. Monthly observations: January 2006–December 2025 (240 observations). The index measures the standard deviation of model residuals; this analysis tests changes in the LEVEL or TREND of that index, not the variance of its disturbances.

The January 2016 split is the nominated year boundary: 120 pre-break months and 120 post-break months. September 2016 is an additional date sensitivity. Dates were nominated after inspecting the data, so these are conditional tests, not confirmatory tests of an independently prespecified or unknown break.

Mean specification: restricted y ~ 1; unrestricted y ~ post. Trend specification: restricted y ~ time; unrestricted y ~ time * post, with time measured in years and zero in the first post-break month. Chow F compares restricted/unrestricted residual sums of squares. The trend test jointly tests a change in intercept and slope; significance does not alone imply a fall in the mean.

Classical Chow assumes independent, homoskedastic disturbances. Twelve-month rolling indices overlap and can be serially correlated. Separate Newey–West HAC Wald chi-square tests use Bartlett weights, lags 12 and 24, no prewhitening and an n/(n-k) correction. HAC intervals use normal asymptotics. None of these calculations propagate first-stage SARIMA estimation uncertainty.

## Mean comparisons (non-overlapping periods)

| Definition | First post month | Pre mean | Post mean | Change | Change (%) |
|---|---|---:|---:|---:|---:|
| current | 2016-01-01 | 0.974550 | 0.764116 | -0.210433 | -21.59% |
| current | 2016-09-01 | 0.977827 | 0.745340 | -0.232486 | -23.78% |
| annual_ministry | 2016-01-01 | 0.994260 | 0.717689 | -0.276571 | -27.82% |
| annual_ministry | 2016-09-01 | 0.997391 | 0.694356 | -0.303035 | -30.38% |

## Tests

| Definition | Split | Specification | Test | Statistic | df | p-value |
|---|---|---|---|---:|---|---:|
| current | 2016-01-01 | mean | Chow F (iid errors) | 26.1014 | 1, 238 | 6.6453e-07 |
| current | 2016-01-01 | mean | HAC Wald chi-square (lag 12) | 9.3479 | 1 | 0.0022324 |
| current | 2016-01-01 | mean | HAC Wald chi-square (lag 24) | 9.2891 | 1 | 0.0023052 |
| current | 2016-01-01 | trend | Chow F (iid errors) | 7.0205 | 2, 236 | 0.0010922 |
| current | 2016-01-01 | trend | HAC Wald chi-square (lag 12) | 19.2784 | 2 | 6.5126e-05 |
| current | 2016-01-01 | trend | HAC Wald chi-square (lag 24) | 23.4712 | 2 | 8.0038e-06 |
| current | 2016-09-01 | mean | Chow F (iid errors) | 32.4837 | 1, 238 | 3.5393e-08 |
| current | 2016-09-01 | mean | HAC Wald chi-square (lag 12) | 11.3984 | 1 | 0.00073507 |
| current | 2016-09-01 | mean | HAC Wald chi-square (lag 24) | 11.3801 | 1 | 0.00074233 |
| current | 2016-09-01 | trend | Chow F (iid errors) | 7.6348 | 2, 236 | 0.0006125 |
| current | 2016-09-01 | trend | HAC Wald chi-square (lag 12) | 22.6964 | 2 | 1.1791e-05 |
| current | 2016-09-01 | trend | HAC Wald chi-square (lag 24) | 26.6503 | 2 | 1.6329e-06 |
| annual_ministry | 2016-01-01 | mean | Chow F (iid errors) | 80.3425 | 1, 238 | 9.4443e-17 |
| annual_ministry | 2016-01-01 | mean | HAC Wald chi-square (lag 12) | 24.7740 | 1 | 6.4462e-07 |
| annual_ministry | 2016-01-01 | mean | HAC Wald chi-square (lag 24) | 22.3048 | 1 | 2.3263e-06 |
| annual_ministry | 2016-01-01 | trend | Chow F (iid errors) | 16.8187 | 2, 236 | 1.4844e-07 |
| annual_ministry | 2016-01-01 | trend | HAC Wald chi-square (lag 12) | 33.2238 | 2 | 6.103e-08 |
| annual_ministry | 2016-01-01 | trend | HAC Wald chi-square (lag 24) | 37.4448 | 2 | 7.3954e-09 |
| annual_ministry | 2016-09-01 | mean | Chow F (iid errors) | 102.7979 | 1, 238 | 2.5995e-20 |
| annual_ministry | 2016-09-01 | mean | HAC Wald chi-square (lag 12) | 34.5835 | 1 | 4.0836e-09 |
| annual_ministry | 2016-09-01 | mean | HAC Wald chi-square (lag 24) | 31.7216 | 1 | 1.7794e-08 |
| annual_ministry | 2016-09-01 | trend | Chow F (iid errors) | 20.2104 | 2, 236 | 7.912e-09 |
| annual_ministry | 2016-09-01 | trend | HAC Wald chi-square (lag 12) | 37.6180 | 2 | 6.7819e-09 |
| annual_ministry | 2016-09-01 | trend | HAC Wald chi-square (lag 24) | 40.3875 | 2 | 1.6981e-09 |

## Weighting definitions

current: monthly execution-weighted program indices pooled across ministries. annual_ministry: monthly ministry indices weighted by each ministry's total annual execution, with available ministries renormalized. Both definitions use the same fitted-program sample. Unusable log observations are missing; programs retain their valid histories. Annual weights include all source spending, while pooled monthly weights use fitted programs. This sensitivity distinguishes changes in volatility from changes in spending composition.

## Interpretation

current: the post-2016 average is lower by 21.59%. The lag-12 HAC level-change test has p = 0.0022324; reject equal levels at the conventional 5% threshold, conditional on this date and specification.

The joint level-and-trend HAC test for current has p = 6.5126e-05. This is a joint test of intercept and slope changes, not a test that the full post-period mean is lower.

annual_ministry: the post-2016 average is lower by 27.82%. The lag-12 HAC level-change test has p = 6.4462e-07; reject equal levels at the conventional 5% threshold, conditional on this date and specification.

The joint level-and-trend HAC test for annual_ministry has p = 6.103e-08. This is a joint test of intercept and slope changes, not a test that the full post-period mean is lower.

Do not switch aggregation definitions solely to obtain a desired decline. Keep the production definition explicit, report the alternative as sensitivity, and distinguish a local 2016 drop from a persistent full-period average shift. A global unknown-break procedure would need search-adjusted inference with serial-dependence treatment.

## Method references

- [strucchange: Chow and structural-change tests](https://search.r-project.org/CRAN/refmans/strucchange/html/sctest.formula.html)
- [sandwich: Newey–West HAC specification](https://sandwich.r-forge.r-project.org/reference/NeweyWest.html)

Reproduce by running 2_scripts/0_master.R. Numerical results are in 1_series.csv, 2_tests.csv and 3_means.csv; figure: 3_output/3_graphs/6_breaks/1_comparacion.png.
