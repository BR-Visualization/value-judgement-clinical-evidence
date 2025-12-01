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
#' **AXIS REVERSAL**: For benefit outcomes with clinical meaningful
#' difference direction = "less", the x-axis automatically reverses
#' (positive values on left, negative on right) and green shading
#' extends towards decreasing x values. This handles cases where
#' lower values indicate better outcomes (e.g., cholesterol reduction).
#'
#' @param data A data frame prepared using `prepare_forest_dot_data()`
#'   or with matching structure.
#' @param outcomes_with_thresholds Either NULL (uses all available
#'   outcomes with no thresholds), a character vector of outcome names
#'   to include (with no thresholds), or a named list where names are
#'   outcomes and values are thresholds. For lists, directions default
#'   to "greater" for positive values and "less" for negative values,
#'   or can be specified as list(outcome = list(threshold = 0.1,
#'   direction = "greater")).
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
#' # First, prepare the data
#' prepared_data <- prepare_forest_dot_data(effects_table)
#'
#' # Generate the plot using all available outcomes with no thresholds
#' dotforest <- create_forest_dot_plot(prepared_data)
#' \dontrun{
#' ggsave_custom("dotforest.png", imgpath = "./", inplot = dotforest, dpi = 300)
#' }
#'
#' # Use only specific outcomes with no thresholds
#' create_forest_dot_plot(prepared_data,
#'   outcomes_with_thresholds = c("Benefit 1", "Benefit 2")
#' )
#'
#' # Custom thresholds with automatic direction detection
#' dotforest_4pub <- create_forest_dot_plot(prepared_data,
#'   outcomes_with_thresholds = list(
#'     "Benefit 1" = 0.10,
#'     "Benefit 2" = -20,
#'     "Risk 1" = -0.05,
#'     "Risk 2" = -0.07
#'   )
#' )
#'
#' \dontrun{
#' ggsave_custom("inst/img/dotforest.png",
#'   imgpath = "./",
#'   inplot = dotforest_4pub, dpi = 300
#' )
#' }
#'
#' # Custom thresholds with explicit directions
#' create_forest_dot_plot(prepared_data,
#'   outcomes_with_thresholds = list(
#'     "Benefit 1" = list(threshold = 0.10, direction = "greater"),
#'     "Risk 1" = list(threshold = -0.05, direction = "less")
#'   )
#' )
#'
#' # AXIS REVERSAL: Benefit outcomes with direction "less"
#' # When benefit outcomes have clinical meaningful difference
#' # direction = "less", the x-axis reverses (positive left, negative right)
#' # and green shading
#' # extends towards negative values (decreasing x direction)
#' create_forest_dot_plot(prepared_data,
#'   outcomes_with_thresholds = list(
#'     "Benefit 1" = list(threshold = -0.15, direction = "less"),
#'     "Benefit 2" = list(threshold = -0.10, direction = "less")
#'   )
#' )
#'
#' # Example: Lower cholesterol levels are better (benefit with negative
#' # direction)
#' # Treatment difference: Drug A - Placebo = -20 mg/dL (Drug A better)
#' # Clinical threshold: -15 mg/dL with direction "less" (values < -15 are
#' # meaningful)
#' # Result: X-axis reverses, green shading extends towards negative values
create_forest_dot_plot <- function(
  data,
  outcomes_with_thresholds = NULL,
  treatment1 = "Drug A",
  treatment2 = "Placebo",
  filter_value = "None",
  precalculated_stats = FALSE,
  forest_upper_limit = NULL
) {
  # Define arrow symbols to avoid issues with LaTeX documentation
  # Use UTF-8 encoded Unicode arrows for proper display in all contexts
  left_arrow <- "\u2190" # ← (leftwards arrow)
  right_arrow <- "\u2192" # → (rightwards arrow)
  spacing <- "                    "

  # Process outcomes and thresholds from combined parameter
  show_thresholds <- FALSE # Flag to track whether to show thresholds

  if (is.null(outcomes_with_thresholds)) {
    # Default: use all available outcomes from the data, no thresholds
    if ("Outcome" %in% names(data)) {
      available_outcomes <- unique(data$Outcome)
      # Use all available outcomes
      outcomes_of_interest <- available_outcomes
      # Create empty thresholds data frame (no thresholds shown)
      clin_thresholds <- data.frame(
        Outcome = character(0),
        Threshold = numeric(0),
        Direction = character(0),
        stringsAsFactors = FALSE
      )
    } else {
      stop(
        paste(
          "No 'Outcome' col found in data.",
          "Specify outcomes_with_thresholds."
        )
      )
    }
  } else if (is.character(outcomes_with_thresholds)) {
    # Simple character vector - no thresholds shown for this case either
    outcomes_of_interest <- outcomes_with_thresholds
    # Create empty thresholds data frame (no thresholds shown)
    clin_thresholds <- data.frame(
      Outcome = character(0),
      Threshold = numeric(0),
      Direction = character(0),
      stringsAsFactors = FALSE
    )
  } else if (is.list(outcomes_with_thresholds)) {
    # List format - extract outcomes and build thresholds, show thresholds
    show_thresholds <- TRUE
    outcomes_of_interest <- names(outcomes_with_thresholds)

    # Debug: Check if outcomes_of_interest is NULL or empty
    if (
      is.null(outcomes_of_interest) ||
        length(outcomes_of_interest) == 0
    ) {
      stop(
        "outcomes_with_thresholds list must have named elements."
      )
    }

    # Convert list to data frame
    threshold_df <- data.frame(
      Outcome = character(0),
      Threshold = numeric(0),
      Direction = character(0),
      stringsAsFactors = FALSE
    )

    for (outcome_name in names(outcomes_with_thresholds)) {
      threshold_value <- outcomes_with_thresholds[[outcome_name]]

      if (is.list(threshold_value)) {
        thresh <- if (!is.null(threshold_value$threshold)) {
          threshold_value$threshold
        } else if (!is.null(threshold_value$Threshold)) {
          threshold_value$Threshold
        } else {
          stop(
            "Threshold value must be specified for outcome: ",
            outcome_name
          )
        }

        direction <- if (!is.null(threshold_value$direction)) {
          threshold_value$direction
        } else if (!is.null(threshold_value$Direction)) {
          threshold_value$Direction
        } else {
          # Default direction based on threshold sign if not specified
          if (thresh >= 0) "greater" else "less"
        }
      } else {
        thresh <- threshold_value
        # Default direction based on threshold sign
        direction <- if (thresh >= 0) "greater" else "less"
      }

      threshold_df <- rbind(
        threshold_df,
        data.frame(
          Outcome = outcome_name,
          Threshold = thresh,
          Direction = direction,
          stringsAsFactors = FALSE
        )
      )
    }

    clin_thresholds <- threshold_df
  } else {
    stop(
      paste(
        "outcomes_with_thresholds must be either NULL,",
        "a character vector, or a named list"
      )
    )
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

  # Check if we have any data after filtering
  if (nrow(filtered_data) == 0) {
    # Get available outcomes from the original data to help with debugging
    available_outcomes <- if ("Outcome" %in% names(data)) {
      unique(data$Outcome)
    } else {
      "Column 'Outcome' not found in data"
    }

    stop(paste0(
      "No data found for the specified outcomes: ",
      paste(outcomes_of_interest, collapse = ", "),
      "\n",
      "Available outcomes in data: ",
      paste(available_outcomes, collapse = ", "),
      "\n",
      "Please check that the outcome names match those in your data."
    ))
  }

  plots <- list()
  plot_outcome_counts <- numeric(0) # Store number of outcomes for each plot
  factors <- unique(filtered_data$Factor)

  # Loop through factors and types to create plots
  for (factor in factors) {
    factor_data <- filtered_data %>% dplyr::filter(Factor == factor)
    types <- unique(factor_data$Type)

    for (type in types) {
      # Check if this is the last plot (for legend and x-axis title
      # display)
      is_last_plot <- (
        factor == tail(factors, 1) && type == tail(types, 1)
      )

      # Filter data for current type
      type_data <- factor_data %>% dplyr::filter(Type == type)

      # Skip if no data for this factor/type combination
      if (nrow(type_data) == 0) {
        next
      }

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

      # Create data for clinical thresholds (only if thresholds should be shown)
      if (show_thresholds && nrow(clin_thresholds) > 0) {
        thresholds_with_treatment <- clin_thresholds %>%
          dplyr::filter(Outcome %in% type_data$Outcome) %>%
          dplyr::mutate(Treatment = "Clinical Threshold")

        # Prepare data for shaded regions
        # Create a lookup for outcomes that need reverse axis
        benefit_outcomes_reverse <- type_data$Outcome[
          type_data$Factor == "Benefit"
        ]

        shade_data <- thresholds_with_treatment %>%
          dplyr::mutate(
            # Check if axis should be reversed for this outcome
            outcome_needs_reverse = Outcome %in%
              benefit_outcomes_reverse &
              Direction == "less",
            # Adjust shading based on axis direction
            xmin = dplyr::case_when(
              # Standard axis
              Direction == "greater" & !outcome_needs_reverse ~ Threshold,
              Direction == "less" & !outcome_needs_reverse ~ -Inf,
              # Reversed axis (benefit + direction "less")
              # For "greater" on reversed axis, shade from -Inf to threshold
              Direction == "greater" & outcome_needs_reverse ~ -Inf,
              # For "less" on reversed axis, shade from -Inf to threshold
              Direction == "less" & outcome_needs_reverse ~ -Inf,
              TRUE ~ -Inf
            ),
            xmax = dplyr::case_when(
              # Standard axis
              Direction == "greater" & !outcome_needs_reverse ~ Inf,
              Direction == "less" & !outcome_needs_reverse ~ Threshold,
              # Reversed axis (benefit + direction "less")
              # For "greater" on reversed axis, shade to +Inf
              # (but this shouldn't happen for benefit outcomes)
              Direction == "greater" & outcome_needs_reverse ~ Inf,
              # For "less" on reversed axis, shade to threshold
              # (meaningful region)
              Direction == "less" & outcome_needs_reverse ~ Threshold,
              TRUE ~ Inf
            ),
            ymin = as.numeric(factor(Outcome, levels = y_levels)) - 0.4,
            ymax = as.numeric(factor(Outcome, levels = y_levels)) + 0.4,
            # Keep benefit areas green, risk areas red
            FillGroup = dplyr::case_when(
              # For benefit outcomes, the clinically meaningful area
              # should be green
              Outcome %in% benefit_outcomes_reverse ~ "Benefit",
              # For risk outcomes, the clinically meaningful area
              # should be red
              Outcome %in% (
                type_data$Outcome[type_data$Factor == "Risk"]
              ) ~ "Risk",
              # Fallback to direction-based logic
              Direction == "greater" ~ "Benefit",
              TRUE ~ "Risk"
            )
          )
      } else {
        # No thresholds to show
        thresholds_with_treatment <- data.frame(
          Outcome = character(0),
          Threshold = numeric(0),
          Direction = character(0),
          Treatment = character(0),
          stringsAsFactors = FALSE
        )
        shade_data <- data.frame(
          xmin = numeric(0),
          xmax = numeric(0),
          ymin = numeric(0),
          ymax = numeric(0),
          FillGroup = character(0),
          stringsAsFactors = FALSE
        )
      }

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

      # Create scales only for treatments that are actually used
      if (show_thresholds && nrow(thresholds_with_treatment) > 0) {
        # With thresholds - include Clinical Threshold in scales
        manual_shapes <- setNames(
          c(21, 24, 5),
          c(treatment1, treatment2, "Clinical Threshold")
        )
        manual_colors <- setNames(
          c("#D55E00", "#0072B2", "black"),
          c(treatment1, treatment2, "Clinical Threshold")
        )
        manual_fills <- setNames(
          c("#D55E00", "#0072B2", "gray85", "black"),
          c(
            treatment1,
            treatment2,
            "Clinically Meaningful Difference",
            "Clinical Threshold"
          )
        )
        fill_breaks <- c(
          treatment1,
          treatment2,
          "Clinical Threshold",
          "Clinically Meaningful Difference"
        )
      } else {
        # No thresholds - only treatment scales
        manual_shapes <- setNames(c(21, 24), c(treatment1, treatment2))
        manual_colors <- setNames(
          c("#D55E00", "#0072B2"),
          c(treatment1, treatment2)
        )
        manual_fills <- setNames(
          c("#D55E00", "#0072B2"),
          c(treatment1, treatment2)
        )
        fill_breaks <- c(treatment1, treatment2)
      }

      # Create scales
      color_scale <- scale_color_manual(name = "", values = manual_colors)
      shape_scale <- scale_shape_manual(name = "", values = manual_shapes)
      fill_scale <- scale_fill_manual(
        name = "",
        values = manual_fills,
        breaks = fill_breaks
      )

      # Calculate x-axis limits for forest plot
      x_min <- min(type_data$Diff_LowerCI, na.rm = TRUE)
      x_max <- max(type_data$Diff_UpperCI, na.rm = TRUE)

      # Handle case where all values are NA/missing
      if (is.infinite(x_min) || is.infinite(x_max)) {
        x_min <- -1
        x_max <- 1
      }

      # Determine if we need to reverse the axis
      # Reverse when: Benefit outcome AND (clinical meaningful
      # direction is "less" OR threshold is negative)
      should_reverse_axis <- FALSE
      if (show_thresholds && nrow(clin_thresholds) > 0) {
        should_reverse_axis <- factor == "Benefit" &&
          any(
            clin_thresholds$Outcome %in%
              type_data$Outcome &
              (clin_thresholds$Direction == "less" |
                clin_thresholds$Threshold < 0)
          )
      }

      x_range <- max(abs(x_min), abs(x_max))

      # Set up x-axis limits and breaks
      x_lim <- c(-x_range, x_range)
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

      # Handle case where all values are NA/missing or no data
      if (is.infinite(max_x_value) || length(dot_data$x) == 0) {
        max_x_value <- 1
      }

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

      # Handle case where all CI values are NA/missing
      if (is.infinite(max_ci)) {
        max_ci <- 1
      }
      if (is.infinite(min_ci)) {
        min_ci <- -1
      }

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

      # Create the base forest plot
      forest_plot <- ggplot()
      # Add shaded regions for clinical meaning (only if thresholds are shown)
      if (show_thresholds && nrow(shade_data) > 0) {
        forest_plot <- forest_plot +
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
          )
      }
      # Add points and error bars for treatment differences
      forest_plot <- forest_plot +
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
        )

      # Add threshold points (only if thresholds are shown)
      if (show_thresholds && nrow(thresholds_with_treatment) > 0) {
        forest_plot <- forest_plot +
          geom_point(
            data = thresholds_with_treatment,
            aes(x = Threshold, y = Outcome, shape = Treatment),
            color = "black",
            fill = NA, # hollow symbol
            size = 3,
            stroke = 1 # make outline thicker for visibility
          )
      }

      # Add reference line at zero
      forest_plot <- forest_plot +
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
        scale_y_discrete(limits = y_levels)

      # Only apply shape scale if thresholds are being used
      if (show_thresholds && nrow(thresholds_with_treatment) > 0) {
        forest_plot <- forest_plot + shape_scale
      }

      # Apply coordinate system
      if (should_reverse_axis) {
        # For reversed axis, coordinate limits should also be reversed
        forest_plot <- forest_plot +
          coord_cartesian(xlim = rev(x_lim), clip = "off")
      } else {
        forest_plot <- forest_plot +
          coord_cartesian(xlim = x_lim, clip = "off")
      }

      # Apply the appropriate x-axis scale
      if (should_reverse_axis) {
        # Use scale_x_reverse to reverse the axis:
        # 60, 40, 20, 0, -20, -40, -60
        # For reversed axis, limits should be in reverse order
        # (high, low)
        forest_plot <- forest_plot +
          scale_x_reverse(limits = rev(x_lim), breaks = forest_breaks)
      } else {
        # Use normal scale: -60, -40, -20, 0, 20, 40, 60
        forest_plot <- forest_plot +
          scale_x_continuous(limits = x_lim, breaks = forest_breaks)
      }

      forest_plot <- forest_plot +
        # Add x-axis label for last plot
        labs(
          x = if (is_last_plot) {
            # Labels should remain consistent regardless of axis reversal
            # Left side (negative values) always favours treatment2
            # Right side (positive values) always favours treatment1
            paste0(
              "<br>",
              "<span style='color:black;font-weight:bold;'>",
              left_arrow,
              " Favours ",
              treatment2,
              "</span>",
              spacing,
              "<span style='color:black;font-weight:bold;'>Favours ",
              treatment1,
              " ",
              right_arrow,
              "</span>",
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

  # Check if we have any plots to combine
  if (length(plots) == 0) {
    stop(
      paste(
        "No plots were generated. This may be because no data was",
        "found for the specified outcomes and factor/type combinations."
      )
    )
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
