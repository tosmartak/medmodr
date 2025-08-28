test_that("plot_mediation_summary_effects builds a plot with defaults", {
  skip_if_not_installed("ggplot2")
  skip_if_not_installed("tidyr")

  df <- tibble::tibble(
    Treatment = "T", Mediator = "M", Outcome = "Y",
    ACME = 0.2, ACME_CI_Lower = 0.05, ACME_CI_Upper = 0.35, ACME_p = 0.01,
    ADE = 0.3, ADE_CI_Lower = 0.10, ADE_CI_Upper = 0.50, ADE_p = 0.02,
    Total_Effect = 0.5, Total_Effect_CI_Lower = 0.2, Total_Effect_CI_Upper = 0.8, Total_Effect_p = 0.01,
    Prop_Mediated = 0.4, PropMediated_CI_Lower = 0.2, PropMediated_CI_Upper = 0.6, PropMediated_p = 0.02,
    Has_Mediation = TRUE
  )

  p <- plot_mediation_summary_effects(df, filter_significant = TRUE)
  expect_true(inherits(p, "ggplot"))
})

test_that("plot_mediation_summary_effects handles empty input with warning", {
  skip_if_not_installed("ggplot2")
  skip_if_not_installed("tidyr")

  df <- tibble::tibble(
    Treatment = character(),
    Mediator = character(),
    Outcome = character(),
    ACME = numeric(),
    ADE = numeric(),
    Total_Effect = numeric(),
    ACME_CI_Lower = numeric(),
    ACME_CI_Upper = numeric(),
    ADE_CI_Lower = numeric(),
    ADE_CI_Upper = numeric(),
    Total_Effect_CI_Lower = numeric(),
    Total_Effect_CI_Upper = numeric(),
    ACME_p = numeric(),
    ADE_p = numeric(),
    Total_Effect_p = numeric(),
    Has_Mediation = logical()
  )

  expect_warning(res <- plot_mediation_summary_effects(df))
  expect_true(inherits(res, "ggplot") || inherits(res, "list"))
})

test_that("plot_mediation_summary_effects can show only ACME", {
  skip_if_not_installed("ggplot2")
  skip_if_not_installed("tidyr")

  df <- tibble::tibble(
    Treatment = "T", Mediator = "M", Outcome = "Y",
    ACME = 0.1, ACME_CI_Lower = 0.01, ACME_CI_Upper = 0.2, ACME_p = 0.01,
    ADE = 0.05, ADE_CI_Lower = -0.1, ADE_CI_Upper = 0.2, ADE_p = 0.5,
    Total_Effect = 0.15, Total_Effect_CI_Lower = 0, Total_Effect_CI_Upper = 0.3, Total_Effect_p = 0.05,
    Prop_Mediated = 0.3, PropMediated_CI_Lower = 0.1, PropMediated_CI_Upper = 0.5, PropMediated_p = 0.05,
    Has_Mediation = TRUE
  )

  p <- plot_mediation_summary_effects(df, show_only_acme = TRUE)
  expect_true(inherits(p, "ggplot"))
})

test_that("plot_mediation_summary_effects returns list when summary_plot=FALSE", {
  skip_if_not_installed("ggplot2")
  skip_if_not_installed("tidyr")

  df <- tibble::tibble(
    Treatment = "T", Mediator = "M", Outcome = "Y",
    ACME = 0.2, ACME_CI_Lower = 0.05, ACME_CI_Upper = 0.35, ACME_p = 0.01,
    ADE = 0.3, ADE_CI_Lower = 0.1, ADE_CI_Upper = 0.5, ADE_p = 0.02,
    Total_Effect = 0.5, Total_Effect_CI_Lower = 0.2, Total_Effect_CI_Upper = 0.8, Total_Effect_p = 0.01,
    Prop_Mediated = 0.4, PropMediated_CI_Lower = 0.2, PropMediated_CI_Upper = 0.6, PropMediated_p = 0.02,
    Has_Mediation = TRUE
  )

  res <- plot_mediation_summary_effects(df, summary_plot = FALSE)
  expect_type(res, "list")
  expect_true(all(vapply(res, inherits, logical(1), what = "ggplot")))
})

test_that("plot_mediation_summary_effects errors if required columns missing", {
  df <- tibble::tibble(Treatment = "T", Mediator = "M", Outcome = "Y")
  expect_error(plot_mediation_summary_effects(df))
})
