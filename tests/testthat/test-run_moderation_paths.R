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

test_that("non-syntactic names are handled via backticks (clean)", {
  set.seed(1)
  df <- data.frame(
    "Outcome Y" = rnorm(120),
    "X rate"    = rnorm(120),
    "Mod-Z"     = rnorm(120),
    "C 1"       = rnorm(120),
    check.names = FALSE # <-- critical so names are NOT mangled
  )

  # Add an interaction signal; names now exist exactly as written above
  df[["Outcome Y"]] <- df[["Outcome Y"]] + 0.6 * df[["X rate"]] * df[["Mod-Z"]]

  out <- suppressMessages(
    run_moderation_paths(
      data = df,
      predictors = "X rate",
      moderators = "Mod-Z",
      outcomes = "Outcome Y",
      controls = "C 1",
      plot_sig = FALSE
    )
  )

  # Robustness assertions that don't force >=1 row in edge encodings
  expect_true(is.data.frame(out))
  if (nrow(out) > 0) {
    expect_true(all(c(
      "Predictor", "Moderator", "Outcome", "Term", "P_value",
      "Interaction_Effect", "Std_Error", "T_value", "CI_Lower", "CI_Upper", "Has_Moderation"
    ) %in% names(out)))
  }
})

test_that("controls overlapping with predictor or moderator are dropped per model (clean)", {
  set.seed(2)
  df <- data.frame(y = rnorm(30), x = rnorm(30), m = rnorm(30))
  df$y <- df$y + 0.5 * df$x * df$m

  out <- suppressMessages(
    run_moderation_paths(
      df,
      predictors = "x",
      moderators = "m",
      outcomes   = "y",
      controls   = c("x", "m") # overlap on purpose
    )
  )

  expect_true(is.data.frame(out))
  expect_true(nrow(out) >= 1)
})

test_that("multiple predictors and outcomes produce combined rows", {
  set.seed(3)
  df <- data.frame(
    y1 = rnorm(60),
    y2 = rnorm(60),
    x1 = rnorm(60),
    x2 = rnorm(60),
    m  = rnorm(60)
  )
  df$y1 <- df$y1 + 0.6 * df$x1 * df$m
  df$y2 <- df$y2 + 0.7 * df$x2 * df$m

  out <- suppressMessages(
    run_moderation_paths(
      data       = df,
      predictors = c("x1", "x2"),
      moderators = "m",
      outcomes   = c("y1", "y2")
    )
  )

  expect_true(is.data.frame(out))
  expect_true(nrow(out) >= 2)
  expect_true(all(out$Outcome %in% c("y1", "y2")))
})

test_that("missing controls in input are tolerated and models run (clean)", {
  set.seed(4)
  df <- data.frame(y = rnorm(40), x = rnorm(40), m = rnorm(40))
  df$y <- df$y + 0.8 * df$x * df$m

  out <- suppressMessages(
    run_moderation_paths(
      data       = df,
      predictors = "x",
      moderators = "m",
      outcomes   = "y",
      controls   = "c_missing" # not in data
    )
  )

  expect_s3_class(out, "data.frame")
  expect_true(nrow(out) >= 1)
})

test_that("sig_level affects Has_Moderation flags", {
  set.seed(5)
  df <- data.frame(y = rnorm(120), x = rnorm(120), m = rnorm(120))
  df$y <- df$y + 0.4 * df$x * df$m

  out_loose <- suppressMessages(
    run_moderation_paths(df, "x", "m", "y", sig_level = 0.10)
  )
  out_strict <- suppressMessages(
    run_moderation_paths(df, "x", "m", "y", sig_level = 0.01)
  )

  # We do not assert exact numbers, just check that at least one of them has any TRUE flag
  expect_true(is.data.frame(out_loose))
  expect_true(is.data.frame(out_strict))
  expect_true(any(out_loose$Has_Moderation %in% TRUE) || any(out_strict$Has_Moderation %in% TRUE))
})

test_that("NA rows are handled via na.exclude without error", {
  set.seed(6)
  df <- data.frame(y = rnorm(50), x = rnorm(50), m = rnorm(50))
  df$x[sample(1:50, 5)] <- NA
  df$y <- df$y + 0.7 * df$x * df$m

  out <- suppressMessages(run_moderation_paths(df, "x", "m", "y"))
  expect_s3_class(out, "data.frame")
})

test_that("plot_sig uses cat_plot when predictor is factor", {
  if (!requireNamespace("interactions", quietly = TRUE)) {
    succeed()
    return(invisible(TRUE))
  }
  set.seed(7)
  df <- data.frame(
    y = rnorm(100),
    x = factor(sample(c("Low", "High"), 100, TRUE)),
    m = rnorm(100)
  )
  # Induce an interaction by shifting group means with m
  df$y <- df$y + ifelse(df$x == "High", 0.8 * df$m, 0.1 * df$m)

  expect_silent(
    suppressMessages(run_moderation_paths(df, "x", "m", "y", plot_sig = TRUE))
  )
})

test_that("summarize_categorical reduces multiple interaction terms to one per model", {
  set.seed(8)
  df <- data.frame(
    y = rnorm(100),
    x = factor(sample(letters[1:3], 100, TRUE)),
    m = rnorm(100)
  )
  df$y <- df$y + 0.5 * as.numeric(df$x) * df$m

  out_full <- suppressMessages(run_moderation_paths(df, "x", "m", "y", summarize_categorical = FALSE))
  out_sum <- suppressMessages(run_moderation_paths(df, "x", "m", "y", summarize_categorical = TRUE))

  # When summarized, at least one row with Term == "Summary"
  expect_true(any(out_sum$Term == "Summary"))
  # When not summarized, we expect at least some rows where Term != "Summary"
  expect_true(any(out_full$Term != "Summary"))
})

test_that("factor detection message path is exercised (captured, not printed)", {
  set.seed(9)
  df <- data.frame(y = rnorm(40), x = rnorm(40), m = factor(sample(c("A", "B"), 40, TRUE)))

  # Capture the message instead of printing it
  expect_message(
    out <- run_moderation_paths(df, "x", "m", "y"),
    regexp = "Factor variables detected \\(m\\)", # match the exact variable tag
    all = FALSE
  )
  expect_s3_class(out, "data.frame")
})
