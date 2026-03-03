# Test and demonstrate time-to-event scatter plots
devtools::load_all()

# Load the example data
data(time_event_data)

# Create output directory if needed
if (!dir.exists("inst/img")) {
  dir.create("inst/img", recursive = TRUE)
}

# ============================================================================
# Example 1: Vary by Benefit Type
# ============================================================================
cat("\n=== Creating plot varying by benefit type ===\n")

plot_vary_benefit <- create_time_to_event_scatter(
  data = time_event_data,
  vary_by = "benefit",
  time_units = "Days",
  add_marginals = TRUE,
  fig_colors = c("#0571b0", "#92c5de", "#2166ac") # Blue shades for benefits
)

# Save the plot
ggsave(
  "inst/img/time_to_event_vary_benefit.png",
  plot = plot_vary_benefit,
  width = 8,
  height = 8,
  dpi = 300
)

cat("✓ Saved: inst/img/time_to_event_vary_benefit.png\n")

# ============================================================================
# Example 2: Vary by Risk Type
# ============================================================================
cat("\n=== Creating plot varying by risk type ===\n")

plot_vary_risk <- create_time_to_event_scatter(
  data = time_event_data,
  vary_by = "risk",
  time_units = "Days",
  add_marginals = TRUE,
  fig_colors = c("#fddbc7", "#f4a582", "#d6604d") # Red/orange shades for risks
)

# Save the plot
ggsave(
  "inst/img/time_to_event_vary_risk.png",
  plot = plot_vary_risk,
  width = 8,
  height = 8,
  dpi = 300
)

cat("✓ Saved: inst/img/time_to_event_vary_risk.png\n")

# ============================================================================
# Example 3: Without marginals for cleaner look
# ============================================================================
cat("\n=== Creating plot without marginals ===\n")

plot_no_marginals <- create_time_to_event_scatter(
  data = time_event_data,
  vary_by = "benefit",
  time_units = "Days",
  add_marginals = FALSE
)

# Save the plot
ggsave(
  "inst/img/time_to_event_no_marginals.png",
  plot = plot_no_marginals,
  width = 7,
  height = 7,
  dpi = 300
)

cat("✓ Saved: inst/img/time_to_event_no_marginals.png\n")

cat("\n=== All plots created successfully! ===\n")
