## Code to prepare `mcda_data` dataset goes here
## This script transforms the effects_table into wide format for MCDA analysis

# Helper function to prepare MCDA data from effects table
# NOTE: This function is specific to the effects_table example data
# and only extracts placebo values from the first drug comparison.
# This is suitable for the example dataset where comparisons share a
# common placebo arm.
prepare_mcda_data_internal <- function(
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
  # NOTE: This assumes all drug comparisons share the same placebo arm
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

  result
}

# Load effects_table
load("data/effects_table.rda")

# Generate mcda_data
mcda_data <- prepare_mcda_data_internal(effects_table)

# Save as package data
usethis::use_data(mcda_data, overwrite = TRUE)
