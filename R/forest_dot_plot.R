#' Create Forest and Dot Plots for Treatment Effects
#'
#' @description
#' Combines dot plots and forest plots to visualize treatment effects across outcomes,
#' highlighting confidence intervals and clinical thresholds.
#'
#' @param data A data frame containing treatment effect data
#' @param clin_thresholds Data frame with 'Outcome' and 'Threshold' columns (optional)
#' @param outcomes_of_interest Character vector of outcomes to include
#' @param treatment1 Name of the first treatment (default: "Drug A")
#' @param treatment2 Name of the second treatment (default: "Placebo")
#' @param filter_value Filter value to include (default: "None")
#' @param precalculated_stats Logical; if TRUE, assumes stats are already calculated
#'
#' @return A patchwork plot object combining dot and forest plots with a shared legend
#' @export
create_forest_dot_plot <- function(data,
                                   clin_thresholds = NULL,
                                   outcomes_of_interest = c("Primary Efficacy", "Secondary Efficacy",
                                                            "HR Quality of Life", "Reoccurring AE", "Rare SAE"),
                                   treatment1 = "Drug A",
                                   treatment2 = "Placebo",
                                   filter_value = "None",
                                   precalculated_stats = FALSE) {

  if (is.null(clin_thresholds)) {
    clin_thresholds <- data.frame(
      Outcome = c("Primary Efficacy", "Secondary Efficacy", "HR Quality of Life", "Reoccurring AE", "Rare SAE"),
      Threshold = c(0.10, 0.08, 5, -0.10, -0.05),
      stringsAsFactors = FALSE
    )
  }

  # Prepare data
  filtered_data <- prepare_forest_dot_data(
    data, outcomes_of_interest, treatment1, treatment2, filter_value, precalculated_stats
  )

  plots <- list()
  factors <- unique(filtered_data$Factor)

  for (factor in factors) {
    factor_data <- filtered_data %>% filter(Factor == factor)
    types <- unique(factor_data$Type)

    for (type in types) {
      type_data <- factor_data %>% filter(Type == type)
      is_last_plot <- (factor == tail(factors, 1) && type == tail(types, 1))

      # Determine columns for plotting
      estimate1 <- if (type == "Binary") "Prop1" else "Mean1"
      estimate2 <- if (type == "Binary") "Prop2" else "Mean2"
      y_levels <- rev(unique(type_data$Outcome))

      # Build dot plot data
      dot_data <- bind_rows(
        data.frame(Outcome = type_data$Outcome, x = type_data[[estimate1]], Treatment = treatment1),
        data.frame(Outcome = type_data$Outcome, x = type_data[[estimate2]], Treatment = treatment2)
      ) %>% filter(!is.na(x))

      # Clinical thresholds (for forest plot)
      thresholds_with_treatment <- clin_thresholds %>%
        filter(Outcome %in% type_data$Outcome) %>%
        mutate(Treatment = "Clinical Meaningful Difference")

      # Aesthetic mappings
      unique_trts <- unique(c(treatment1, treatment2, "Clinical Meaningful Difference"))
      manual_colors <- setNames(c("#D55E00", "#0072B2", "black"), unique_trts)
      manual_shapes <- setNames(c(21, 24, 18), unique_trts)

      color_scale <- scale_color_manual(name = "", values = manual_colors)
      fill_scale <- scale_fill_manual(name = "", values = manual_colors)
      shape_scale <- scale_shape_manual(name = "", values = manual_shapes)

      # Define axis limits for forest plot
      x_min <- min(type_data$Diff_LowerCI, na.rm = TRUE)
      x_max <- max(type_data$Diff_UpperCI, na.rm = TRUE)
      x_range <- max(abs(x_min), abs(x_max))
      x_lim <- c(-x_range, x_range)

      # Dot plot
      dot_plot <- ggplot(dot_data) +
        geom_point(aes(y = Outcome, x = x, shape = Treatment, color = Treatment, fill = Treatment), size = 3) +
        scale_y_discrete(limits = y_levels) +
        color_scale + shape_scale + fill_scale +
        labs(x = if (is_last_plot) "Treatment Response" else NULL) +
        theme_minimal(base_family = "serif") +
        theme(
          panel.border = element_rect(color = "gray90", fill = NA, linewidth = 0.5),
          axis.title.y = element_blank(),
          axis.title.x = element_text(face = "bold"),
          legend.position = "bottom"
        )

      # Forest plot
      forest_plot <- ggplot() +
        geom_point(data = type_data,
                   aes(y = Outcome, x = Diff, color = CI_color, fill = CI_color),
                   size = 3) +
        geom_errorbarh(data = type_data,
                       aes(y = Outcome, xmin = Diff_LowerCI, xmax = Diff_UpperCI, color = CI_color),
                       height = 0.2) +
        scale_color_manual(values = c("green" = "forestgreen", "red" = "firebrick", "black" = "black", "Clinical Meaningful Difference" = "black")) +
        guides(color = "none") +
        geom_point(data = thresholds_with_treatment,
                   aes(x = Threshold, y = Outcome, color = Treatment, shape = Treatment, fill = Treatment),
                   size = 4) +
        geom_vline(xintercept = 0, linetype = "dashed", color = "black", linewidth = 0.5) +
        scale_y_discrete(limits = y_levels) +
        shape_scale + fill_scale +
        coord_cartesian(xlim = x_lim, clip = "off") +
        theme_minimal(base_family = "serif") +
        theme(
          panel.border = element_rect(color = "gray90", fill = NA, linewidth = 0.5),
          axis.title.y = element_blank(),
          axis.text.y = element_blank(),
          axis.ticks.y = element_blank(),
          legend.position = "bottom",
          plot.margin = unit(c(0.5, 0.5, 1.5, 0.5), "cm")
        ) +
        labs(x = if (is_last_plot)
          paste0("\u2190 Favours ", treatment2, "       Favours ", treatment1, " \u2192\n\nTreatment Difference with 95% CI")
          else NULL) +
        theme(axis.title.x = element_text(face = "bold"))

      combined_plot <- wrap_plots(dot_plot, forest_plot, ncol = 2, widths = c(1, 1))
      plots[[paste(factor, type, sep = "_")]] <- combined_plot
    }
  }

  # Assemble final plot
  wrap_plots(plots, ncol = 1) +
    plot_layout(guides = "collect") &
    theme(legend.position = "bottom")
}
