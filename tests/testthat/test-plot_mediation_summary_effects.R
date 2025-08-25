test_that("plot_mediation_summary_effects builds a plot (skip if missing suggests)", {
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
