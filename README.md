
<!-- README.md is generated from README.Rmd. Please edit that file -->

# medmodr Package: Iterated Moderation and Mediation Analysis at Scale

<!-- badges: start -->

[![R-CMD-check](https://github.com/tosmartak/medmodr/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/tosmartak/medmodr/actions/workflows/R-CMD-check.yaml)
[![License: GPL
v3](https://img.shields.io/badge/License-GPL%20v3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
<!-- badges: end -->

Systematic moderation and mediation analysis in R.

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

The package includes a small demo dataset `demo_medmodr`. Below we show
one minimal moderation and mediation analysis.

``` r
data("demo_medmodr")
```

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

|                   | Predictor | Moderator | Outcome | Term        | Interaction_Effect | Std_Error |    T_value |   P_value |   CI_Lower |   CI_Upper | Has_Moderation |
|:------------------|:----------|:----------|:--------|:------------|-------------------:|----------:|-----------:|----------:|-----------:|-----------:|:---------------|
| …1                | x1        | m1        | y1      | x1:m1       |          0.4562917 | 0.0498605 |  9.1513655 | 0.0000000 |  0.3585651 |  0.5540183 | TRUE           |
| …2                | x1        | m1        | y2      | x1:m1       |          0.0504688 | 0.0687074 |  0.7345471 | 0.4635023 | -0.0841977 |  0.1851354 | FALSE          |
| …3                | x1        | grp       | y1      | x1:grptreat |         -0.4894794 | 0.1869071 | -2.6188375 | 0.0095200 | -0.8558173 | -0.1231414 | TRUE           |
| …4                | x1        | grp       | y2      | x1:grptreat |          0.0983691 | 0.1979661 |  0.4968987 | 0.6198231 | -0.2896445 |  0.4863827 | FALSE          |
| x1:edusecondary…5 | x1        | edu       | y1      | Summary     |          0.2194922 | 0.2411250 |  0.9102839 | 0.3638141 | -0.2531128 |  0.6920972 | FALSE          |
| x1:edusecondary…6 | x1        | edu       | y2      | Summary     |         -0.3076175 | 0.2508876 | -1.2261170 | 0.2216563 | -0.7993572 |  0.1841221 | FALSE          |

### Mediation example

``` r
med_summary <- run_mediation_paths(
  data = demo_medmodr,
  treatments = c("x1", "x2"), # you can also include "grp" if you want to treat it as a treatment
  mediators = c("m1", "m2"),
  outcomes = c("y1", "y2"),
  controls = c("c1", "c2", "edu"),
  sims = 200, boot = FALSE, seed = 1
)
```

The resulting dataset from our mediation analysis is shown below:

``` r
knitr::kable(head(med_summary))
```

| Treatment | Mediator | Outcome |       ACME | ACME_CI_Lower | ACME_CI_Upper | ACME_p |        ADE | ADE_CI_Lower | ADE_CI_Upper | ADE_p | Total_Effect | Total_Effect_CI_Lower | Total_Effect_CI_Upper | Total_Effect_p | Prop_Mediated | PropMediated_CI_Lower | PropMediated_CI_Upper | PropMediated_p | Has_Mediation |
|:----------|:---------|:--------|-----------:|--------------:|--------------:|-------:|-----------:|-------------:|-------------:|------:|-------------:|----------------------:|----------------------:|---------------:|--------------:|----------------------:|----------------------:|---------------:|:--------------|
| x1        | m1       | y1      |  0.4047129 |     0.2733835 |     0.5278130 |   0.00 |  0.0490381 |   -0.1419017 |    0.2103644 |  0.56 |    0.4537510 |             0.2788478 |             0.6174781 |           0.00 |     0.8879809 |             0.5922091 |             1.4236754 |           0.00 | TRUE          |
| x1        | m1       | y2      |  0.0870821 |    -0.0337763 |     0.1964244 |   0.16 | -0.1090870 |   -0.3300890 |    0.0776391 |  0.31 |   -0.0220049 |            -0.2018976 |             0.1506394 |           0.80 |    -0.3005459 |           -11.9603192 |            13.4232514 |           0.86 | FALSE         |
| x2        | m1       | y1      |  0.0024246 |    -0.1277854 |     0.1023357 |   0.91 |  0.0416984 |   -0.1272681 |    0.1958826 |  0.57 |    0.0441230 |            -0.1605703 |             0.2115216 |           0.60 |     0.1958763 |            -9.3779764 |             4.4197954 |           0.77 | FALSE         |
| x2        | m1       | y2      | -0.0001291 |    -0.0223901 |     0.0151895 |   0.93 |  0.7079424 |    0.5375039 |    0.8634700 |  0.00 |    0.7078133 |             0.5269663 |             0.8660899 |           0.00 |     0.0004459 |            -0.0335334 |             0.0209049 |           0.93 | FALSE         |
| x1        | m2       | y1      | -0.0083915 |    -0.0394585 |     0.0139128 |   0.48 |  0.4625412 |    0.2779904 |    0.6254832 |  0.00 |    0.4541498 |             0.2710269 |             0.6105789 |           0.00 |    -0.0126784 |            -0.0971600 |             0.0277309 |           0.48 | FALSE         |
| x1        | m2       | y2      | -0.0743946 |    -0.2051507 |     0.0185182 |   0.12 |  0.0516452 |   -0.1118692 |    0.1960140 |  0.53 |   -0.0227493 |            -0.2317083 |             0.1323458 |           0.81 |     0.5057719 |           -10.2314835 |             8.4874179 |           0.79 | FALSE         |

#### Visual summaries for mediation

These plots are fast for small tables but can be heavy on large scans,
so we kept most of them eval=FALSE in README. Use them interactively in
your analysis.

**Effect overview plot (ACME, ADE, Total Effect with CIs):**

By default, it would generate a summary grid plot for significant
mediations only

``` r
plot_mediation_summary_effects(med_summary, filter_significant = TRUE, summary_plot = TRUE)
```

**You can also show only ACME plots from significant results**

``` r
plot_mediation_summary_effects(med_summary, filter_significant = TRUE, show_only_acme = TRUE, summary_plot = TRUE)
```

**You can equally loop over all significant mediation triples and plot
each**

``` r
plot_mediation_summary_effects(med_summary, filter_significant = TRUE, summary_plot = FALSE)
```

**You can also show only ACME for single plots**

``` r
plot_mediation_summary_effects(med_summary, filter_significant = TRUE, summary_plot = FALSE, show_only_acme = TRUE)
```

## Function reference (quick)

- `run_moderation_paths(data, predictors, moderators, outcomes, controls, categorical_vars = NULL, sig_level = 0.05, plot_sig = FALSE, summarize_categorical = FALSE)`
  — loop over predictors × moderators × outcomes

- `run_mediation_paths(data, treatments, mediators, outcomes, controls, sims = 1000, boot = TRUE, seed = 123)`
  — loop over treatments × mediators × outcomes

- `plot_mediation_summary_effects(summary_table, filter_significant = FALSE, show_only_acme = FALSE)`
  — visualize significant mediation results

## License and issues

- [![License: GPL
  v3](https://img.shields.io/badge/License-GPL%20v3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)

- Please file issues and feature requests on GitHub

- Contributions welcome (add tests where possible)

## Citation

If you use medmodr in your research, please cite it:

``` r
citation("medmodr")
#> To cite medmodr in publications, please use:
#> 
#>   Akingbemisilu T (2025). _medmodr: Moderation and Mediation Path
#>   Analysis in R_. R package version 0.1.0,
#>   <https://tosmartak.github.io/medmodr>.
#> 
#> A BibTeX entry for LaTeX users is
#> 
#>   @Manual{,
#>     title = {medmodr: Moderation and Mediation Path Analysis in R},
#>     author = {Tosin Harold Akingbemisilu},
#>     year = {2025},
#>     note = {R package version 0.1.0},
#>     url = {https://tosmartak.github.io/medmodr},
#>   }
```
