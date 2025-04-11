#' @name forest_dot_plot_imports
#' @title Internal package dependencies for forest and dot plots
#' @description Load required libraries for forest_dot_plot functionality
#' @keywords internal
# Load required libraries
library(dplyr)
library(ggplot2)
library(patchwork)
library(grid)
library(rlang)

#' Create Forest and Dot Plots for Treatment Effects
#'
#' @description Generates side-by-side forest and dot plots for
#' specified outcomes, grouped by factor and type. Displays
#' treatment effects, confidence intervals, and optional clinical
#' thresholds.
#'
#' @param data A data frame prepared using `prepare_forest_dot_data()`
#'   or with matching structure.
#' @param clin_thresholds Optional data frame with `Outcome` and
#'   `Threshold` columns for reference lines (defaults provided).
#' @param direction Optional character vector or single value indicating
#'   the direction of clinical significance for each outcome. Accepts
#'   `"greater"` or `"less"`. Can be a single value applied to all,
#'   a vector matching `clin_thresholds`, or a named vector by outcome.
#' @param outcomes_of_interest Character vector of outcomes to include
#'   (default includes major efficacy and safety endpoints).
#'   (default includes major efficacy and safety endpoints).
#' @param treatment1 Character; label of the first treatment group
#'   (default: `"Drug A"`).
#' @param treatment2 Character; label of the second treatment group
#'   (default: `"Placebo"`).
#' @param filter_value Character; value used to filter the `Filter` column
#'   (default: `"None"`).
#' @param precalculated_stats Logical; if `TRUE`, skips calculation and uses
#'   provided statistics.
#' @param forest_upper_limit Numeric; optional upper limit for the forest
#'   plot, adds a reference line at this value if provided.
#'
#' @return A patchwork object containing combined dot and forest plots with a
#'   shared legend.
#'
#' @import ggplot2
#' @importFrom dplyr %>% filter mutate case_when if_else arrange bind_rows
#' @importFrom patchwork wrap_plots plot_layout
#' @importFrom stats qt qnorm setNames df
#' @importFrom utils tail
#' @importFrom grid unit
#' @importFrom rlang .data
#' @importFrom ggtext element_markdown
#'
#' @export
#'
#' @examples
#' \donttest{
#' # First, prepare the data
#' prepared_data <- prepare_forest_dot_data(effects_table)
#'
#' # Generate the plot
#' dotforest <- create_forest_dot_plot(prepared_data)
#' ggsave_custom("dotforest.png", imgpath = "./", inplot = dotforest, dpi = 300)
#'
#' # With clinical thresholds
#' thresholds <- data.frame(
#'   Outcome = c("Benefit 1", "Benefit 2"),
#'   Threshold = c(0.10, 0.08),
#'   Direction = c("greater", "greater")
#' )
#' create_forest_dot_plot(prepared_data,
#'   outcomes_of_interest = c(
#'     "Benefit 1",
#'     "Benefit 2"
#'   ),
#'   clin_thresholds = thresholds
#' )
#' }
create_forest_dot_plot <- function(
    data,
    clin_thresholds = NULL,
    direction = NULL,
    outcomes_of_interest = c(
      "Benefit 1",
      "Benefit 2",
      "Benefit 3",
      "Risk 1",
      "Risk 2"
    ),
    treatment1 = "Drug A",
    treatment2 = "Placebo",
    filter_value = "None",
    precalculated_stats = FALSE,
    forest_upper_limit = NULL) { # Define arrow symbols to avoid issues with LaTeX documentation
  # Use UTF-8 encoded Unicode arrows for proper display in all contexts
  left_arrow <- "\u2190" # ← (leftwards arrow)
  right_arrow <- "\u2192" # → (rightwards arrow)
  spacing <- "                    "
  # Set up default clinical thresholds
  default_thresholds <- data.frame(
    Outcome = c(
      "Benefit 1",
      "Benefit 2",
      "Benefit 3",
      "Risk 1",
      "Risk 2"
    ),
    Threshold = c(0.10, 0.08, 5, -0.10, -0.05),
    Direction = c("greater", "greater", "greater", "less", "less"),
    stringsAsFactors = FALSE
  )

  # Process clinical thresholds
  if (is.null(clin_thresholds)) {
    clin_thresholds <- default_thresholds
  } else {
    # Add Direction from argument if supplied
    if (!is.null(direction)) {
      if (is.character(direction) && length(direction) == 1) {
        # Single direction applied to all
        clin_thresholds$Direction <- direction
      } else if (
        is.character(direction) && length(direction) == nrow(clin_thresholds)
      ) {
        clin_thresholds$Direction <- direction
      } else {
        warning(
          "Invalid 'direction' argument: must be a single value or match",
          " the number of rows in clin_thresholds."
        )
      }
    } else if (!"Direction" %in% names(clin_thresholds)) {
      # Use defaults for missing directions
      clin_thresholds <- merge(
        clin_thresholds,
        default_thresholds[, c("Outcome", "Direction")],
        by = "Outcome",
        all.x = TRUE
      )
    }
  }

  # Prepare data
  filtered_data <- prepare_forest_dot_data(
    data,
    outcomes_of_interest,
    treatment1,
    treatment2,
    filter_value,
    precalculated_stats
  )

  plots <- list()
  plot_outcome_counts <- c() # Store number of outcomes for each plot
  factors <- unique(filtered_data$Factor)

  # Loop through factors and types to create plots
  for (factor in factors) {
    factor_data <- filtered_data %>% dplyr::filter(Factor == factor)
    types <- unique(factor_data$Type)

    for (type in types) {
      # Check if this is the last plot (for legend and x-axis title display)
      is_last_plot <- (factor == tail(factors, 1) && type == tail(types, 1))

      # Filter data for current type
      type_data <- factor_data %>% dplyr::filter(Type == type)

      # Determine estimate column names based on type
      estimate1 <- if (type == "Binary") "Prop1" else "Mean1"
      estimate2 <- if (type == "Binary") "Prop2" else "Mean2"
      y_levels <- rev(unique(type_data$Outcome))

      # Create data for dot plot
      dot_data <- dplyr::bind_rows(
        data.frame(
          Outcome = type_data$Outcome,
          x = type_data[[estimate1]],
          Treatment = treatment1
        ),
        data.frame(
          Outcome = type_data$Outcome,
          x = type_data[[estimate2]],
          Treatment = treatment2
        )
      ) %>%
        dplyr::filter(!is.na(x))

      # Create data for clinical thresholds
      thresholds_with_treatment <- clin_thresholds %>%
        dplyr::filter(Outcome %in% type_data$Outcome) %>%
        dplyr::mutate(Treatment = "Clinical Threshold")

      # Prepare data for shaded regions
      shade_data <- thresholds_with_treatment %>%
        dplyr::mutate(
          xmin = dplyr::if_else(Direction == "greater", Threshold, -Inf),
          xmax = dplyr::if_else(Direction == "greater", Inf, Threshold),
          ymin = as.numeric(factor(Outcome, levels = y_levels)) - 0.4,
          ymax = as.numeric(factor(Outcome, levels = y_levels)) + 0.4,
          FillGroup = dplyr::if_else(Direction == "greater", "Benefit", "Risk")
        )

      # Dummy data for legend
      dummy_legend <- data.frame(
        xmin = -Inf,
        xmax = -Inf,
        ymin = -Inf,
        ymax = -Inf,
        FillGroup = c("Benefit", "Risk")
      )

      # Set up color and shape scales
      manual_fill_colors <- c("Benefit" = "lightgreen", "Risk" = "lightcoral")
      unique_trts <- unique(c(treatment1, treatment2, "Clinical Threshold"))
      # Use hollow circle (5) for Clinical Threshold
      manual_shapes <- setNames(c(21, 24, 5), unique_trts)
      manual_colors <- setNames(c("#D55E00", "#0072B2", "black"), unique_trts)
      manual_fills <- setNames(
        c("#D55E00", "#0072B2", "gray85", "black"),
        c(
          treatment1,
          treatment2,
          "Clinically Meaningful Difference",
          "Clinical Threshold"
        )
      )

      # Create scales
      color_scale <- scale_color_manual(name = "", values = manual_colors)
      shape_scale <- scale_shape_manual(name = "", values = manual_shapes)
      fill_scale <- scale_fill_manual(
        name = "",
        values = manual_fills,
        breaks = c(
          treatment1,
          treatment2,
          "Clinical Threshold",
          "Clinically Meaningful Difference"
        )
      )

      # Calculate x-axis limits for forest plot
      x_min <- min(type_data$Diff_LowerCI, na.rm = TRUE)
      x_max <- max(type_data$Diff_UpperCI, na.rm = TRUE)
      x_range <- max(abs(x_min), abs(x_max))
      x_lim <- c(-x_range, x_range)

      # Set up x-axis breaks for forest plot
      forest_breaks <- pretty(x_lim, n = 5)
      # Ensure forest_upper_limit is included as a tick if specified
      if (!is.null(forest_upper_limit)) {
        # Expand x_lim if needed
        if (forest_upper_limit > max(x_lim)) {
          x_lim[2] <- forest_upper_limit
        }
        # Always set the last break to forest_upper_limit
        forest_breaks <- forest_breaks[forest_breaks <= x_lim[2]]
        if (tail(forest_breaks, 1) != forest_upper_limit) {
          forest_breaks <- c(forest_breaks, forest_upper_limit)
        }
        # Add an extra interval to ensure a tick after the plotted points
        interval <- if (length(forest_breaks) > 1) {
          diff(tail(forest_breaks, 2))
        } else {
          1
        }
        extra_tick <- forest_upper_limit + interval
        forest_breaks <- c(forest_breaks, extra_tick)
        x_lim[2] <- extra_tick
      }

      # Find the maximum value across all dot plots in the same factor/type
      max_x_value <- max(dot_data$x, na.rm = TRUE)

      # Round up the maximum value to a nice number
      # Add a small buffer to ensure we do not cut off points
      max_x_value <- max_x_value * 1.05

      # Create breaks with more intuitive intervals based on rounded max value
      # Ensure there is always a tick mark after the last data point
      if (length(dot_data$x) == 0 || max_x_value <= 0) {
        # Handle edge case of empty data or zero/negative max values
        max_x_value <- 1
        dot_breaks <- c(0, 0.2, 0.4, 0.6, 0.8, 1.0)
      } else if (max_x_value <= 0.05) {
        # Round up to nearest 0.01
        max_x_value <- ceiling(max_x_value * 100) / 100
        dot_breaks <- seq(0, max_x_value, by = 0.01)
      } else if (max_x_value <= 0.2) {
        # Round up to nearest 0.05
        max_x_value <- ceiling(max_x_value * 20) / 20
        dot_breaks <- seq(0, max_x_value, by = 0.05)
      } else if (max_x_value <= 0.5) {
        # Round up to nearest 0.1
        max_x_value <- ceiling(max_x_value * 10) / 10
        dot_breaks <- seq(0, max_x_value, by = 0.1)
      } else if (max_x_value <= 1) {
        # Round up to nearest 0.2
        max_x_value <- ceiling(max_x_value * 5) / 5
        dot_breaks <- seq(0, max_x_value, by = 0.2)
      } else if (max_x_value <= 2) {
        # Round up to nearest 0.5
        max_x_value <- ceiling(max_x_value * 2) / 2
        dot_breaks <- seq(0, max_x_value, by = 0.5)
      } else if (max_x_value <= 5) {
        max_x_value <- ceiling(max_x_value)
        dot_breaks <- seq(0, max_x_value, by = 1)
      } else if (max_x_value <= 10) {
        # Round up to nearest 2
        max_x_value <- ceiling(max_x_value / 2) * 2
        dot_breaks <- seq(0, max_x_value, by = 2)
      } else if (max_x_value <= 20) {
        # Round up to nearest 5
        max_x_value <- ceiling(max_x_value / 5) * 5
        dot_breaks <- seq(0, max_x_value, by = 5)
      } else if (max_x_value <= 50) {
        # Round up to nearest 10
        max_x_value <- ceiling(max_x_value / 10) * 10
        dot_breaks <- seq(0, max_x_value, by = 10)
      } else if (max_x_value <= 100) {
        # Round up to nearest 20
        max_x_value <- ceiling(max_x_value / 20) * 20
        dot_breaks <- seq(0, max_x_value, by = 20)
      } else {
        power <- floor(log10(max_x_value))
        base <- 10^(power - 1)
        if (max_x_value <= 5 * 10^power) {
          interval <- base * 10
        } else {
          interval <- base * 20
        }
        max_x_value <- ceiling(max_x_value / interval) * interval
        dot_breaks <- seq(0, max_x_value, by = interval)
      }

      # Always add a tick after the last CI bound for forest plot
      max_ci <- max(type_data$Diff_UpperCI, na.rm = TRUE)
      min_ci <- min(type_data$Diff_LowerCI, na.rm = TRUE)
      if (length(forest_breaks) > 1) {
        interval <- forest_breaks[2] - forest_breaks[1]
        last_tick <- max(forest_breaks)
        if (last_tick <= max_ci) {
          forest_breaks <- c(forest_breaks, last_tick + interval)
          x_lim[2] <- last_tick + interval
        }
        # Also check lower bound for symmetry
        first_tick <- min(forest_breaks)
        if (first_tick >= min_ci) {
          forest_breaks <- c(first_tick - interval, forest_breaks)
          x_lim[1] <- first_tick - interval
        }
      }

      # After all forest_breaks are finalized, ensure x_lim[2] matches the
      # last tick
      if (length(forest_breaks) > 1) {
        x_lim[2] <- max(forest_breaks)
        x_lim[1] <- min(forest_breaks)
      }

      # Create dot plot with intuitive breaks
      dot_plot <- ggplot(dot_data) +
        geom_point(
          aes(
            y = Outcome,
            x = x,
            shape = Treatment,
            color = Treatment,
            fill = Treatment
          ),
          size = 3
        ) +
        scale_y_discrete(limits = y_levels) +
        scale_x_continuous(
          limits = c(0, max(dot_breaks)),
          breaks = dot_breaks,
          labels = function(x) {
            # Custom function to format numbers with minimal decimal places
            if (length(x) == 0) {
              return(character(0))
            }
            format(x, nsmall = 0, trim = TRUE)
          }
        ) +
        color_scale +
        shape_scale +
        fill_scale +
        labs(x = if (is_last_plot) "<br>Treatment Response" else NULL) +
        theme_minimal(base_family = "sans") +
        theme(
          panel.border = element_rect(
            color = "gray90",
            fill = NA,
            linewidth = 0.5
          ),
          axis.title.y = element_blank(),
          axis.title.x = if (is_last_plot) {
            ggtext::element_markdown(face = "bold", color = "black")
          } else {
            element_text(face = "bold", color = "black")
          },
          legend.position = if (is_last_plot) "bottom" else "none",
          axis.text.y = element_blank(), # Remove y-axis labels from dot plot
          axis.ticks.y = element_blank(), # Remove y-axis ticks from dot plot
          plot.margin = unit(c(0.2, 0.2, 0.2, 0.2), "cm")
        )

      # Create forest plot
      forest_plot <- ggplot() +
        # Add shaded regions for clinical meaning
        geom_rect(
          data = dummy_legend,
          aes(
            xmin = xmin,
            xmax = xmax,
            ymin = ymin,
            ymax = ymax,
            fill = FillGroup
          ),
          inherit.aes = FALSE,
          show.legend = FALSE
        ) +
        geom_rect(
          data = shade_data,
          aes(
            xmin = xmin,
            xmax = xmax,
            ymin = ymin,
            ymax = ymax,
            fill = FillGroup
          ),
          alpha = 0.3,
          inherit.aes = FALSE,
          show.legend = FALSE
        ) +
        scale_fill_manual(
          values = manual_fill_colors,
          guide = "none"
        ) +
        # Add points and error bars for treatment differences
        geom_point(
          data = type_data,
          aes(y = Outcome, x = Diff),
          color = "black",
          fill = "black",
          size = 3
        ) +
        geom_errorbarh(
          data = type_data,
          aes(y = Outcome, xmin = Diff_LowerCI, xmax = Diff_UpperCI),
          color = "black",
          height = 0.2
        ) +
        # Add threshold points
        geom_point(
          data = thresholds_with_treatment,
          aes(x = Threshold, y = Outcome, shape = Treatment),
          color = "black",
          fill = NA, # hollow symbol
          size = 3,
          stroke = 1 # make outline thicker for visibility
        ) +
        # Add reference line at zero
        geom_vline(
          xintercept = 0,
          linetype = "dashed",
          color = "black",
          linewidth = 0.5
        ) +
        # Apply scales and coordinate system
        scale_color_manual(
          values = c(
            "green" = "forestgreen",
            "red" = "firebrick",
            "black" = "black",
            "Clinical Threshold" = "black"
          ),
          guide = "none"
        ) +
        guides(
          shape = guide_legend(override.aes = list(bg = "white"))
        ) +
        scale_y_discrete(limits = y_levels) +
        shape_scale +
        coord_cartesian(xlim = x_lim, clip = "off") +
        scale_x_continuous(limits = x_lim, breaks = forest_breaks) + # Add x-axis label for last plot
        labs(
          x = if (is_last_plot) {
            paste0(
              "<br>",
              "<span style='color:black;font-weight:bold;'>",
              left_arrow, " Favours ",
              treatment2,
              "</span>",
              spacing,
              "<span style='color:black;font-weight:bold;'>Favours ",
              treatment1,
              " ", right_arrow, "</span>",
              "<br>",
              "Treatment Difference with 95% CI"
            )
          } else {
            NULL
          }
        ) +
        # Apply theme
        theme_minimal() +
        theme(
          legend.key = element_rect(fill = "white", color = NA),
          panel.border = element_rect(
            color = "gray90",
            fill = NA,
            linewidth = 0.5
          ),
          axis.title.y = element_blank(),
          axis.text.y = element_text(), # Show y-axis labels on forest plot
          axis.ticks.y = element_line(), # Show y-axis ticks on forest plot
          axis.title.x = if (is_last_plot) {
            ggtext::element_markdown(color = "black", face = "bold")
          } else {
            element_blank()
          },
          axis.text.x = element_text(color = "black"),
          # Only show legend on last plot
          legend.position = if (is_last_plot) "bottom" else "none",
          plot.margin = unit(c(0.2, 0.2, 0.2, 0.2), "cm")
        )

      # Combine forest and dot plots (forest on left, dot on right)
      combined_plot <- wrap_plots(
        forest_plot,
        dot_plot,
        ncol = 2,
        widths = c(1, 1)
      ) +
        theme(
          # Reduced bottom margin
          plot.margin = unit(c(0.3, 0.2, 0.1, 0.2), "cm"),
          axis.title.x = if (is_last_plot) {
            ggtext::element_markdown(color = "black", face = "bold")
          } else {
            element_blank()
          }
        )

      # Store combined plot
      plots[[paste(factor, type, sep = "_")]] <- combined_plot
      # Store number of outcomes for this plot
      plot_outcome_counts <- c(plot_outcome_counts, length(y_levels))
    }
  }

  # Set min and max height to avoid too tall/short plots
  min_height <- 1
  max_height <- 3
  heights <- pmax(min_height, pmin(sqrt(plot_outcome_counts), max_height))

  # Combine all plots vertically, resizing according to number of outcomes
  # (with limits)
  final_plot_assembly <- wrap_plots(plots, ncol = 1, heights = heights)

  return(final_plot_assembly)
}
