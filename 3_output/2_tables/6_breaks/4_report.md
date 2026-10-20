# Structural change in state volatility: 2016 audit

## Data and hypotheses

Monthly observations: January 2005–December 2025 (252 observations). The index measures the standard deviation of model residuals; this analysis tests changes in the LEVEL or TREND of that index, not the variance of its disturbances.

The January 2016 split is the nominated year boundary: 132 pre-break months and 120 post-break months. September 2016 is an additional date sensitivity. Dates were nominated after inspecting the data, so these are conditional tests, not confirmatory tests of an independently prespecified or unknown break.

Mean specification: restricted y ~ 1; unrestricted y ~ post. Trend specification: restricted y ~ time; unrestricted y ~ time * post, with time measured in years and zero in the first post-break month. Chow F compares restricted/unrestricted residual sums of squares. The trend test jointly tests a change in intercept and slope; significance does not alone imply a fall in the mean.

Classical Chow assumes independent, homoskedastic disturbances. Twelve-month rolling indices overlap and can be serially correlated. Separate Newey–West HAC Wald chi-square tests use Bartlett weights, lags 12 and 24, no prewhitening and an n/(n-k) correction. HAC intervals use normal asymptotics. None of these calculations propagate first-stage SARIMA estimation uncertainty.

## Mean comparisons (non-overlapping periods)

| Definition | First post month | Pre mean | Post mean | Change | Change (%) |
|---|---|---:|---:|---:|---:|
| current | 2016-01-01 | 0.773176 | 0.706641 | -0.066535 | -8.61% |
| current | 2016-09-01 | 0.782260 | 0.690533 | -0.091726 | -11.73% |
| annual_ministry | 2016-01-01 | 0.790784 | 0.670489 | -0.120296 | -15.21% |
| annual_ministry | 2016-09-01 | 0.800335 | 0.649957 | -0.150378 | -18.79% |

## Tests

| Definition | Split | Specification | Test | Statistic | df | p-value |
|---|---|---|---|---:|---|---:|
| current | 2016-01-01 | mean | Chow F (iid errors) | 3.4872 | 1, 250 | 0.063017 |
| current | 2016-01-01 | mean | HAC Wald chi-square (lag 12) | 0.8846 | 1 | 0.34694 |
| current | 2016-01-01 | mean | HAC Wald chi-square (lag 24) | 0.7796 | 1 | 0.37727 |
| current | 2016-01-01 | trend | Chow F (iid errors) | 13.9613 | 2, 248 | 1.7963e-06 |
| current | 2016-01-01 | trend | HAC Wald chi-square (lag 12) | 10.5089 | 2 | 0.0052241 |
| current | 2016-01-01 | trend | HAC Wald chi-square (lag 24) | 9.0690 | 2 | 0.010732 |
| current | 2016-09-01 | mean | Chow F (iid errors) | 6.6423 | 1, 250 | 0.010532 |
| current | 2016-09-01 | mean | HAC Wald chi-square (lag 12) | 1.6749 | 1 | 0.1956 |
| current | 2016-09-01 | mean | HAC Wald chi-square (lag 24) | 1.4523 | 1 | 0.22815 |
| current | 2016-09-01 | trend | Chow F (iid errors) | 14.6584 | 2, 248 | 9.615e-07 |
| current | 2016-09-01 | trend | HAC Wald chi-square (lag 12) | 10.9474 | 2 | 0.0041957 |
| current | 2016-09-01 | trend | HAC Wald chi-square (lag 24) | 9.3377 | 2 | 0.009383 |
| annual_ministry | 2016-01-01 | mean | Chow F (iid errors) | 18.0486 | 1, 250 | 3.0407e-05 |
| annual_ministry | 2016-01-01 | mean | HAC Wald chi-square (lag 12) | 3.6192 | 1 | 0.057117 |
| annual_ministry | 2016-01-01 | mean | HAC Wald chi-square (lag 24) | 2.9803 | 1 | 0.084281 |
| annual_ministry | 2016-01-01 | trend | Chow F (iid errors) | 28.2730 | 2, 248 | 8.6903e-12 |
| annual_ministry | 2016-01-01 | trend | HAC Wald chi-square (lag 12) | 11.8551 | 2 | 0.002665 |
| annual_ministry | 2016-01-01 | trend | HAC Wald chi-square (lag 24) | 10.4241 | 2 | 0.0054505 |
| annual_ministry | 2016-09-01 | mean | Chow F (iid errors) | 29.0667 | 1, 250 | 1.6179e-07 |
| annual_ministry | 2016-09-01 | mean | HAC Wald chi-square (lag 12) | 6.1285 | 1 | 0.013302 |
| annual_ministry | 2016-09-01 | mean | HAC Wald chi-square (lag 24) | 4.9145 | 1 | 0.026633 |
| annual_ministry | 2016-09-01 | trend | Chow F (iid errors) | 31.9686 | 2, 248 | 4.4429e-13 |
| annual_ministry | 2016-09-01 | trend | HAC Wald chi-square (lag 12) | 13.6175 | 2 | 0.0011041 |
| annual_ministry | 2016-09-01 | trend | HAC Wald chi-square (lag 24) | 11.5185 | 2 | 0.0031535 |

## Weighting definitions

current: monthly execution-weighted program indices pooled across ministries. annual_ministry: monthly ministry indices weighted by each ministry's total annual execution, with available ministries renormalized. Both definitions use the same fitted-program sample. Unusable log observations are missing; programs retain their valid histories. Annual weights include all source spending, while pooled monthly weights use fitted programs. This sensitivity distinguishes changes in volatility from changes in spending composition.

## Interpretation

current: the post-2016 average is lower by 8.61%. The lag-12 HAC level-change test has p = 0.34694; do not reject equal levels at the conventional 5% threshold, conditional on this date and specification.

The joint level-and-trend HAC test for current has p = 0.0052241. This is a joint test of intercept and slope changes, not a test that the full post-period mean is lower.

annual_ministry: the post-2016 average is lower by 15.21%. The lag-12 HAC level-change test has p = 0.057117; do not reject equal levels at the conventional 5% threshold, conditional on this date and specification.

The joint level-and-trend HAC test for annual_ministry has p = 0.002665. This is a joint test of intercept and slope changes, not a test that the full post-period mean is lower.

Do not switch aggregation definitions solely to obtain a desired decline. Keep the production definition explicit, report the alternative as sensitivity, and distinguish a local 2016 drop from a persistent full-period average shift. A global unknown-break procedure would need search-adjusted inference with serial-dependence treatment.

## Method references

- [strucchange: Chow and structural-change tests](https://search.r-project.org/CRAN/refmans/strucchange/html/sctest.formula.html)
- [sandwich: Newey–West HAC specification](https://sandwich.r-forge.r-project.org/reference/NeweyWest.html)

Reproduce by running 2_scripts/0_master.R. Numerical results are in 1_series.csv, 2_tests.csv and 3_means.csv; figure: 3_output/3_graphs/6_breaks/1_comparacion.png.
