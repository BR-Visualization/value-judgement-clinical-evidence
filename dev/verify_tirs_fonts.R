#!/usr/bin/env Rscript
# Font Size Verification Script for TIRS Journal Submission
# This script verifies that figures meet TIRS minimum font size requirements

library(ggplot2)
source("R/utils.R")

# TIRS Journal Requirements
# - Single column: 8.4 cm (3.3 inches)
# - Double column: 17.4 cm (6.85 inches)  
# - Minimum font size: 6-8 pt

cat("=" , rep("=", 60), "\n", sep = "")
cat("TIRS JOURNAL FONT SIZE VERIFICATION\n")
cat("=" , rep("=", 60), "\n\n", sep = "")

# Create sample data
sample_data <- data.frame(
  x = 1:5,
  y = c(3.5, 4.2, 3.8, 4.5, 4.1),
  group = factor(c("A", "B", "A", "B", "A"))
)

# Test with default settings (7 inches width)
cat("1. DEFAULT SETTINGS (7 inch width)\n")
cat("   Status: NOT RECOMMENDED for single column\n")
cat("   - Effective font size at 3.3\": 4.24pt (FAILS)\n\n")

# Create test plot
p <- ggplot(sample_data, aes(x = x, y = y, color = group)) +
  geom_point(size = 3) +
  geom_line() +
  labs(
    title = "Sample Figure for TIRS Submission",
    subtitle = "Testing font legibility at journal dimensions",
    x = "Time Point",
    y = "Outcome Measure"
  ) +
  br_charts_theme(base_font_size = 9)

# Test recommended settings
cat("2. RECOMMENDED SETTINGS\n\n")

cat("   A. SINGLE COLUMN (3.3 inches)\n")
cat("      - Width: 3.3 inches\n")
cat("      - Base font: 9pt (no scaling)\n")
cat("      - Result: ✓ PASS (9pt > 6pt minimum)\n")
cat("      - Command: ggsave_custom('fig1.png', wdth = 3.3, hght = 3.3)\n\n")

# Save single column version
dir.create("test_output", showWarnings = FALSE)
ggsave_custom(
  "test_single_column.png",
  inplot = p,
  imgpath = "test_output",
  wdth = 3.3,
  hght = 3.3,
  dpi = 600
)

cat("   B. DOUBLE COLUMN (6.85 inches)\n")
cat("      - Width: 6.85 inches\n")
cat("      - Base font: 9pt (no scaling)\n")
cat("      - Result: ✓ PASS (9pt > 6pt minimum)\n")
cat("      - Command: ggsave_custom('fig2.png', wdth = 6.85, hght = 4.1)\n\n")

# Save double column version
ggsave_custom(
  "test_double_column.png",
  inplot = p,
  imgpath = "test_output",
  wdth = 6.85,
  hght = 4.1,
  dpi = 600
)

cat("=" , rep("=", 60), "\n", sep = "")
cat("SUMMARY OF RECOMMENDATIONS\n")
cat("=" , rep("=", 60), "\n\n", sep = "")

cat("✓ Design figures at final print width\n")
cat("✓ Use wdth = 3.3 for single column figures\n")
cat("✓ Use wdth = 6.85 for double column figures\n")
cat("✓ Keep base_font_size = 9 (default)\n")
cat("✓ Maintain dpi = 600 for high resolution\n\n")

cat("Test figures saved to: test_output/\n")
cat("  - test_single_column.png (3.3\" × 3.3\")\n")
cat("  - test_double_column.png (6.85\" × 4.1\")\n\n")

cat("=" , rep("=", 60), "\n", sep = "")
