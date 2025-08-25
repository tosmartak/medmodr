#' Plot all significant mediation triples
#'
#' For each row of a summary table with \code{Has_Mediation == TRUE},
#' produce a default \code{mediation::mediate()} plot via
#' \code{\link{plot_mediation_result}}. Optionally save PDFs.
#'
#' @param summary_table A data frame returned by \code{run_mediation_paths()}.
#' @inheritParams plot_mediation_result
#' @return Invisibly returns \code{NULL}.
#' @export
plot_all_significant_mediations <- function(
    summary_table, data, controls = NULL, save_path = NULL,
    sims = 1000, boot = TRUE, seed = 123) {
  if (!requireNamespace("mediation", quietly = TRUE)) {
    stop("Package 'mediation' is required for plot_all_significant_mediations().", call. = FALSE)
  }
  if (!("Has_Mediation" %in% names(summary_table))) {
    stop("summary_table must include column 'Has_Mediation'.", call. = FALSE)
  }

  sig_rows <- summary_table[summary_table$Has_Mediation %in% TRUE, , drop = FALSE]
  if (!nrow(sig_rows)) {
    message("No significant mediation effects to plot.")
    return(invisible(NULL))
  }

  for (i in seq_len(nrow(sig_rows))) {
    row <- sig_rows[i, ]
    title <- paste(row$Treatment, "->", row$Mediator, "->", row$Outcome)
    message("Plotting: ", title)
    plot_mediation_result(
      data = data,
      treatment = row$Treatment,
      mediator = row$Mediator,
      outcome = row$Outcome,
      controls = controls,
      sims = sims, boot = boot, seed = seed,
      title = title,
      save_path = save_path
    )
  }
  invisible(NULL)
}
