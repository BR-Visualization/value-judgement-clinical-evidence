#' Create MCDA Bar Chart: Normalized Values Comparison
#'
#' @param data A data frame in wide format with Study, Treatment, and
#'   criteria columns. Required parameter - must be provided. Each row
#'   should contain raw values for a treatment on their original
#'   measurement scales. See \code{\link{mcda_data}} for example format.
#' @param study Character string specifying which study to analyze.
#'   If NULL, uses all data (assumes single comparator). Default is NULL.
#' @param comparator_name Character string specifying the name of the
#'   reference treatment (e.g., placebo or active control) in the data.
#'   Required. Default is "Placebo".
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
#' @param weights Named numeric vector of criterion weights. Must sum to 1.
#'   If NULL, uses equal weights. Default is NULL.
#' @param fig_colors A vector of length 2 specifying colors for benefits
#'   and risks. Default is c("#0571b0", "#ca0020") to match
#'   correlogram colors.
#' @param base_font_size Numeric; base font size in points for all text
#'   elements in the plot (default: 9).
#'
#' @return A patchwork object showing four panels: Normalized
#'   Values (side-by-side bars for Comparator and Drug), Difference
#'   of Normalized Values (Drug - Comparator), Weights, and
#'   Benefit-Risk scores, or NULL if data is not provided.
#' @export
#' @import ggplot2
#' @importFrom patchwork wrap_plots
#'
#' @examples
#' # Load example MCDA data
#' data(mcda_data)
#'
#' # View the data structure - each study has comparator and active treatment
#' head(mcda_data)
#' #   Study      Treatment Benefit 1 Benefit 2 Benefit 3 Risk 1 Risk 2
#' # 1 Study 1    Placebo      0.05        65         9   0.30  0.087
#' # 2 Study 1    Drug A       0.46        20        60   0.46  0.100
#' # 3 Study 2    Placebo      0.05        65         9   0.30  0.087
#' # 4 Study 2    Drug B       ...          ...        ...  ...   ...
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
#' # Define weights from stakeholder elicitation
#' weights <- c(
#'   `Benefit 1` = 0.30,
#'   `Benefit 2` = 0.20,
#'   `Benefit 3` = 0.10,
#'   `Risk 1` = 0.30,
#'   `Risk 2` = 0.10
#' )
#'
#' # Create comparison barplot for a specific study
#' # Side-by-side Normalized Values | Difference | Weight | Benefit-Risk
#' barplot_comp_a <- create_mcda_barplot_comparison(
#'   data = mcda_data,
#'   study = "Study 1",
#'   benefit_criteria = c("Benefit 1", "Benefit 2", "Benefit 3"),
#'   risk_criteria = c("Risk 1", "Risk 2"),
#'   comparison_drug = "Drug A",
#'   clinical_scales = clinical_scales,
#'   weights = weights
#' )
#'
#' # Save the plot
#' \dontrun{
#' ggsave(
#'   "inst/img/barplot_mcda_comparison_drug_a.png",
#'   barplot_comp_a,
#'   width = 16,
#'   height = 6,
#'   dpi = 600
#' )
#' }
create_mcda_barplot_comparison <- function(
  data = NULL,
  study = NULL,
  comparator_name = "Placebo",
  comparison_drug = "Drug A",
  benefit_criteria = NULL,
  risk_criteria = NULL,
  clinical_scales = NULL,
  weights = NULL,
  fig_colors = c("#0571b0", "#ca0020"),
  base_font_size = 9
) {
  typography <- publication_typography(base_font_size = base_font_size)
  side_label_size <- publication_geom_text_size(typography$data_label * 1.08)

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
  if (is.null(clinical_scales) || !is.list(clinical_scales)) {
    stop(
      "`clinical_scales` must be a named list defining clinical reference levels. ",
      "Ensure you have defined it, or load the example via data(clinical_scales)."
    )
  }

  # Validate weights if provided
  if (!is.null(weights) && !is.numeric(weights)) {
    stop(
      "`weights` must be a named numeric vector (e.g., c(`Benefit 1` = 0.3, ...)). ",
      "The name `weights` conflicts with a base R function — ensure you have defined ",
      "your own weights object, or load the example via data(weights)."
    )
  }

  # Filter by study if specified, or auto-detect from comparison_drug
  if (!is.null(study)) {
    if (!"Study" %in% colnames(data)) {
      stop("Study column not found in data but study parameter was specified.")
    }
    data <- data[data$Study == study, ]
    if (nrow(data) == 0) {
      stop(
        "No data found for study '", study, "'. ",
        "Available studies: ", paste(unique(data$Study), collapse = ", ")
      )
    }
    # Validate that study has exactly 2 rows (comparator + active treatment)
    if (nrow(data) != 2) {
      stop(
        "Study '", study, "' should have exactly 2 rows ",
        "(comparator + active treatment), but has ", nrow(data), " rows."
      )
    }
  } else if ("Study" %in% colnames(data)) {
    # Auto-detect study from comparison_drug
    drug_studies <- data$Study[data$Treatment == comparison_drug]
    if (length(drug_studies) == 0) {
      stop(
        "Comparison drug '", comparison_drug, "' not found in data. ",
        "Available treatments: ", paste(unique(data$Treatment), collapse = ", ")
      )
    }
    if (length(drug_studies) > 1) {
      stop(
        "Comparison drug '", comparison_drug, "' found in multiple studies. ",
        "Please specify the 'study' parameter."
      )
    }
    # Filter to the detected study
    study <- drug_studies[1]
    data <- data[data$Study == study, ]
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

  # Default weights if not provided - equal weights
  if (is.null(weights)) {
    n_criteria <- length(all_criteria)
    weights <- setNames(rep(1 / n_criteria, n_criteria), all_criteria)
  }

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

  # Calculate weights (as percentages for display) and weighted contributions
  weight_values <- weights[all_criteria] * 100
  contribution_values <- diff_values * weights[all_criteria]
  total_score <- sum(contribution_values)

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

  # Create data frames for combined and difference plots
  # Prepare data with all outcomes
  combined_data <- data.frame(
    Criterion = rep(all_criteria, 2),
    Value = c(placebo_values, drug_values),
    Treatment = rep(
      c(comparator_name, comparison_drug),
      each = length(all_criteria)
    ),
    Type = rep(
      c(
        rep("Benefit", length(benefit_criteria)),
        rep("Risk", length(risk_criteria))
      ),
      2
    ),
    stringsAsFactors = FALSE
  )

  diff_data <- data.frame(
    Criterion = all_criteria,
    Value = diff_values,
    Type = c(
      rep("Benefit", length(benefit_criteria)),
      rep("Risk", length(risk_criteria))
    ),
    stringsAsFactors = FALSE
  )

  # Reverse criterion order for plotting (top to bottom)
  combined_data$Criterion <- factor(
    combined_data$Criterion, levels = rev(all_criteria)
  )
  diff_data$Criterion <- factor(diff_data$Criterion, levels = rev(all_criteria))

  # Set treatment factor levels - reversed for position_dodge to show correctly
  # (position_dodge displays in reverse order for horizontal bars)
  combined_data$Treatment <- factor(
    combined_data$Treatment, levels = c(comparison_drug, comparator_name)
  )

  # Define colors for treatments (active vs comparator)
  # Contrasting colors: neutral gray for comparator, orange for active
  # These complement the blue (#0571b0) and red (#ca0020) benefit-risk colors
  treatment_colors <- c("#808080", "#ff7f00")
  names(treatment_colors) <- c(comparator_name, comparison_drug)

  # Plot 1: Combined Normalized Values (side-by-side bars)
  # Color by treatment (comparator vs active) for simplified legend
  plot_combined <- ggplot(
    combined_data,
    aes(x = Value, y = Criterion, fill = Treatment)
  ) +
    geom_col(
      width = 0.7,
      position = position_dodge(width = 0.8)
    ) +
    geom_vline(xintercept = 0, linetype = "solid", color = "black") +
    geom_text(
      aes(
        label = sprintf("%.0f", Value),
        group = Treatment
      ),
      position = position_dodge(width = 0.8),
      hjust = -0.1,
      size = publication_geom_text_size(typography$data_label),
      show.legend = FALSE
    ) +
    scale_fill_manual(
      values = treatment_colors,
      name = NULL,
      breaks = c(comparator_name, comparison_drug)
    ) +
    scale_x_continuous(
      limits = norm_lim,
      breaks = norm_breaks,
      expand = expansion(mult = c(0.05, 0.15))
    ) +
    labs(
      title = "Normalized Values",
      x = NULL,
      y = NULL
    ) +
    theme_minimal(base_size = base_font_size) +
    theme(
      legend.position = c(0.98, 0.98),
      legend.justification = c("right", "top"),
      legend.background = element_rect(
        fill = "white", color = "darkgray", linewidth = 0.5
      ),
      legend.margin = margin(2, 4, 2, 4),
      legend.key.size = unit(0.55, "lines"),
      legend.text = element_text(size = typography$legend_text * 0.9),
      plot.title = element_text(size = typography$plot_title, face = "bold", hjust = 0.5),
      axis.text.y = element_text(size = typography$tick, face = "bold"),
      axis.text.x = element_text(size = typography$tick),
      axis.ticks.y = element_blank(),
      axis.ticks.x = element_line(color = "grey92"),
      panel.grid.major.y = element_blank(),
      panel.grid.minor.y = element_blank(),
      plot.margin = margin(5, 0, 5, 5),
      panel.border = element_rect(
        color = "darkgray",
        fill = NA,
        linewidth = 1
      )
    )

  # Plot 2: Normalized Difference
  plot_diff <- ggplot(diff_data, aes(x = Value, y = Criterion, fill = Type)) +
    geom_col(width = 0.7) +
    geom_vline(xintercept = 0, linetype = "solid", color = "black") +
    scale_fill_manual(
      values = c("Benefit" = fig_colors[1], "Risk" = fig_colors[2])
    ) +
    scale_x_continuous(
      limits = diff_lim,
      expand = expansion(mult = c(0.15, 0.15))
    ) +
    labs(
      title = "Difference",
      x = NULL,
      y = NULL
    ) +
    theme_minimal(base_size = base_font_size) +
    theme(
      legend.position = "none",
      plot.title = element_text(size = typography$plot_title, face = "bold", hjust = 0.5),
      axis.text.y = element_blank(),
      axis.text.x = element_text(size = typography$tick),
      axis.ticks.y = element_blank(),
      axis.ticks.x = element_line(color = "grey92"),
      panel.grid.major.y = element_blank(),
      panel.grid.minor.y = element_blank(),
      plot.margin = margin(5, 0, 5, 0),
      panel.border = element_rect(
        color = "darkgray",
        fill = NA,
        linewidth = 1
      )
    ) +
    geom_text(
      aes(label = sprintf("%.0f", Value)),
      hjust = ifelse(diff_data$Value < 0, 1.2, -0.1),
      size = side_label_size
    ) +
    coord_cartesian(clip = "off")

  # Plot 3: Weights
  weights_data <- data.frame(
    Criterion = factor(all_criteria, levels = rev(all_criteria)),
    Weight = weight_values,
    Type = c(
      rep("Benefit", length(benefit_criteria)),
      rep("Risk", length(risk_criteria))
    ),
    stringsAsFactors = FALSE
  )

  plot_weights <- ggplot(
    weights_data,
    aes(x = Weight, y = Criterion, fill = Type)
  ) +
    geom_col(width = 0.7) +
    geom_vline(xintercept = 0, linetype = "solid", color = "black") +
    scale_fill_manual(
      values = c("Benefit" = fig_colors[1], "Risk" = fig_colors[2])
    ) +
    scale_x_continuous(
      limits = c(0, 100),
      expand = expansion(mult = c(0.05, 0.15))
    ) +
    labs(
      title = "Weight",
      x = NULL,
      y = NULL
    ) +
    theme_minimal(base_size = base_font_size) +
    theme(
      legend.position = "none",
      plot.title = element_text(size = typography$plot_title, face = "bold", hjust = 0.5),
      axis.text.y = element_blank(),
      axis.text.x = element_text(size = typography$tick),
      axis.ticks.y = element_blank(),
      axis.ticks.x = element_line(color = "grey92"),
      panel.grid.major.y = element_blank(),
      panel.grid.minor.y = element_blank(),
      plot.margin = margin(5, 0, 5, 0),
      panel.border = element_rect(
        color = "darkgray",
        fill = NA,
        linewidth = 1
      )
    ) +
    geom_text(
      aes(label = sprintf("%.0f", Weight)),
      hjust = -0.1,
      size = side_label_size
    ) +
    coord_cartesian(clip = "off")

  # Plot 4: Benefit-Risk (Weighted Contributions)
  contrib_data <- data.frame(
    Criterion = factor(all_criteria, levels = rev(all_criteria)),
    Contribution = contribution_values,
    Type = c(
      rep("Benefit", length(benefit_criteria)),
      rep("Risk", length(risk_criteria))
    ),
    stringsAsFactors = FALSE
  )

  # Calculate symmetric scale around zero for weighted contributions
  max_abs_contrib <- max(abs(contribution_values), na.rm = TRUE)
  contrib_lim <- c(-max_abs_contrib * 1.15, max_abs_contrib * 1.15)

  plot_contrib <- ggplot(
    contrib_data,
    aes(x = Contribution, y = Criterion, fill = Type)
  ) +
    geom_col(width = 0.7) +
    geom_vline(xintercept = 0, linetype = "solid", color = "black") +
    scale_fill_manual(
      values = c("Benefit" = fig_colors[1], "Risk" = fig_colors[2])
    ) +
    scale_x_continuous(
      limits = contrib_lim,
      expand = expansion(mult = c(0.15, 0.15))
    ) +
    labs(
      title = "Benefit-Risk",
      subtitle = sprintf("Total = %.1f", total_score),
      x = NULL,
      y = NULL
    ) +
    theme_minimal(base_size = base_font_size) +
    theme(
      legend.position = "none",
      plot.title = element_text(size = typography$plot_title, face = "bold", hjust = 0.5),
      plot.subtitle = element_text(size = typography$plot_subtitle * 0.9, hjust = 0.5),
      axis.text.y = element_blank(),
      axis.text.x = element_text(size = typography$tick),
      axis.ticks.y = element_blank(),
      axis.ticks.x = element_line(color = "grey92"),
      panel.grid.major.y = element_blank(),
      panel.grid.minor.y = element_blank(),
      plot.margin = margin(5, 15, 5, 0),
      panel.border = element_rect(
        color = "darkgray",
        fill = NA,
        linewidth = 1
      )
    ) +
    geom_text(
      aes(
        label = sprintf("%.1f", Contribution),
        hjust = ifelse(Contribution < 0, 1.2, -0.1)
      ),
      size = side_label_size
    ) +
    coord_cartesian(clip = "off")

  # Combine all four plots horizontally
  combined <- patchwork::wrap_plots(
    plot_combined,
    plot_diff,
    plot_weights,
    plot_contrib,
    ncol = 4,
    widths = c(1.5, 1, 1, 1)
  )

  combined
}

#' Create MCDA Bar Chart: Calculation Walkthrough
#'
#' @param data A data frame in wide format with Study, Treatment, and
#'   criteria columns. Required parameter - must be provided. Each row
#'   should contain raw values for a treatment on their original
#'   measurement scales. See \code{\link{mcda_data}} for example format.
#' @param study Character string specifying which study to analyze.
#'   If NULL, uses all data (assumes single comparator). Default is NULL.
#' @param comparator_name Character string specifying the name of the
#'   reference treatment (e.g., placebo or active control). Required.
#'   Default is "Placebo".
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
#' @param base_font_size Numeric; base font size in points for all text
#'   elements in the plot (default: 9).
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
#' # View the data structure - each study has comparator and active treatment
#' head(mcda_data)
#' #   Study      Treatment Benefit 1 Benefit 2 Benefit 3 Risk 1 Risk 2
#' # 1 Study 1    Placebo      0.05        65         9   0.30  0.087
#' # 2 Study 1    Drug A       0.46        20        60   0.46  0.100
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
#'   study = "Study 2",
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
#'   study = "Study 1",
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
  study = NULL,
  comparator_name = "Placebo",
  comparison_drug = "Drug A",
  benefit_criteria = NULL,
  risk_criteria = NULL,
  weights = NULL,
  clinical_scales = NULL,
  fig_colors = c("#0571b0", "#ca0020"),
  base_font_size = 9
) {
  typography <- publication_typography(base_font_size = base_font_size)

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

  # Filter by study if specified, or auto-detect from comparison_drug
  if (!is.null(study)) {
    if (!"Study" %in% colnames(data)) {
      stop("Study column not found in data but study parameter was specified.")
    }
    data <- data[data$Study == study, ]
    if (nrow(data) == 0) {
      stop(
        "No data found for study '", study, "'. ",
        "Available studies: ", paste(unique(data$Study), collapse = ", ")
      )
    }
    # Validate that study has exactly 2 rows (comparator + active treatment)
    if (nrow(data) != 2) {
      stop(
        "Study '", study, "' should have exactly 2 rows ",
        "(comparator + active treatment), but has ", nrow(data), " rows."
      )
    }
  } else if ("Study" %in% colnames(data)) {
    # Auto-detect study from comparison_drug
    drug_studies <- data$Study[data$Treatment == comparison_drug]
    if (length(drug_studies) == 0) {
      stop(
        "Comparison drug '", comparison_drug, "' not found in data. ",
        "Available treatments: ", paste(unique(data$Treatment), collapse = ", ")
      )
    }
    if (length(drug_studies) > 1) {
      stop(
        "Comparison drug '", comparison_drug, "' found in multiple studies. ",
        "Please specify the 'study' parameter."
      )
    }
    # Filter to the detected study
    study <- drug_studies[1]
    data <- data[data$Study == study, ]
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
    scale_x_continuous(
      limits = norm_lim,
      expand = expansion(mult = c(0.15, 0.15))
    ) +
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
    theme_minimal(base_size = base_font_size) +
    theme(
      axis.text.y = element_text(size = typography$tick, face = "bold"),
      axis.text.x = element_text(size = typography$tick),
      axis.ticks.x = element_line(color = "grey92"),
      legend.position = "none",
      plot.title = element_text(size = typography$plot_title, face = "bold", hjust = 0.5),
      plot.subtitle = element_text(size = typography$plot_subtitle, hjust = 0.5),
      plot.margin = margin(5, 0, 5, 5),
      panel.border = element_rect(
        color = "darkgray",
        fill = NA,
        linewidth = 1
      )
    ) +
    geom_text(
      aes(
        label = sprintf("%.0f", Value),
        hjust = ifelse(Value < 0, 1.2, -0.1)
      ),
      size = publication_geom_text_size(typography$data_label)
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
    scale_x_continuous(
      limits = c(0, x_max),
      expand = expansion(mult = c(0.05, 0.15))
    ) +
    labs(
      title = "Weight",
      subtitle = "Importance (%)",
      x = NULL,
      y = NULL
    ) +
    theme_minimal(base_size = base_font_size) +
    theme(
      axis.text.y = element_blank(),
      axis.text.x = element_text(size = typography$tick),
      axis.ticks.x = element_line(color = "grey92"),
      legend.position = "none",
      plot.title = element_text(size = typography$plot_title, face = "bold", hjust = 0.5),
      plot.subtitle = element_text(size = typography$plot_subtitle, hjust = 0.5),
      plot.margin = margin(5, 0, 5, 0),
      panel.border = element_rect(
        color = "darkgray",
        fill = NA,
        linewidth = 1
      )
    ) +
    geom_text(
      aes(label = sprintf("%.0f", Weight)),
      hjust = -0.1,
      size = publication_geom_text_size(typography$data_label)
    ) +
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
    scale_x_continuous(
      limits = contrib_lim,
      expand = expansion(mult = c(0.15, 0.15))
    ) +
    labs(
      title = "Benefit-Risk",
      subtitle = sprintf("Total = %.1f", drug_total),
      x = NULL,
      y = NULL
    ) +
    theme_minimal(base_size = base_font_size) +
    theme(
      axis.text.y = element_blank(),
      axis.text.x = element_text(size = typography$tick),
      axis.ticks.x = element_line(color = "grey92"),
      legend.position = "none",
      plot.title = element_text(size = typography$plot_title, face = "bold", hjust = 0.5),
      plot.subtitle = element_text(size = typography$plot_subtitle, hjust = 0.5),
      plot.margin = margin(5, 15, 5, 0),
      panel.border = element_rect(
        color = "darkgray",
        fill = NA,
        linewidth = 1
      )
    ) +
    geom_text(
      aes(
        label = sprintf("%.1f", Contribution),
        hjust = ifelse(Contribution < 0, 1.2, -0.1)
      ),
      size = publication_geom_text_size(typography$data_label)
    ) +
    coord_cartesian(clip = "off")

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
