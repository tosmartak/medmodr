#' Iterate moderation analyses across variable sets
#'
#' Fits linear models of the form \code{outcome ~ predictor * moderator + controls}
#' for all combinations of \code{predictors}, \code{moderators}, and \code{outcomes}.
#' Returns a tidy summary of interaction terms; optionally plots significant effects.
#'
#' @param data A data frame containing all variables referenced.
#' @param predictors Character vector of focal predictor variable names.
#' @param moderators Character vector of moderator variable names.
#' @param outcomes Character vector of outcome variable names.
#' @param controls Optional character vector of control variable names.
#'   Any controls that duplicate the current predictor or moderator are dropped per model.
#' @param categorical_vars Optional character vector of variables to coerce to factor
#'   (use this to explicitly mark categorical inputs instead of guessing).
#' @param sig_level Numeric p-value threshold used to flag significance (default 0.05).
#' @param plot_sig Logical; if \code{TRUE}, attempt to plot significant interactions via
#'   \pkg{interactions}. Plots are best-effort and skipped if the package is unavailable.
#' @param summarize_categorical Logical; when the interaction expands to multiple terms
#'   (e.g., factor-by-numeric), record only the most significant interaction term per model.
#'
#' @return A tibble with one row per interaction term (or one per model if
#'   \code{summarize_categorical = TRUE}) and columns:
#'   \itemize{
#'     \item \code{Predictor}, \code{Moderator}, \code{Outcome}, \code{Term}
#'     \item \code{Interaction_Effect}, \code{Std_Error}, \code{T_value}, \code{P_value}
#'     \item \code{CI_Lower}, \code{CI_Upper}
#'     \item \code{Has_Moderation} (logical; \code{P_value < sig_level})
#'   }
#'
#' @details
#' The formula is assembled with backticks to tolerate non-syntactic names.
#' Models are fit via \code{stats::lm()} with \code{na.action = stats::na.exclude}.
#' For plotting, \pkg{interactions} is required; if not installed or an error occurs,
#' plotting is skipped with a message.
#'
#' @examples
#' \donttest{
#' set.seed(1)
#' df <- data.frame(
#'   y = rnorm(80),
#'   x = rnorm(80),
#'   m = rnorm(80),
#'   c1 = rnorm(80)
#' )
#' res <- run_moderation_paths(
#'   data = df,
#'   predictors = "x",
#'   moderators = "m",
#'   outcomes = "y",
#'   controls = "c1",
#'   plot_sig = FALSE
#' )
#' head(res)
#' }
#'
#' @export
run_moderation_paths <- function(
    data,
    predictors,
    moderators,
    outcomes,
    controls = NULL,
    categorical_vars = NULL,
    sig_level = 0.05,
    plot_sig = FALSE,
    summarize_categorical = FALSE) {
  stopifnot(is.data.frame(data))
  # Ensure character vectors (NULL ok for controls / categorical_vars)
  predictors <- as.character(predictors)
  moderators <- as.character(moderators)
  outcomes <- as.character(outcomes)
  if (!is.null(controls)) controls <- as.character(controls)
  if (!is.null(categorical_vars)) categorical_vars <- as.character(categorical_vars)

  # Coerce explicitly-specified categoricals to factor (only if they exist)
  if (!is.null(categorical_vars)) {
    categorical_vars <- intersect(categorical_vars, colnames(data))
    for (v in categorical_vars) data[[v]] <- as.factor(data[[v]])
  }

  # Helper: build formula y ~ x * m + controls
  build_formula <- function(outcome, predictor, modx, ctrl) {
    # drop duplicates and self-terms from controls
    if (!is.null(ctrl)) {
      ctrl <- setdiff(unique(ctrl), c(predictor, modx))
      ctrl <- ctrl[ctrl %in% names(data)]
    }
    # backtick every variable to tolerate spaces/symbols
    bt <- function(v) paste0("`", v, "`")
    rhs_terms <- c(paste0(bt(predictor), "*", bt(modx)))
    if (length(ctrl)) rhs_terms <- c(rhs_terms, bt(ctrl))
    stats::as.formula(paste(bt(outcome), "~", paste(rhs_terms, collapse = " + ")))
  }

  # Helper: robustly find interaction rows in coef table (ignore backticks)
  find_interaction_rows <- function(rownms, predictor, modx) {
    rn <- gsub("`", "", rownms)
    pat <- paste0(
      "(^|:)", predictor, "(:|\\*)", modx, "($|:)", "|",
      "(^|:)", modx, "(:|\\*)", predictor, "($|:)"
    )
    which(grepl(pat, rn))
  }

  out_rows <- list()

  for (x in predictors) {
    for (m in moderators) {
      if (identical(x, m)) next
      for (y in outcomes) {
        # Skip if required columns are absent
        needed <- unique(stats::na.omit(c(y, x, m, controls)))
        missing <- setdiff(needed, names(data))
        if (length(missing)) {
          message("[WARN] Skipping (missing vars): ", paste(missing, collapse = ", "))
          next
        }

        fml <- build_formula(y, x, m, controls)

        model <- tryCatch(
          stats::lm(fml, data = data, na.action = stats::na.exclude),
          error = function(e) {
            message("[WARN] Model failed for: ", x, " × ", m, " → ", y, " : ", e$message)
            return(NULL)
          }
        )
        if (is.null(model)) next

        cs <- summary(model)$coefficients
        if (is.null(cs) || !nrow(cs)) next

        idx <- find_interaction_rows(rownames(cs), x, m)
        has_any_sig <- FALSE

        if (length(idx) > 0) {
          rows <- cs[idx, , drop = FALSE]

          if (summarize_categorical && nrow(rows) > 1) {
            pvals <- rows[, "Pr(>|t|)"]
            keep <- which.min(pvals)
            rows <- rows[keep, , drop = FALSE]
          }

          for (i in seq_len(nrow(rows))) {
            term <- rownames(rows)[i]
            effect <- rows[i, "Estimate"]
            std_error <- rows[i, "Std. Error"]
            t_value <- rows[i, "t value"]
            p_val <- rows[i, "Pr(>|t|)"]
            sig_flag <- is.finite(p_val) && p_val < sig_level
            has_any_sig <- has_any_sig || sig_flag

            out_rows[[length(out_rows) + 1L]] <- tibble::tibble(
              Predictor = x,
              Moderator = m,
              Outcome = y,
              Term = term,
              Interaction_Effect = effect,
              Std_Error = std_error,
              T_value = t_value,
              P_value = p_val,
              CI_Lower = effect - 1.96 * std_error,
              CI_Upper = effect + 1.96 * std_error,
              Has_Moderation = sig_flag
            )
          }
        }

        # Optional plotting for significant interactions
        if (plot_sig && has_any_sig) {
          if (!requireNamespace("interactions", quietly = TRUE)) {
            message("ℹ Skipping plot: package 'interactions' not installed.")
          } else {
            message("[PLOT] Plotting: ", x, " × ", m, " → ", y)
            tryCatch(
              {
                if (is.factor(data[[x]])) {
                  p <- interactions::cat_plot(
                    model = model, pred = x, modx = m, data = data,
                    plot.points = FALSE, main.title = paste0(x, " × ", m, " → ", y)
                  )
                } else {
                  p <- interactions::interact_plot(
                    model = model, pred = x, modx = m, data = data,
                    plot.points = FALSE, main.title = paste0(x, " × ", m, " → ", y)
                  )
                }
                print(p)
              },
              error = function(e) {
                message("  [ERROR] Plot failed: ", e$message)
              }
            )
          }
        }
      }
    }
  }

  if (length(out_rows)) {
    dplyr::bind_rows(out_rows)
  } else {
    tibble::tibble()
  }
}
