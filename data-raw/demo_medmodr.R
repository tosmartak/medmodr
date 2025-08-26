## code to prepare `demo_medmodr` dataset goes here
set.seed(42)
n <- 200

demo_medmodr <- data.frame(
  # numeric features
  x1 = rnorm(n),
  x2 = rnorm(n),
  m1 = rnorm(n),
  m2 = rnorm(n),
  c1 = rnorm(n),
  c2 = rnorm(n),
  # categorical features
  grp = factor(sample(c("control", "treat"), n, replace = TRUE)),
  edu = factor(sample(c("primary", "secondary", "tertiary"), n, replace = TRUE))
)

# Inject mediation signals
# x1 -> m1 -> y1 ; x2 -> m2 -> y2
demo_medmodr$m1 <- 0.8 * demo_medmodr$x1 + demo_medmodr$m1
demo_medmodr$m2 <- 0.6 * demo_medmodr$x2 + demo_medmodr$m2

# Create outcomes with both mediation and direct effects + controls
y1 <- 0.5 * demo_medmodr$m1 + 0.3 * demo_medmodr$x1 + 0.2 * demo_medmodr$c1 + rnorm(n)
y2 <- 0.4 * demo_medmodr$m2 + 0.25 * demo_medmodr$x2 + 0.15 * demo_medmodr$c2 + rnorm(n)

# Inject moderation signals (interactions)
# x1 * m1 on y1; x2 * grp on y2
y1 <- y1 + 0.5 * demo_medmodr$x1 * demo_medmodr$m1
y2 <- y2 + ifelse(demo_medmodr$grp == "treat", 0.4 * demo_medmodr$x2, 0)

demo_medmodr$y1 <- y1
demo_medmodr$y2 <- y2

# Save into package
usethis::use_data(demo_medmodr, overwrite = TRUE)
