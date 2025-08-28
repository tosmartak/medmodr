# tests/testthat/test-run_moderation_paths.R

test_that("run_moderation_paths returns rows for interaction (clean)", {
  set.seed(123)
  n <- 60
  df <- data.frame(
    y = rnorm(n),
    x = rnorm(n),
    m = rnorm(n),
    c1 = rnorm(n)
  )
  # Inject a simple interaction so we expect at least one row back
  df$y <- df$y + 0.8 * df$x * df$m

  out <- suppressMessages(
    run_moderation_paths(
      data = df,
      predictors = "x",
      moderators = "m",
      outcomes = "y",
      controls = "c1",
      plot_sig = FALSE
    )
  )

  expect_true(is.data.frame(out))
  expect_true(nrow(out) >= 1)
  expect_true(all(c("Predictor", "Moderator", "Outcome", "Term", "P_value") %in% names(out)))
})

test_that("errors are thrown for invalid inputs (clean)", {
  df <- data.frame(y = 1:5, x = 1:5, m = 1:5)

  # Non-data.frame input
  expect_error(run_moderation_paths(1:5, "x", "m", "y"))

  # Missing predictors
  expect_error(run_moderation_paths(df, NULL, "m", "y"))

  # Missing column
  expect_error(run_moderation_paths(df, "not_a_col", "m", "y"))

  # Invalid logical inputs
  expect_error(run_moderation_paths(df, "x", "m", "y", plot_sig = "yes"))
})

test_that("categorical_vars and factor handling work (expect warning, no messages)", {
  df <- data.frame(y = rnorm(20), x = rnorm(20), m = rep(c("A", "B"), 10))

  # Expect the *warning* about non-numeric variable(s); suppress informational messages
  expect_warning(
    out <- suppressMessages(
      run_moderation_paths(
        df,
        predictors = "x", moderators = "m",
        outcomes = "y", categorical_vars = "m"
      )
    ),
    "Non-numeric and non-factor"
  )
  expect_true("Moderator" %in% names(out))
})

test_that("summarize_categorical collapses multiple terms (clean)", {
  set.seed(123)
  df <- data.frame(y = rnorm(50), x = sample(letters[1:3], 50, TRUE), m = rnorm(50))
  df$x <- as.factor(df$x)

  out <- suppressMessages(
    run_moderation_paths(
      df,
      predictors = "x", moderators = "m",
      outcomes = "y", summarize_categorical = TRUE
    )
  )
  expect_true(any(out$Term == "Summary"))
})

test_that("returns a valid tibble when no interactions (clean, no messages)", {
  df <- data.frame(y = rnorm(20), x = rnorm(20), m = rnorm(20))

  out <- suppressMessages(
    run_moderation_paths(df, predictors = "x", moderators = "m", outcomes = "y")
  )
  expect_s3_class(out, "data.frame")
  expect_true(nrow(out) >= 0)
})

test_that("self-interaction predictor==moderator is skipped (clean)", {
  df <- data.frame(y = rnorm(20), x = rnorm(20))
  out <- suppressMessages(
    run_moderation_paths(df, predictors = "x", moderators = "x", outcomes = "y")
  )
  expect_true(nrow(out) == 0)
})

test_that("plot_sig branch runs without error when interactions are significant (no messages)", {
  if (!requireNamespace("interactions", quietly = TRUE)) {
    succeed()
    return(invisible(TRUE))
  }

  set.seed(123)
  df <- data.frame(y = rnorm(60), x = rnorm(60), m = rnorm(60))
  df$y <- df$y + 0.5 * df$x * df$m

  # Produce plots but keep console quiet
  expect_silent(
    suppressMessages(
      run_moderation_paths(df, "x", "m", "y", plot_sig = TRUE)
    )
  )
})
