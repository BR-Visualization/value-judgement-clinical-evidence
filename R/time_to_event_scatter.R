#' Create Time-to-Event Scatter Plot: Benefit vs Risk Timing
#'
#' @param data A data frame with subject-level time-to-event data containing:
#'   - subject_id: Unique subject identifier
#'   - time_to_benefit: Time to first benefit event (or censoring time)
#'   - benefit_type: Type of benefit outcome
#'   - time_to_risk: Time to first risk event (or censoring time)
#'   - risk_type: Type of risk outcome
#'   - benefit_observed: (optional) 1 = event observed, 0 = censored
#'   - risk_observed: (optional) 1 = event observed, 0 = censored
#'   Censored observations are displayed at their censoring time with open circles and tick marks.
#' @param vary_by Character string specifying which dimension to vary by color/shape.
#'   Options: "benefit" (vary by benefit type) or "risk" (vary by risk type).
#'   Default is "benefit".
#' @param time_units Character string for time unit labels (e.g., "Days", "Weeks", "Months").
#'   Default is "Days".
#' @param add_marginals Logical. If TRUE, adds marginal density plots. Default is TRUE.
#' @param fig_colors Optional vector of colors for different event types.
#'   If NULL, uses default color palette.
#'
#' @return A ggplot object showing the time-to-event scatter plot with unity line.
#'   Points below the unity line indicate risk occurred before benefit (unfavorable).
#'   Points above the unity line indicate benefit occurred before risk (favorable).
#'
#' @export
#' @import ggplot2
#' @importFrom ggExtra ggMarginal
#'
#' @details
#' This visualization helps identify temporal patterns in benefit-risk profiles:
#' - Unity line (y=x): represents equal timing of benefit and risk
#' - Below line: risk precedes benefit (less favorable patient experience)
#' - Above line: benefit precedes risk (more favorable patient experience)
#'
#' The plot can highlight whether certain benefit or risk types tend to occur
#' earlier in treatment, which may inform:
#' - Treatment adherence strategies
#' - Patient counseling and expectation setting
#' - Risk mitigation timing
#'
#' Censored observations are shown with:
#' - Open circles (hollow shapes) instead of filled
#' - Tick marks (+) to indicate censoring direction
#' - Time displayed is the censoring time (e.g., end of follow-up)
#'
#' Note: Summary statistics (mean, benefit-before-risk %) are calculated only
#' among subjects with both events observed. Consider competing risks and
#' informative censoring in interpretation.
#'
#' @examples
#' \dontrun{
#' # Create example data
#' time_data <- data.frame(
#'   subject_id = 1:100,
#'   time_to_benefit = rexp(100, rate = 0.05),
#'   benefit_type = sample(c("Symptom Relief", "Clinical Response"), 100, replace = TRUE),
#'   time_to_risk = rexp(100, rate = 0.03),
#'   risk_type = sample(c("Mild AE", "Moderate AE"), 100, replace = TRUE)
#' )
#'
#' # Create plot varying by benefit type
#' create_time_to_event_scatter(
#'   data = time_data,
#'   vary_by = "benefit",
#'   time_units = "Days"
#' )
#'
#' # Create plot varying by risk type
#' create_time_to_event_scatter(
#'   data = time_data,
#'   vary_by = "risk",
#'   time_units = "Weeks"
#' )
#' }
create_time_to_event_scatter <- function(
  data,
  vary_by = "benefit",
  time_units = "Days",
  add_marginals = TRUE,
  fig_colors = NULL
) {
  # Validate inputs
  if (!vary_by %in% c("benefit", "risk")) {
    stop("vary_by must be either 'benefit' or 'risk'")
  }

  required_cols <- c(
    "subject_id",
    "time_to_benefit",
    "benefit_type",
    "time_to_risk",
    "risk_type"
  )
  missing_cols <- setdiff(required_cols, colnames(data))
  if (length(missing_cols) > 0) {
    stop(paste0(
      "Missing required columns: ",
      paste(missing_cols, collapse = ", ")
    ))
  }

  # Check if censoring indicators exist
  has_censoring <- all(
    c("benefit_observed", "risk_observed") %in% colnames(data)
  )

  # Keep all subjects, including those with censored observations
  if (has_censoring) {
    data_clean <- data[
      complete.cases(data[, c("time_to_benefit", "time_to_risk")]),
    ]

    # Create censoring status for plotting
    data_clean$censoring_status <- with(
      data_clean,
      ifelse(
        benefit_observed == 1 & risk_observed == 1,
        "Both observed",
        ifelse(
          benefit_observed == 0 & risk_observed == 1,
          "Benefit censored",
          ifelse(
            benefit_observed == 1 & risk_observed == 0,
            "Risk censored",
            "Both censored"
          )
        )
      )
    )

    n_total_original <- nrow(data)
    n_both_observed <- sum(
      data_clean$benefit_observed == 1 & data_clean$risk_observed == 1
    )
    n_censored <- nrow(data_clean) - n_both_observed
  } else {
    # If no censoring indicators, just remove missing values
    data_clean <- data[
      complete.cases(data[, c("time_to_benefit", "time_to_risk")]),
    ]
    data_clean$censoring_status <- "Both observed"
    n_total_original <- nrow(data)
    n_both_observed <- nrow(data_clean)
    n_censored <- 0
  }

  if (nrow(data_clean) == 0) {
    stop("No subjects with data")
  }

  # Set up color/shape variable
  if (vary_by == "benefit") {
    data_clean$group <- data_clean$benefit_type
    group_label <- "Benefit Type"
  } else {
    data_clean$group <- data_clean$risk_type
    group_label <- "Risk Type"
  }

  # Set default colors if not provided
  if (is.null(fig_colors)) {
    n_groups <- length(unique(data_clean$group))
    fig_colors <- scales::hue_pal()(n_groups)
  }

  # Calculate summary statistics (among those with both observed)
  both_obs_idx <- data_clean$censoring_status == "Both observed"
  n_total <- nrow(data_clean)
  n_benefit_first <- sum(
    data_clean$time_to_benefit[both_obs_idx] <
      data_clean$time_to_risk[both_obs_idx]
  )
  pct_benefit_first <- 100 * n_benefit_first / sum(both_obs_idx)

  # Calculate mean times (among those with both observed)
  mean_benefit <- mean(data_clean$time_to_benefit[both_obs_idx], na.rm = TRUE)
  mean_risk <- mean(data_clean$time_to_risk[both_obs_idx], na.rm = TRUE)

  # Determine axis limits (square plot)
  max_time <- max(
    c(data_clean$time_to_benefit, data_clean$time_to_risk),
    na.rm = TRUE
  )
  axis_limit <- max_time * 1.05

  # Create the scatter plot
  p <- ggplot(
    data_clean,
    aes(x = time_to_benefit, y = time_to_risk, color = group, shape = group)
  ) +
    # Unity line (y=x)
    geom_abline(
      intercept = 0,
      slope = 1,
      linetype = "solid",
      color = "black",
      linewidth = 0.8
    ) +
    # Shaded regions
    annotate(
      "ribbon",
      x = c(0, axis_limit),
      ymin = c(0, axis_limit),
      ymax = axis_limit,
      fill = "#0571b0",
      alpha = 0.1
    ) + # Above line: benefit first (favorable)
    annotate(
      "ribbon",
      x = c(0, axis_limit),
      ymin = 0,
      ymax = c(0, axis_limit),
      fill = "#ca0020",
      alpha = 0.1
    ) + # Below line: risk first (unfavorable)
    # Data points - both observed (filled shapes)
    geom_point(
      data = data_clean[data_clean$censoring_status == "Both observed", ],
      size = 2.5,
      alpha = 0.7
    ) +
    # Censored points (open shapes with tick marks)
    geom_point(
      data = data_clean[data_clean$censoring_status != "Both observed", ],
      size = 2.5,
      alpha = 0.5,
      shape = 1
    ) + # Open circles
    # Add tick marks for censored observations
    geom_point(
      data = data_clean[data_clean$censoring_status == "Benefit censored", ],
      aes(x = time_to_benefit),
      shape = 3,
      size = 2,
      color = "black",
      alpha = 0.7
    ) +
    geom_point(
      data = data_clean[data_clean$censoring_status == "Risk censored", ],
      aes(y = time_to_risk),
      shape = 3,
      size = 2,
      color = "black",
      alpha = 0.7
    ) +
    geom_point(
      data = data_clean[data_clean$censoring_status == "Both censored", ],
      shape = 3,
      size = 2,
      color = "black",
      alpha = 0.7
    ) +
    # Mean point (diamond) - only for both observed
    annotate(
      "point",
      x = mean_benefit,
      y = mean_risk,
      color = "black",
      shape = 18,
      size = 5
    ) +
    # Scales
    scale_x_continuous(limits = c(0, axis_limit), expand = c(0.02, 0)) +
    scale_y_continuous(limits = c(0, axis_limit), expand = c(0.02, 0)) +
    scale_color_manual(values = fig_colors, name = group_label) +
    scale_shape_manual(
      values = rep(
        c(16, 17, 15, 18),
        length.out = length(unique(data_clean$group))
      ),
      name = group_label
    ) +
    # Labels
    labs(
      x = paste0("Time to First Benefit (", time_units, ")"),
      y = paste0("Time to First Risk (", time_units, ")"),
      title = "Time-to-Event: Benefit vs Risk",
      subtitle = if (has_censoring && n_censored > 0) {
        paste0(
          n_both_observed,
          "/",
          n_total,
          " subjects with both events (",
          sprintf("%.1f%%", pct_benefit_first),
          " benefit first); ",
          n_censored,
          " censored (open circles + ticks)"
        )
      } else {
        paste0(
          sprintf("%.1f%%", pct_benefit_first),
          " (",
          n_benefit_first,
          "/",
          n_total,
          ") experienced benefit before risk"
        )
      }
    ) +
    # Annotations
    annotate(
      "text",
      x = axis_limit * 0.95,
      y = axis_limit * 0.98,
      label = "Benefit = Risk",
      angle = 45,
      vjust = 0,
      hjust = 1,
      size = 3,
      color = "black",
      fontface = "italic"
    ) +
    annotate(
      "text",
      x = axis_limit * 0.75,
      y = axis_limit * 0.25,
      label = "Risk Occurred\nBefore Benefit",
      size = 3.5,
      color = "#ca0020",
      alpha = 0.8,
      fontface = "bold"
    ) +
    annotate(
      "text",
      x = axis_limit * 0.25,
      y = axis_limit * 0.75,
      label = "Benefit Occurred\nBefore Risk",
      size = 3.5,
      color = "#0571b0",
      alpha = 0.8,
      fontface = "bold"
    ) +
    annotate(
      "text",
      x = mean_benefit,
      y = mean_risk,
      label = sprintf("Mean\n(%.1f, %.1f)", mean_benefit, mean_risk),
      hjust = 0.5,
      vjust = 1.5,
      size = 2.8,
      color = "black",
      fontface = "bold"
    ) +
    # Theme
    coord_fixed() +
    theme_minimal() +
    theme(
      plot.title = element_text(size = 13, face = "bold", hjust = 0.5),
      plot.subtitle = element_text(size = 9, hjust = 0.5),
      axis.title = element_text(size = 11, face = "bold"),
      axis.text = element_text(size = 10),
      legend.position = "bottom",
      legend.title = element_text(size = 10, face = "bold"),
      legend.text = element_text(size = 9),
      panel.grid.minor = element_blank(),
      panel.border = element_rect(color = "grey80", fill = NA, linewidth = 0.5)
    )

  # Add marginal plots if requested
  if (add_marginals) {
    p <- ggExtra::ggMarginal(
      p,
      type = "density",
      groupColour = TRUE,
      groupFill = TRUE,
      alpha = 0.3,
      size = 5
    )
  }

  return(p)
}
