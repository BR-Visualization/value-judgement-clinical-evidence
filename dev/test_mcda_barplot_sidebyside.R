# Test script to verify the updated MCDA barplot with side-by-side layout
# This script tests the changes made to create_mcda_barplot_comparison

# Load the package
devtools::load_all()

# Load MCDA data
data(mcda_data)

# Define clinical scales
clinical_scales <- list(
  `Benefit 1` = list(min = 0, max = 1, direction = "increasing"),
  `Benefit 2` = list(min = 0, max = 100, direction = "decreasing"),
  `Benefit 3` = list(min = 0, max = 100, direction = "increasing"),
  `Risk 1` = list(min = 0, max = 0.5, direction = "decreasing"),
  `Risk 2` = list(min = 0, max = 0.3, direction = "decreasing")
)

# Define weights from stakeholder elicitation
weights <- c(
  `Benefit 1` = 0.30,
  `Benefit 2` = 0.20,
  `Benefit 3` = 0.10,
  `Risk 1` = 0.30,
  `Risk 2` = 0.10
)

# Test: Create comparison barplot for Drug A
# Should show 4 panels: Side-by-side Normalized Values | Difference | Weight | Benefit-Risk
cat("Creating MCDA barplot comparison for Drug A (4 panels)...\n")
barplot_comp_a <- create_mcda_barplot_comparison(
  data = mcda_data,
  study = "Study 1",
  benefit_criteria = c("Benefit 1", "Benefit 2", "Benefit 3"),
  risk_criteria = c("Risk 1", "Risk 2"),
  comparison_drug = "Drug A",
  clinical_scales = clinical_scales,
  weights = weights
)

# Check that result is a patchwork object
if (inherits(barplot_comp_a, "patchwork")) {
  cat("SUCCESS: Function returns a patchwork object\n")
} else {
  cat("ERROR: Function did not return a patchwork object\n")
}

# Display the plot
print(barplot_comp_a)

# Save the plot
if (!dir.exists("dev/output")) {
  dir.create("dev/output", recursive = TRUE)
}

ggsave(
  "dev/output/test_barplot_sidebyside_drug_a.png",
  barplot_comp_a,
  width = 16,
  height = 6,
  dpi = 300
)

cat("Plot saved to dev/output/test_barplot_sidebyside_drug_a.png\n")

# Test with Drug B
cat("\nCreating MCDA barplot comparison for Drug B (4 panels)...\n")
barplot_comp_b <- create_mcda_barplot_comparison(
  data = mcda_data,
  study = "Study 2",
  benefit_criteria = c("Benefit 1", "Benefit 2", "Benefit 3"),
  risk_criteria = c("Risk 1", "Risk 2"),
  comparison_drug = "Drug B",
  clinical_scales = clinical_scales,
  weights = weights
)

# Save the plot
ggsave(
  "dev/output/test_barplot_sidebyside_drug_b.png",
  barplot_comp_b,
  width = 16,
  height = 6,
  dpi = 300
)

cat("Plot saved to dev/output/test_barplot_sidebyside_drug_b.png\n")
cat("\nTest completed successfully!\n")
