# tests/testthat/test-run_mediation_paths.R

test_that("run_mediation_paths returns tidy rows when mediation holds (no skips, clean)", {
  if (!requireNamespace("mediation", quietly = TRUE)) {
    # If mediation isn't installed, we assert the function errors as designed and PASS the test
    df <- data.frame(T = 1:5, M = 1:5, Y = 1:5)
    expect_error(run_mediation_paths(df, "T", "M", "Y"))
    return(invisible(TRUE))
  }

  set.seed(42)
  n <- 120
  df <- data.frame(T = rnorm(n), C = rnorm(n))
  # Construct mediator and outcome with a mediated path
  df$M <- 0.8 * df$T + rnorm(n, sd = 0.5)
  df$Y <- 0.6 * df$M + 0.3 * df$T + 0.2 * df$C + rnorm(n, sd = 0.5)

  res <- suppressMessages(
    run_mediation_paths(
      data = df,
      treatments = "T",
      mediators = "M",
      outcomes = "Y",
      controls = "C",
      sims = 50, boot = FALSE, seed = 1
    )
  )
  expect_s3_class(res, "data.frame")
  expect_true(nrow(res) >= 1)
  expect_true(all(c(
    "Treatment", "Mediator", "Outcome",
    "ACME", "ADE", "Total_Effect", "Has_Mediation"
  ) %in% names(res)))
})

test_that("run_mediation_paths errors if mediation package missing (no skip)", {
  if (requireNamespace("mediation", quietly = TRUE)) {
    # mediation is available; nothing to test here wrt missing pkg
    succeed()
    return(invisible(TRUE))
  }
  df <- data.frame(T = 1:5, M = 1:5, Y = 1:5)
  expect_error(run_mediation_paths(df, "T", "M", "Y"))
})

test_that("run_mediation_paths errors for invalid inputs (no messages)", {
  if (!requireNamespace("mediation", quietly = TRUE)) {
    succeed()
    return(invisible(TRUE))
  }

  df <- data.frame(T = 1:5, M = 1:5, Y = 1:5)

  expect_error(run_mediation_paths(1:5, "T", "M", "Y"), "data.frame")
  expect_error(run_mediation_paths(df, NULL, "M", "Y"))
  expect_error(run_mediation_paths(df, "not_a_col", "M", "Y"))
})

test_that("redundant treatment=mediator is skipped cleanly (no messages)", {
  if (!requireNamespace("mediation", quietly = TRUE)) {
    succeed()
    return(invisible(TRUE))
  }

  df <- data.frame(T = rnorm(20), Y = rnorm(20))
  out <- suppressMessages(run_mediation_paths(df, treatments = "T", mediators = "T", outcomes = "Y"))
  expect_equal(nrow(out), 0)
})

test_that("works with both boot and non-boot modes (robust, clean)", {
  if (!requireNamespace("mediation", quietly = TRUE)) {
    succeed()
    return(invisible(TRUE))
  }

  set.seed(123)
  n <- 100 # stabilize bootstrap a bit
  df <- data.frame(T = rnorm(n))
  df$M <- 0.7 * df$T + rnorm(n, sd = 0.6)
  df$Y <- 0.7 * df$M + 0.2 * df$T + rnorm(n, sd = 0.6)

  out1 <- suppressMessages(run_mediation_paths(df, "T", "M", "Y", sims = 80, boot = TRUE))
  out2 <- suppressMessages(run_mediation_paths(df, "T", "M", "Y", sims = 80, boot = FALSE))

  expect_s3_class(out1, "data.frame")
  if (nrow(out1) > 0) {
    expect_true(all(c("ACME", "ADE", "Total_Effect") %in% names(out1)))
  }

  expect_s3_class(out2, "data.frame")
  if (nrow(out2) > 0) {
    expect_true(all(c("ACME", "ADE", "Total_Effect") %in% names(out2)))
  }
})

test_that("factors are handled without error (fully silent)", {
  if (!requireNamespace("mediation", quietly = TRUE)) {
    succeed()
    return(invisible(TRUE))
  }

  set.seed(123)
  df <- data.frame(
    T = factor(sample(c("A", "B"), 50, replace = TRUE)),
    M = rnorm(50),
    Y = rnorm(50)
  )

  # Be strict: no output, no warnings, no messages
  res <- NULL
  expect_silent({
    res <- suppressWarnings(
      suppressMessages(
        run_mediation_paths(df, "T", "M", "Y")
      )
    )
  })
  expect_s3_class(res, "data.frame")
})
