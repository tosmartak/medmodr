
<!-- README.md is generated from README.Rmd. Please edit that file -->

# medmodr Package: Iterated Moderation and Mediation Analysis at Scale

<!-- badges: start -->

[![R-CMD-check](https://github.com/tosmartak/medmodr/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/tosmartak/medmodr/actions/workflows/R-CMD-check.yaml)
[![License: GPL
v3](https://img.shields.io/badge/License-GPL%20v3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
<!-- badges: end -->

We implement a `medmodr` package which helps you systematically sweep
through combinations of variables to detect:

- **Moderation**: is the effect of an independent variable (X) on a
  dependent variable (Y) conditional on or moderated by a third variable
  (M)?
- **Mediation**: does an independent variable (X) influence a dependent
  variable (Y) indirectly through a third variable called a mediator
  (M)?

Instead of fitting models one by one, `medmodr` iterates across your
variable sets and returns tidy summary tables you can filter, rank, and
plot. It also automatically generates clean plots suitable for
publications. This package builds upon the
[`mediation`](https://CRAN.R-project.org/package=mediation) package
\[Tingley et al., 2014\] for mediation analysis and the
[`interactions`](https://CRAN.R-project.org/package=interactions)
package \[Long, 2024\] for moderation plots.

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

## Quick Start

Load the package and access the demo dataset included:

``` r
library(medmodr)
```

## Load Dataset

Below we load our small simulated dataset and run one moderation and one
mediation analysis.

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

**What each variable represents (for this README)**

- Treatments / Predictors: x1, x2 (numeric); grp (binary factor)
- Mediators: m1, m2 (numeric)
- Moderators: m1, m2, grp, edu (some numeric, some categorical)
- Outcomes: y1, y2 (numeric)
- Controls: c1, c2, edu (as covariates; can mix numeric and categorical)

This mirrors a realistic workflow where you scan multiple candidates at
once.

### Moderation example

`run_moderation_paths()` loops over all
`(predictor, moderator, outcome)` combinations and fits `lm()` with the
interaction term. It returns one row per interaction term (or a summary
row for categorical interactions if requested).

Below we intentionally pass `multiple variables` to each argument. Set
plot_sig = FALSE here to keep knitting fast; you can enable plots in
your own analysis by setting plot_sig = TRUE

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

**What to look at:**

- `Term` is the specific interaction term (or a summary label for
  categorical moderators)

- `Interaction_Effect`, `Std_Error`, `T_value`, `P_value`, `CI_Lower`,
  `CI_Upper`

- `Has_Moderation` indicates significance at `sig_level`

### Mediation example

`run_mediation_paths()` loops over all `(treatment, mediator, outcome)`
triples. For each triple it fits the two linear models and calls
`mediation::mediate()` to estimate
`ACME, ADE, Total Effect, and Proportion Mediated with 95% CIs`.

We pass **multiple treatments, mediators, and outcomes**. For speed in
documentation, we use `sims = 200` and `boot = FALSE`. In real analysis,
increase sims (e.g., 1000–5000) and consider boot = TRUE.

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

## Learn more

Browse the vignettes for detailed workflow

- Topics covered in vignettes:

  - How to prepare your dataset

  - Detailed moderation and mediation workflows

  - Plotting significant results

  - Performance and reproducibility tips

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
