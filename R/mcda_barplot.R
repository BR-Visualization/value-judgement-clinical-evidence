#' Create MCDA Bar Chart: Normalized Values Comparison
#'
#' @param data A data frame in wide format with Treatment column and
#'   criteria columns. Required parameter - must be provided. Each row
#'   should contain raw values for a treatment on their original
#'   measurement scales. See \code{\link{mcda_data}} for example format.
#' @param comparator_name Character string specifying the name of the
#'   reference treatment (e.g., placebo or active control) in the data.
#'   Default is "Placebo".
#' @param comparison_drug Character string specifying which drug to
#'   compare with the reference treatment in the visualization.
#'   Default is "Drug A".
#' @param benefit_criteria Character vector of benefit criterion names
#'   (column names in data).
#' @param risk_criteria Character vector of risk criterion names
#'   (column names in data).
#' @param clinical_scales List defining clinical reference levels for
#'   each criterion. Each element should be a list with: min (lower
#'   threshold), max (upper threshold), direction ("increasing" for
#'   higher is better, "decreasing" for lower is better).
#' @param fig_colors A vector of length 2 specifying colors for benefits
#'   and risks. Default is c("#0571b0", "#ca0020") to match
#'   correlogram colors.
#'
#' @return A patchwork object showing three panels: Normalized
#'   Comparator values, Normalized Drug values, and Difference of
#'   Normalized Values (Drug - Comparator), or NULL if data is not
#'   provided.
#' @export
#' @import ggplot2
#' @importFrom patchwork wrap_plots
#' @importFrom ggh4x facetted_pos_scales
#'
#' @examples
#' # Load example MCDA data
#' data(mcda_data)
#'
#' # View the data structure - each row has raw values for a treatment
#' head(mcda_data)
#' #   Treatment Benefit 1 Benefit 2 Benefit 3 Risk 1 Risk 2
#' # 1   Placebo      0.05        65         9   0.30  0.087
#' # 2    Drug A      0.46        20        60   0.46  0.100
#' # 3    Drug B      ...
#'
#' # Define clinical scales
#' clinical_scales <- list(
#'   `Benefit 1` = list(min = 0, max = 1, direction = "increasing"),
#'   `Benefit 2` = list(min = 0, max = 100, direction = "decreasing"),
#'   `Benefit 3` = list(min = 0, max = 100, direction = "increasing"),
#'   `Risk 1` = list(min = 0, max = 0.5, direction = "decreasing"),
#'   `Risk 2` = list(min = 0, max = 0.3, direction = "decreasing")
#' )
#'
#' # Create comparison barplot showing
#' # Normalized Comparator | Normalized Drug B | Difference
#' barplot_comp <- create_mcda_barplot_comparison(
#'   data = mcda_data,
#'   benefit_criteria = c("Benefit 1", "Benefit 2", "Benefit 3"),
#'   risk_criteria = c("Risk 1", "Risk 2"),
#'   comparison_drug = "Drug B",
#'   clinical_scales = clinical_scales
#' )
#'
#' # Compare a different drug
#' \dontrun{
#' barplot_comp_a <- create_mcda_barplot_comparison(
#'   data = mcda_data,
#'   benefit_criteria = c("Benefit 1", "Benefit 2", "Benefit 3"),
#'   risk_criteria = c("Risk 1", "Risk 2"),
#'   comparison_drug = "Drug A",
#'   clinical_scales = clinical_scales
#' )
#' ggsave(
#'   "inst/img/barplot_mcda_comparison_drug_a.png",
#'   barplot_comp_a,
#'   width = 12,
#'   height = 6,
#'   dpi = 300
#' )
#' }
create_mcda_barplot_comparison <- function(
  data = NULL,
  comparator_name = "Placebo",
  comparison_drug = "Drug A",
  benefit_criteria = NULL,
  risk_criteria = NULL,
  clinical_scales = NULL,
  fig_colors = c("#0571b0", "#ca0020")
) {
  # Check if data is provided
  if (is.null(data)) {
    warning(
      "No data provided. Please supply a data frame with Treatment ",
      "column and criteria columns. See ?mcda_data for expected format."
    )
    return(invisible(NULL))
  }

  # Check if criteria are provided
  if (is.null(benefit_criteria) || is.null(risk_criteria)) {
    stop(
      "Both benefit_criteria and risk_criteria must be specified as ",
      "column names in the data."
    )
  }

  # Check if clinical scales are provided
  if (is.null(clinical_scales)) {
    stop(
      "Clinical scales must be provided. Please define clinical",
      "reference levels for normalization."
    )
  }

  # Extract placebo and drug data
  placebo_row <- data[data$Treatment == comparator_name, ]
  drug_row <- data[data$Treatment == comparison_drug, ]

  # Check if comparison_drug exists
  if (nrow(drug_row) == 0) {
    stop(
      "Comparison drug '",
      comparison_drug,
      "' not found in data. ",
      "Available treatments: ",
      paste(unique(data$Treatment), collapse = ", ")
    )
  }

  # Check if comparator exists
  if (nrow(placebo_row) == 0) {
    stop(
      "Comparator '",
      comparator_name,
      "' not found in data. ",
      "Available treatments: ",
      paste(unique(data$Treatment), collapse = ", ")
    )
  }

  all_criteria <- c(benefit_criteria, risk_criteria)

  # Verify all criteria columns exist in data
  missing_cols <- setdiff(all_criteria, colnames(data))
  if (length(missing_cols) > 0) {
    stop(
      "The following criteria columns are not found in data: ",
      paste(missing_cols, collapse = ", "),
      ". ",
      "Available columns: ",
      paste(setdiff(colnames(data), "Treatment"), collapse = ", ")
    )
  }

  # Helper function to normalize values using clinical scales
  normalize_value <- function(x, scale) {
    if (
      is.null(scale$min) || is.null(scale$max) ||
        is.null(scale$direction)
    ) {
      stop("Scale must have min, max, and direction")
    }

    if (scale$direction == "increasing") {
      # Higher values are better
      values <- 100 * (x - scale$min) / (scale$max - scale$min)
    } else if (scale$direction == "decreasing") {
      # Lower values are better
      values <- 100 * (scale$max - x) / (scale$max - scale$min)
    } else {
      stop("Direction must be 'increasing' or 'decreasing'")
    }

    # Allow extrapolation by default
    if (
      !is.null(scale$allow_extrapolation) &&
        !scale$allow_extrapolation
    ) {
      values <- pmax(0, pmin(100, values))
    }

    values
  }

  # Get raw values
  placebo_raw <- unlist(placebo_row[, all_criteria, drop = FALSE])
  drug_raw <- unlist(drug_row[, all_criteria, drop = FALSE])

  # Normalize values for each criterion
  placebo_values <- sapply(seq_along(all_criteria), function(i) {
    criterion <- all_criteria[i]
    normalize_value(placebo_raw[i], clinical_scales[[criterion]])
  })
  names(placebo_values) <- all_criteria

  drug_values <- sapply(seq_along(all_criteria), function(i) {
    criterion <- all_criteria[i]
    normalize_value(drug_raw[i], clinical_scales[[criterion]])
  })
  names(drug_values) <- all_criteria

  # Calculate difference of normalized values
  diff_values <- drug_values - placebo_values

  # For normalized values, use 0-100 scale. Determine the maximum
  # absolute value across all normalized values for scaling
  max_norm_value <- max(c(abs(placebo_values), abs(drug_values)), na.rm = TRUE)

  # Set scale to 0-100 or extend if extrapolation occurs
  norm_max <- max(100, ceiling(max_norm_value / 10) * 10)
  norm_lim <- c(0, norm_max)
  norm_breaks <- seq(0, norm_max, by = 20)

  # Calculate common scale for all difference plots -
  # symmetric around zero
  max_abs_diff <- max(abs(diff_values), na.rm = TRUE)
  diff_max <- max(max_abs_diff * 1.15, 10)
  diff_lim <- c(-diff_max, diff_max)

  # Create data frames for all three plots
  # Prepare data with all outcomes
  plot_data <- data.frame(
    Criterion = rep(all_criteria, 3),
    Value = c(placebo_values, drug_values, diff_values),
    Group = rep(
      c(
        paste("Normalized", comparator_name),
        paste("Normalized", comparison_drug),
        "Difference"
      ),
      each = length(all_criteria)
    ),
    Type = rep(
      c(
        rep("Benefit", length(benefit_criteria)),
        rep("Risk", length(risk_criteria))
      ),
      3
    ),
    stringsAsFactors = FALSE
  )

  # Reverse criterion order for plotting (top to bottom)
  plot_data$Criterion <- factor(plot_data$Criterion, levels = rev(all_criteria))

  # Plot 1: Normalized Placebo
  plot_placebo <- ggplot(
    plot_data[plot_data$Group == paste("Normalized", comparator_name), ],
    aes(x = Value, y = Criterion, fill = Type)
  ) +
    geom_col(width = 0.7) +
    geom_vline(xintercept = 0, linetype = "solid", color = "black") +
    scale_fill_manual(
      values = c("Benefit" = fig_colors[1], "Risk" = fig_colors[2])
    ) +
    scale_x_continuous(
      limits = norm_lim,
      breaks = norm_breaks,
      expand = c(0.02, 0)
    ) +
    labs(
      title = paste("Normalized", comparator_name),
      x = NULL,
      y = NULL
    ) +
    theme_minimal() +
    theme(
      legend.position = "none",
      plot.title = element_text(size = 12, face = "bold", hjust = 0.5),
      axis.text.y = element_text(size = 10, face = "bold"),
      axis.text.x = element_text(size = 9),
      axis.ticks.y = element_blank(),
      axis.ticks.x = element_line(color = "grey92"),
      panel.grid.major.y = element_blank(),
      panel.grid.minor.y = element_blank(),
      plot.margin = margin(5, 15, 5, 5),
      plot.background = element_rect(
        color = "darkgray",
        fill = NA,
        linewidth = 1
      )
    ) +
    geom_text(aes(label = sprintf("%.0f", Value)), hjust = -0.1, size = 3) +
    coord_cartesian(clip = "off")

  # Plot 2: Normalized Drug
  plot_drug <- ggplot(
    plot_data[plot_data$Group == paste("Normalized", comparison_drug), ],
    aes(x = Value, y = Criterion, fill = Type)
  ) +
    geom_col(width = 0.7) +
    geom_vline(xintercept = 0, linetype = "solid", color = "black") +
    scale_fill_manual(
      values = c("Benefit" = fig_colors[1], "Risk" = fig_colors[2])
    ) +
    scale_x_continuous(
      limits = norm_lim,
      breaks = norm_breaks,
      expand = c(0.02, 0)
    ) +
    labs(
      title = paste("Normalized", comparison_drug),
      x = NULL,
      y = NULL
    ) +
    theme_minimal() +
    theme(
      legend.position = "none",
      plot.title = element_text(size = 12, face = "bold", hjust = 0.5),
      axis.text.y = element_blank(),
      axis.text.x = element_text(size = 9),
      axis.ticks.y = element_blank(),
      axis.ticks.x = element_line(color = "grey92"),
      panel.grid.major.y = element_blank(),
      panel.grid.minor.y = element_blank(),
      plot.margin = margin(5, 15, 5, 5),
      plot.background = element_rect(
        color = "darkgray",
        fill = NA,
        linewidth = 1
      )
    ) +
    geom_text(aes(label = sprintf("%.0f", Value)), hjust = -0.1, size = 3) +
    coord_cartesian(clip = "off")

  # Plot 3: Normalized Difference
  diff_data <- plot_data[plot_data$Group == "Difference", ]
  plot_diff <- ggplot(diff_data, aes(x = Value, y = Criterion, fill = Type)) +
    geom_col(width = 0.7) +
    geom_vline(xintercept = 0, linetype = "solid", color = "black") +
    scale_fill_manual(
      values = c("Benefit" = fig_colors[1], "Risk" = fig_colors[2])
    ) +
    scale_x_continuous(limits = diff_lim, expand = c(0.02, 0)) +
    labs(
      title = "Difference",
      x = NULL,
      y = NULL
    ) +
    theme_minimal() +
    theme(
      legend.position = "none",
      plot.title = element_text(size = 12, face = "bold", hjust = 0.5),
      axis.text.y = element_blank(),
      axis.text.x = element_text(size = 9),
      axis.ticks.y = element_blank(),
      axis.ticks.x = element_line(color = "grey92"),
      panel.grid.major.y = element_blank(),
      panel.grid.minor.y = element_blank(),
      plot.margin = margin(5, 15, 5, 5),
      plot.background = element_rect(
        color = "darkgray",
        fill = NA,
        linewidth = 1
      )
    ) +
    geom_text(
      aes(label = sprintf("%.0f", Value)),
      hjust = ifelse(diff_data$Value < 0, 1.2, -0.1),
      size = 3
    ) +
    coord_cartesian(clip = "off")

  # Combine the three plots horizontally
  combined <- patchwork::wrap_plots(
    plot_placebo,
    plot_drug,
    plot_diff,
    ncol = 3,
    widths = c(1.2, 1, 1)
  )

  combined
}

#' Create MCDA Bar Chart: Calculation Walkthrough
#'
#' @param data A data frame in wide format with Treatment column and
#'   criteria columns. Required parameter - must be provided. Each row
#'   should contain raw values for a treatment on their original
#'   measurement scales. See \code{\link{mcda_data}} for example format.
#' @param comparator_name Character string specifying the name of the
#'   reference treatment (e.g., placebo or active control). Default is
#'   "Placebo".
#' @param comparison_drug Character string specifying which drug to show
#'   the calculation for. Default is "Drug A".
#' @param benefit_criteria Character vector of benefit criterion names
#'   (column names in data).
#' @param risk_criteria Character vector of risk criterion names
#'   (column names in data).
#' @param weights Named numeric vector of criterion weights. Must sum to 1.
#'   If NULL, uses equal weights.
#' @param clinical_scales List defining clinical reference levels for
#'   each criterion. Each element should be a list with: min (lower
#'   threshold), max (upper threshold), direction ("increasing" for
#'   higher is better, "decreasing" for lower is better), and
#'   optionally allow_extrapolation (default TRUE). If NULL, uses
#'   data-driven normalization (not recommended per FDA/EMA guidance).
#'   Example: \code{list(`Benefit 1` = list(min = 0, max = 1,
#'   direction = "increasing"), `Risk 1` = list(min = 0, max = 0.5,
#'   direction = "decreasing"))} Based on FDA/EMA best practices and
#'   PROTECT framework.
#' @param fig_colors A vector of length 2 specifying colors for
#'   benefits and risks.
#'   Default is c("#0571b0", "#ca0020").
#'
#' @return A grid arrangement of three panels showing: (1) Normalized
#'   Difference (on 0-100 scale: Drug normalized - Comparator normalized),
#'   (2) Weights, and (3) Weighted contributions (Benefit-Risk scores),
#'   or NULL if data is not provided. Negative values in panels 1 and 3
#'   indicate the drug performs worse than the comparator.
#' @export
#' @import ggplot2
#' @importFrom gridExtra arrangeGrob
#' @importFrom grid textGrob gpar
#'
#' @examples
#' # Load example MCDA data
#' data(mcda_data)
#'
#' # View the data structure - each row has raw values for a treatment
#' head(mcda_data)
#' #   Treatment Benefit 1 Benefit 2 Benefit 3 Risk 1 Risk 2
#' # 1   Placebo      0.05        65         9   0.30  0.087
#' # 2    Drug A      0.46        20        60   0.46  0.100
#'
#' # Define clinical scales
#' clinical_scales <- list(
#'   `Benefit 1` = list(min = 0, max = 1, direction = "increasing"),
#'   `Benefit 2` = list(min = 0, max = 100, direction = "decreasing"),
#'   `Benefit 3` = list(min = 0, max = 100, direction = "increasing"),
#'   `Risk 1` = list(min = 0, max = 0.5, direction = "decreasing"),
#'   `Risk 2` = list(min = 0, max = 0.3, direction = "decreasing")
#' )
#'
#' # Create walkthrough showing the MCDA calculation steps for Drug B
#' barplot_walk <- create_mcda_walkthrough(
#'   data = mcda_data,
#'   benefit_criteria = c("Benefit 1", "Benefit 2", "Benefit 3"),
#'   risk_criteria = c("Risk 1", "Risk 2"),
#'   comparison_drug = "Drug B",
#'   clinical_scales = clinical_scales
#' )
#'
#' # With custom weights and clinical scales for Drug A
#' \dontrun{
#' weights <- c(
#'   `Benefit 1` = 0.30,
#'   `Benefit 2` = 0.20,
#'   `Benefit 3` = 0.10,
#'   `Risk 1` = 0.30,
#'   `Risk 2` = 0.10
#' )
#'
#' # Define clinical scales based on clinical guidelines, MCID, or
#' # regulatory precedents. These fixed scales ensure stability and
#' # interpretability.
#' # Note: The "direction" field specifies which direction is favorable:
#' #   - "increasing": higher values are better
#' #   - "decreasing": lower values are better
#' clinical_scales <- list(
#'   `Benefit 1` = list(
#'     min = 0, # No benefit (unacceptable)
#'     max = 1, # Maximum expected benefit
#'     direction = "increasing"
#'   ),
#'   `Benefit 2` = list(
#'     min = 0, # Best outcome (no symptoms)
#'     max = 100, # Worst outcome (severe symptoms)
#'     direction = "decreasing" # Lower is better (e.g., symptom severity)
#'   ),
#'   `Benefit 3` = list(
#'     min = 0, # No improvement
#'     max = 100, # Maximum improvement
#'     direction = "increasing"
#'   ),
#'   `Risk 1` = list(
#'     min = 0, # No adverse events (ideal)
#'     max = 0.5, # 50% rate (unacceptable threshold)
#'     direction = "decreasing"
#'   ),
#'   `Risk 2` = list(
#'     min = 0, # No adverse events (ideal)
#'     max = 0.3, # 30% rate (concerning threshold)
#'     direction = "decreasing"
#'   )
#' )
#'
#' barplot_walk_a <- create_mcda_walkthrough(
#'   data = mcda_data,
#'   benefit_criteria = c("Benefit 1", "Benefit 2", "Benefit 3"),
#'   risk_criteria = c("Risk 1", "Risk 2"),
#'   comparison_drug = "Drug A",
#'   weights = weights,
#'   clinical_scales = clinical_scales
#' )
#' ggsave(
#'   "inst/img/barplot_mcda_walkthrough_drug_a.png",
#'   barplot_walk_a,
#'   width = 12,
#'   height = 6,
#'   dpi = 300
#' )
#' }
create_mcda_walkthrough <- function(
  data = NULL,
  comparator_name = "Placebo",
  comparison_drug = "Drug A",
  benefit_criteria = NULL,
  risk_criteria = NULL,
  weights = NULL,
  clinical_scales = NULL,
  fig_colors = c("#0571b0", "#ca0020")
) {
  # Check if data is provided
  if (is.null(data)) {
    warning(
      "No data provided. Please supply a data frame with Treatment ",
      "column and criteria columns. See ?mcda_data for expected format."
    )
    return(invisible(NULL))
  }

  # Check if criteria are provided
  if (is.null(benefit_criteria) || is.null(risk_criteria)) {
    stop(
      "Both benefit_criteria and risk_criteria must be specified as ",
      "column names in the data."
    )
  }

  # Default weights if not provided - equal weights
  all_criteria <- c(benefit_criteria, risk_criteria)
  if (is.null(weights)) {
    n_criteria <- length(all_criteria)
    weights <- setNames(rep(1 / n_criteria, n_criteria), all_criteria)
  }

  # Determine favorable direction for fallback normalization
  # (only used when clinical_scales is not provided)
  # Benefits: higher is better by default
  # Risks: lower is better by default
  # Note: When clinical_scales is provided, direction comes from
  # clinical_scales$direction instead
  favorable_direction <- setNames(
    c(
      rep("higher", length(benefit_criteria)),
      rep("lower", length(risk_criteria))
    ),
    all_criteria
  )

  criteria_internal <- all_criteria

  # Verify all criteria columns exist in data
  missing_cols <- setdiff(all_criteria, colnames(data))
  if (length(missing_cols) > 0) {
    stop(
      "The following criteria columns are not found in data: ",
      paste(missing_cols, collapse = ", "),
      ". ",
      "Available columns: ",
      paste(setdiff(colnames(data), "Treatment"), collapse = ", ")
    )
  }

  # Calculate treatment differences
  placebo_row <- data[data$Treatment == comparator_name, ]
  treatments <- data[data$Treatment != comparator_name, ]

  # Check if comparator exists
  if (nrow(placebo_row) == 0) {
    stop(
      "Comparator '",
      comparator_name,
      "' not found in data. ",
      "Available treatments: ",
      paste(unique(data$Treatment), collapse = ", ")
    )
  }

  # Check if comparison_drug exists
  if (!(comparison_drug %in% treatments$Treatment)) {
    stop(
      "Comparison drug '",
      comparison_drug,
      "' not found in data. ",
      "Available treatments: ",
      paste(unique(data$Treatment), collapse = ", ")
    )
  }

  # Create matrices for actual values (to be normalized separately)
  drug_actual_matrix <- matrix(
    NA,
    nrow = nrow(treatments),
    ncol = length(all_criteria)
  )
  colnames(drug_actual_matrix) <- criteria_internal
  rownames(drug_actual_matrix) <- treatments$Treatment

  placebo_actual_matrix <- matrix(
    NA,
    nrow = nrow(treatments),
    ncol = length(all_criteria)
  )
  colnames(placebo_actual_matrix) <- criteria_internal
  rownames(placebo_actual_matrix) <- treatments$Treatment

  for (i in seq_along(all_criteria)) {
    criterion <- all_criteria[i]
    criterion_int <- criteria_internal[i]

    # Store actual values for normalization
    drug_actual_matrix[, criterion_int] <- as.numeric(treatments[[criterion]])
    # Repeat placebo value for each drug row (for consistent matrix operations)
    placebo_actual_matrix[, criterion_int] <- rep(
      as.numeric(placebo_row[[criterion]]),
      nrow(treatments)
    )
  }

  # Apply clinical threshold-based value functions to normalize to
  # 0-100 scale. This approach uses fixed clinical scales (global
  # scales) rather than treatment-relative normalization (local scales)
  # as recommended by FDA/EMA best practices and the PROTECT framework.
  #
  # Key principle: Normalize ACTUAL values for each treatment
  # separately, then compute differences in normalized values.
  #
  # Benefits:
  # - Stability: Results don't change when new treatments are added
  # - Interpretability: Scores reflect absolute clinical performance
  # - Regulatory acceptance: Aligns with FDA/EMA best practices
  # - Comparability: Enables consistent evaluation across different
  #   treatment sets

  # Helper function to normalize a matrix using clinical scales
  normalize_clinical <- function(
    actual_matrix,
    clinical_scales,
    criteria_list
  ) {
    normalized <- sapply(criteria_list, function(criterion) {
      x <- actual_matrix[, criterion]

      # Check if scale is defined for this criterion
      if (is.null(clinical_scales[[criterion]])) {
        stop(sprintf(
          "Clinical scale not defined for criterion: '%s'",
          criterion
        ))
      }

      scale <- clinical_scales[[criterion]]

      # Validate scale definition
      if (
        is.null(scale$min) || is.null(scale$max) ||
          is.null(scale$direction)
      ) {
        stop(sprintf(
          "Scale for '%s' must have min, max, and direction",
          criterion
        ))
      }

      if (scale$min >= scale$max) {
        stop(
          sprintf("Scale for '%s': min must be less than max", criterion)
        )
      }

      # Apply linear value function based on clinical thresholds
      if (scale$direction == "increasing") {
        # Higher values are better: v(x) = 100 * (x - min) / (max - min)
        values <- 100 * (x - scale$min) / (scale$max - scale$min)
      } else if (scale$direction == "decreasing") {
        # Lower values are better: v(x) = 100 * (max - x) / (max - min)
        values <- 100 * (scale$max - x) / (scale$max - scale$min)
      } else {
        stop(sprintf(
          "Direction for '%s' must be 'increasing' or 'decreasing'",
          criterion
        ))
      }

      # Handle extrapolation - allow values outside [0, 100] by default
      # This is important when treatments perform outside expected
      # clinical ranges
      if (
        !is.null(scale$allow_extrapolation) &&
          !scale$allow_extrapolation
      ) {
        values <- pmax(0, pmin(100, values))
      }

      values
    })

    # Preserve row names
    if (!is.matrix(normalized)) {
      normalized <- matrix(
        normalized,
        nrow = nrow(actual_matrix),
        ncol = length(normalized),
        dimnames = list(rownames(actual_matrix), names(normalized))
      )
    }

    normalized
  }

  # If clinical scales are not provided, fall back to data-driven scales
  # (though this is not recommended per FDA/EMA guidance)
  if (is.null(clinical_scales)) {
    warning(
      "Clinical scales not provided. Using data-driven normalization",
      "(not recommended). Consider defining clinical thresholds based",
      "on clinical guidelines, MCID, or regulatory precedents."
    )

    # Compute performance differences for normalization
    perf_matrix <- matrix(
      NA,
      nrow = nrow(treatments),
      ncol = length(all_criteria)
    )
    colnames(perf_matrix) <- criteria_internal
    rownames(perf_matrix) <- treatments$Treatment

    for (i in seq_along(all_criteria)) {
      criterion <- all_criteria[i]
      criterion_int <- criteria_internal[i]
      fav_dir <- favorable_direction[criterion]

      if (fav_dir == "higher") {
        perf_matrix[, criterion_int] <- drug_actual_matrix[, criterion_int] -
          placebo_actual_matrix[, criterion_int]
      } else {
        perf_matrix[, criterion_int] <- placebo_actual_matrix[, criterion_int] -
          drug_actual_matrix[, criterion_int]
      }
    }

    normalized <- apply(perf_matrix, 2, function(x) {
      max_val <- max(x, na.rm = TRUE)
      min_val <- min(x, na.rm = TRUE)

      if (max_val == min_val) {
        return(rep(50, length(x)))
      }

      100 * (x - min_val) / (max_val - min_val)
    })
  } else {
    # Use clinical threshold-based normalization
    # Normalize drug actual values
    drug_normalized <- normalize_clinical(
      drug_actual_matrix,
      clinical_scales,
      criteria_internal
    )

    # Normalize placebo actual values
    placebo_normalized <- normalize_clinical(
      placebo_actual_matrix,
      clinical_scales,
      criteria_internal
    )

    # Ensure drug_normalized is a matrix (in case of single row)
    if (!is.matrix(drug_normalized)) {
      drug_normalized <- matrix(
        drug_normalized,
        nrow = 1,
        ncol = length(drug_normalized),
        dimnames = list(rownames(drug_actual_matrix), names(drug_normalized))
      )
    }

    # Ensure placebo_normalized is a matrix (in case of single row)
    if (!is.matrix(placebo_normalized)) {
      placebo_normalized <- matrix(
        placebo_normalized,
        nrow = 1,
        ncol = length(placebo_normalized),
        dimnames = list(
          rownames(placebo_actual_matrix),
          names(placebo_normalized)
        )
      )
    }

    # Compute difference in normalized values:
    # Drug normalized - Placebo normalized
    # This represents how much better (or worse) the drug performs
    # compared to placebo on the 0-100 value scale
    normalized <- drug_normalized - placebo_normalized
  }

  # Ensure normalized is a matrix (in case of single row)
  if (!is.matrix(normalized)) {
    normalized <- matrix(
      normalized,
      nrow = 1,
      ncol = length(normalized),
      dimnames = list(rownames(drug_actual_matrix), names(normalized))
    )
  }

  # Get the row for the comparison drug
  drug_idx <- which(rownames(drug_actual_matrix) == comparison_drug)
  if (length(drug_idx) == 0) {
    drug_idx <- 1
  }

  # For the walkthrough visualization, we show:
  # 1. Difference in normalized values
  #    (Drug normalized - Placebo normalized)
  # 2. Weights
  # 3. Weighted contributions (Benefit-Risk)
  #
  # The "normalized" matrix already contains differences in normalized values,
  # which is what we want to display in the "Difference" panel

  drug_values <- normalized[drug_idx, ]
  drug_weights <- weights[criteria_internal] * 100
  drug_contributions <- drug_values * weights[criteria_internal]
  drug_total <- sum(drug_contributions)

  x_max <- 100

  # Panel 1: Difference (Drug normalized - Placebo normalized)
  # This shows how much better (positive) or worse (negative) the drug
  # performs compared to placebo on the normalized 0-100 value scale
  drug_values_df <- data.frame(
    Criterion = factor(all_criteria, levels = rev(all_criteria)),
    Value = drug_values,
    Type = c(
      rep("Benefit", length(benefit_criteria)),
      rep("Risk", length(risk_criteria))
    )
  )

  # Calculate symmetric scale around zero for normalized differences
  max_abs_norm <- max(abs(drug_values), na.rm = TRUE)
  norm_lim <- c(-max_abs_norm * 1.15, max_abs_norm * 1.15)

  p_values <- ggplot(
    drug_values_df,
    aes(x = Value, y = Criterion, fill = Type)
  ) +
    geom_bar(stat = "identity", width = 0.7) +
    geom_vline(xintercept = 0, linetype = "solid", color = "black") +
    scale_fill_manual(
      values = c("Benefit" = fig_colors[1], "Risk" = fig_colors[2])
    ) +
    scale_x_continuous(limits = norm_lim, expand = c(0.02, 0)) +
    labs(
      title = "Difference",
      subtitle = paste0(
        "Normalized ",
        comparison_drug,
        " - Normalized ",
        comparator_name
      ),
      x = NULL,
      y = NULL
    ) +
    theme_minimal() +
    theme(
      axis.text.y = element_text(size = 10),
      axis.ticks.x = element_line(color = "grey92"),
      legend.position = "none",
      plot.title = element_text(size = 12, face = "bold", hjust = 0.5),
      plot.subtitle = element_text(size = 10, hjust = 0.5),
      plot.margin = margin(5, 15, 5, 5)
    ) +
    geom_text(
      aes(
        label = sprintf("%.0f", Value),
        hjust = ifelse(Value < 0, 1.2, -0.1)
      ),
      size = 3
    ) +
    coord_cartesian(clip = "off")

  # Panel 2: Weights
  weights_df_plot <- data.frame(
    Criterion = factor(all_criteria, levels = rev(all_criteria)),
    Weight = drug_weights,
    Type = c(
      rep("Benefit", length(benefit_criteria)),
      rep("Risk", length(risk_criteria))
    )
  )

  p_weights <- ggplot(
    weights_df_plot,
    aes(x = Weight, y = Criterion, fill = Type)
  ) +
    geom_bar(stat = "identity", width = 0.7) +
    geom_vline(xintercept = 0, linetype = "solid", color = "black") +
    scale_fill_manual(
      values = c("Benefit" = fig_colors[1], "Risk" = fig_colors[2])
    ) +
    scale_x_continuous(limits = c(0, x_max), expand = c(0.02, 0)) +
    labs(
      title = "Weight",
      subtitle = "Importance (%)",
      x = NULL,
      y = NULL
    ) +
    theme_minimal() +
    theme(
      axis.text.y = element_blank(),
      axis.ticks.x = element_line(color = "grey92"),
      legend.position = "none",
      plot.title = element_text(size = 12, face = "bold", hjust = 0.5),
      plot.subtitle = element_text(size = 10, hjust = 0.5),
      plot.margin = margin(5, 15, 5, 5)
    ) +
    geom_text(aes(label = sprintf("%.0f", Weight)), hjust = -0.1, size = 3) +
    coord_cartesian(clip = "off")

  # Panel 3: Weighted Contributions (Benefit-Risk)
  # Positive contributions = Drug better than Placebo
  # Negative contributions = Drug worse than Placebo
  drug_contrib_df <- data.frame(
    Criterion = factor(all_criteria, levels = rev(all_criteria)),
    Contribution = drug_contributions,
    Type = c(
      rep("Benefit", length(benefit_criteria)),
      rep("Risk", length(risk_criteria))
    )
  )

  # Calculate symmetric scale around zero for weighted contributions
  max_abs_contrib <- max(abs(drug_contributions), na.rm = TRUE)
  contrib_lim <- c(-max_abs_contrib * 1.15, max_abs_contrib * 1.15)

  p_weighted <- ggplot(
    drug_contrib_df,
    aes(x = Contribution, y = Criterion, fill = Type)
  ) +
    geom_bar(stat = "identity", width = 0.7) +
    geom_vline(xintercept = 0, linetype = "solid", color = "black") +
    scale_fill_manual(
      values = c("Benefit" = fig_colors[1], "Risk" = fig_colors[2])
    ) +
    scale_x_continuous(limits = contrib_lim, expand = c(0.02, 0)) +
    labs(
      title = "Benefit-Risk",
      subtitle = sprintf("Total = %.1f", drug_total),
      x = NULL,
      y = NULL
    ) +
    theme_minimal() +
    theme(
      axis.text.y = element_blank(),
      axis.ticks.x = element_line(color = "grey92"),
      legend.position = "none",
      plot.title = element_text(size = 12, face = "bold", hjust = 0.5),
      plot.subtitle = element_text(size = 10, hjust = 0.5),
      plot.margin = margin(5, 15, 5, 5)
    ) +
    geom_text(
      aes(
        label = sprintf("%.1f", Contribution),
        hjust = ifelse(Contribution < 0, 1.2, -0.1)
      ),
      size = 3
    ) +
    coord_cartesian(clip = "off")

  # Add borders to individual panels
  p_values <- p_values +
    theme(
      plot.background = element_rect(
        color = "darkgray",
        fill = NA,
        linewidth = 1
      )
    )
  p_weights <- p_weights +
    theme(
      plot.background = element_rect(
        color = "darkgray",
        fill = NA,
        linewidth = 1
      )
    )
  p_weighted <- p_weighted +
    theme(
      plot.background = element_rect(
        color = "darkgray",
        fill = NA,
        linewidth = 1
      )
    )

  # Combine panels - 3 panels
  # Order: Normalized Difference -> Weight -> Benefit-Risk
  combined_plot <- patchwork::wrap_plots(
    p_values,
    p_weights,
    p_weighted,
    ncol = 3,
    widths = c(1.2, 1, 1)
  )

  combined_plot
}
