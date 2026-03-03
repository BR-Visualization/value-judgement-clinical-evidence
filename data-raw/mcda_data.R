## Code to prepare `mcda_data` dataset goes here
## This script transforms the effects_table into wide format for MCDA analysis

# Helper function to prepare MCDA data from effects table
# This function creates two rows for each treatment comparison:
# one for the active treatment (Trt1) and one for the comparator (Trt2)
# Each comparison gets a unique Study identifier
prepare_mcda_data_internal <- function(source_data) {
  # Filter for identified outcomes only, Category == 'All'
  identified <- source_data[
    source_data$Outcome_Status == "Identified" &
      source_data$Category == "All",
  ]

  # Get unique treatment pairs (Trt1-Trt2 combinations)
  treatment_pairs <- unique(identified[, c("Trt1", "Trt2")])

  # Extract unique outcomes
  outcomes <- unique(identified$Outcome)

  # Initialize result data frame
  result <- data.frame(
    Study = character(),
    Treatment = character(),
    stringsAsFactors = FALSE
  )

  # Process each unique treatment comparison
  for (i in seq_len(nrow(treatment_pairs))) {
    trt1_name <- treatment_pairs$Trt1[i]
    trt2_name <- treatment_pairs$Trt2[i]

    # Create study identifier
    study_id <- paste0("Study ", i)

    # Get all data for this treatment pair
    pair_data <- identified[
      identified$Trt1 == trt1_name & identified$Trt2 == trt2_name,
    ]

    # Create row for Trt1 (active treatment)
    trt1_row <- data.frame(
      Study = study_id,
      Treatment = trt1_name,
      stringsAsFactors = FALSE
    )

    # Create row for Trt2 (comparator)
    trt2_row <- data.frame(
      Study = study_id,
      Treatment = trt2_name,
      stringsAsFactors = FALSE
    )

    # Extract values for each outcome
    for (outcome in outcomes) {
      outcome_data <- pair_data[pair_data$Outcome == outcome, ]

      if (nrow(outcome_data) == 0) {
        trt1_row[[outcome]] <- NA
        trt2_row[[outcome]] <- NA
        next
      }

      outcome_data <- outcome_data[1, ]

      # Extract Trt1 value (active treatment)
      if (!is.na(outcome_data$Prop1)) {
        trt1_row[[outcome]] <- outcome_data$Prop1
      } else if (!is.na(outcome_data$Mean1)) {
        trt1_row[[outcome]] <- outcome_data$Mean1
      } else {
        trt1_row[[outcome]] <- NA
      }

      # Extract Trt2 value (comparator)
      if (!is.na(outcome_data$Prop2)) {
        trt2_row[[outcome]] <- outcome_data$Prop2
      } else if (!is.na(outcome_data$Mean2)) {
        trt2_row[[outcome]] <- outcome_data$Mean2
      } else {
        trt2_row[[outcome]] <- NA
      }
    }

    # Add both rows to the result
    result <- rbind(result, trt2_row, trt1_row)
  }

  result
}

# Load effects_table
load("data/effects_table.rda")

# Generate mcda_data
mcda_data <- prepare_mcda_data_internal(effects_table)

# Save as package data
usethis::use_data(mcda_data, overwrite = TRUE)
