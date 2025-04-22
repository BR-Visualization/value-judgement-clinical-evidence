#' Create Forest and Dot Plots for Treatment Effects
#'
#' @description
#' Generates side-by-side forest and dot plots for specified outcomes, grouped by factor and type.
#' Displays treatment effects, confidence intervals, and optional clinical thresholds.
#'
#' @param data A data frame prepared using `prepare_forest_dot_data()` or with matching structure.
#' @param clin_thresholds Optional data frame with `Outcome` and `Threshold` columns for reference lines (defaults provided).
#' @param direction Optional character vector or single value indicating the direction of clinical significance for each outcome.
#'   Accepts `"greater"` or `"less"`. Can be a single value applied to all, a vector matching `clin_thresholds`, or a named vector by outcome.
#' @param outcomes_of_interest Character vector of outcomes to include (default includes major efficacy and safety endpoints).
#' @param treatment1 Character; label of the first treatment group (default: `"Drug A"`).
#' @param treatment2 Character; label of the second treatment group (default: `"Placebo"`).
#' @param filter_value Character; value used to filter the `Filter` column (default: `"None"`).
#' @param precalculated_stats Logical; if `TRUE`, skips calculation and uses provided statistics.
#'
#' @return A patchwork object containing combined dot and forest plots with a shared legend.
#'
#' @importFrom dplyr %>% filter mutate case_when if_else arrange bind_rows
#' @importFrom ggplot2 ggplot aes geom_point geom_errorbarh geom_vline labs theme theme_minimal element_text element_blank element_rect geom_rect
#' @importFrom ggplot2 scale_color_manual scale_fill_manual scale_shape_manual scale_y_discrete coord_cartesian guides guide_legend
#' @importFrom patchwork wrap_plots plot_layout
#' @importFrom stats qt qnorm setNames df
#' @importFrom utils tail
#' @importFrom grid unit
#' @importFrom rlang .data
#'
#' @export
#'
#' @examples
#' # First, prepare the data
#' prepared_data <- prepare_forest_dot_data(effects_table)
#'
#' # Generate the plot
#' create_forest_dot_plot(prepared_data)
#'
#' # With clinical thresholds
#' thresholds <- data.frame(
#'   Outcome = c("Primary Efficacy", "Secondary Efficacy"),
#'   Threshold = c(0.10, 0.08),
#'   Direction = c("greater", "greater")
#' )
#' create_forest_dot_plot(prepared_data,
#'   outcomes_of_interest = c(
#'     "Primary Efficacy",
#'     "Secondary Efficacy"
#'   ),
#'   clin_thresholds = thresholds
#' )
create_forest_dot_plot <- function(data,
                                   clin_thresholds = NULL,
                                   direction = NULL,
                                   outcomes_of_interest = c(
                                     "Primary Efficacy", "Secondary Efficacy",
                                     "HR Quality of Life", "Reoccurring AE", "Rare SAE"
                                   ),
                                   treatment1 = "Drug A",
                                   treatment2 = "Placebo",
                                   filter_value = "None",
                                   precalculated_stats = FALSE) {
  default_thresholds <- data.frame(
    Outcome = c("Primary Efficacy", "Secondary Efficacy", "HR Quality of Life", "Reoccurring AE", "Rare SAE"),
    Threshold = c(0.10, 0.08, 5, -0.10, -0.05),
    Direction = c("greater", "greater", "greater", "less", "less"),
    stringsAsFactors = FALSE
  )

  if (is.null(clin_thresholds)) {
    clin_thresholds <- default_thresholds
  } else {
    # Add Direction from argument if supplied
    if (!is.null(direction)) {
      if (is.character(direction) && length(direction) == 1) {
        # Single direction applied to all
        clin_thresholds$Direction <- direction
      } else if (is.character(direction) && length(direction) == nrow(clin_thresholds)) {
        clin_thresholds$Direction <- direction
      } else {
        warning("Invalid 'direction' argument: must be a single value or match the number of rows in clin_thresholds.")
      }
    } else if (!"Direction" %in% names(clin_thresholds)) {
      # Use defaults for missing directions
      clin_thresholds <- merge(clin_thresholds, default_thresholds[, c("Outcome", "Direction")], by = "Outcome", all.x = TRUE)
    }
  }


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

      estimate1 <- if (type == "Binary") "Prop1" else "Mean1"
      estimate2 <- if (type == "Binary") "Prop2" else "Mean2"
      y_levels <- rev(unique(type_data$Outcome))

      dot_data <- bind_rows(
        data.frame(Outcome = type_data$Outcome, x = type_data[[estimate1]], Treatment = treatment1),
        data.frame(Outcome = type_data$Outcome, x = type_data[[estimate2]], Treatment = treatment2)
      ) %>% filter(!is.na(x))

      thresholds_with_treatment <- clin_thresholds %>%
        filter(Outcome %in% type_data$Outcome) %>%
        mutate(Treatment = "Clinical Threshold")

      # Shaded region data
      shade_data <- thresholds_with_treatment %>%
        mutate(
          ymin = as.numeric(factor(Outcome, levels = y_levels)) - 0.4,
          ymax = as.numeric(factor(Outcome, levels = y_levels)) + 0.4,
          xmin = if_else(Direction == "greater", Threshold, -Inf),
          xmax = if_else(Direction == "greater", Inf, Threshold),
          FillGroup = "Clinically Meaningful Difference"
        )

      # Dummy rect for legend
      dummy_legend <- data.frame(
        xmin = -Inf, xmax = -Inf, ymin = -Inf, ymax = -Inf,
        FillGroup = "Clinically Meaningful Difference"
      )

      unique_trts <- unique(c(treatment1, treatment2, "Clinical Threshold"))
      manual_colors <- setNames(c("#D55E00", "#0072B2", "black"), unique_trts)
      manual_shapes <- setNames(c(21, 24, 18), unique_trts)
      manual_fills <- setNames(c("#D55E00", "#0072B2", "gray85", "black"), c(treatment1, treatment2, "Clinically Meaningful Difference", "Clinical Threshold"))

      color_scale <- scale_color_manual(name = "", values = manual_colors)
      shape_scale <- scale_shape_manual(name = "", values = manual_shapes)
      fill_scale <- scale_fill_manual(
        name = "",
        values = manual_fills,
        breaks = c(treatment1, treatment2, "Clinical Threshold", "Clinically Meaningful Difference")
      )

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
          legend.position = "bottom",
          plot.margin = unit(c(0.2, 0.2, 0.2, 0.2), "cm")
        )

      # Forest plot
      forest_plot <- ggplot() +
        geom_rect( # Legend dummy
          data = dummy_legend,
          aes(xmin = xmin, xmax = xmax, ymin = ymin, ymax = ymax, fill = FillGroup),
          inherit.aes = FALSE, show.legend = TRUE
        ) +
        geom_rect( # Actual shading
          data = shade_data,
          aes(xmin = xmin, xmax = xmax, ymin = ymin, ymax = ymax, fill = FillGroup),
          alpha = 0.3, inherit.aes = FALSE, show.legend = FALSE
        ) +
        geom_point(
          data = type_data,
          aes(y = Outcome, x = Diff, color = CI_color, fill = CI_color),
          size = 3
        ) +
        geom_errorbarh(
          data = type_data,
          aes(y = Outcome, xmin = Diff_LowerCI, xmax = Diff_UpperCI, color = CI_color),
          height = 0.2
        ) +
        scale_color_manual(values = c("green" = "forestgreen", "red" = "firebrick", "black" = "black", "Clinical Threshold" = "black")) +
        guides(color = "none",
               shape = guide_legend(override.aes = list(bg = "white"))) +
        geom_point(
          data = thresholds_with_treatment,
          aes(x = Threshold, y = Outcome, shape = Treatment),
          size = 4
        ) +
        # guides(fill = "none") +
        geom_vline(xintercept = 0, linetype = "dashed", color = "black", linewidth = 0.5) +
        scale_y_discrete(limits = y_levels) +
        shape_scale + fill_scale +
        coord_cartesian(xlim = x_lim, clip = "off") +
        theme_minimal(base_family = "serif") +
        theme(
          legend.key = element_rect(fill = "white", color = NA),
          panel.border = element_rect(color = "gray90", fill = NA, linewidth = 0.5),
          axis.title.y = element_blank(),
          axis.text.y = element_blank(),
          axis.ticks.y = element_blank(),
          legend.position = "bottom",
          plot.margin = unit(c(0.2, 0.2, 0.2, 0.2), "cm")
        ) +
        labs(x = if (is_last_plot) {
          paste0(
            "<span style='color:firebrick;font-weight:bold;'>&larr; Favours ", treatment2, "</span>",
            "\u2003\u2003\u2003\u2003\u2003\u2003\u2003\u2003\u2003\u2003",
            "<span style='color:forestgreen;font-weight:bold;'>Favours ", treatment1, " &rarr;</span>",
            "<br><br>",
            "Treatment Difference with 95% CI"
          )
        } else NULL) +
        theme(axis.title.x = ggtext::element_markdown(face = "bold"))

      combined_plot <- wrap_plots(dot_plot, forest_plot, ncol = 2, widths = c(1, 1)) +
        plot_layout(heights = c(1))

      plots[[paste(factor, type, sep = "_")]] <- combined_plot
    }
  }

  wrap_plots(plots, ncol = 1) +
    plot_layout(guides = "collect") &
    theme(
      legend.position = "bottom",
      plot.margin = unit(c(0.3, 0.2, 0.3, 0.2), "cm")
    )
}
