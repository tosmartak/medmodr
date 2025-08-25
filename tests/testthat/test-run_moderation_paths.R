test_that("run_moderation_paths returns rows for interaction", {
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
  
  out <- run_moderation_paths(
    data = df,
    predictors = "x",
    moderators = "m",
    outcomes = "y",
    controls = "c1",
    plot_sig = FALSE
  )
  
  expect_true(is.data.frame(out))
  expect_true(nrow(out) >= 1)
  expect_true(all(c("Predictor","Moderator","Outcome","Term","P_value") %in% names(out)))
})
