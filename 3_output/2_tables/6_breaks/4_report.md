# Structural change in state volatility: 2016 audit

## Data and hypotheses

Scope: 15 observed source groups, excluding public-debt service before calculating indices, totals and weights. Monthly observations: January 2005–December 2025 (252 observations). The index measures the standard deviation of model residuals; this analysis tests changes in the LEVEL or TREND of that index, not the variance of its disturbances.

The January 2016 split is the nominated year boundary: 132 pre-break months and 120 post-break months. September 2016 is an additional date sensitivity. Dates were nominated after inspecting the data, so these are conditional tests, not confirmatory tests of an independently prespecified or unknown break.

Mean specification: restricted y ~ 1; unrestricted y ~ post. Trend specification: restricted y ~ time; unrestricted y ~ time * post, with time measured in years and zero in the first post-break month. Chow F compares restricted/unrestricted residual sums of squares. The trend test jointly tests a change in intercept and slope; significance does not alone imply a fall in the mean.

Classical Chow assumes independent, homoskedastic disturbances. Twelve-month rolling indices overlap and can be serially correlated. Separate Newey–West HAC Wald chi-square tests use Bartlett weights, lags 12 and 24, no prewhitening and an n/(n-k) correction. HAC intervals use normal asymptotics. None of these calculations propagate first-stage SARIMA estimation uncertainty.

## Mean comparisons (non-overlapping periods)

| Definition | First post month | Pre mean | Post mean | Change | Change (%) |
|---|---|---:|---:|---:|---:|
| current | 2016-01-01 | 0.916198 | 0.764116 | -0.152082 | -16.60% |
| current | 2016-09-01 | 0.922528 | 0.745340 | -0.177188 | -19.21% |
| annual_ministry | 2016-01-01 | 0.934587 | 0.717689 | -0.216898 | -23.21% |
| annual_ministry | 2016-09-01 | 0.940859 | 0.694356 | -0.246504 | -26.20% |

## Tests

| Definition | Split | Specification | Test | Statistic | df | p-value |
|---|---|---|---|---:|---|---:|
| current | 2016-01-01 | mean | Chow F (iid errors) | 12.4842 | 1, 250 | 0.00048872 |
| current | 2016-01-01 | mean | HAC Wald chi-square (lag 12) | 3.3372 | 1 | 0.06773 |
| current | 2016-01-01 | mean | HAC Wald chi-square (lag 24) | 2.9286 | 1 | 0.08702 |
| current | 2016-01-01 | trend | Chow F (iid errors) | 19.4761 | 2, 248 | 1.3919e-08 |
| current | 2016-01-01 | trend | HAC Wald chi-square (lag 12) | 14.9920 | 2 | 0.00055531 |
| current | 2016-01-01 | trend | HAC Wald chi-square (lag 24) | 13.1080 | 2 | 0.0014244 |
| current | 2016-09-01 | mean | Chow F (iid errors) | 17.0681 | 1, 250 | 4.9221e-05 |
| current | 2016-09-01 | mean | HAC Wald chi-square (lag 12) | 4.6585 | 1 | 0.030901 |
| current | 2016-09-01 | mean | HAC Wald chi-square (lag 24) | 4.1137 | 1 | 0.042537 |
| current | 2016-09-01 | trend | Chow F (iid errors) | 19.6645 | 2, 248 | 1.1829e-08 |
| current | 2016-09-01 | trend | HAC Wald chi-square (lag 12) | 15.2073 | 2 | 0.00049864 |
| current | 2016-09-01 | trend | HAC Wald chi-square (lag 24) | 12.9881 | 2 | 0.0015124 |
| annual_ministry | 2016-01-01 | mean | Chow F (iid errors) | 39.8149 | 1, 250 | 1.2611e-09 |
| annual_ministry | 2016-01-01 | mean | HAC Wald chi-square (lag 12) | 8.5603 | 1 | 0.0034357 |
| annual_ministry | 2016-01-01 | mean | HAC Wald chi-square (lag 24) | 6.8572 | 1 | 0.0088286 |
| annual_ministry | 2016-01-01 | trend | Chow F (iid errors) | 39.6595 | 2, 248 | 1.1365e-15 |
| annual_ministry | 2016-01-01 | trend | HAC Wald chi-square (lag 12) | 17.4476 | 2 | 0.00016267 |
| annual_ministry | 2016-01-01 | trend | HAC Wald chi-square (lag 24) | 15.0225 | 2 | 0.00054691 |
| annual_ministry | 2016-09-01 | mean | Chow F (iid errors) | 53.2695 | 1, 250 | 3.8581e-12 |
| annual_ministry | 2016-09-01 | mean | HAC Wald chi-square (lag 12) | 12.5230 | 1 | 0.00040198 |
| annual_ministry | 2016-09-01 | mean | HAC Wald chi-square (lag 24) | 10.0038 | 1 | 0.0015622 |
| annual_ministry | 2016-09-01 | trend | Chow F (iid errors) | 41.9001 | 2, 248 | 2.1052e-16 |
| annual_ministry | 2016-09-01 | trend | HAC Wald chi-square (lag 12) | 18.4668 | 2 | 9.7721e-05 |
| annual_ministry | 2016-09-01 | trend | HAC Wald chi-square (lag 24) | 15.3376 | 2 | 0.00046718 |

## Weighting definitions

current: monthly execution-weighted program indices pooled across ministries. annual_ministry: monthly ministry indices weighted by each ministry's total annual execution, with available ministries renormalized. Both definitions use the same fitted-program sample. Unusable log observations are missing; programs retain their valid histories. Annual weights include all source spending, while pooled monthly weights use fitted programs. This sensitivity distinguishes changes in volatility from changes in spending composition.

## Interpretation

current: the post-2016 average is lower by 16.60%. The lag-12 HAC level-change test has p = 0.06773; do not reject equal levels at the conventional 5% threshold, conditional on this date and specification.

The joint level-and-trend HAC test for current has p = 0.00055531. This is a joint test of intercept and slope changes, not a test that the full post-period mean is lower.

annual_ministry: the post-2016 average is lower by 23.21%. The lag-12 HAC level-change test has p = 0.0034357; reject equal levels at the conventional 5% threshold, conditional on this date and specification.

The joint level-and-trend HAC test for annual_ministry has p = 0.00016267. This is a joint test of intercept and slope changes, not a test that the full post-period mean is lower.

Do not switch aggregation definitions solely to obtain a desired decline. Keep the production definition explicit, report the alternative as sensitivity, and distinguish a local 2016 drop from a persistent full-period average shift. A global unknown-break procedure would need search-adjusted inference with serial-dependence treatment.

## Method references

- [strucchange: Chow and structural-change tests](https://search.r-project.org/CRAN/refmans/strucchange/html/sctest.formula.html)
- [sandwich: Newey–West HAC specification](https://sandwich.r-forge.r-project.org/reference/NeweyWest.html)

Reproduce by running 2_scripts/0_master.R. Numerical results are in 1_series.csv, 2_tests.csv and 3_means.csv; figure: 3_output/3_graphs/6_breaks/1_comparacion.png.
