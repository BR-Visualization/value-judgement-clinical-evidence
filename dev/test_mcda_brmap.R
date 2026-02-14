# Test script for create_mcda_brmap function
# This script tests the benefit-risk map function

# Load required packages
library(BRpub)
library(ggplot2)

# Load the mcda_data dataset
data(mcda_data)

# View the data structure
cat("Data structure:\n")
print(head(mcda_data))
cat("\nStudies:", unique(mcda_data$Study), "\n")
cat("Treatments:", unique(mcda_data$Treatment), "\n")
cat("Outcomes:", setdiff(names(mcda_data), c("Study", "Treatment")), "\n\n")

# Define benefit and risk criteria
benefit_criteria <- c("Benefit 1", "Benefit 2", "Benefit 3")
risk_criteria <- c("Risk 1", "Risk 2")

# Define clinical scales
clinical_scales <- list(
  `Benefit 1` = list(min = 0, max = 1, direction = "increasing"),
  `Benefit 2` = list(min = 0, max = 100, direction = "decreasing"),
  `Benefit 3` = list(min = 0, max = 100, direction = "increasing"),
  `Risk 1` = list(min = 0, max = 0.5, direction = "decreasing"),
  `Risk 2` = list(min = 0, max = 0.3, direction = "decreasing")
)

# Define weights
# Target: Drug A (80, 50), Drug B (40, 60), Drug C (60, 10), Drug D (20, 100)
# Starting with equal weights - adjust based on results
weights <- c(
  `Benefit 1` = 0.200,
  `Benefit 2` = 0.200,
  `Benefit 3` = 0.200,
  `Risk 1` = 0.200,
  `Risk 2` = 0.200
)

# Test 1: Create benefit-risk map for all studies
cat("Test 1: Creating benefit-risk map for all studies...\n")
brmap_all <- create_mcda_brmap(
  data = mcda_data,
  comparator_name = "Placebo",
  benefit_criteria = benefit_criteria,
  risk_criteria = risk_criteria,
  weights = weights,
  clinical_scales = clinical_scales,
  show_frontier = TRUE,
  show_labels = TRUE
)

if (!is.null(brmap_all)) {
  print(brmap_all)
  cat("Test 1: SUCCESS\n\n")
} else {
  cat("Test 1: FAILED - Plot is NULL\n\n")
}

# Test 2: Create benefit-risk map for a specific study
cat("Test 2: Creating benefit-risk map for Study 1...\n")
brmap_study1 <- create_mcda_brmap(
  data = mcda_data,
  study = "Study 1",
  comparator_name = "Placebo",
  benefit_criteria = benefit_criteria,
  risk_criteria = risk_criteria,
  weights = weights,
  clinical_scales = clinical_scales,
  show_frontier = FALSE,
  show_labels = TRUE
)

if (!is.null(brmap_study1)) {
  print(brmap_study1)
  cat("Test 2: SUCCESS\n\n")
} else {
  cat("Test 2: FAILED - Plot is NULL\n\n")
}

# Test 3: Create benefit-risk map with custom colors
cat("Test 3: Creating benefit-risk map with custom colors...\n")

# Get treatment names (excluding Placebo)
treatment_names <- unique(mcda_data$Treatment[mcda_data$Treatment != "Placebo"])

# Define custom colors
custom_colors <- c(
  "Drug A" = "#FF6B6B",
  "Drug B" = "#4ECDC4",
  "Drug C" = "#45B7D1",
  "Drug D" = "#96CEB4"
)

# Only use colors for treatments that exist in the data
existing_treatments <- intersect(names(custom_colors), treatment_names)
custom_colors <- custom_colors[existing_treatments]

brmap_custom <- create_mcda_brmap(
  data = mcda_data,
  comparator_name = "Placebo",
  benefit_criteria = benefit_criteria,
  risk_criteria = risk_criteria,
  weights = weights,
  clinical_scales = clinical_scales,
  show_frontier = TRUE,
  show_labels = TRUE,
  fig_colors = custom_colors
)

if (!is.null(brmap_custom)) {
  print(brmap_custom)
  cat("Test 3: SUCCESS\n\n")
} else {
  cat("Test 3: FAILED - Plot is NULL\n\n")
}

# Save the plots
cat("Saving plots to dev/ directory...\n")
ggsave(
  "dev/test_brmap_all_studies.png",
  brmap_all,
  width = 8,
  height = 8,
  dpi = 300
)

ggsave(
  "dev/test_brmap_custom.png",
  brmap_custom,
  width = 8,
  height = 8,
  dpi = 300
)

cat("\nAll tests completed!\n")
cat("Plots saved to dev/ directory\n")
