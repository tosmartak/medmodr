#' Plot ACME, ADE, and Total Effect with confidence intervals
#'
#' Creates either:
#' - a faceted pointrange plot across outcomes (rows) and groups (Treatment -> Mediator)
#'   when `summary_plot = TRUE` (default), or
#' - a list of single-row ggplots (one per Outcome × Group) when `summary_plot = FALSE`.
#'
#' Requires \pkg{ggplot2} and \pkg{tidyr}.
#'
#' @param summary_table Data frame from \code{run_mediation_paths()}.
#' @param filter_significant Logical; if \code{TRUE}, keep only rows with \code{Has_Mediation == TRUE}.
#' @param show_only_acme Logical; if \code{TRUE}, show only ACME.
#' @param summary_plot Logical; if \code{TRUE} (default) return a single faceted plot.
#'   If \code{FALSE}, return a named list of ggplot objects (one per row).
#'   a list of plots per (Outcome × Treatment × Mediator).
#'
#' @return A ggplot object if \code{summary_plot = TRUE}; otherwise a named list of ggplot objects.
#' @export
plot_mediation_summary_effects <- function(summary_table,
                                           filter_significant = TRUE,
                                           show_only_acme = FALSE,
                                           summary_plot = TRUE) {
  # ------------------------------
  # Validation block
  # ------------------------------
  if (!is.data.frame(summary_table)) {
    stop("`summary_table` must be a data frame (output of run_mediation_paths).", call. = FALSE)
  }

  required_cols <- c(
    "Treatment", "Mediator", "Outcome",
    "ACME", "ADE", "Total_Effect",
    "ACME_CI_Lower", "ACME_CI_Upper",
    "ADE_CI_Lower", "ADE_CI_Upper",
    "Total_Effect_CI_Lower", "Total_Effect_CI_Upper",
    "ACME_p", "ADE_p", "Total_Effect_p",
    "Has_Mediation"
  )

  missing <- setdiff(required_cols, names(summary_table))
  if (length(missing)) {
    stop("Missing required columns in `summary_table`: ", paste(missing, collapse = ", "), call. = FALSE)
  }

  if (!is.logical(filter_significant) || length(filter_significant) != 1) {
    stop("`filter_significant` must be a single logical value.", call. = FALSE)
  }
  if (!is.logical(show_only_acme) || length(show_only_acme) != 1) {
    stop("`show_only_acme` must be a single logical value.", call. = FALSE)
  }
  if (!is.logical(summary_plot) || length(summary_plot) != 1) {
    stop("`summary_plot` must be a single logical value.", call. = FALSE)
  }

  # ------------------------------
  # Core logic
  # ------------------------------
  data <- summary_table

  if (isTRUE(filter_significant)) {
    data <- dplyr::filter(data, Has_Mediation %in% TRUE)
  }

  if (nrow(data) == 0L) {
    rlang::warn("No rows available after filtering; returning empty result.")
    return(if (isTRUE(summary_plot)) {
      ggplot2::ggplot() +
        ggplot2::theme_void()
    } else {
      list()
    })
  }

  data_long <- data |>
    tidyr::pivot_longer(
      cols = c("ACME", "ADE", "Total_Effect"),
      names_to = "Effect",
      values_to = "Estimate"
    ) |>
    dplyr::mutate(
      Effect = dplyr::recode(Effect, "Total_Effect" = "Total Effect"),
      CI_Lower = dplyr::case_when(
        Effect == "ACME" ~ ACME_CI_Lower,
        Effect == "ADE" ~ ADE_CI_Lower,
        Effect == "Total Effect" ~ Total_Effect_CI_Lower
      ),
      CI_Upper = dplyr::case_when(
        Effect == "ACME" ~ ACME_CI_Upper,
        Effect == "ADE" ~ ADE_CI_Upper,
        Effect == "Total Effect" ~ Total_Effect_CI_Upper
      ),
      Sig = dplyr::case_when(
        Effect == "ACME" ~ ACME_p < 0.05,
        Effect == "ADE" ~ ADE_p < 0.05,
        Effect == "Total Effect" ~ Total_Effect_p < 0.05
      ),
      Group = paste(Treatment, "->", Mediator),
      # keep a stable ordering of effect types
      Effect = factor(Effect, levels = c("ACME", "ADE", "Total Effect"))
    )

  if (isTRUE(show_only_acme)) {
    data_long <- dplyr::filter(data_long, Effect == "ACME")
  }

  # Shared geoms/scales/theme
  base_layers <- list(
    ggplot2::geom_pointrange(
      position = ggplot2::position_dodge(width = 0.5),
      linewidth = 1.1
    ),
    ggplot2::geom_hline(yintercept = 0, linetype = "dashed"),
    ggplot2::scale_color_manual(values = c(
      "ACME" = "#1b9e77",
      "ADE" = "#d95f02",
      "Total Effect" = "#7570b3"
    )),
    ggplot2::theme_minimal(base_size = 14),
    ggplot2::theme(
      strip.text = ggplot2::element_text(face = "bold"),
      axis.text.x = ggplot2::element_text(angle = 45, hjust = 1),
      panel.grid.minor = ggplot2::element_blank()
    ),
    ggplot2::labs(
      x = "Effect Type",
      y = "Estimate"
    )
  )

  if (isTRUE(summary_plot)) {
    # Return a single faceted plot (current behavior)
    return(
      ggplot2::ggplot(
        data_long,
        ggplot2::aes(x = Effect, y = Estimate, ymin = CI_Lower, ymax = CI_Upper, color = Effect)
      ) +
        base_layers +
        ggplot2::facet_grid(
          rows = ggplot2::vars(Outcome),
          cols = ggplot2::vars(Group),
          scales = "free"
        ) +
        ggplot2::labs(title = "Estimated Mediation Effects with 95% Confidence Intervals")
    )
  } else {
    # Return one plot per row (Outcome × Group)
    # Split by unique row identifiers from the original (pre-pivot) data
    # We use distinct combinations of Outcome, Treatment, Mediator to drive grouping
    keys <- data |>
      dplyr::transmute(
        .row_id = dplyr::row_number(),
        Outcome, Treatment, Mediator,
        Group = paste(Treatment, "->", Mediator)
      )

    plots <- vector("list", nrow(keys))
    names(plots) <- paste0(
      keys$.row_id, ": ",
      keys$Outcome, " | ", keys$Group
    )

    for (i in seq_len(nrow(keys))) {
      k <- keys[i, ]
      df_i <- dplyr::filter(
        data_long,
        Outcome == k$Outcome,
        Treatment == k$Treatment,
        Mediator == k$Mediator
      )

      # It's possible (though unlikely) for a key to be empty after show_only_acme filtering
      if (nrow(df_i) == 0L) {
        plots[[i]] <- ggplot2::ggplot() +
          ggplot2::theme_void()
        next
      }

      p_i <-
        ggplot2::ggplot(
          df_i,
          ggplot2::aes(x = Effect, y = Estimate, ymin = CI_Lower, ymax = CI_Upper, color = Effect)
        ) +
        base_layers +
        ggplot2::labs(
          title = paste0(
            "Estimated Mediation Effects (95% CI)\n",
            k$Outcome, " | ", k$Group
          )
        )

      plots[[i]] <- p_i
    }

    return(plots)
  }
}
