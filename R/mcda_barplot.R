#' Prepare MCDA data from effects table
#'
#' @param source_data The effects table dataset (effects_table format).
#' @param placebo_name Name of the placebo. Default is "Placebo".
#'
#' @return A data frame in wide format with Treatment as rows and criteria as columns.
#'   Each row contains the raw values for that treatment. Note: Outcomes are on
#'   different scales:
#'   - Binary outcomes (e.g., Benefit 1, Risk 1): proportions (0-1 scale)
#'   - Continuous outcomes (e.g., Benefit 2, Benefit 3): means (various scales)
#' @export
#'
#' @details
#' This function transforms the long-format effects_table into wide format
#' suitable for MCDA visualizations. Each treatment retains its raw values on
#' the original measurement scales:
#' \itemize{
#'   \item Binary outcomes use Prop1/Prop2 (proportions: 0-1)
#'   \item Continuous outcomes use Mean1/Mean2 (original measurement units)
#' }
#' The MCDA visualization functions will calculate treatment differences from
#' placebo and display the transformation steps.
#'
#' @examples
#' # Prepare data from effects_table
#' mcda_data <- prepare_mcda_data(effects_table)
#' head(mcda_data)
#'
#' # Check the structure - raw values for each treatment
#' str(mcda_data)
#' # Each row contains raw values on original scales
prepare_mcda_data <- function(
  source_data,
  placebo_name = "Placebo"
) {
  # Filter for identified outcomes only, Category == 'All'
  identified <- source_data[
    source_data$Outcome_Status == "Identified" &
      source_data$Category == "All",
  ]

  # Get unique drugs (Trt1 values)
  drugs <- unique(identified$Trt1)

  # Extract unique outcomes
  outcomes <- unique(identified$Outcome)

  # Initialize result data frame
  result <- data.frame(Treatment = character(), stringsAsFactors = FALSE)

  # First, get placebo values from any drug row (Trt2/Prop2/Mean2)
  first_drug_data <- identified[identified$Trt1 == drugs[1], ]
  placebo_row <- data.frame(Treatment = placebo_name, stringsAsFactors = FALSE)

  for (outcome in outcomes) {
    row_data <- first_drug_data[first_drug_data$Outcome == outcome, ]

    if (nrow(row_data) == 0) {
      placebo_row[[outcome]] <- NA
      next
    }

    row_data <- row_data[1, ]

    # Extract placebo value
    if (!is.na(row_data$Prop2)) {
      placebo_row[[outcome]] <- row_data$Prop2
    } else if (!is.na(row_data$Mean2)) {
      placebo_row[[outcome]] <- row_data$Mean2
    } else {
      placebo_row[[outcome]] <- NA
    }
  }

  result <- rbind(result, placebo_row)

  # Process each drug
  for (drug in drugs) {
    drug_data <- identified[identified$Trt1 == drug, ]

    # Create a new row for this drug
    drug_row <- data.frame(Treatment = drug, stringsAsFactors = FALSE)

    for (outcome in outcomes) {
      row_data <- drug_data[drug_data$Outcome == outcome, ]

      if (nrow(row_data) == 0) {
        drug_row[[outcome]] <- NA
        next
      }

      row_data <- row_data[1, ]

      # Extract drug value (raw value, not difference)
      if (!is.na(row_data$Prop1)) {
        # Binary outcome - proportion scale (0-1)
        drug_row[[outcome]] <- row_data$Prop1
      } else if (!is.na(row_data$Mean1)) {
        # Continuous outcome - original measurement scale
        drug_row[[outcome]] <- row_data$Mean1
      } else {
        drug_row[[outcome]] <- NA
      }
    }

    # Add this drug's row to the result
    result <- rbind(result, drug_row)
  }

  return(result)
}

#' Create MCDA Bar Chart: From Raw Data to Treatment Differences
#'
#' @param data A data frame in wide format with Treatment column and criteria columns.
#'   Required parameter - must be provided. Should be the output from prepare_mcda_data(),
#'   which contains raw values for each treatment on their original measurement scales.
#' @param placebo_name Character string specifying the name of the placebo/control
#'   treatment in the data. Default is "Placebo".
#' @param comparison_drug Character string specifying which drug to compare with
#'   placebo in the visualization. Default is "Drug A".
#' @param benefit_criteria Character vector of benefit criterion names (column names in data).
#' @param risk_criteria Character vector of risk criterion names (column names in data).
#' @param fig_colors A vector of length 2 specifying colors for benefits and risks.
#'   Default is c("#0571b0", "#ca0020") to match correlogram colors.
#'
#' @return A patchwork object showing three panels: Placebo values, Drug values, and
#'   Treatment Differences (Drug - Placebo), or NULL if data is not provided.
#' @export
#' @import ggplot2
#' @importFrom patchwork wrap_plots
#' @importFrom ggh4x facetted_pos_scales
#'
#' @examples
#' # Prepare data from effects_table (extracts raw values for all treatments)
#' mcda_data <- prepare_mcda_data(effects_table)
#'
#' # View the data structure - each row has raw values
#' head(mcda_data)
#' #   Treatment Benefit 1 Benefit 2 Benefit 3 Risk 1 Risk 2
#' # 1   Placebo      0.05        65         9   0.30  0.087
#' # 2    Drug A      0.46        20        60   0.46  0.100
#' # 3    Drug B      ...
#'
#' # Create comparison barplot showing Placebo | Drug B | Treatment Difference
#' barplot_comp <- create_mcda_barplot_comparison(
#'   data = mcda_data,
#'   benefit_criteria = c("Benefit 1", "Benefit 2", "Benefit 3"),
#'   risk_criteria = c("Risk 1", "Risk 2"),
#'   comparison_drug = "Drug B"
#' )
#'
#' # Compare a different drug
#' \dontrun{
#' barplot_comp_a <- create_mcda_barplot_comparison(
#'   data = mcda_data,
#'   benefit_criteria = c("Benefit 1", "Benefit 2", "Benefit 3"),
#'   risk_criteria = c("Risk 1", "Risk 2"),
#'   comparison_drug = "Drug A"
#' )
#' ggsave(
#'   "inst/img/barplot_mcda_comparison_drug_a.png",
#'   barplot_comp_a,
#'   width = 12,
#'   height = 6,
#'   dpi = 300
#' )
#' }
create_mcda_barplot_comparison <- function(data = NULL,
                                           placebo_name = "Placebo",
                                           comparison_drug = "Drug A",
                                           benefit_criteria = NULL,
                                           risk_criteria = NULL,
                                           fig_colors = c("#0571b0", "#ca0020")) {
  # Check if data is provided
  if (is.null(data)) {
    warning("No data provided. Please supply a data frame with Treatment column and criteria columns. Use prepare_mcda_data() to prepare data from effects_table.")
    return(invisible(NULL))
  }

  # Check if criteria are provided
  if (is.null(benefit_criteria) || is.null(risk_criteria)) {
    stop("Both benefit_criteria and risk_criteria must be specified as column names in the data.")
  }

  # Extract placebo and drug data
  placebo_row <- data[data$Treatment == placebo_name, ]
  drug_row <- data[data$Treatment == comparison_drug, ]

  # Check if comparison_drug exists
  if (nrow(drug_row) == 0) {
    stop(paste0("Comparison drug '", comparison_drug, "' not found in data. Available treatments: ", paste(unique(data$Treatment), collapse = ", ")))
  }

  # Check if placebo exists
  if (nrow(placebo_row) == 0) {
    stop(paste0("Placebo '", placebo_name, "' not found in data. Available treatments: ", paste(unique(data$Treatment), collapse = ", ")))
  }

  all_criteria <- c(benefit_criteria, risk_criteria)

  # Verify all criteria columns exist in data
  missing_cols <- setdiff(all_criteria, colnames(data))
  if (length(missing_cols) > 0) {
    stop(paste0("The following criteria columns are not found in data: ", paste(missing_cols, collapse = ", "), ". Available columns: ", paste(setdiff(colnames(data), "Treatment"), collapse = ", ")))
  }

  # Create values for each panel
  placebo_values <- unlist(placebo_row[, all_criteria, drop = FALSE])
  drug_values <- unlist(drug_row[, all_criteria, drop = FALSE])
  diff_values <- drug_values - placebo_values

  # Adjust for risks (for display purposes, scale if needed)
  # For AE/SAE that are proportions, multiply by 100 for percentage
  for (i in seq_along(all_criteria)) {
    criterion <- all_criteria[i]
    if (grepl("Efficacy", criterion, ignore.case = TRUE) &&
      max(abs(c(placebo_values[i], drug_values[i]))) < 1) {
      placebo_values[i] <- placebo_values[i] * 100
      drug_values[i] <- drug_values[i] * 100
      diff_values[i] <- diff_values[i] * 100
    } else if (grepl("AE|SAE", criterion, ignore.case = TRUE) &&
      max(abs(c(placebo_values[i], drug_values[i]))) < 1) {
      placebo_values[i] <- placebo_values[i] * 100
      drug_values[i] <- drug_values[i] * 100
      diff_values[i] <- diff_values[i] * 100
    }
  }

  # Helper function to determine tick interval based on magnitude
  get_tick_interval <- function(max_val) {
    if (max_val <= 0.01) {
      0.002
    } else if (max_val <= 0.05) {
      0.01
    } else if (max_val <= 1) {
      0.2
    } else if (max_val <= 5) {
      1
    } else if (max_val <= 10) {
      2
    } else if (max_val <= 20) {
      5
    } else if (max_val <= 50) {
      10
    } else if (max_val <= 100) {
      20
    } else {
      50
    }
  }

  # Helper function to round up to nearest tick interval
  round_to_tick <- function(x, interval) {
    ceiling(x / interval) * interval
  }

  # Calculate max value for each outcome
  outcome_maxes <- sapply(seq_along(all_criteria), function(i) {
    max(c(placebo_values[i], drug_values[i]), na.rm = TRUE)
  })

  # Determine tick interval for each outcome
  outcome_intervals <- sapply(outcome_maxes, get_tick_interval)

  # For each interval group, find the max value and create common limits
  outcome_scale_info <- lapply(seq_along(all_criteria), function(i) {
    interval <- outcome_intervals[i]
    # Find all outcomes with same interval
    same_interval_idx <- which(outcome_intervals == interval)
    group_max <- max(outcome_maxes[same_interval_idx], na.rm = TRUE)
    group_max_rounded <- round_to_tick(group_max, interval)

    list(
      lim = c(0, group_max_rounded),
      breaks = seq(0, group_max_rounded, by = interval)
    )
  })

  # Create separate plots for each outcome, then combine them
  outcome_plots <- list()

  for (i in seq_along(all_criteria)) {
    criterion <- all_criteria[i]
    criterion_type <- if (criterion %in% benefit_criteria) "Benefit" else "Risk"

    # Create data for this outcome - each row is a different treatment group
    outcome_data <- data.frame(
      Group = c(placebo_name, comparison_drug, "Treatment Difference"),
      Value = c(placebo_values[i], drug_values[i], diff_values[i]),
      Type = criterion_type,
      stringsAsFactors = FALSE
    )

    outcome_data$Group <- factor(outcome_data$Group,
      levels = c(placebo_name, comparison_drug, "Treatment Difference")
    )

    # Determine if this is the first outcome (for labels on left)
    is_first <- (i == 1)

    # Determine if this is the last outcome (for x-axis labels)
    is_last <- (i == length(all_criteria))

    # Use the scale for this outcome's group (aligned with similar-scaled outcomes)
    raw_lim <- outcome_scale_info[[i]]$lim
    raw_breaks <- outcome_scale_info[[i]]$breaks

    # Calculate range for difference plot - symmetric around zero
    diff_val <- abs(diff_values[i])
    diff_max <- diff_val * 1.15
    diff_lim <- c(-diff_max, diff_max)

    # Create individual plots for each group
    # Plot 1: Placebo
    plot_placebo <- ggplot(
      outcome_data[outcome_data$Group == placebo_name, ],
      aes(x = Value, y = Type, fill = Type)
    ) +
      geom_col(width = 0.7) +
      geom_vline(xintercept = 0, linetype = "solid", color = "black") +
      scale_fill_manual(values = c("Benefit" = fig_colors[1], "Risk" = fig_colors[2])) +
      scale_x_continuous(limits = raw_lim, breaks = raw_breaks, expand = c(0.02, 0)) +
      labs(
        title = if (is_first) placebo_name else NULL,
        x = NULL,
        y = criterion
      ) +
      theme_minimal() +
      theme(
        legend.position = "none",
        plot.title = element_text(size = 12, face = "bold", hjust = 0.5),
        axis.text.y = element_blank(),
        axis.text.x = element_text(size = 9),
        axis.title.y = element_text(size = 11, face = "bold", angle = 0, vjust = 0.5, hjust = 1),
        axis.title.x = if (is_last) element_text(size = 10, face = "bold") else element_blank(),
        axis.ticks.y = element_blank(),
        axis.ticks.x = element_line(color = "grey92"),
        panel.grid.major.y = element_blank(),
        panel.grid.minor.y = element_blank(),
        plot.margin = margin(5, 15, 5, 5)
      ) +
      geom_text(aes(label = Value), hjust = -0.1, size = 3) +
      coord_cartesian(clip = "off")

    # Plot 2: Drug A
    plot_drug <- ggplot(
      outcome_data[outcome_data$Group == comparison_drug, ],
      aes(x = Value, y = Type, fill = Type)
    ) +
      geom_col(width = 0.7) +
      geom_vline(xintercept = 0, linetype = "solid", color = "black") +
      scale_fill_manual(values = c("Benefit" = fig_colors[1], "Risk" = fig_colors[2])) +
      scale_x_continuous(limits = raw_lim, breaks = raw_breaks, expand = c(0.02, 0)) +
      labs(
        title = if (is_first) comparison_drug else NULL,
        x = NULL,
        y = ""
      ) +
      theme_minimal() +
      theme(
        legend.position = "none",
        plot.title = element_text(size = 12, face = "bold", hjust = 0.5),
        axis.text.y = element_blank(),
        axis.text.x = element_text(size = 9),
        axis.title.x = if (is_last) element_text(size = 10, face = "bold") else element_blank(),
        axis.ticks.y = element_blank(),
        axis.ticks.x = element_line(color = "grey92"),
        panel.grid.major.y = element_blank(),
        panel.grid.minor.y = element_blank(),
        plot.margin = margin(5, 15, 5, 5)
      ) +
      geom_text(aes(label = Value), hjust = -0.1, size = 3) +
      coord_cartesian(clip = "off")

    # Plot 3: Treatment Difference
    plot_diff <- ggplot(
      outcome_data[outcome_data$Group == "Treatment Difference", ],
      aes(x = Value, y = Type, fill = Type)
    ) +
      geom_col(width = 0.7) +
      geom_vline(xintercept = 0, linetype = "solid", color = "black") +
      scale_fill_manual(values = c("Benefit" = fig_colors[1], "Risk" = fig_colors[2])) +
      scale_x_continuous(limits = diff_lim, expand = c(0.02, 0)) +
      labs(
        title = if (is_first) "Treatment Difference" else NULL,
        x = NULL,
        y = ""
      ) +
      theme_minimal() +
      theme(
        legend.position = "none",
        plot.title = element_text(size = 12, face = "bold", hjust = 0.5),
        axis.text.y = element_blank(),
        axis.text.x = element_text(size = 9),
        axis.title.x = if (is_last) element_text(size = 10, face = "bold") else element_blank(),
        axis.ticks.y = element_blank(),
        axis.ticks.x = element_line(color = "grey92"),
        panel.grid.major.y = element_blank(),
        panel.grid.minor.y = element_blank(),
        plot.margin = margin(5, 15, 5, 5)
      ) +
      geom_text(aes(label = Value),
        hjust = ifelse(diff_values[i] < 0, 1.2, -0.1),
        size = 3
      ) +
      coord_cartesian(clip = "off")

    # Combine the three plots horizontally for this outcome
    outcome_row <- patchwork::wrap_plots(plot_placebo, plot_drug, plot_diff, ncol = 3, widths = c(1.2, 1, 1)) &
      theme(
        plot.background = element_rect(color = "grey92", fill = NA, linewidth = 0.5)
      )
    outcome_plots[[criterion]] <- outcome_row
  }

  # Combine all outcome rows vertically using patchwork
  combined <- patchwork::wrap_plots(outcome_plots, ncol = 1) +
    patchwork::plot_layout(guides = "collect")

  return(combined)
}

#' Create MCDA Bar Chart: Calculation Walkthrough
#'
#' @param data A data frame in wide format with Treatment column and criteria columns.
#'   Required parameter - must be provided. Should be the output from prepare_mcda_data(),
#'   which contains raw values for each treatment on their original measurement scales.
#' @param placebo_name Character string specifying the name of the placebo/control
#'   treatment. Default is "Placebo".
#' @param comparison_drug Character string specifying which drug to show the
#'   calculation for. Default is "Drug A".
#' @param benefit_criteria Character vector of benefit criterion names (column names in data).
#' @param risk_criteria Character vector of risk criterion names (column names in data).
#' @param weights Named numeric vector of criterion weights. Must sum to 1.
#'   If NULL, uses equal weights.
#' @param favorable_direction Named character vector specifying the favorable direction
#'   for each criterion. Values should be either "higher" or "lower". If NULL, defaults to
#'   "higher" for benefits and "lower" for risks. Use this to specify outcomes like
#'   "Benefit 2" where lower values are better (e.g., symptom severity, days to recovery).
#' @param fig_colors A vector of length 2 specifying colors for benefits and risks.
#'   Default is c("#0571b0", "#ca0020").
#'
#' @return A grid arrangement of four panels showing: (1) Treatment Difference
#'   (Drug - Placebo), (2) Weights, (3) Normalized values, and (4) Weighted
#'   contributions, or NULL if data is not provided.
#' @export
#' @import ggplot2
#' @importFrom gridExtra arrangeGrob
#' @importFrom grid textGrob gpar
#'
#' @examples
#' # Prepare data from effects_table (extracts raw values for all treatments)
#' mcda_data <- prepare_mcda_data(effects_table)
#'
#' # View the data structure - each row has raw values
#' head(mcda_data)
#' #   Treatment Benefit 1 Benefit 2 Benefit 3 Risk 1 Risk 2
#' # 1   Placebo      0.05        65         9   0.30  0.087
#' # 2    Drug A      0.46        20        60   0.46  0.100
#'
#' # Create walkthrough showing the MCDA calculation steps for Drug B
#' barplot_walk <- create_mcda_barplot_walkthrough(
#'   data = mcda_data,
#'   benefit_criteria = c("Benefit 1", "Benefit 2", "Benefit 3"),
#'   risk_criteria = c("Risk 1", "Risk 2"),
#'   comparison_drug = "Drug B"
#' )
#'
#' # With custom weights for Drug A
#' \dontrun{
#' weights <- c(
#'   `Benefit 1` = 0.30,
#'   `Benefit 2` = 0.20,
#'   `Benefit 3` = 0.10,
#'   `Risk 1` = 0.30,
#'   `Risk 2` = 0.10
#' )
#'
#' # Specify that Benefit 2 is "lower is better" (e.g., symptom severity)
#' favorable_dir <- c(
#'   `Benefit 1` = "higher",
#'   `Benefit 2` = "lower",
#'   `Benefit 3` = "higher",
#'   `Risk 1` = "lower",
#'   `Risk 2` = "lower"
#' )
#'
#' barplot_walk_a <- create_mcda_barplot_walkthrough(
#'   data = mcda_data,
#'   benefit_criteria = c("Benefit 1", "Benefit 2", "Benefit 3"),
#'   risk_criteria = c("Risk 1", "Risk 2"),
#'   comparison_drug = "Drug A",
#'   weights = weights,
#'   favorable_direction = favorable_dir
#' )
#' ggsave(
#'   "inst/img/barplot_mcda_walkthrough_drug_a.png",
#'   barplot_walk_a,
#'   width = 14,
#'   height = 6,
#'   dpi = 300
#' )
#' }
create_mcda_barplot_walkthrough <- function(data = NULL,
                                            placebo_name = "Placebo",
                                            comparison_drug = "Drug A",
                                            benefit_criteria = NULL,
                                            risk_criteria = NULL,
                                            weights = NULL,
                                            favorable_direction = NULL,
                                            fig_colors = c("#0571b0", "#ca0020")) {
  # Check if data is provided
  if (is.null(data)) {
    warning("No data provided. Please supply a data frame with Treatment column and criteria columns. Use prepare_mcda_data() to prepare data from effects_table.")
    return(invisible(NULL))
  }

  # Check if criteria are provided
  if (is.null(benefit_criteria) || is.null(risk_criteria)) {
    stop("Both benefit_criteria and risk_criteria must be specified as column names in the data.")
  }

  # Default weights if not provided - equal weights
  all_criteria <- c(benefit_criteria, risk_criteria)
  if (is.null(weights)) {
    n_criteria <- length(all_criteria)
    weights <- setNames(rep(1 / n_criteria, n_criteria), all_criteria)
  }

  # Default favorable direction if not provided
  # Benefits: higher is better by default
  # Risks: lower is better by default
  if (is.null(favorable_direction)) {
    favorable_direction <- setNames(
      c(rep("higher", length(benefit_criteria)), rep("lower", length(risk_criteria))),
      all_criteria
    )
  }

  criteria_internal <- all_criteria

  # Verify all criteria columns exist in data
  missing_cols <- setdiff(all_criteria, colnames(data))
  if (length(missing_cols) > 0) {
    stop(paste0("The following criteria columns are not found in data: ", paste(missing_cols, collapse = ", "), ". Available columns: ", paste(setdiff(colnames(data), "Treatment"), collapse = ", ")))
  }

  # Calculate treatment differences
  placebo_row <- data[data$Treatment == placebo_name, ]
  treatments <- data[data$Treatment != placebo_name, ]

  # Check if placebo exists
  if (nrow(placebo_row) == 0) {
    stop(paste0("Placebo '", placebo_name, "' not found in data. Available treatments: ", paste(unique(data$Treatment), collapse = ", ")))
  }

  # Check if comparison_drug exists
  if (!(comparison_drug %in% treatments$Treatment)) {
    stop(paste0("Comparison drug '", comparison_drug, "' not found in data. Available treatments: ", paste(unique(data$Treatment), collapse = ", ")))
  }

  # Create two matrices:
  # 1. raw_diff_matrix: actual raw differences (Drug - Placebo) for display
  # 2. perf_matrix: performance-oriented differences for normalization
  raw_diff_matrix <- matrix(NA, nrow = nrow(treatments), ncol = length(all_criteria))
  colnames(raw_diff_matrix) <- criteria_internal
  rownames(raw_diff_matrix) <- treatments$Treatment

  perf_matrix <- matrix(NA, nrow = nrow(treatments), ncol = length(all_criteria))
  colnames(perf_matrix) <- criteria_internal
  rownames(perf_matrix) <- treatments$Treatment

  for (i in seq_along(all_criteria)) {
    criterion <- all_criteria[i]
    criterion_int <- criteria_internal[i]

    # Always calculate raw difference as Drug - Placebo for display
    raw_diff_matrix[, criterion_int] <- as.numeric(treatments[[criterion]]) - as.numeric(placebo_row[[criterion]])

    # Get the favorable direction for this criterion
    fav_dir <- favorable_direction[criterion]

    if (fav_dir == "higher") {
      # Higher is better: positive difference means improvement
      # drug - placebo: positive = drug better than placebo
      perf_matrix[, criterion_int] <- as.numeric(treatments[[criterion]]) - as.numeric(placebo_row[[criterion]])
    } else {
      # Lower is better: negative raw difference means improvement, so flip the sign
      # placebo - drug: positive performance = drug better than placebo (lower value)
      perf_matrix[, criterion_int] <- as.numeric(placebo_row[[criterion]]) - as.numeric(treatments[[criterion]])
    }
  }

  # Normalize to 0-100 scale
  # For each criterion, normalize across all treatments:
  # 0 = worst treatment difference, 100 = best treatment difference
  # This is the standard MCDA normalization approach

  normalized <- apply(perf_matrix, 2, function(x) {
    if (max(x) == min(x)) {
      # All treatments perform the same - assign middle value
      return(rep(50, length(x)))
    }
    # Normalize: (x - min) / (max - min) * 100
    (x - min(x)) / (max(x) - min(x)) * 100
  })

  # Ensure normalized is a matrix (in case of single row)
  if (!is.matrix(normalized)) {
    normalized <- matrix(normalized,
      nrow = 1, ncol = length(normalized),
      dimnames = list(rownames(perf_matrix), names(normalized))
    )
  }

  # Get the row for the comparison drug
  drug_idx <- which(rownames(perf_matrix) == comparison_drug)
  if (length(drug_idx) == 0) drug_idx <- 1

  drug_values <- normalized[drug_idx, ]
  drug_weights <- weights[criteria_internal] * 100
  drug_contributions <- drug_values * weights[criteria_internal]
  drug_total <- sum(drug_contributions)

  x_max <- 100

  # Get raw treatment differences for the comparison drug (actual Drug - Placebo)
  drug_idx <- which(rownames(raw_diff_matrix) == comparison_drug)
  if (length(drug_idx) == 0) drug_idx <- 1
  raw_diff_values <- raw_diff_matrix[drug_idx, ]

  # Panel 1: Raw Treatment Differences
  raw_diff_df <- data.frame(
    Criterion = factor(all_criteria, levels = rev(all_criteria)),
    Value = raw_diff_values,
    Type = c(rep("Benefit", length(benefit_criteria)), rep("Risk", length(risk_criteria)))
  )

  # Determine scale for raw differences - symmetric around zero
  max_abs_diff <- max(abs(raw_diff_values), na.rm = TRUE)
  diff_lim <- c(-max_abs_diff * 1.15, max_abs_diff * 1.15)

  p_raw_diff <- ggplot(raw_diff_df, aes(x = Value, y = Criterion, fill = Type)) +
    geom_bar(stat = "identity", width = 0.7) +
    scale_fill_manual(values = c("Benefit" = fig_colors[1], "Risk" = fig_colors[2])) +
    scale_x_continuous(limits = diff_lim, expand = c(0.02, 0)) +
    labs(
      title = "Treatment Difference",
      subtitle = paste0(comparison_drug, " vs ", placebo_name),
      x = NULL, y = NULL
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
    geom_text(aes(label = Value),
      hjust = ifelse(raw_diff_values < 0, 1.2, -0.1),
      size = 3
    ) +
    coord_cartesian(clip = "off")

  # Panel 2: Weights
  weights_df_plot <- data.frame(
    Criterion = factor(all_criteria, levels = rev(all_criteria)),
    Weight = drug_weights,
    Type = c(rep("Benefit", length(benefit_criteria)), rep("Risk", length(risk_criteria)))
  )

  p_weights <- ggplot(weights_df_plot, aes(x = Weight, y = Criterion, fill = Type)) +
    geom_bar(stat = "identity", width = 0.7) +
    scale_fill_manual(values = c("Benefit" = fig_colors[1], "Risk" = fig_colors[2])) +
    scale_x_continuous(limits = c(0, x_max), expand = c(0.02, 0)) +
    labs(title = "Weight", subtitle = "Importance (%)", x = NULL, y = NULL) +
    theme_minimal() +
    theme(
      axis.text.y = element_blank(),
      axis.ticks.x = element_line(color = "grey92"),
      legend.position = "none",
      plot.title = element_text(size = 12, face = "bold", hjust = 0),
      plot.subtitle = element_text(size = 10, hjust = 0),
      plot.margin = margin(5, 15, 5, 5)
    ) +
    geom_text(aes(label = Weight), hjust = -0.1, size = 3) +
    coord_cartesian(clip = "off")

  # Panel 3: Drug Normalized Values
  drug_values_df <- data.frame(
    Criterion = factor(all_criteria, levels = rev(all_criteria)),
    Value = drug_values,
    Type = c(rep("Benefit", length(benefit_criteria)), rep("Risk", length(risk_criteria)))
  )

  p_values <- ggplot(drug_values_df, aes(x = Value, y = Criterion, fill = Type)) +
    geom_bar(stat = "identity", width = 0.7) +
    scale_fill_manual(values = c("Benefit" = fig_colors[1], "Risk" = fig_colors[2])) +
    scale_x_continuous(limits = c(0, x_max), expand = c(0.02, 0)) +
    labs(title = "Normalized Value", subtitle = "0-100 scale (%)", x = NULL, y = NULL) +
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
        label = sprintf("%.0f", Value),
        hjust = ifelse(Value == 100, 1.1, -0.1),
        color = ifelse(Value == 100, "white", "black")
      ),
      size = 3
    ) +
    scale_color_identity() +
    coord_cartesian(clip = "off")

  # Panel 4: Weighted Contributions
  drug_contrib_df <- data.frame(
    Criterion = factor(all_criteria, levels = rev(all_criteria)),
    Contribution = drug_contributions,
    Type = c(rep("Benefit", length(benefit_criteria)), rep("Risk", length(risk_criteria)))
  )

  p_weighted <- ggplot(drug_contrib_df, aes(x = Contribution, y = Criterion, fill = Type)) +
    geom_bar(stat = "identity", width = 0.7) +
    scale_fill_manual(values = c("Benefit" = fig_colors[1], "Risk" = fig_colors[2])) +
    scale_x_continuous(limits = c(0, x_max), expand = c(0.02, 0)) +
    labs(
      title = "Benefit-Risk",
      subtitle = sprintf("Total = %.1f", drug_total),
      x = NULL, y = NULL
    ) +
    theme_minimal() +
    theme(
      axis.text.y = element_blank(),
      axis.ticks.x = element_line(color = "grey92"),
      legend.position = "none",
      plot.title = element_text(size = 12, face = "bold", hjust = 0),
      plot.subtitle = element_text(size = 10, hjust = 0),
      plot.margin = margin(5, 15, 5, 5)
    ) +
    geom_text(aes(label = sprintf("%.1f", Contribution)), hjust = -0.1, size = 3) +
    coord_cartesian(clip = "off")

  # Add borders to individual panels
  p_raw_diff <- p_raw_diff + theme(plot.background = element_rect(color = "grey92", fill = NA, linewidth = 0.5))
  p_values <- p_values + theme(plot.background = element_rect(color = "grey92", fill = NA, linewidth = 0.5))
  p_weights <- p_weights + theme(plot.background = element_rect(color = "grey92", fill = NA, linewidth = 0.5))
  p_weighted <- p_weighted + theme(plot.background = element_rect(color = "grey92", fill = NA, linewidth = 0.5))

  # Combine panels - now 4 panels
  # Order: Treatment Difference -> Normalized Value -> Weight -> Benefit-Risk
  combined_plot <- patchwork::wrap_plots(p_raw_diff, p_values, p_weights, p_weighted,
    ncol = 4,
    widths = c(1.2, 1, 1, 1)
  )

  return(combined_plot)
}
