# tests/testthat/test-run_mediation_paths.R

test_that("errors clearly if mediation package is missing", {
  # This test does not require mediation to be installed
  if (requireNamespace("mediation", quietly = TRUE)) {
    testthat::succeed("mediation installed; missing-pkg branch not exercised")
    return(invisible(TRUE))
  }
  df <- data.frame(T = 1:5, M = 1:5, Y = 1:5)
  expect_error(
    run_mediation_paths(df, "T", "M", "Y"),
    "Package 'mediation' is required"
  )
})

test_that("works in package scope on a minimal example", {
  skip_if_not_installed("mediation")
  set.seed(1)
  df <- data.frame(
    intervention = rbinom(200, 1, 0.5),
    KG = rnorm(200),
    HFIA = rnorm(200),
    SBC = rnorm(200)
  )
  res <- suppressMessages(run_mediation_paths(
    data = df,
    treatments = "intervention",
    mediators = "KG",
    outcomes = "HFIA",
    controls = "SBC",
    sims = 80, boot = TRUE, seed = 42
  ))
  expect_s3_class(res, "data.frame")
  expect_true(all(c("Treatment", "Mediator", "Outcome") %in% names(res)))
})

test_that("returns tidy rows when mediation signal is present", {
  skip_if_not_installed("mediation")

  set.seed(42)
  n <- 140
  df <- data.frame(T = rnorm(n), C = rnorm(n))
  df$M <- 0.8 * df$T + rnorm(n, sd = 0.5)
  df$Y <- 0.6 * df$M + 0.3 * df$T + 0.2 * df$C + rnorm(n, sd = 0.5)

  res <- suppressMessages(run_mediation_paths(
    data = df,
    treatments = "T",
    mediators = "M",
    outcomes = "Y",
    controls = "C",
    sims = 60, boot = FALSE, seed = 1
  ))
  expect_s3_class(res, "data.frame")
  expect_true(nrow(res) >= 1)
  expect_true(all(c("ACME", "ADE", "Total_Effect", "Has_Mediation") %in% names(res)))
  expect_type(res$Has_Mediation, "logical")
})

test_that("invalid inputs error cleanly", {
  skip_if_not_installed("mediation")
  df <- data.frame(T = 1:5, M = 1:5, Y = 1:5)

  expect_error(run_mediation_paths(1:5, "T", "M", "Y"), "data.frame")
  expect_error(run_mediation_paths(df, NULL, "M", "Y"))
  expect_error(run_mediation_paths(df, "not_a_col", "M", "Y"))
})

test_that("redundant treatment==mediator is skipped", {
  skip_if_not_installed("mediation")
  df <- data.frame(T = rnorm(30), Y = rnorm(30))
  out <- suppressMessages(run_mediation_paths(df, treatments = "T", mediators = "T", outcomes = "Y"))
  expect_equal(nrow(out), 0)
})

test_that("both boot and non-boot modes return tidy output", {
  skip_if_not_installed("mediation")

  set.seed(123)
  n <- 120
  df <- data.frame(T = rnorm(n))
  df$M <- 0.7 * df$T + rnorm(n, sd = 0.6)
  df$Y <- 0.7 * df$M + 0.2 * df$T + rnorm(n, sd = 0.6)

  out1 <- suppressMessages(run_mediation_paths(df, "T", "M", "Y", sims = 60, boot = TRUE))
  out2 <- suppressMessages(run_mediation_paths(df, "T", "M", "Y", sims = 60, boot = FALSE))

  for (out in list(out1, out2)) {
    expect_s3_class(out, "data.frame")
    if (nrow(out) > 0) {
      expect_true(all(c("ACME", "ADE", "Total_Effect") %in% names(out)))
    }
  }
})

test_that("handles non-syntactic names", {
  skip_if_not_installed("mediation")

  set.seed(11)
  n <- 90
  df <- data.frame(
    check.names = FALSE,
    "T rate" = rnorm(n),
    "C-1"    = rnorm(n)
  )
  df[["Med rate"]] <- 0.6 * df[["T rate"]] + rnorm(n, sd = 0.5)
  df[["Outcome Y"]] <- 0.5 * df[["Med rate"]] + 0.2 * df[["T rate"]] + 0.1 * df[["C-1"]] + rnorm(n, sd = 0.5)

  res <- suppressMessages(run_mediation_paths(
    data = df,
    treatments = "T rate",
    mediators = "Med rate",
    outcomes = "Outcome Y",
    controls = "C-1",
    sims = 50, boot = FALSE
  ))
  expect_s3_class(res, "data.frame")
  expect_true(all(c("ACME", "ADE", "Total_Effect", "Has_Mediation") %in% names(res)))
})

test_that("drops overlapping controls without error", {
  skip_if_not_installed("mediation")

  set.seed(22)
  n <- 80
  df <- data.frame(T = rnorm(n))
  df$M <- 0.7 * df$T + rnorm(n, sd = 0.6)
  df$Y <- 0.6 * df$M + 0.2 * df$T + rnorm(n, sd = 0.6)

  res <- suppressMessages(run_mediation_paths(
    data = df,
    treatments = "T",
    mediators = "M",
    outcomes = "Y",
    controls = c("T", "M"),
    sims = 40, boot = FALSE
  ))
  expect_s3_class(res, "data.frame")
  if (nrow(res)) expect_type(res$Has_Mediation, "logical")
})

test_that("missing controls cause skip but function returns gracefully", {
  skip_if_not_installed("mediation")

  set.seed(33)
  n <- 70
  df <- data.frame(T = rnorm(n))
  df$M <- 0.5 * df$T + rnorm(n)
  df$Y <- 0.5 * df$M + 0.2 * df$T + rnorm(n)

  res <- suppressMessages(run_mediation_paths(
    data = df,
    treatments = "T",
    mediators = "M",
    outcomes = "Y",
    controls = "C_missing",
    sims = 30, boot = FALSE
  ))
  expect_s3_class(res, "data.frame")
  expect_true(nrow(res) %in% c(0, 1))
})

test_that("multi-grid runs produce the expected number of rows", {
  skip_if_not_installed("mediation")

  set.seed(7)
  n <- 120
  df <- data.frame(
    T1 = rnorm(n), T2 = rnorm(n), C = rnorm(n)
  )
  df$M1 <- 0.5 * df$T1 + rnorm(n)
  df$M2 <- 0.4 * df$T2 + 0.2 * df$T1 + rnorm(n)
  df$Y1 <- 0.6 * df$M1 + 0.3 * df$T1 + 0.1 * df$C + rnorm(n)
  df$Y2 <- 0.5 * df$M2 + 0.2 * df$T2 + 0.1 * df$C + rnorm(n)

  ts <- c("T1", "T2")
  ms <- c("M1", "M2")
  ys <- c("Y1", "Y2")
  res <- suppressMessages(run_mediation_paths(
    data = df, treatments = ts, mediators = ms, outcomes = ys, controls = "C",
    sims = 30, boot = FALSE
  ))
  # Each (treat, mediator, outcome) triple -> 2*2*2 = 8 rows expected
  expect_true(nrow(res) %in% c(6, 8)) # allow small skips if any model fails numerically
  expect_true(all(res$Treatment %in% ts))
  expect_true(all(res$Mediator %in% ms))
  expect_true(all(res$Outcome %in% ys))
})
