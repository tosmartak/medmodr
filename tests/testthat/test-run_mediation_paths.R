test_that("run_mediation_paths returns tidy rows when mediation holds (skip if missing mediation)", {
  skip_if_not_installed("mediation")
  set.seed(42)
  n <- 120
  df <- data.frame(
    T = rnorm(n),
    C = rnorm(n)
  )
  # Construct mediator and outcome with a real mediated path
  df$M <- 0.8 * df$T + rnorm(n)
  df$Y <- 0.6 * df$M + 0.3 * df$T + 0.2 * df$C + rnorm(n)

  res <- run_mediation_paths(
    data = df,
    treatments = "T",
    mediators = "M",
    outcomes = "Y",
    controls = "C",
    sims = 200, boot = FALSE, seed = 1
  )
  expect_true(is.data.frame(res))
  expect_true(nrow(res) >= 1)
  expect_true(all(c("Treatment", "Mediator", "Outcome", "ACME", "ADE", "Total_Effect", "Has_Mediation") %in% names(res)))
})
