#' Plot a single mediation result
#'
#' Fits the two models for a given triple and plots the \code{mediation::mediate()}
#' output using its default plot method. Optionally saves a PDF.
#'
#' @inheritParams run_mediation_paths
#' @param treatment Single treatment variable name.
#' @param mediator  Single mediator variable name.
#' @param outcome   Single outcome variable name.
#' @param title Optional character title for the plot.
#' @param save_path Optional directory path to save a PDF; if provided, a file
#'   named \code{"<treatment>_<mediator>_<outcome>.pdf"} is written.
#'
#' @return The plot object returned by \code{plot()} for the mediate result.
#' @export
plot_mediation_result <- function(
    data, treatment, mediator, outcome, controls = NULL,
    sims = 1000, boot = TRUE, seed = 123,
    title = NULL, save_path = NULL) {
  if (!requireNamespace("mediation", quietly = TRUE)) {
    stop("Package 'mediation' is required for plot_mediation_result(). Install it first.", call. = FALSE)
  }
  stopifnot(is.data.frame(data))

  ctrl <- controls
  if (!is.null(ctrl)) {
    ctrl <- setdiff(unique(ctrl), c(treatment, mediator))
    ctrl <- ctrl[ctrl %in% names(data)]
  }

  bt <- function(v) paste0("`", v, "`")
  f_med <- stats::as.formula(paste(bt(mediator), "~", paste(c(bt(treatment), bt(ctrl)), collapse = " + ")))
  f_out <- stats::as.formula(paste(bt(outcome), "~", paste(c(bt(mediator), bt(treatment), bt(ctrl)), collapse = " + ")))

  med_model <- stats::lm(f_med, data = data, na.action = stats::na.exclude)
  out_model <- stats::lm(f_out, data = data, na.action = stats::na.exclude)

  set.seed(seed)
  res <- mediation::mediate(med_model, out_model,
    treat = treatment, mediator = mediator,
    boot = boot, sims = sims
  )

  main_title <- if (is.null(title)) paste(treatment, "->", mediator, "->", outcome) else title
  p <- plot(res, main = main_title)

  if (!is.null(save_path)) {
    if (!dir.exists(save_path)) dir.create(save_path, recursive = TRUE)
    filename <- file.path(save_path, paste0(treatment, "_", mediator, "_", outcome, ".pdf"))
    grDevices::pdf(filename)
    plot(res, main = main_title)
    grDevices::dev.off()
  }

  p
}
