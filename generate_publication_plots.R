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
  inplot = create_correlogram(corr2),
  wdth = 7,
  hght = 7,
  unts = "in", # Single column width
  dpi = 600 # Higher DPI for publication quality
)

# ============================================================================
# MCDA Comparison Plots
# 4-panel visualization: Side-by-side Normalized Values | Difference | Weight | Benefit-Risk
# Uses clinical threshold-based normalization to convert raw values to 0-100 scale
# ============================================================================

# Load MCDA data (generated from effects_table via data-raw/mcda_data.R)
data("mcda_data")

# --------------------------------------------------------------------------
# Define Clinical Scales and Weights (Used for All Drugs)
# --------------------------------------------------------------------------

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
    max = 0.3, # 30% SAE rate (concerning threshold)
    direction = "decreasing"
  )
)

# Define weights from stakeholder elicitation
weights <- c(
  `Benefit 1` = 0.30,
  `Benefit 2` = 0.20,
  `Benefit 3` = 0.10,
  `Risk 1` = 0.30,
  `Risk 2` = 0.10
)

# --------------------------------------------------------------------------
# Drug A: MCDA Comparison Plot
# --------------------------------------------------------------------------

barplot_comp_a <- create_mcda_barplot_comparison(
  data = mcda_data,
  study = "Study 1",
  benefit_criteria = c("Benefit 1", "Benefit 2", "Benefit 3"),
  risk_criteria = c("Risk 1", "Risk 2"),
  comparison_drug = "Drug A",
  clinical_scales = clinical_scales,
  weights = weights
)

ggsave_custom(
  "inst/img/barplot_mcda_comparison_drug_a.png",
  imgpath = "./",
  inplot = barplot_comp_a,
  wdth = 16, # Width for 4 panels
  hght = 6,
  unts = "in",
  dpi = 600 # Higher DPI for publication quality
)

# --------------------------------------------------------------------------
# Drug B: MCDA Comparison Plot
# --------------------------------------------------------------------------

barplot_comp_b <- create_mcda_barplot_comparison(
  data = mcda_data,
  study = "Study 2",
  benefit_criteria = c("Benefit 1", "Benefit 2", "Benefit 3"),
  risk_criteria = c("Risk 1", "Risk 2"),
  comparison_drug = "Drug B",
  clinical_scales = clinical_scales,
  weights = weights
)

ggsave_custom(
  "inst/img/barplot_mcda_comparison_drug_b.png",
  imgpath = "./",
  inplot = barplot_comp_b,
  wdth = 16, # Width for 4 panels
  hght = 6,
  unts = "in",
  dpi = 600
)

# --------------------------------------------------------------------------
# Drug C: MCDA Comparison Plot
# --------------------------------------------------------------------------

barplot_comp_c <- create_mcda_barplot_comparison(
  data = mcda_data,
  study = "Study 3",
  benefit_criteria = c("Benefit 1", "Benefit 2", "Benefit 3"),
  risk_criteria = c("Risk 1", "Risk 2"),
  comparison_drug = "Drug C",
  clinical_scales = clinical_scales,
  weights = weights
)

ggsave_custom(
  "inst/img/barplot_mcda_comparison_drug_c.png",
  imgpath = "./",
  inplot = barplot_comp_c,
  wdth = 16, # Width for 4 panels
  hght = 6,
  unts = "in",
  dpi = 600
)

# --------------------------------------------------------------------------
# Drug D: MCDA Comparison Plot
# --------------------------------------------------------------------------

barplot_comp_d <- create_mcda_barplot_comparison(
  data = mcda_data,
  study = "Study 4",
  benefit_criteria = c("Benefit 1", "Benefit 2", "Benefit 3"),
  risk_criteria = c("Risk 1", "Risk 2"),
  comparison_drug = "Drug D",
  clinical_scales = clinical_scales,
  weights = weights
)

ggsave_custom(
  "inst/img/barplot_mcda_comparison_drug_d.png",
  imgpath = "./",
  inplot = barplot_comp_d,
  wdth = 16, # Width for 4 panels
  hght = 6,
  unts = "in",
  dpi = 600
)

# --------------------------------------------------------------------------
# MCDA Waterfall Plot: Cumulative Contribution of Criteria
# Shows how each criterion builds up to the total benefit-risk score
# All active treatments compared to their study-specific comparators
# --------------------------------------------------------------------------

waterfall_all <- create_mcda_waterfall(
  data = mcda_data,
  comparator_name = "Placebo",
  benefit_criteria = c("Benefit 1", "Benefit 2", "Benefit 3"),
  risk_criteria = c("Risk 1", "Risk 2"),
  weights = weights,
  clinical_scales = clinical_scales
)

ggsave_custom(
  "inst/img/mcda_waterfall_all_drugs.png",
  imgpath = "./",
  inplot = waterfall_all,
  wdth = 16, # Width for 4 drug panels
  hght = 6,
  unts = "in",
  dpi = 600 # Higher DPI for publication quality
)

# --------------------------------------------------------------------------
# MCDA Benefit-Risk Map: 2D Visualization of Benefits vs Risks
# Shows all treatments positioned by their total benefit and risk scores
# Higher is better on both axes
# --------------------------------------------------------------------------

brmap_all <- create_mcda_brmap(
  data = mcda_data,
  comparator_name = "Placebo",
  benefit_criteria = c("Benefit 1", "Benefit 2", "Benefit 3"),
  risk_criteria = c("Risk 1", "Risk 2"),
  weights = weights,
  clinical_scales = clinical_scales,
  show_frontier = TRUE,
  show_labels = TRUE
)

ggsave_custom(
  "inst/img/mcda_benefit_risk_map.png",
  imgpath = "./",
  inplot = brmap_all,
  wdth = 8,
  hght = 8,
  unts = "in",
  dpi = 600 # Higher DPI for publication quality
)
