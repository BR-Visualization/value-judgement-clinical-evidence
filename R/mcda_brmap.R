#' Create MCDA Benefit-Risk Map
#'
#' Creates a benefit-risk map showing the trade-off between aggregated benefits
#' and risks for each treatment. Each treatment is plotted as a point where the
#' x-axis represents the total weighted benefit score (0-100 scale)
#' and the y-axis represents the transformed risk score (0-100 scale, calculated
#' as 100 + risk_score). Higher is better on both axes: high benefit scores
#' indicate more benefits vs comparator, high risk scores indicate better risk
#' profiles (fewer/less severe adverse events) vs comparator. For example, a
#' risk score of -10 (slightly worse than placebo) becomes 90 on the map.
#' Treatments in the upper-right region offer both high benefits and low risks.
#' This function reuses the calculation logic from
#' \code{\link{create_mcda_walkthrough}} to ensure consistency.
#'
#' @param data A data frame in wide format with Study, Treatment, and
#'   criteria columns. Required parameter - must be provided. Each row
#'   should contain raw values for a treatment on their original
#'   measurement scales. See \code{\link{mcda_data}} for example format.
#' @param study Character string specifying which study to analyze. If NULL,
#'   analyzes all studies (each active treatment will be compared to its
#'   study-specific comparator). Default is NULL.
#' @param comparator_name Character string specifying the name of the
#'   reference treatment (e.g., placebo or active control) in the data.
#'   Required. Default is "Placebo".
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
#' @param show_frontier Logical indicating whether to show the efficiency
#'   frontier region (shaded area representing good benefit-risk profiles,
#'   bounded by the treatments with maximum benefits and maximum risk scores).
#'   Default is TRUE.
#' @param show_labels Logical indicating whether to show treatment labels
#'   on points. Default is TRUE.
#' @param show_title Logical indicating whether to show the plot title.
#'   Default is FALSE.
#' @param show_subtitle Logical indicating whether to show the plot subtitle.
#'   Default is FALSE.
#' @param fig_colors A vector specifying colors for each treatment. If NULL,
#'   uses default color palette.
#'
#' @return A ggplot object showing the benefit-risk map, or NULL if data
#'   is not provided.
#' @export
#' @import ggplot2
#' @importFrom dplyr mutate arrange group_by ungroup filter select bind_rows
#'
#' @examples
#' # Load example MCDA data
#' data(mcda_data)
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
#' # Create benefit-risk map (no title/subtitle by default)
#' brmap_plot <- create_mcda_brmap(
#'   data = mcda_data,
#'   comparator_name = "Placebo",
#'   benefit_criteria = c("Benefit 1", "Benefit 2", "Benefit 3"),
#'   risk_criteria = c("Risk 1", "Risk 2"),
#'   clinical_scales = clinical_scales
#' )
#'
#' # With title and subtitle
#' brmap_with_titles <- create_mcda_brmap(
#'   data = mcda_data,
#'   comparator_name = "Placebo",
#'   benefit_criteria = c("Benefit 1", "Benefit 2", "Benefit 3"),
#'   risk_criteria = c("Risk 1", "Risk 2"),
#'   clinical_scales = clinical_scales,
#'   show_title = TRUE,
#'   show_subtitle = TRUE
#' )
#'
#' # With custom weights and colors
#' \dontrun{
#' weights <- c(
#'   `Benefit 1` = 0.30,
#'   `Benefit 2` = 0.20,
#'   `Benefit 3` = 0.10,
#'   `Risk 1` = 0.30,
#'   `Risk 2` = 0.10
#' )
#'
#' # Custom colors for treatments
#' custom_colors <- c(
#'   "Drug A" = "#FF6B6B",
#'   "Drug B" = "#4ECDC4",
#'   "Drug C" = "#45B7D1",
#'   "Drug D" = "#96CEB4"
#' )
#'
#' brmap_custom <- create_mcda_brmap(
#'   data = mcda_data,
#'   benefit_criteria = c("Benefit 1", "Benefit 2", "Benefit 3"),
#'   risk_criteria = c("Risk 1", "Risk 2"),
#'   weights = weights,
#'   clinical_scales = clinical_scales,
#'   fig_colors = custom_colors,
#'   show_frontier = TRUE
#' )
#'
#' # Show only title without subtitle
#' brmap_title_only <- create_mcda_brmap(
#'   data = mcda_data,
#'   comparator_name = "Placebo",
#'   benefit_criteria = c("Benefit 1", "Benefit 2", "Benefit 3"),
#'   risk_criteria = c("Risk 1", "Risk 2"),
#'   clinical_scales = clinical_scales,
#'   show_title = TRUE,
#'   show_subtitle = FALSE
#' )
#' }
create_mcda_brmap <- function(
  data = NULL,
  study = NULL,
  comparator_name = "Placebo",
  benefit_criteria = NULL,
  risk_criteria = NULL,
  weights = NULL,
  clinical_scales = NULL,
  show_frontier = TRUE,
  show_labels = TRUE,
  show_title = FALSE,
  show_subtitle = FALSE,
  fig_colors = NULL
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

  all_criteria <- c(benefit_criteria, risk_criteria)

  # Default weights if not provided - equal weights
  if (is.null(weights)) {
    n_criteria <- length(all_criteria)
    weights <- setNames(rep(1 / n_criteria, n_criteria), all_criteria)
  }

  # Filter by study if specified
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
  }

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

  # Process data by study to match each active treatment with its
  # study-specific comparator
  if ("Study" %in% colnames(data)) {
    # Process by study
    studies <- unique(data$Study)
    all_comparisons <- list()

    for (study_id in studies) {
      study_data <- data[data$Study == study_id, ]
      placebo_row <- study_data[study_data$Treatment == comparator_name, ]
      active_rows <- study_data[study_data$Treatment != comparator_name, ]

      if (nrow(placebo_row) == 0) {
        warning(
          "Study '", study_id, "' has no comparator '", comparator_name,
          "'. Skipping this study."
        )
        next
      }

      if (nrow(placebo_row) > 1) {
        warning(
          "Study '", study_id, "' has multiple comparator rows. ",
          "Using first occurrence."
        )
        placebo_row <- placebo_row[1, ]
      }

      if (nrow(active_rows) == 0) {
        warning(
          "Study '", study_id, "' has no active treatments. Skipping."
        )
        next
      }

      # For each active treatment in this study
      for (i in seq_len(nrow(active_rows))) {
        all_comparisons[[length(all_comparisons) + 1]] <- list(
          treatment_name = active_rows$Treatment[i],
          study = study_id,
          drug_values = active_rows[i, all_criteria],
          placebo_values = placebo_row[1, all_criteria]
        )
      }
    }

    if (length(all_comparisons) == 0) {
      stop("No valid treatment comparisons found in data.")
    }

    # Build matrices from comparisons
    n_comparisons <- length(all_comparisons)
    drug_actual_matrix <- matrix(
      NA,
      nrow = n_comparisons,
      ncol = length(all_criteria)
    )
    placebo_actual_matrix <- matrix(
      NA,
      nrow = n_comparisons,
      ncol = length(all_criteria)
    )

    treatment_names <- character(n_comparisons)

    for (i in seq_len(n_comparisons)) {
      treatment_names[i] <- all_comparisons[[i]]$treatment_name
      drug_actual_matrix[i, ] <- as.numeric(all_comparisons[[i]]$drug_values)
      placebo_actual_matrix[i, ] <- as.numeric(
        all_comparisons[[i]]$placebo_values
      )
    }

    colnames(drug_actual_matrix) <- criteria_internal
    rownames(drug_actual_matrix) <- treatment_names
    colnames(placebo_actual_matrix) <- criteria_internal
    rownames(placebo_actual_matrix) <- treatment_names

  } else {
    # No Study column - use original single-comparison logic
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

    # Check if treatments exist
    if (nrow(treatments) == 0) {
      stop("No treatments found to compare against comparator.")
    }

    # Create matrices for actual values
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
      # Repeat placebo value for each drug row
      placebo_actual_matrix[, criterion_int] <- rep(
        as.numeric(placebo_row[[criterion]]),
        nrow(treatments)
      )
    }
  }

  # Reuse normalization function from mcda_waterfall.R
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
  if (is.null(clinical_scales)) {
    warning(
      "Clinical scales not provided. Using data-driven normalization ",
      "(not recommended). Consider defining clinical thresholds based ",
      "on clinical guidelines, MCID, or regulatory precedents."
    )

    # Determine favorable direction for fallback normalization
    favorable_direction <- setNames(
      c(
        rep("higher", length(benefit_criteria)),
        rep("lower", length(risk_criteria))
      ),
      all_criteria
    )

    # Compute performance differences for normalization
    perf_matrix <- matrix(
      NA,
      nrow = nrow(drug_actual_matrix),
      ncol = length(all_criteria)
    )
    colnames(perf_matrix) <- criteria_internal
    rownames(perf_matrix) <- rownames(drug_actual_matrix)

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
    # Use clinical threshold-based normalization (recommended approach)
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

    # Ensure matrices (in case of single row)
    if (!is.matrix(drug_normalized)) {
      drug_normalized <- matrix(
        drug_normalized,
        nrow = 1,
        ncol = length(drug_normalized),
        dimnames = list(rownames(drug_actual_matrix), names(drug_normalized))
      )
    }

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

  # Calculate weighted contributions for each criterion
  weighted_contributions <- matrix(
    NA,
    nrow = nrow(normalized),
    ncol = ncol(normalized),
    dimnames = dimnames(normalized)
  )

  for (i in seq_len(nrow(normalized))) {
    weighted_contributions[i, ] <- normalized[i, ] * weights[criteria_internal]
  }

  # Separate benefits and risks
  benefit_indices <- which(criteria_internal %in% benefit_criteria)
  risk_indices <- which(criteria_internal %in% risk_criteria)


  # Total benefit and risk scores for each treatment
  # Positive values = better than comparator
  # Negative values = worse than comparator
  benefit_scores <- rowSums(
    weighted_contributions[, benefit_indices, drop = FALSE]
  )
  risk_scores <- rowSums(weighted_contributions[, risk_indices, drop = FALSE])

  # Scale to 0-100 for visualization
  # Higher is better on both axes (more benefits, fewer risks)

  # For BENEFITS: Use the scores directly (already scaled 0-100 typically)
  # or cap at 0-100 range
  benefits_scaled <- pmax(0, pmin(100, benefit_scores))

  # Transform risks from negative scale to positive:
  # same as placebo maps to 100, much worse maps to 0.
  risks_scaled <- 100 + risk_scores

  # Cap risks at 0-100 range in case some treatments are better than placebo
  # (positive risk scores would give >100)
  risks_scaled <- pmax(0, pmin(100, risks_scaled))

  # Create data frame for plotting
  br_map_df <- data.frame(
    Treatment = rownames(weighted_contributions),
    Benefits = benefits_scaled,
    Risks = risks_scaled,
    Label = seq_len(nrow(weighted_contributions)),
    stringsAsFactors = FALSE
  )

  # Default colors if not provided
  if (is.null(fig_colors)) {
    # Use a default color palette
    treatment_names <- br_map_df$Treatment
    n_treatments <- length(treatment_names)
    default_palette <- c(
      "#FF6B6B",
      "#4ECDC4",
      "#45B7D1",
      "#96CEB4",
      "#FFEAA7",
      "#DDA15E",
      "#BC6C25"
    )
    fig_colors <- setNames(
      default_palette[seq_len(n_treatments)],
      treatment_names
    )
  }

  # Create the base plot
  p_brmap <- ggplot(
    br_map_df,
    aes(x = Benefits, y = Risks, color = Treatment)
  )

  # Add frontier polygon if requested
  if (show_frontier && nrow(br_map_df) >= 1) {
    # For benefit-risk map where higher is better on BOTH axes,
    # create a frontier region showing the "good" area
    # This is the upper-right region defined by the best treatments

    # Find the treatment with maximum benefits
    max_benefit_point <- br_map_df[which.max(br_map_df$Benefits), ]
    # Find the treatment with maximum risks (best risk profile)
    max_risk_point <- br_map_df[which.max(br_map_df$Risks), ]

    # Create frontier polygon from origin to max points
    # This shades the region that represents good benefit-risk profiles
    frontier_polygon <- data.frame(
      x = c(
        0,
        0,
        max_risk_point$Benefits,
        max_benefit_point$Benefits,
        max(br_map_df$Benefits),
        0
      ),
      y = c(
        0,
        max(br_map_df$Risks),
        max_risk_point$Risks,
        max_benefit_point$Risks,
        0,
        0
      )
    )

    p_brmap <- p_brmap +
      geom_polygon(
        data = frontier_polygon,
        aes(x = x, y = y),
        inherit.aes = FALSE,
        fill = "lightgreen",
        alpha = 0.3
      )
  }

  # Add points
  p_brmap <- p_brmap +
    geom_point(size = 8, alpha = 0.8)

  # Add labels if requested
  if (show_labels) {
    p_brmap <- p_brmap +
      geom_text(
        aes(label = Label),
        color = "black",
        size = 5,
        fontface = "bold"
      )
  }

  # Add color scale and theme
  p_brmap <- p_brmap +
    scale_color_manual(
      values = fig_colors,
      labels = paste0(
        br_map_df$Treatment,
        " (", br_map_df$Label, ")"
      )
    ) +
    xlim(0, 100) +
    ylim(0, 100)

  # Build labs() arguments dynamically based on show_title and show_subtitle
  labs_args <- list(
    x = "Benefits \u2192",
    y = "Risks \u2192"
  )

  if (show_title) {
    labs_args$title <- "Benefit-Risk Map"
  }

  if (show_subtitle) {
    labs_args$subtitle <- paste(
      "Higher is better on both axes",
      "(treatment differences vs", comparator_name, ")"
    )
  }

  p_brmap <- p_brmap +
    do.call(labs, labs_args) +
    theme_minimal() +
    theme(
      panel.grid.major = element_line(color = "lightgray"),
      plot.title = element_text(size = 14, face = "bold"),
      plot.subtitle = element_text(size = 11),
      legend.position = "right",
      legend.title = element_text(face = "bold"),
      axis.title = element_text(size = 12)
    )

  p_brmap
}
