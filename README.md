
# medmodr Package: Systematic moderation and mediation analysis in R.

<!-- badges: start -->

[![R-CMD-check](https://github.com/tosmartak/medmodr/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/tosmartak/medmodr/actions/workflows/R-CMD-check.yaml)
[![License: GPL (\>=
2)](https://img.shields.io/badge/license-GPL%20(%3E=2)-blue.svg)](https://www.gnu.org/licenses/gpl-2.0.html)
[![Codecov test
coverage](https://codecov.io/gh/tosmartak/medmodr/graph/badge.svg)](https://app.codecov.io/gh/tosmartak/medmodr)
[![GitHub
version](https://img.shields.io/github/r-package/v/tosmartak/medmodr)](https://github.com/tosmartak/medmodr/)
[![pkgdown
site](https://img.shields.io/badge/docs-pkgdown-blue.svg)](https://tosmartak.github.io/medmodr/)
<!-- badges: end -->

<!-- CRAN badges (uncomment once on CRAN)
[![CRAN status](https://www.r-pkg.org/badges/version/medmodr)](https://CRAN.R-project.org/package=medmodr)
[![CRAN downloads](https://cranlogs.r-pkg.org/badges/last-month/medmodr)](https://CRAN.R-project.org/package=medmodr)
[![CRAN checks](https://badges.cranchecks.info/worst/medmodr.svg)](https://cran.r-project.org/web/checks/check_results_medmodr.html)
-->

`medmodr` helps you scan multiple variable combinations for moderation
and mediation effects without having to manually fit each model. It
provides tidy outputs and ready-to-publish visualizations. This package
builds upon the
[`mediation`](https://CRAN.R-project.org/package=mediation) package
\[Tingley et al., 2014\] for mediation analysis and the
[`interactions`](https://CRAN.R-project.org/package=interactions)
package \[Long, 2024\] for moderation plots.

## Learn more

Full walkthrough with moderation, mediation, and plotting:
[`Getting started with medmodr`](https://tosmartak.github.io/medmodr/articles/getting-started.html)

## Installation

`medmodr` requires `R >= 4.1.0`.

You can install the released version of **medmodr** from CRAN with:

``` r
install.packages("medmodr")
```

And you can install the development version from GitHub with:

``` r
# install.packages("pak")
pak::pak("tosmartak/medmodr")
# or alternatively:
# devtools::install_github("tosmartak/medmodr")
```

``` r
library(medmodr)
```

## Example

The package includes a small synthetic dataset `demo_medmodr` with
multiple predictors, mediators, moderators, and outcomes, designed to
demonstrate how to use the functions quickly.

``` r
data("demo_medmodr")
knitr::kable(head(demo_medmodr))
```

|         x1 |         x2 |         m1 |         m2 |         c1 |         c2 | grp     | edu       |         y1 |         y2 |
|-----------:|-----------:|-----------:|-----------:|-----------:|-----------:|:--------|:----------|-----------:|-----------:|
|  1.3709584 | -2.0009292 |  2.4316793 | -1.4490405 |  0.6888078 |  2.3250585 | treat   | tertiary  |  4.4866832 | -0.5296494 |
| -0.5646982 |  0.3337772 | -1.3210303 |  0.6225867 |  0.7250830 |  0.5241222 | control | tertiary  |  0.3903687 |  1.0376276 |
|  0.3631284 |  1.1713251 |  0.3459897 |  1.6904484 |  0.2173802 |  0.9707334 | control | secondary |  0.3218529 |  0.6648226 |
|  0.6328626 |  2.0595392 |  0.5553570 |  2.0712917 | -0.2016567 |  0.3769734 | treat   | tertiary  |  2.0106726 |  3.1052683 |
|  0.4042683 | -1.3768616 | -0.2549411 | -1.4866388 | -1.3656899 | -0.9959334 | treat   | primary   |  0.2309061 | -0.5248641 |
| -0.1061245 | -1.1508556 | -1.0836383 |  0.8735562 | -0.3089376 | -0.5974829 | control | secondary | -0.7814729 |  0.2024834 |

### Moderation example

``` r
mod_summary <- run_moderation_paths(
  data = demo_medmodr,
  predictors = c("x1", "x2"),
  moderators = c("m1", "grp", "edu"), # mix of numeric and categorical
  outcomes = c("y1", "y2"),
  controls = c("c1", "c2"),
  categorical_vars = c("grp", "edu"),
  sig_level = 0.05,
  plot_sig = FALSE, # set TRUE in your analysis to auto-plot significant interactions using the interaction package
  summarize_categorical = TRUE # summarize multiple dummy-by-interaction lines into a single row per categorical mod
)
```

The resulting dataset from our moderation analysis is shown below:

``` r
knitr::kable(head(mod_summary))
```

| Predictor | Moderator | Outcome | Term        | Interaction_Effect | Std_Error |    T_value |   P_value |   CI_Lower |   CI_Upper | Has_Moderation |
|:----------|:----------|:--------|:------------|-------------------:|----------:|-----------:|----------:|-----------:|-----------:|:---------------|
| x1        | m1        | y1      | x1:m1       |          0.4562917 | 0.0498605 |  9.1513655 | 0.0000000 |  0.3585651 |  0.5540183 | TRUE           |
| x1        | m1        | y2      | x1:m1       |          0.0504688 | 0.0687074 |  0.7345471 | 0.4635023 | -0.0841977 |  0.1851354 | FALSE          |
| x1        | grp       | y1      | x1:grptreat |         -0.4894794 | 0.1869071 | -2.6188375 | 0.0095200 | -0.8558173 | -0.1231414 | TRUE           |
| x1        | grp       | y2      | x1:grptreat |          0.0983691 | 0.1979661 |  0.4968987 | 0.6198231 | -0.2896445 |  0.4863827 | FALSE          |
| x1        | edu       | y1      | Summary     |          0.2194922 | 0.2411250 |  0.9102839 | 0.3638141 | -0.2531128 |  0.6920972 | FALSE          |
| x1        | edu       | y2      | Summary     |         -0.3076175 | 0.2508876 | -1.2261170 | 0.2216563 | -0.7993572 |  0.1841221 | FALSE          |

### Mediation example

``` r
med_summary <- run_mediation_paths(
  data = demo_medmodr,
  treatments = c("x1", "x2"), # you can also include "grp" if you want to treat it as a treatment
  mediators = c("m1", "m2"),
  outcomes = c("y1", "y2"),
  controls = c("c1", "c2", "edu"),
  sims = 20, # used 20 for faster run, you should set `sims = 1000–5000` and consider `boot = TRUE` for more robust estimates
  boot = FALSE, # consider `boot = TRUE`
  seed = 1
)
```

The resulting dataset from our mediation analysis is shown below:

``` r
knitr::kable(head(med_summary))
```

| Treatment | Mediator | Outcome |       ACME | ACME_CI_Lower | ACME_CI_Upper | ACME_p |        ADE | ADE_CI_Lower | ADE_CI_Upper | ADE_p | Total_Effect | Total_Effect_CI_Lower | Total_Effect_CI_Upper | Total_Effect_p | Prop_Mediated | PropMediated_CI_Lower | PropMediated_CI_Upper | PropMediated_p | Has_Mediation |
|:----------|:---------|:--------|-----------:|--------------:|--------------:|-------:|-----------:|-------------:|-------------:|------:|-------------:|----------------------:|----------------------:|---------------:|--------------:|----------------------:|----------------------:|---------------:|:--------------|
| x1        | m1       | y1      |  0.4377062 |     0.2712782 |     0.5561495 |    0.0 |  0.0196702 |   -0.1048360 |    0.1457572 |   0.9 |    0.4573765 |             0.3094468 |             0.6036864 |            0.0 |     0.9527539 |             0.7021084 |             1.3034933 |            0.0 | TRUE          |
| x1        | m1       | y2      |  0.1153722 |    -0.0229650 |     0.2334151 |    0.3 | -0.1430786 |   -0.2871876 |    0.0028599 |   0.1 |   -0.0277065 |            -0.1736169 |             0.1336072 |            0.7 |    -0.2042186 |            -6.6634030 |            66.2261019 |            1.0 | FALSE         |
| x2        | m1       | y1      |  0.0179415 |    -0.0783874 |     0.1021055 |    0.5 |  0.0243356 |   -0.0855415 |    0.1310880 |   0.7 |    0.0422771 |            -0.0858951 |             0.1720157 |            0.6 |     0.3210235 |            -4.6468356 |             1.7875704 |            0.7 | FALSE         |
| x2        | m1       | y2      |  0.0031665 |    -0.0121681 |     0.0191415 |    0.6 |  0.6904284 |    0.5795941 |    0.7981109 |   0.0 |    0.6935949 |             0.5828137 |             0.8045308 |            0.0 |     0.0039813 |            -0.0166915 |             0.0251326 |            0.6 | FALSE         |
| x1        | m2       | y1      | -0.0082691 |    -0.0345748 |     0.0135654 |    0.5 |  0.4426967 |    0.3073049 |    0.5718144 |   0.0 |    0.4344276 |             0.3039848 |             0.5572924 |            0.0 |    -0.0184695 |            -0.0756975 |             0.0293382 |            0.5 | FALSE         |
| x1        | m2       | y2      | -0.0624286 |    -0.1531276 |     0.0236876 |    0.2 |  0.0340628 |   -0.0858962 |    0.1484627 |   0.5 |   -0.0283659 |            -0.1571435 |             0.0912951 |            0.8 |     0.5374838 |            -2.9659636 |             3.2079808 |            0.6 | FALSE         |

## For more details and walkthrough: [`Getting started with medmodr`](https://tosmartak.github.io/medmodr/articles/getting-started.html)

## Function reference (quick)

- `run_moderation_paths(data, predictors, moderators, outcomes, controls, categorical_vars = NULL, sig_level = 0.05, plot_sig = FALSE, summarize_categorical = FALSE)`
  — loop over predictors × moderators × outcomes

- `run_mediation_paths(data, treatments, mediators, outcomes, controls, sims = 1000, boot = TRUE, seed = 123)`
  — loop over treatments × mediators × outcomes

- `plot_mediation_summary_effects(summary_table, filter_significant = FALSE, show_only_acme = FALSE)`
  — visualize significant mediation results

## Contributing and Code of Conduct

We welcome contributions! Please note that the medmodr project is
released with a [Contributor Code of
Conduct](https://tosmartak.github.io/medmodr/CODE_OF_CONDUCT.html). By
contributing to this project, you agree to abide by its terms.

Please check out:

- [Contributing
  guidelines](https://github.com/tosmartak/medmodr/blob/main/.github/CONTRIBUTING.md)
- [Code of
  Conduct](https://github.com/tosmartak/medmodr/blob/main/CODE_OF_CONDUCT.md)
- [Open an issue](https://github.com/tosmartak/medmodr/issues)
  (templates will guide you for bug reports and feature requests)
- [View issue
  templates](https://github.com/tosmartak/medmodr/tree/main/.github/ISSUE_TEMPLATE)
  (to preview them)

## License

- [![License: GPL
  v3](https://img.shields.io/badge/License-GPL%20v3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)

## Citation

If you use medmodr in your research, please cite it:

``` r
citation("medmodr")
#> To cite medmodr in publications, please use:
#> 
#>   Akingbemisilu T (2025). _medmodr Package: Systematic moderation and
#>   mediation analysis in R_. R package version 0.1.0,
#>   <https://tosmartak.github.io/medmodr/>.
#> 
#> A BibTeX entry for LaTeX users is
#> 
#>   @Manual{,
#>     title = {medmodr Package: Systematic moderation and mediation analysis in R},
#>     author = {Tosin Harold Akingbemisilu},
#>     year = {2025},
#>     note = {R package version 0.1.0},
#>     url = {https://tosmartak.github.io/medmodr/},
#>   }
```
