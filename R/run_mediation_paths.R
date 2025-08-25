#' Iterate mediation analyses across variable sets
#'
#' Fits two linear models per triple \code{(treatment, mediator, outcome)}:
#' \code{mediator ~ treatment + controls} and \code{outcome ~ mediator + treatment + controls},
#' then estimates mediation effects via \code{mediation::mediate()}.
#' Returns a tidy summary row per triple.
#'
#' @param data A data frame containing all variables.
#' @param treatments Character vector of treatment variable names.
#' @param mediators Character vector of mediator variable names.
#' @param outcomes Character vector of outcome variable names.
#' @param controls Optional character vector of controls; duplicates of current
#'   treatment/mediator are removed per model.
#' @param sims Integer number of simulation draws for \code{mediate()} (default 1000).
#' @param boot Logical; if \code{TRUE}, nonparametric bootstrap; if \code{FALSE},
#'   quasi-Bayesian Monte Carlo (default \code{TRUE}).
#' @param seed Integer RNG seed for reproducibility (default 123).
#'
#' @return A tibble with columns:
#' \itemize{
#' \item \code{Treatment}, \code{Mediator}, \code{Outcome}
#' \item \code{ACME}, \code{ACME_CI_Lower}, \code{ACME_CI_Upper}, \code{ACME_p}
#' \item \code{ADE}, \code{ADE_CI_Lower}, \code{ADE_CI_Upper}, \code{ADE_p}
#' \item \code{Total_Effect}, \code{Total_Effect_CI_Lower}, \code{Total_Effect_CI_Upper}, \code{Total_Effect_p}
#' \item \code{Prop_Mediated}, \code{PropMediated_CI_Lower}, \code{PropMediated_CI_Upper}, \code{PropMediated_p}
#' \item \code{Has_Mediation} (logical; significant ACME with CI not crossing 0)
#' }
#'
#' @details
#' Models are fit with \code{stats::lm()} and \code{na.action = stats::na.exclude}.
#' Formulas are constructed safely without \code{eval(parse())}.
#' The \pkg{mediation} package is required; if unavailable, an informative error is thrown.
#'
#' @examples
#' \donttest{
#' if (requireNamespace("mediation", quietly = TRUE)) {
#'   set.seed(1)
#'   n <- 120
#'   df <- data.frame(
#'     T = rnorm(n),
#'     M = rnorm(n),
#'     Y = rnorm(n),
#'     C = rnorm(n)
#'   )
#'   # Inject simple mediation signal
#'   df$M <- 0.7 * df$T + df$M
#'   df$Y <- 0.6 * df$M + 0.3 * df$T + df$Y + 0.2 * df$C
#'
#'   out <- run_mediation_paths(
#'     data = df,
#'     treatments = "T",
#'     mediators = "M",
#'     outcomes = "Y",
#'     controls = "C",
#'     sims = 200, boot = FALSE
#'   )
#'   head(out)
#' }
#' }
#'
#' @export
run_mediation_paths <- function(
    data,
    treatments,
    mediators,
    outcomes,
    controls = NULL,
    sims = 1000,
    boot = TRUE,
    seed = 123) {
  if (!requireNamespace("mediation", quietly = TRUE)) {
    stop("Package 'mediation' is required for run_mediation_paths(). Install it first.", call. = FALSE)
  }
  stopifnot(is.data.frame(data))
  treatments <- as.character(treatments)
  mediators <- as.character(mediators)
  outcomes <- as.character(outcomes)
  if (!is.null(controls)) controls <- as.character(controls)

  # helper: build safe formula strings and convert to formulas
  build_formula <- function(lhs, rhs_terms) {
    bt <- function(v) paste0("`", v, "`")
    rhs <- paste(bt(rhs_terms), collapse = " + ")
    stats::as.formula(paste(bt(lhs), "~", rhs))
  }

  out_list <- list()

  for (med in mediators) {
    for (tr in treatments) {
      if (identical(tr, med)) {
        message("Skipping redundant pair: ", tr, " used as both treatment and mediator")
        next
      }

      for (y in outcomes) {
        # controls: drop duplicates and any that don't exist
        ctrl <- controls
        if (!is.null(ctrl)) {
          ctrl <- setdiff(unique(ctrl), c(tr, med))
          ctrl <- ctrl[ctrl %in% names(data)]
        }

        needed <- unique(na.omit(c(tr, med, y, ctrl)))
        missing <- setdiff(needed, names(data))
        if (length(missing)) {
          message("[WARN] Missing variables: ", paste(missing, collapse = ", "), " -> skipping")
          next
        }

        # mediator model: med ~ tr + ctrl
        rhs_med <- c(tr, ctrl)
        f_med <- build_formula(med, rhs_med)

        # outcome model: y ~ med + tr + ctrl
        rhs_out <- c(med, tr, ctrl)
        f_out <- build_formula(y, rhs_out)

        med_model <- tryCatch(
          stats::lm(f_med, data = data, na.action = stats::na.exclude),
          error = function(e) {
            message("[WARN] mediator model failed: ", e$message)
            return(NULL)
          }
        )
        if (is.null(med_model)) next

        out_model <- tryCatch(
          stats::lm(f_out, data = data, na.action = stats::na.exclude),
          error = function(e) {
            message("[WARN] outcome model failed: ", e$message)
            return(NULL)
          }
        )
        if (is.null(out_model)) next

        message("Running: ", tr, " -> ", med, " -> ", y)

        res <- tryCatch(
          {
            set.seed(seed)
            mediation::mediate(med_model, out_model,
              treat = tr, mediator = med,
              boot = boot, sims = sims
            )
          },
          error = function(e) {
            message("  [ERROR] mediate() failed: ", e$message)
            return(NULL)
          }
        )
        if (is.null(res)) next

        acme_sig <- is.finite(res$d0.p) && (res$d0.p < 0.05) &&
          is.finite(res$d0.ci[1]) && is.finite(res$d0.ci[2]) &&
          sign(res$d0.ci[1]) == sign(res$d0.ci[2])

        out_list[[length(out_list) + 1L]] <- tibble::tibble(
          Treatment = tr,
          Mediator = med,
          Outcome = y,
          ACME = res$d0,
          ACME_CI_Lower = res$d0.ci[1],
          ACME_CI_Upper = res$d0.ci[2],
          ACME_p = res$d0.p,
          ADE = res$z0,
          ADE_CI_Lower = res$z0.ci[1],
          ADE_CI_Upper = res$z0.ci[2],
          ADE_p = res$z0.p,
          Total_Effect = res$tau.coef,
          Total_Effect_CI_Lower = res$tau.ci[1],
          Total_Effect_CI_Upper = res$tau.ci[2],
          Total_Effect_p = res$tau.p,
          Prop_Mediated = res$n0,
          PropMediated_CI_Lower = res$n0.ci[1],
          PropMediated_CI_Upper = res$n0.ci[2],
          PropMediated_p = res$n0.p,
          Has_Mediation = acme_sig
        )
      }
    }
  }

  if (length(out_list)) dplyr::bind_rows(out_list) else tibble::tibble()
}
