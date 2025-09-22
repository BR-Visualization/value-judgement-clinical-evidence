#' Prepare Data for Forest and Dot Plots
#'
#' @description Prepares and optionally calculates treatment effect
#' differences and confidence intervals for specified outcomes, based
#' on whether a higher value indicates risk or benefit.
#'
#' @param data A data frame containing treatment comparisons, estimates, and
#'   metadata.
#' @param outcomes_of_interest Character vector of outcome names to include.
#'   If NULL (default), uses all available outcomes from the data.
#' @param treatment1 Character; label of the first treatment group
#'   (default: `"Drug A"`).
#' @param treatment2 Character; label of the second treatment group
#'   (default: `"Placebo"`).
#' @param filter_value Character; value to filter the `Filter` column
#'   (default: `"None"`).
#' @param precalculated_stats Logical; if `TRUE`, assumes data already
#'   contains `Diff`, `Diff_LowerCI`, and `Diff_UpperCI`.
#'
#' @return A filtered data frame with computed or validated treatment
#'   differences and 95% confidence intervals. Includes directionally colored
#'   confidence intervals for plotting.
#'
#' @importFrom dplyr %>% filter mutate case_when if_else arrange bind_rows
#' @export
#'
#' @examples
#' # Load or create a sample dataset `effects_table`
#' head(effects_table)
#'
#' # Prepare using all available outcomes and calculate statistics
#' prepared_data <- prepare_forest_dot_data(effects_table)
#'
#' # Use precalculated stats
#' prepared_data2 <- prepare_forest_dot_data(effects_table,
#'   precalculated_stats = TRUE
#' )
prepare_forest_dot_data <- function(data,
                                    outcomes_of_interest = NULL,
                                    treatment1 = "Drug A",
                                    treatment2 = "Placebo",
                                    filter_value = "None",
                                    precalculated_stats = FALSE) {
  # Auto-discover outcomes if not specified
  if (is.null(outcomes_of_interest)) {
    if ("Outcome" %in% names(data)) {
      outcomes_of_interest <- unique(data$Outcome)
    } else {
      stop(
        "No 'Outcome' col found in data and no outcomes_of_interest specified."
      )
    }
  }

  # Filter data
  filtered_data <- data %>%
    filter(
      Outcome %in% outcomes_of_interest,
      Trt1 == treatment1,
      Trt2 == treatment2,
      Filter == filter_value
    ) %>%
    arrange(match(Outcome, outcomes_of_interest))

  # If using precalculated stats, validate presence of required columns
  if (precalculated_stats) {
    required_cols <- c("Diff_LowerCI", "Diff_UpperCI")
    missing_cols <- setdiff(required_cols, names(filtered_data))

    if (length(missing_cols) > 0) {
      stop(
        "Missing required precalculated columns: ",
        paste(missing_cols, collapse = ", ")
      )
    }

    return(filtered_data)
  }

  # Check which columns are available
  has_binary_cols <- all(c("Prop1", "Prop2") %in% names(filtered_data))
  has_continuous_cols <- all(c("Mean1", "Mean2", "Sd1", "Sd2") %in%
    names(filtered_data))

  # Calculate treatment differences and confidence intervals
  result <- filtered_data

  # Calculate Diff column
  if (has_continuous_cols) {
    result <- result %>%
      mutate(
        Diff = case_when(
          Type == "Continuous" & Factor == "Benefit" ~ Mean1 - Mean2,
          Type == "Continuous" & Factor == "Risk" ~ Mean2 - Mean1,
          TRUE ~ NA_real_
        )
      )
  }

  if (has_binary_cols) {
    result <- result %>%
      mutate(
        Diff = case_when(
          !is.na(Diff) ~ Diff, # Keep existing values
          Type == "Binary" & Factor == "Benefit" ~ Prop1 - Prop2,
          Type == "Binary" & Factor == "Risk" ~ Prop2 - Prop1,
          TRUE ~ NA_real_
        )
      )
  }

  # Calculate SE_diff column
  if (has_continuous_cols) {
    result <- result %>%
      mutate(
        SE_diff = case_when(
          Type == "Continuous" ~ sqrt((Sd1^2 / N1) + (Sd2^2 / N2)),
          TRUE ~ NA_real_
        )
      )
  }

  if (has_binary_cols) {
    result <- result %>%
      mutate(
        SE_diff = case_when(
          !is.na(SE_diff) ~ SE_diff, # Keep existing values
          Type == "Binary" ~ sqrt((Prop1 * (1 - Prop1) / N1) +
            (Prop2 * (1 - Prop2) / N2)),
          TRUE ~ NA_real_
        )
      )
  }

  # Calculate confidence intervals and other columns
  result %>%
    mutate(
      df = if_else(
        Type == "Continuous",
        ((Sd1^2 / N1 + Sd2^2 / N2)^2) /
          (((Sd1^2 / N1)^2 / (N1 - 1)) + ((Sd2^2 / N2)^2 / (N2 - 1))),
        NA_real_
      ),
      Diff_LowerCI = if_else(
        Type == "Continuous",
        Diff - qt(0.975, df) * SE_diff,
        Diff - qnorm(0.975) * SE_diff
      ),
      Diff_UpperCI = if_else(
        Type == "Continuous",
        Diff + qt(0.975, df) * SE_diff,
        Diff + qnorm(0.975) * SE_diff
      ),
      CI_color = case_when(
        Diff_LowerCI > 0 ~ "green",
        Diff_UpperCI < 0 ~ "red",
        TRUE ~ "black"
      )
    )
}
