# Generate publication plots for brpubVJCE package
# This script creates PNG files for the publication figures
devtools::load_all()
library(devtools)

if (!dir.exists("inst/img")) {
  dir.create("inst/img", recursive = TRUE)
}

# Scatter plot
data(scatterplot)
outcome <- c("Benefit", "Risk")
scatter_plot_fig <- scatter_plot(scatterplot, outcome, mab = 0.2, mar = 0.6)
ggsave_custom(
  "inst/img/scatter_plot.png",
  imgpath = "./",
  inplot = scatter_plot_fig,
  wdth = 7,
  hght = 7,
  unts = "in", # Single column width
  dpi = 600 # Higher DPI for publication quality
)

# Forest dot plot
data(effects_table)
prepared_data <- prepare_forest_dot_data(effects_table)
dotforest_4pub <- create_forest_dot_plot(
  prepared_data,
  outcomes_with_thresholds = list(
    "Benefit 1" = 0.10,
    "Benefit 2" = -20,
    "Risk 1" = -0.05,
    "Risk 2" = -0.07
  )
)

ggsave_custom(
  "inst/img/dotforest.png",
  imgpath = "./",
  inplot = dotforest_4pub,
  wdth = 7,
  hght = 5,
  unts = "in", # Single column width
  dpi = 600 # Higher DPI for publication quality
)

# Trade-off plot

effects_table_filtered <- effects_table %>%
  filter(Outcome %in% c("Risk 1", "Benefit 1"))

tradeoff <- generate_tradeoff_plot(
  data = effects_table_filtered,
  filter = "None",
  category = "All",
  benefit = "Benefit 1",
  risk = "Risk 1",
  type_risk = "Crude proportions",
  type_graph = "Absolute risk",
  ci = "Yes",
  ci_method = "Calculated",
  cl = 0.95,
  mab = 0.05,
  mar = 0.45,
  threshold = "Segmented line",
  ratio = 4,
  b1 = 0.05,
  b2 = 0.1,
  b3 = 0.15,
  b4 = 0.2,
  b5 = 0.25,
  b6 = 0.3,
  b7 = 0.35,
  b8 = 0.4,
  b9 = 0.45,
  b10 = 0.5,
  r1 = 0.09,
  r2 = 0.17,
  r3 = 0.24,
  r4 = 0.3,
  r5 = 0.35,
  r6 = 0.39,
  r7 = 0.42,
  r8 = 0.44,
  r9 = 0.45,
  r10 = 0.45,
  testdrug = "Yes",
  type_scale = "Free",
  lower_x = 0,
  upper_x = 0.5,
  lower_y = 0,
  upper_y = 0.5,
  chartcolors = colfun()$fig7_colors
)

ggsave_custom(
  "inst/img/tradeoff_plot.png",
  imgpath = "./",
  inplot = tradeoff,
  wdth = 5,
  hght = 5,
  unts = "in", # Single column width
  dpi = 600 # Higher DPI for publication quality
)

# Combined survival plot
data(cumexcess)
cumulative_excess_plot <-
  gensurv_combined(
    df_plot = cumexcess,
    subjects_pt = 100,
    visits_pt = 6,
    df_table = cumexcess,
    fig_colors_pt = colfun()$fig13_colors,
    mar = 30,
    mab = 10,
    mcd = 15,
    titlename_p = "Cumulative Excess # of Subjects w/ Events (per 1000 Subjects)",
  )


ggsave_custom(
  "inst/img/cumulative_excess_plot.png",
  imgpath = "./",
  inplot = cumulative_excess_plot,
  wdth = 7,
  hght = 7,
  unts = "in", # Single column width
  dpi = 600 # Higher DPI for publication quality
)

ggsave_custom(
  "inst/img/correlogram_plot.png",
  imgpath = "./",
  inplot = create_correlogram(corr),
  wdth = 7,
  hght = 7,
  unts = "in", # Single column width
  dpi = 600 # Higher DPI for publication quality
)

# ============================================================================
# MCDA Barplots
# ============================================================================

# Prepare MCDA data from effects table
mcda_data <- prepare_mcda_data(effects_table)

# --------------------------------------------------------------------------
# MCDA Comparison Plot: Shows Normalized Placebo | Normalized Drug | Normalized Difference
# Uses clinical threshold-based normalization to convert raw values to 0-100 scale
# --------------------------------------------------------------------------

# Define clinical scales (same as walkthrough - moved before comparison plot)
clinical_scales <- list(
  `Benefit 1` = list(
    min = 0, # No efficacy (unacceptable)
    max = 1, # 100% efficacy (maximum expected)
    direction = "increasing"
  ),
  `Benefit 2` = list(
    min = 0, # No symptoms (best outcome)
    max = 100, # Severe symptoms (worst outcome)
    direction = "decreasing" # Lower is better
  ),
  `Benefit 3` = list(
    min = 0, # No improvement
    max = 100, # Maximum improvement
    direction = "increasing"
  ),
  `Risk 1` = list(
    min = 0, # No adverse events (ideal)
    max = 0.5, # 50% AE rate (unacceptable threshold)
    direction = "decreasing"
  ),
  `Risk 2` = list(
    min = 0, # No serious adverse events (ideal)
    max = 0.15, # 15% SAE rate (concerning threshold)
    direction = "decreasing"
  )
)

barplot_comp_a <- create_mcda_barplot_comparison(
  data = mcda_data,
  benefit_criteria = c("Benefit 1", "Benefit 2", "Benefit 3"),
  risk_criteria = c("Risk 1", "Risk 2"),
  comparison_drug = "Drug A",
  clinical_scales = clinical_scales # Required parameter for normalization
)

ggsave_custom(
  "inst/img/barplot_mcda_comparison_drug_a.png",
  imgpath = "./",
  inplot = barplot_comp_a,
  wdth = 12,
  hght = 8,
  unts = "in", # Single column width
  dpi = 600 # Higher DPI for publication quality
)

# --------------------------------------------------------------------------
# MCDA Walkthrough Plot: Clinical Threshold-Based Normalization
# Shows 3 panels: Normalized Difference | Weights | Benefit-Risk
# --------------------------------------------------------------------------

# Define weights from stakeholder elicitation
weights <- c(
  `Benefit 1` = 0.30,
  `Benefit 2` = 0.20,
  `Benefit 3` = 0.10,
  `Risk 1` = 0.30,
  `Risk 2` = 0.10
)

# Specify favorable direction for each criterion
# Note: This is different from clinical_scales$direction
# favorable_direction is used for computing performance-oriented differences
# Benefit 2 is "lower is better" (e.g., symptom severity)
favorable_direction <- c(
  `Benefit 1` = "higher",
  `Benefit 2` = "lower",
  `Benefit 3` = "higher",
  `Risk 1` = "lower",
  `Risk 2` = "lower"
)

# Create MCDA walkthrough using clinical threshold-based normalization
barplot_walk_a <- create_mcda_walkthrough(
  data = mcda_data,
  benefit_criteria = c("Benefit 1", "Benefit 2", "Benefit 3"),
  risk_criteria = c("Risk 1", "Risk 2"),
  comparison_drug = "Drug A",
  weights = weights,
  favorable_direction = favorable_direction,
  clinical_scales = clinical_scales # Use clinical thresholds, not data-driven normalization
)

ggsave_custom(
  "inst/img/barplot_mcda_walkthrough_drug_a.png",
  imgpath = "./",
  inplot = barplot_walk_a,
  wdth = 12, # Width for 3 panels
  hght = 6,
  unts = "in",
  dpi = 600 # Higher DPI for publication quality
)
