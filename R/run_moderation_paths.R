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
run_moderation_paths <- function(data, predictors, moderators, outcomes, controls,
                                 categorical_vars = NULL,
                                 sig_level = 0.05,
                                 plot_sig = FALSE,
                                 summarize_categorical = FALSE) {
  # Convert only user-specified categorical variables to factors
  if (!is.null(categorical_vars)) {
    categorical_vars <- intersect(categorical_vars, colnames(data))
    for (v in categorical_vars) {
      data[[v]] <- as.factor(data[[v]])
    }
  }

  summary_list <- list()

  for (predictor in predictors) {
    for (modx in moderators) {
      if (predictor == modx) next # avoid self-interaction

      for (outcome in outcomes) {
        ctrl_vars <- setdiff(controls, c(predictor, modx))

        formula_str <- paste(outcome, "~", paste(c(
          paste0("`", predictor, "`*`", modx, "`"), paste0("`", ctrl_vars, "`")
        ), collapse = " + "))

        model_formula <- stats::as.formula(formula_str)
        model <- tryCatch(
          stats::lm(model_formula, data = data),
          error = function(e) {
            message("Model failed for: ", predictor, " x ", modx, " -> ", outcome)
            return(NULL)
          }
        )
        if (is.null(model)) next

        coef_summary <- summary(model)$coefficients

        interaction_terms <- grep(
          paste0("(^|:)", predictor, ".*:", modx, "|", modx, ".*:", predictor),
          rownames(coef_summary),
          value = TRUE
        )

        has_any_sig <- FALSE

        if (length(interaction_terms) > 0) {
          if (summarize_categorical && length(interaction_terms) > 1) {
            effects <- coef_summary[interaction_terms, "Estimate"]
            ses <- coef_summary[interaction_terms, "Std. Error"]
            tvals <- coef_summary[interaction_terms, "t value"]
            pvals <- coef_summary[interaction_terms, "Pr(>|t|)"]

            min_idx <- which.min(pvals)

            effect <- effects[min_idx]
            std_error <- ses[min_idx]
            t_value <- tvals[min_idx]
            p_val <- pvals[min_idx]

            has_any_sig <- !is.na(p_val) && p_val < sig_level

            summary_list[[paste(outcome, predictor, modx, sep = "_")]] <- data.frame(
              Predictor = predictor,
              Moderator = modx,
              Outcome = outcome,
              Term = "Summary",
              Interaction_Effect = effect,
              Std_Error = std_error,
              T_value = t_value,
              P_value = p_val,
              CI_Lower = effect - 1.96 * std_error,
              CI_Upper = effect + 1.96 * std_error,
              Has_Moderation = has_any_sig
            )
          } else {
            for (term in interaction_terms) {
              effect <- coef_summary[term, "Estimate"]
              std_error <- coef_summary[term, "Std. Error"]
              t_value <- coef_summary[term, "t value"]
              p_val <- coef_summary[term, "Pr(>|t|)"]

              has_sig <- !is.na(p_val) && p_val < sig_level
              has_any_sig <- has_any_sig || has_sig

              summary_list[[paste(outcome, predictor, modx, term, sep = "_")]] <- data.frame(
                Predictor = predictor,
                Moderator = modx,
                Outcome = outcome,
                Term = term,
                Interaction_Effect = effect,
                Std_Error = std_error,
                T_value = t_value,
                P_value = p_val,
                CI_Lower = effect - 1.96 * std_error,
                CI_Upper = effect + 1.96 * std_error,
                Has_Moderation = has_sig
              )
            }
          }
        }

        # ---- Plotting block ----
        if (plot_sig && has_any_sig) {
          message("Plotting: ", predictor, " x ", modx, " -> ", outcome)
          tryCatch(
            {
              if (is.factor(data[[predictor]])) {
                # Use cat_plot for factor predictors
                p <- do.call(interactions::cat_plot, list(
                  model = model,
                  pred = predictor,
                  modx = modx,
                  data = data,
                  plot.points = FALSE,
                  main.title = paste0(predictor, " x ", modx, " -> ", outcome)
                ))
              } else {
                # Use interact_plot for numeric predictors
                p <- do.call(interactions::interact_plot, list(
                  model = model,
                  pred = predictor,
                  modx = modx,
                  data = data,
                  plot.points = FALSE,
                  main.title = paste0(predictor, " x ", modx, " -> ", outcome)
                ))
              }
              print(p)
            },
            error = function(e) {
              message("  Plot failed: ", e$message)
            }
          )
        }
      }
    }
  }

  if (length(summary_list) > 0) {
    return(dplyr::bind_rows(summary_list))
  } else {
    return(tibble::tibble())
  }
}
