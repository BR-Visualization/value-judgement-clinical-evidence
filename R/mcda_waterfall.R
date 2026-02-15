#' Create MCDA Waterfall Chart
#'
#' Creates a waterfall chart showing cumulative contribution of each criterion
#' to the total weighted benefit-risk score. Each bar segment represents one
#' criterion's weighted contribution, stacked to show how they build up to the
#' total score. This function reuses the calculation logic from
#' \code{\link{create_mcda_walkthrough}} to ensure consistency.
#'
#' @param data A data frame in wide format with Study, Treatment, and
#'   criteria columns. Required parameter - must be provided. Each row
#'   should contain raw values for a treatment on their original
#'   measurement scales. See \code{\link{mcda_data}} for example format.
#' @param study Character string specifying which study to analyze. If NULL,
#'   analyzes all studies (each active treatment will be compared to its
#'   study-specific comparator in a faceted chart). Default is NULL.
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
#' @param fig_colors A named vector of length 2 specifying colors for
#'   benefits and risks. Default is c("Benefit" = "#0571b0",
#'   "Risk" = "#ca0020") to match the mcda_barplot colors. If NULL,
#'   uses default colors.
#' @param show_total Logical indicating whether to show total score bar.
#'   Default is TRUE.
#' @param show_labels Logical indicating whether to show value labels on bars.
#'   Default is TRUE.
#' @param label_threshold Minimum contribution value to show label.
#'   Default is 0.5.
#' @param base_font_size Numeric; base font size in points for all text
#'   elements in the plot (default: 9).
#'
#' @return A ggplot object showing the waterfall chart, or NULL if data
#'   is not provided.
#' @export
#' @import ggplot2
#' @importFrom dplyr mutate arrange group_by ungroup filter select
#'   bind_rows row_number summarise desc left_join
#' @importFrom tidyr pivot_longer
#' @importFrom stats end start
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
#' # Create waterfall chart for a specific study
#' waterfall_plot <- create_mcda_waterfall(
#'   data = mcda_data,
#'   comparator_name = "Placebo",
#'   study = "Study 1",
#'   benefit_criteria = c("Benefit 1", "Benefit 2", "Benefit 3"),
#'   risk_criteria = c("Risk 1", "Risk 2"),
#'   clinical_scales = clinical_scales
#' )
#'
#' # Or analyze all studies together - each active treatment compared to its
#' # study-specific comparator
#' waterfall_all <- create_mcda_waterfall(
#'   data = mcda_data,
#'   comparator_name = "Placebo",
#'   benefit_criteria = c("Benefit 1", "Benefit 2", "Benefit 3"),
#'   risk_criteria = c("Risk 1", "Risk 2"),
#'   clinical_scales = clinical_scales
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
#' # Custom colors for benefits and risks
#' custom_colors <- c("Benefit" = "#4ECDC4", "Risk" = "#FF6B6B")
#'
#' waterfall_custom <- create_mcda_waterfall(
#'   data = mcda_data,
#'   benefit_criteria = c("Benefit 1", "Benefit 2", "Benefit 3"),
#'   risk_criteria = c("Risk 1", "Risk 2"),
#'   weights = weights,
#'   clinical_scales = clinical_scales
#' )
#' }
create_mcda_waterfall <- function(
  data = NULL,
  study = NULL,
  comparator_name = "Placebo",
  benefit_criteria = NULL,
  risk_criteria = NULL,
  weights = NULL,
  clinical_scales = NULL,
  fig_colors = NULL,
  show_total = TRUE,
  show_labels = TRUE,
  label_threshold = 0.5,
  base_font_size = 9
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
    # Validate that study has exactly 2 rows (comparator + active treatment)
    if (nrow(data) != 2) {
      stop(
        "Study '", study, "' should have exactly 2 rows ",
        "(comparator + active treatment), but has ", nrow(data), " rows."
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


  # For waterfall, we process each study separately
  # to match each active treatment with its comparator

  # Check if Study column exists
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

  # Reuse normalization function from mcda_barplot.R
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
  # (though this is not recommended per FDA/EMA guidance)
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

  # Calculate weighted contributions
  weighted_contributions <- matrix(
    NA,
    nrow = nrow(normalized),
    ncol = ncol(normalized),
    dimnames = dimnames(normalized)
  )

  for (i in seq_len(nrow(normalized))) {
    weighted_contributions[i, ] <- normalized[i, ] * weights[criteria_internal]
  }

  # Convert to long format for plotting
  contrib_list <- list()
  for (i in seq_len(nrow(weighted_contributions))) {
    treatment_name <- rownames(weighted_contributions)[i]
    contrib_df <- data.frame(
      Treatment = treatment_name,
      Criterion = all_criteria,
      Contribution = weighted_contributions[i, ],
      stringsAsFactors = FALSE
    )
    contrib_list[[i]] <- contrib_df
  }

  # Combine all contributions
  all_contrib <- do.call(rbind, contrib_list)

  # Add Type column to distinguish benefits from risks
  all_contrib$Type <- c(
    rep("Benefit", length(benefit_criteria)),
    rep("Risk", length(risk_criteria))
  )[match(all_contrib$Criterion, all_criteria)]

  # Default colors if not provided - use the same scheme as mcda_barplot.R
  if (is.null(fig_colors)) {
    # Use the same default colors as mcda_barplot.R: benefit = blue, risk = red
    fig_colors <- c("Benefit" = "#0571b0", "Risk" = "#ca0020")
  }

  # Prepare waterfall data with cumulative sums
  waterfall_data <- all_contrib |>
    mutate(
      Criterion = factor(Criterion, levels = all_criteria)
    ) |>
    arrange(Treatment, Criterion) |>
    group_by(Treatment) |>
    mutate(
      end = cumsum(Contribution),
      start = dplyr::lag(end, default = 0),
      id = length(all_criteria) + 2 - row_number()
    ) |>
    ungroup()

  # Add total bars if requested
  if (show_total) {
    totals <- waterfall_data |>
      group_by(Treatment) |>
      summarise(Total_Score = sum(Contribution), .groups = "drop") |>
      mutate(
        Criterion = factor(
          "Total",
          levels = c(all_criteria, "Total")
        ),
        Contribution = Total_Score,
        start = 0,
        end = Total_Score,
        id = 1,
        Type = "Total"
      )

    waterfall_complete <- bind_rows(waterfall_data, totals) |>
      mutate(
        Criterion = factor(
          Criterion,
          levels = c(all_criteria, "Total")
        ),
        Type = factor(Type, levels = c("Benefit", "Risk", "Total"))
      )

    # Add total to colors
    fig_colors_complete <- c(fig_colors, "Total" = "#34495e")
  } else {
    waterfall_complete <- waterfall_data |>
      mutate(Type = factor(Type, levels = c("Benefit", "Risk")))
    fig_colors_complete <- fig_colors
  }

  # Create connector lines between segments
  connector_lines <- waterfall_data |>
    arrange(Treatment, desc(id)) |>
    group_by(Treatment) |>
    mutate(
      next_start = dplyr::lead(start),
      next_id = dplyr::lead(id)
    ) |>
    filter(!is.na(next_start)) |>
    ungroup()

  # Add connectors from last criterion to Total (if showing total)
  if (show_total) {
    last_to_total <- waterfall_data |>
      group_by(Treatment) |>
      filter(id == min(id)) |>
      ungroup() |>
      left_join(
        totals |> select(Treatment, total_end = end, total_id = id),
        by = "Treatment"
      ) |>
      mutate(
        next_start = 0,
        next_id = total_id
      ) |>
      select(Treatment, Criterion, end, id, next_start, next_id)

    all_connectors <- bind_rows(connector_lines, last_to_total)
  } else {
    all_connectors <- connector_lines
  }

  # Create the waterfall plot
  p_waterfall <- ggplot(
    waterfall_complete,
    aes(
      y = id,
      fill = Type,
      ymin = id - 0.45,
      ymax = id + 0.45,
      xmin = start,
      xmax = end
    )
  ) +
    geom_rect(alpha = 0.9) +
    geom_segment(
      data = all_connectors,
      aes(x = end, xend = end, y = id + 0.45, yend = next_id - 0.45),
      linetype = "dotted",
      color = "gray40",
      linewidth = 0.5,
      inherit.aes = FALSE
    ) +
    facet_wrap(
      ~factor(
        Treatment,
        levels = rownames(weighted_contributions)
      ),
      nrow = 1
    ) +
    scale_fill_manual(
      values = fig_colors_complete,
      drop = FALSE
    ) +
    scale_y_continuous(
      breaks = seq_len(length(all_criteria) + ifelse(show_total, 1, 0)),
      labels = {
        if (show_total) {
          c("Total", rev(all_criteria))
        } else {
          rev(all_criteria)
        }
      },
      expand = c(0.02, 0.02)
    ) +
    scale_x_continuous(expand = expansion(mult = c(0.15, 0.15))) +
    labs(
      x = "Cumulative Weighted Score Difference",
      y = NULL
    ) +
    theme_minimal(base_size = base_font_size) +
    theme(
      legend.position = "none",
      axis.text.y = element_text(size = base_font_size, hjust = 1, face = "bold"),
      panel.grid.major.y = element_blank(),
      panel.grid.minor.y = element_blank(),
      panel.grid.major.x = element_line(color = "grey92"),
      plot.margin = margin(5, 15, 5, 5),
      panel.border = element_rect(
        color = "darkgray",
        fill = NA,
        linewidth = 1
      ),
      panel.spacing = unit(0, "lines"),
      strip.text = element_text(size = base_font_size * 1.22, face = "bold"),
      strip.background = element_rect(fill = "white", color = NA)
    )

  # Add value labels if requested
  # Following the same labeling pattern as mcda_barplot.R
  if (show_labels) {
    # Labels for criterion contributions
    p_waterfall <- p_waterfall +
      geom_text(
        data = filter(waterfall_complete, Criterion != "Total"),
        aes(
          x = end,
          y = id,
          label = sprintf("%.1f", Contribution),
          hjust = ifelse(Contribution < 0, 1.2, -0.1)
        ),
        inherit.aes = FALSE,
        size = base_font_size * 0.35
      )

    # Labels for total scores (if showing total)
    if (show_total) {
      p_waterfall <- p_waterfall +
        geom_text(
          data = filter(waterfall_complete, Criterion == "Total"),
          aes(
            x = end,
            y = id,
            label = sprintf("%.1f", Contribution),
            hjust = ifelse(Contribution < 0, 1.2, -0.1)
          ),
          inherit.aes = FALSE,
          size = base_font_size * 0.35
        )
    }
  }

  # Allow labels to extend beyond plot area
  p_waterfall <- p_waterfall + coord_cartesian(clip = "off")

  # Add vertical line at zero
  p_waterfall <- p_waterfall +
    geom_vline(
      xintercept = 0, linetype = "solid",
      color = "black", linewidth = 0.5
    )

  p_waterfall
}
