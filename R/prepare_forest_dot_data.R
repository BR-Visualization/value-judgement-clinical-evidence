#' Prepare Data for Forest and Dot Plots
#'
#' @description
#' For outcomes where `Factor` is "Risk", treatment differences are calculated as Mean2 - Mean1
#' or Prop2 - Prop1 to reflect higher values being worse. For "Benefit", the direction is reversed
#' (Mean1 - Mean2 or Prop1 - Prop2).
#' and calculating treatment differences and confidence intervals if they're not already provided.
#'
#' @param data A data frame containing treatment effect data
#' @param outcomes_of_interest Character vector of outcome names to include in the plots
#' @param treatment1 Character, name of the first treatment (default: "Drug A")
#' @param treatment2 Character, name of the second treatment (default: "Placebo")
#' @param filter_value Character, value for the Filter column to include (default: "None")
#' @param precalculated_stats Logical, whether the input data already contains calculated statistics
#'   (Diff, Diff_LowerCI, Diff_UpperCI) (default: FALSE)
#'
#' @return A filtered and processed data frame with calculated statistics
#'
#' @import dplyr
#' @import rlang
#'
#' @export
prepare_forest_dot_data <- function(data,
                                    outcomes_of_interest = c(
                                      "Primary Efficacy", "Secondary Efficacy",
                                      "HR Quality of Life", "Reoccurring AE", "Rare SAE"
                                    ),
                                    treatment1 = "Drug A",
                                    treatment2 = "Placebo",
                                    filter_value = "None",
                                    precalculated_stats = FALSE) {
  # Filter data for outcomes of interest and specified treatments
  filtered_data <- data %>%
    filter(
      Outcome %in% outcomes_of_interest,
      Trt1 == treatment1,
      Trt2 == treatment2,
      Filter == filter_value
    ) %>%
    arrange(match(Outcome, outcomes_of_interest))

  # If statistics are already calculated, return the filtered data
  if (precalculated_stats) {
    required_cols <- c("Diff", "Diff_LowerCI", "Diff_UpperCI")
    missing_cols <- required_cols[!required_cols %in% names(filtered_data)]

    if (length(missing_cols) > 0) {
      stop(paste(
        "Input data is missing required precalculated columns:",
        paste(missing_cols, collapse = ", ")
      ))
    }

    return(filtered_data)
  }

  # Calculate statistics for treatment differences and confidence intervals
  processed_data <- filtered_data %>%
    mutate(
      Diff = case_when(
        Type == "Continuous" & Factor == "Benefit" ~ Mean1 - Mean2,
        Type == "Continuous" & Factor == "Risk" ~ Mean2 - Mean1,
        Type == "Binary" & Factor == "Benefit" ~ Prop1 - Prop2,
        Type == "Binary" & Factor == "Risk" ~ Prop2 - Prop1,
        TRUE ~ NA_real_
      ),
      SE_diff = case_when(
        Type == "Continuous" ~ sqrt((Sd1^2 / N1) + (Sd2^2 / N2)),
        Type == "Binary" ~ sqrt((Prop1 * (1 - Prop1) / N1) + (Prop2 * (1 - Prop2) / N2)),
        TRUE ~ NA_real_
      ),

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

  return(processed_data)
}
