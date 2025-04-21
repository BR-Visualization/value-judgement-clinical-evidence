#' Prepare Data for Forest and Dot Plots
#'
#' @description
#' Calculates or validates treatment differences and confidence intervals for outcomes,
#' adjusting direction based on whether higher values are "Risk" or "Benefit".
#'
#' @param data A data frame containing treatment effect data
#' @param outcomes_of_interest Character vector of outcome names to include in the plots
#' @param treatment1 Name of the first treatment (default: "Drug A")
#' @param treatment2 Name of the second treatment (default: "Placebo")
#' @param filter_value Value for the Filter column to include (default: "None")
#' @param precalculated_stats Logical; if TRUE, assumes data already includes Diff, Diff_LowerCI, and Diff_UpperCI
#'
#' @return A filtered and processed data frame with calculated statistics
#' @export
prepare_forest_dot_data <- function(data,
                                    outcomes_of_interest = c("Primary Efficacy", "Secondary Efficacy",
                                                             "HR Quality of Life", "Reoccurring AE", "Rare SAE"),
                                    treatment1 = "Drug A",
                                    treatment2 = "Placebo",
                                    filter_value = "None",
                                    precalculated_stats = FALSE) {

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
    required_cols <- c("Diff", "Diff_LowerCI", "Diff_UpperCI")
    missing_cols <- setdiff(required_cols, names(filtered_data))

    if (length(missing_cols) > 0) {
      stop("Missing required precalculated columns: ", paste(missing_cols, collapse = ", "))
    }

    return(filtered_data)
  }

  # Calculate treatment differences and confidence intervals
  filtered_data %>%
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
}
