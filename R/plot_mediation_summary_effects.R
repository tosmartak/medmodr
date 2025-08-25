#' Plot ACME, ADE, and Total Effect with confidence intervals
#'
#' Creates a faceted pointrange plot across outcomes (rows) and groups
#' (Treatment -> Mediator). Requires \pkg{ggplot2} and \pkg{tidyr}.
#'
#' @param summary_table Data frame from \code{run_mediation_paths()}.
#' @param filter_significant Logical; if \code{TRUE}, keep only rows with \code{Has_Mediation == TRUE}.
#' @param show_only_acme Logical; if \code{TRUE}, show only ACME.
#'
#' @return A ggplot object.
#' @export
plot_mediation_summary_effects <- function(summary_table, filter_significant = FALSE, show_only_acme = FALSE) {
  if (!requireNamespace("ggplot2", quietly = TRUE)) stop("Package 'ggplot2' is required.", call. = FALSE)
  if (!requireNamespace("tidyr", quietly = TRUE)) stop("Package 'tidyr' is required.", call. = FALSE)
  if (!requireNamespace("dplyr", quietly = TRUE)) stop("Package 'dplyr' is required.", call. = FALSE)

  data <- summary_table
  if (isTRUE(filter_significant)) {
    data <- dplyr::filter(data, .data$Has_Mediation %in% TRUE)
  }

  data_long <- data |>
    tidyr::pivot_longer(
      cols = c(.data$ACME, .data$ADE, .data$Total_Effect),
      names_to = "Effect",
      values_to = "Estimate"
    ) |>
    dplyr::mutate(
      Effect = dplyr::recode(.data$Effect, "Total_Effect" = "Total Effect"),
      CI_Lower = dplyr::case_when(
        .data$Effect == "ACME" ~ .data$ACME_CI_Lower,
        .data$Effect == "ADE" ~ .data$ADE_CI_Lower,
        .data$Effect == "Total Effect" ~ .data$Total_Effect_CI_Lower
      ),
      CI_Upper = dplyr::case_when(
        .data$Effect == "ACME" ~ .data$ACME_CI_Upper,
        .data$Effect == "ADE" ~ .data$ADE_CI_Upper,
        .data$Effect == "Total Effect" ~ .data$Total_Effect_CI_Upper
      ),
      Sig = dplyr::case_when(
        .data$Effect == "ACME" ~ .data$ACME_p < 0.05,
        .data$Effect == "ADE" ~ .data$ADE_p < 0.05,
        .data$Effect == "Total Effect" ~ .data$Total_Effect_p < 0.05
      ),
      Group = paste(.data$Treatment, "->", .data$Mediator)
    )

  if (isTRUE(show_only_acme)) {
    data_long <- dplyr::filter(data_long, .data$Effect == "ACME")
  }

  ggplot2::ggplot(
    data_long,
    ggplot2::aes(x = .data$Effect, y = .data$Estimate, ymin = .data$CI_Lower, ymax = .data$CI_Upper, color = .data$Effect)
  ) +
    ggplot2::geom_pointrange(position = ggplot2::position_dodge(width = 0.5), linewidth = 1.1) +
    ggplot2::facet_grid(rows = ggplot2::vars(.data$Outcome), cols = ggplot2::vars(.data$Group), scales = "free") +
    ggplot2::geom_hline(yintercept = 0, linetype = "dashed") +
    ggplot2::scale_color_manual(values = c("ACME" = "#1b9e77", "ADE" = "#d95f02", "Total Effect" = "#7570b3")) +
    ggplot2::theme_minimal(base_size = 14) +
    ggplot2::theme(
      strip.text = ggplot2::element_text(face = "bold"),
      axis.text.x = ggplot2::element_text(angle = 45, hjust = 1),
      panel.grid.minor = ggplot2::element_blank()
    ) +
    ggplot2::labs(
      title = "Estimated Mediation Effects with 95% Confidence Intervals",
      x = "Effect Type",
      y = "Estimate"
    )
}
