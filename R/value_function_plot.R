#' Create Value Function Visualization
#'
#' Creates a visualization showing how raw clinical outcome values are
#' transformed into normalized value scores (0-100 scale) using linear
#' value functions. Supports both increasing direction (higher is better,
#' for benefits) and decreasing direction (lower is better, for risks).
#' This visualization helps stakeholders understand the normalization
#' process in MCDA analyses.
#'
#' @param criterion_name Character string specifying the name of the criterion
#'   to visualize (e.g., "Efficacy", "Adverse Events"). Required.
#' @param min_val Numeric value specifying the lower threshold of the
#'   clinical scale. Required.
#' @param max_val Numeric value specifying the upper threshold of the
#'   clinical scale. Required.
#' @param direction Character string specifying the favorable direction.
#'   Either "increasing" (higher raw values are better, used for benefits)
#'   or "decreasing" (lower raw values are better, used for risks).
#'   Required.
#' @param n_points Integer specifying the number of points to use for
#'   plotting the curve. Default is 100.
#' @param color Character string specifying the color for the value function
#'   line. If NULL, uses "#0571b0" (blue) for increasing and "#ca0020" (red)
#'   for decreasing. Default is NULL.
#' @param show_title Logical indicating whether to show the plot title.
#'   Default is TRUE.
#' @param show_reference_line Logical indicating whether to show a horizontal
#'   reference line at value = 50. Default is TRUE.
#' @param x_label Character string for the x-axis label. If NULL, uses
#'   criterion_name. Default is NULL.
#' @param y_label Character string for the y-axis label. Default is
#'   "Value (0-100)".
#' @param base_font_size Numeric; base font size in points for all text
#'   elements in the plot (default: 9).
#'
#' @return A ggplot object showing the value function transformation.
#' @export
#' @import ggplot2
#'
#' @examples
#' # Benefit criterion: higher efficacy is better
#' plot_efficacy <- create_value_function_plot(
#'   criterion_name = "Response Rate (%)",
#'   min_val = 0,
#'   max_val = 100,
#'   direction = "increasing"
#' )
#'
#' # Risk criterion: lower adverse event rate is better
#' plot_ae <- create_value_function_plot(
#'   criterion_name = "Adverse Event Rate (%)",
#'   min_val = 0,
#'   max_val = 50,
#'   direction = "decreasing"
#' )
#'
#' # Custom styling
#' \dontrun{
#' plot_custom <- create_value_function_plot(
#'   criterion_name = "QoL Score",
#'   min_val = 0,
#'   max_val = 100,
#'   direction = "increasing",
#'   color = "#2c7bb6",
#'   show_title = FALSE
#' )
#' }
create_value_function_plot <- function(
  criterion_name = NULL,
  min_val = NULL,
  max_val = NULL,
  direction = NULL,
  n_points = 100,
  color = NULL,
  show_title = TRUE,
  show_reference_line = TRUE,
  x_label = NULL,
  y_label = "Value (0-100)",
  base_font_size = 9
) {
  # Input validation
  if (is.null(criterion_name)) {
    stop("criterion_name is required")
  }
  if (is.null(min_val) || is.null(max_val)) {
    stop("Both min_val and max_val are required")
  }
  if (is.null(direction)) {
    stop("direction is required (either 'increasing' or 'decreasing')")
  }
  if (!direction %in% c("increasing", "decreasing")) {
    stop("direction must be either 'increasing' or 'decreasing'")
  }
  if (min_val >= max_val) {
    stop("min_val must be less than max_val")
  }

  # Generate x values (raw outcome values)
  x_vals <- seq(min_val, max_val, length.out = n_points)

  # Calculate value function based on direction
  if (direction == "increasing") {
    # Higher is better: v(x) = 100 * (x - min) / (max - min)
    values <- 100 * (x_vals - min_val) / (max_val - min_val)
  } else {
    # Lower is better: v(x) = 100 * (max - x) / (max - min)
    values <- 100 * (max_val - x_vals) / (max_val - min_val)
  }

  # Create data frame for plotting
  plot_data <- data.frame(
    x = x_vals,
    value = values
  )

  # Set default color based on direction if not provided
  if (is.null(color)) {
    color <- if (direction == "increasing") "#0571b0" else "#ca0020"
  }

  # Set x-axis label
  if (is.null(x_label)) {
    x_label <- criterion_name
  }

  # Create base plot
  p <- ggplot(plot_data, aes(x = x, y = value)) +
    geom_line(color = color, linewidth = 1.2)

  # Add reference line if requested
  if (show_reference_line) {
    p <- p + geom_hline(
      yintercept = 50,
      linetype = "dashed",
      color = "gray50"
    )
  }

  # Build labs arguments
  labs_args <- list(
    x = x_label,
    y = y_label
  )

  if (show_title) {
    title_direction <- if (direction == "increasing") {
      "Increasing (Higher is Better)"
    } else {
      "Decreasing (Lower is Better)"
    }
    labs_args$title <- paste0(
      "Value Function: ",
      criterion_name,
      "\n",
      title_direction
    )
  }

  # Apply labels and theme
  p <- p +
    do.call(labs, labs_args) +
    theme_minimal(base_size = base_font_size) +
    theme(
      plot.title = element_text(size = base_font_size * 1.33, face = "bold"),
      axis.title = element_text(size = base_font_size * 1.22),
      panel.grid.major = element_line(color = "lightgray"),
      panel.grid.minor = element_line(color = "gray95")
    )

  p
}


#' Compare Value Functions for Benefits and Risks
#'
#' Creates a side-by-side comparison of value functions for benefit and
#' risk criteria, showing how the normalization differs based on whether
#' higher or lower raw values are favorable. This is useful for educational
#' purposes and for communicating the MCDA normalization approach to
#' stakeholders.
#'
#' @param benefit_name Character string for the benefit criterion name.
#'   Default is "Benefits".
#' @param benefit_min Numeric value for benefit minimum threshold.
#'   Default is 0.
#' @param benefit_max Numeric value for benefit maximum threshold.
#'   Default is 100.
#' @param benefit_label Character string for benefit x-axis label.
#'   If NULL, uses benefit_name. Default is NULL.
#' @param risk_name Character string for the risk criterion name.
#'   Default is "Risks".
#' @param risk_min Numeric value for risk minimum threshold.
#'   Default is 0.
#' @param risk_max Numeric value for risk maximum threshold.
#'   Default is 50.
#' @param risk_label Character string for risk x-axis label.
#'   If NULL, uses risk_name. Default is NULL.
#' @param show_titles Logical indicating whether to show plot titles.
#'   Default is TRUE.
#' @param show_reference_lines Logical indicating whether to show horizontal
#'   reference lines at value = 50. Default is TRUE.
#' @param base_font_size Numeric; base font size in points for all text
#'   elements in the plot (default: 9).
#'
#' @return A combined plot (using patchwork) showing both value functions
#'   side by side.
#' @export
#' @import ggplot2
#' @importFrom patchwork wrap_plots
#'
#' @examples
#' # Default comparison
#' comparison_plot <- compare_value_functions()
#'
#' # Custom comparison with specific criteria
#' custom_comparison <- compare_value_functions(
#'   benefit_name = "Response Rate",
#'   benefit_min = 0,
#'   benefit_max = 100,
#'   benefit_label = "Response Rate (%)",
#'   risk_name = "Adverse Events",
#'   risk_min = 0,
#'   risk_max = 50,
#'   risk_label = "AE Rate (%)"
#' )
#'
#' # Without titles for cleaner display
#' \dontrun{
#' comparison_clean <- compare_value_functions(
#'   show_titles = FALSE
#' )
#' }
compare_value_functions <- function(
  benefit_name = "Benefits",
  benefit_min = 0,
  benefit_max = 100,
  benefit_label = NULL,
  risk_name = "Risks",
  risk_min = 0,
  risk_max = 50,
  risk_label = NULL,
  show_titles = TRUE,
  show_reference_lines = TRUE,
  base_font_size = 9
) {
  # Create benefit plot (increasing direction)
  p_benefit <- create_value_function_plot(
    criterion_name = benefit_name,
    min_val = benefit_min,
    max_val = benefit_max,
    direction = "increasing",
    color = "#0571b0",
    show_title = show_titles,
    show_reference_line = show_reference_lines,
    x_label = benefit_label,
    base_font_size = base_font_size
  )

  # Create risk plot (decreasing direction)
  p_risk <- create_value_function_plot(
    criterion_name = risk_name,
    min_val = risk_min,
    max_val = risk_max,
    direction = "decreasing",
    color = "#ca0020",
    show_title = show_titles,
    show_reference_line = show_reference_lines,
    x_label = risk_label,
    base_font_size = base_font_size
  )

  # Combine plots side by side
  combined_plot <- patchwork::wrap_plots(p_benefit, p_risk, ncol = 2)

  combined_plot
}


#' Compare Multiple Value Functions
#'
#' Creates a multi-panel plot comparing value functions for multiple
#' criteria from MCDA clinical scales. This function takes the clinical_scales
#' list structure used in MCDA functions and creates visualizations for
#' all criteria.
#'
#' @param clinical_scales List defining clinical reference levels for
#'   each criterion. Each element should be a list with: min (lower
#'   threshold), max (upper threshold), and direction ("increasing" for
#'   higher is better, "decreasing" for lower is better). Required.
#' @param criteria Character vector of criterion names to plot. If NULL,
#'   plots all criteria in clinical_scales. Default is NULL.
#' @param ncol Integer specifying number of columns in the grid layout.
#'   Default is 2.
#' @param show_titles Logical indicating whether to show individual plot
#'   titles. Default is TRUE.
#' @param show_reference_lines Logical indicating whether to show horizontal
#'   reference lines at value = 50. Default is TRUE.
#' @param base_font_size Numeric; base font size in points for all text
#'   elements in the plot (default: 9).
#'
#' @return A combined plot (using patchwork) showing all value functions
#'   in a grid layout.
#' @export
#' @import ggplot2
#' @importFrom patchwork wrap_plots
#'
#' @examples
#' # Define clinical scales
#' clinical_scales <- list(
#'   `Benefit 1` = list(min = 0, max = 1, direction = "increasing"),
#'   `Benefit 2` = list(min = 0, max = 100, direction = "decreasing"),
#'   `Risk 1` = list(min = 0, max = 0.5, direction = "decreasing"),
#'   `Risk 2` = list(min = 0, max = 0.3, direction = "decreasing")
#' )
#'
#' # Plot all criteria
#' all_plots <- plot_multiple_value_functions(
#'   clinical_scales = clinical_scales
#' )
#'
#' # Plot specific criteria only
#' \dontrun{
#' selected_plots <- plot_multiple_value_functions(
#'   clinical_scales = clinical_scales,
#'   criteria = c("Benefit 1", "Risk 1"),
#'   ncol = 2
#' )
#' }
plot_multiple_value_functions <- function(
  clinical_scales = NULL,
  criteria = NULL,
  ncol = 2,
  show_titles = TRUE,
  show_reference_lines = TRUE,
  base_font_size = 9
) {
  # Input validation
  if (is.null(clinical_scales)) {
    stop("clinical_scales is required")
  }

  # Determine which criteria to plot
  if (is.null(criteria)) {
    criteria <- names(clinical_scales)
  }

  # Validate that all requested criteria exist in clinical_scales
  missing_criteria <- setdiff(criteria, names(clinical_scales))
  if (length(missing_criteria) > 0) {
    stop(
      "The following criteria are not found in clinical_scales: ",
      paste(missing_criteria, collapse = ", ")
    )
  }

  # Create a plot for each criterion
  plots_list <- list()

  for (criterion in criteria) {
    scale <- clinical_scales[[criterion]]

    # Validate scale structure
    if (is.null(scale$min) || is.null(scale$max) || is.null(scale$direction)) {
      warning(
        "Skipping criterion '", criterion,
        "': missing min, max, or direction"
      )
      next
    }

    # Determine color based on direction
    plot_color <- if (scale$direction == "increasing") "#0571b0" else "#ca0020"

    # Create the plot
    p <- create_value_function_plot(
      criterion_name = criterion,
      min_val = scale$min,
      max_val = scale$max,
      direction = scale$direction,
      color = plot_color,
      show_title = show_titles,
      show_reference_line = show_reference_lines,
      base_font_size = base_font_size
    )

    plots_list[[criterion]] <- p
  }

  # Combine all plots
  if (length(plots_list) == 0) {
    stop("No valid plots were created")
  }

  combined_plot <- patchwork::wrap_plots(plots_list, ncol = ncol)

  combined_plot
}


#' Compare Different Value Function Types
#'
#' Creates a comparison plot showing multiple value function types
#' (Linear, Piecewise Linear, Exponential, Sigmoid, Step) overlaid on
#' the same plot. This visualization helps stakeholders understand how
#' different functional forms would transform the same raw clinical data,
#' and demonstrates why linear functions are the regulatory-preferred
#' default. Creates separate plots for benefits (increasing direction)
#' and risks (decreasing direction).
#'
#' @param benefit_name Character string for the benefit criterion name.
#'   Default is "Benefits".
#' @param benefit_min Numeric value for benefit minimum threshold.
#'   Default is 0.
#' @param benefit_max Numeric value for benefit maximum threshold.
#'   Default is 100.
#' @param benefit_label Character string for benefit x-axis label.
#'   If NULL, uses benefit_name. Default is NULL.
#' @param risk_name Character string for the risk criterion name.
#'   Default is "Risks".
#' @param risk_min Numeric value for risk minimum threshold.
#'   Default is 0.
#' @param risk_max Numeric value for risk maximum threshold.
#'   Default is 50.
#' @param risk_label Character string for risk x-axis label.
#'   If NULL, uses risk_name. Default is NULL.
#' @param n_points Integer specifying number of points for plotting.
#'   Default is 100.
#' @param show_titles Logical indicating whether to show plot titles.
#'   Default is TRUE.
#' @param show_legend Logical indicating whether to show the legend.
#'   Default is TRUE.
#' @param power Numeric value for the power/exponential function exponent.
#'   Default is 2 (risk-averse, diminishing returns).
#' @param base_font_size Numeric; base font size in points for all text
#'   elements in the plot (default: 9).
#'
#' @return A combined plot (using patchwork) showing value function type
#'   comparisons for both benefits and risks side by side.
#' @export
#' @import ggplot2
#' @importFrom patchwork wrap_plots
#'
#' @examples
#' # Default comparison
#' comparison_plot <- compare_value_function_types()
#'
#' # Custom comparison with specific criteria
#' custom_comparison <- compare_value_function_types(
#'   benefit_name = "Efficacy",
#'   benefit_min = 0,
#'   benefit_max = 100,
#'   benefit_label = "Response Rate (%)",
#'   risk_name = "Safety",
#'   risk_min = 0,
#'   risk_max = 50,
#'   risk_label = "Adverse Event Rate (%)"
#' )
#'
#' # Without titles for cleaner display
#' \dontrun{
#' comparison_clean <- compare_value_function_types(
#'   show_titles = FALSE
#' )
#' }
compare_value_function_types <- function(
  benefit_name = "Benefits",
  benefit_min = 0,
  benefit_max = 100,
  benefit_label = NULL,
  risk_name = "Risks",
  risk_min = 0,
  risk_max = 50,
  risk_label = NULL,
  n_points = 100,
  show_titles = TRUE,
  show_legend = TRUE,
  power = 2,
  base_font_size = 9
) {
  # Helper functions for different value function types
  linear_increasing <- function(x, min_val, max_val) {
    100 * (x - min_val) / (max_val - min_val)
  }

  linear_decreasing <- function(x, min_val, max_val) {
    100 * (max_val - x) / (max_val - min_val)
  }

  piecewise_linear <- function(x, breakpoints, slopes, intercepts) {
    value <- numeric(length(x))
    for (i in seq_along(x)) {
      if (x[i] < breakpoints[1]) {
        value[i] <- slopes[1] * x[i] + intercepts[1]
      } else if (x[i] < breakpoints[2]) {
        value[i] <- slopes[2] * (x[i] - breakpoints[1]) + intercepts[2]
      } else {
        value[i] <- slopes[3] * (x[i] - breakpoints[2]) + intercepts[3]
      }
    }
    pmax(0, pmin(100, value))
  }

  power_function <- function(x, min_val, max_val, power_param) {
    normalized <- (x - min_val) / (max_val - min_val)
    100 * normalized^power_param
  }

  sigmoid_function <- function(x, min_val, max_val, midpoint, steepness) {
    x_centered <- x - midpoint
    100 / (1 + exp(-steepness * x_centered))
  }

  step_function <- function(x, thresholds, values) {
    result <- numeric(length(x))
    for (i in seq_along(x)) {
      category <- sum(x[i] >= thresholds) + 1
      result[i] <- values[category]
    }
    result
  }

  # Set x-axis labels
  if (is.null(benefit_label)) {
    benefit_label <- benefit_name
  }
  if (is.null(risk_label)) {
    risk_label <- risk_name
  }

  # Create exponential label once for consistency
  exponential_label <- sprintf("Exponential (b=%.1f)", power)

  # Create benefit plot (increasing direction)
  x_benefit <- seq(benefit_min, benefit_max, length.out = n_points)

  # Calculate breakpoints for piecewise (at 20%, 60% of range)
  benefit_range <- benefit_max - benefit_min
  benefit_bp1 <- benefit_min + 0.2 * benefit_range
  benefit_bp2 <- benefit_min + 0.6 * benefit_range

  # For piecewise increasing: slow start, faster middle, slower end
  benefit_piecewise <- piecewise_linear(
    x_benefit,
    c(benefit_bp1, benefit_bp2),
    c(0.5, 2, 0.5),  # slopes
    c(0, 10, 70)     # intercepts
  )

  # Calculate midpoint for sigmoid
  benefit_midpoint <- benefit_min + 0.5 * benefit_range

  benefit_comparison <- data.frame(
    x = rep(x_benefit, 5),
    value = c(
      linear_increasing(x_benefit, benefit_min, benefit_max),
      benefit_piecewise,
      power_function(x_benefit, benefit_min, benefit_max, power),
      sigmoid_function(
        x_benefit,
        benefit_min,
        benefit_max,
        benefit_midpoint,
        8 / benefit_range
      ),
      step_function(
        x_benefit,
        c(
          benefit_min + 0.2 * benefit_range,
          benefit_min + 0.5 * benefit_range,
          benefit_min + 0.8 * benefit_range
        ),
        c(0, 25, 60, 100)
      )
    ),
    type = rep(
      c(
        "Linear (Current Standard)",
        "Piecewise Linear",
        exponential_label,
        "Sigmoid",
        "Step"
      ),
      each = length(x_benefit)
    )
  )

  benefit_comparison$type <- factor(
    benefit_comparison$type,
    levels = c(
      "Linear (Current Standard)",
      "Piecewise Linear",
      exponential_label,
      "Sigmoid",
      "Step"
    )
  )

  # Create risk plot (decreasing direction)
  x_risk <- seq(risk_min, risk_max, length.out = n_points)

  # Calculate breakpoints for piecewise (at 20%, 50% of range)
  risk_range <- risk_max - risk_min
  risk_bp1 <- risk_min + 0.2 * risk_range
  risk_bp2 <- risk_min + 0.5 * risk_range

  # For piecewise decreasing (risks)
  risk_piecewise <- piecewise_linear(
    x_risk,
    c(risk_bp1, risk_bp2),
    c(-2, -3, -5),         # slopes (increasing concern)
    c(100, 80, 35)         # intercepts
  )

  # Calculate midpoint for sigmoid
  risk_midpoint <- risk_min + 0.5 * risk_range

  risk_comparison <- data.frame(
    x = rep(x_risk, 5),
    value = c(
      linear_decreasing(x_risk, risk_min, risk_max),
      risk_piecewise,
      power_function(risk_max - x_risk, 0, risk_range, power),
      100 - sigmoid_function(
        x_risk,
        risk_min,
        risk_max,
        risk_midpoint,
        7.5 / risk_range
      ),
      step_function(
        x_risk,
        c(
          risk_min + 0.1 * risk_range,
          risk_min + 0.3 * risk_range,
          risk_min + 0.6 * risk_range
        ),
        c(100, 75, 40, 0)
      )
    ),
    type = rep(
      c(
        "Linear (Current Standard)",
        "Piecewise Linear",
        exponential_label,
        "Sigmoid",
        "Step"
      ),
      each = length(x_risk)
    )
  )

  risk_comparison$type <- factor(
    risk_comparison$type,
    levels = c(
      "Linear (Current Standard)",
      "Piecewise Linear",
      exponential_label,
      "Sigmoid",
      "Step"
    )
  )

  # Color palette
  colors <- c("gray50", "#2c7bb6", "#fdae61", "#d7191c", "#542788")
  names(colors) <- c(
    "Linear (Current Standard)",
    "Piecewise Linear",
    exponential_label,
    "Sigmoid",
    "Step"
  )

  # Create benefit plot
  p_benefit <- ggplot(benefit_comparison, aes(x = x, y = value, color = type)) +
    geom_line(linewidth = 1.2) +
    scale_color_manual(values = colors) +
    labs(
      x = benefit_label,
      y = "Value (0-100)",
      color = "Function Type"
    ) +
    theme_minimal(base_size = base_font_size) +
    theme(
      plot.title = element_text(face = "bold", size = base_font_size * 1.22),
      plot.subtitle = element_text(size = base_font_size),
      legend.position = if (show_legend) "bottom" else "none",
      panel.grid.major = element_line(color = "lightgray")
    )

  if (show_titles) {
    p_benefit <- p_benefit +
      labs(
        title = paste("Value Function Comparison:", benefit_name),
        subtitle = "Higher is better (Increasing direction)"
      )
  }

  # Create risk plot
  p_risk <- ggplot(risk_comparison, aes(x = x, y = value, color = type)) +
    geom_line(linewidth = 1.2) +
    scale_color_manual(values = colors) +
    labs(
      x = risk_label,
      y = "Value (0-100)",
      color = "Function Type"
    ) +
    theme_minimal(base_size = base_font_size) +
    theme(
      plot.title = element_text(face = "bold", size = base_font_size * 1.22),
      plot.subtitle = element_text(size = base_font_size),
      legend.position = if (show_legend) "bottom" else "none",
      panel.grid.major = element_line(color = "lightgray")
    )

  if (show_titles) {
    p_risk <- p_risk +
      labs(
        title = paste("Value Function Comparison:", risk_name),
        subtitle = "Lower is better (Decreasing direction)"
      )
  }

  # Combine plots side by side
  combined_plot <- patchwork::wrap_plots(p_benefit, p_risk, ncol = 2) +
    patchwork::plot_layout(guides = "collect") &
    theme(legend.position = "bottom")

  combined_plot
}
