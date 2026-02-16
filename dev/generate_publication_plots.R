# Generate publication plots for brpubVJCE package WITH CONSISTENT FONT SCALING
# This script creates PNG files with properly scaled fonts based on figure dimensions
devtools::load_all()
library(devtools)

if (!dir.exists("inst/img/pub")) {
  dir.create("inst/img/pub", recursive = TRUE)
}
if (!dir.exists("inst/img/other")) {
  dir.create("inst/img/other", recursive = TRUE)
}

# Remove old image files before generating new ones
old_files <- c(
  "inst/img/dotforest.png",
  "inst/img/tradeoff_plot.png",
  "inst/img/correlogram_plot.png",
  "inst/img/scatter_plot.png",
  "inst/img/divergent_stacked_barchart.png",
  "inst/img/cumulative_excess_plot.png",
  "inst/img/value_function_types_comparison.png",
  "inst/img/barplot_mcda_comparison_drug_a.png",
  "inst/img/other/barplot_mcda_comparison_drug_b.png",
  "inst/img/other/barplot_mcda_comparison_drug_c.png",
  "inst/img/other/barplot_mcda_comparison_drug_d.png",
  "inst/img/mcda_waterfall_all_drugs.png",
  "inst/img/mcda_benefit_risk_map.png",
  "inst/img/mcda_tornado_drug_a.png",
  "inst/img/other/mcda_tornado_drug_b.png",
  "inst/img/other/mcda_tornado_drug_c.png",
  "inst/img/other/mcda_tornado_drug_d.png",
  "inst/img/other/stacked_barchart.png",
  "inst/img/other/value_function_benefit_example.png",
  "inst/img/other/value_function_risk_example.png",
  "inst/img/other/value_function_comparison_benefit_risk.png",
  "inst/img/other/value_function_multiple_criteria.png"
)

for (f in old_files) {
  if (file.exists(f)) {
    file.remove(f)
    message("Removed old file: ", f)
  }
}

# ============================================================================
# FONT SCALING CONFIGURATION
# ============================================================================
# Font sizes are automatically scaled based on figure dimensions using font_config()
# Reference: 9pt font for 7×7" figure
# Formula: base_font_size = 9 × sqrt((width × height) / 49)

# ============================================================================
# SINGLE-COLUMN PLOTS (5-7 inches wide)
# ============================================================================

# Scatter plot (7×7)
data(scatterplot)
outcome <- c("Benefit", "Risk")
fonts_7x7 <- font_config(7, 7)
scatter_plot_fig <- scatter_plot(scatterplot, outcome, mab = 0.2, mar = 0.6, base_font_size = fonts_7x7$p)
ggsave_custom(
  "inst/img/pub/image04_scatter.png",
  imgpath = "./",
  inplot = scatter_plot_fig,
  wdth = 7,
  hght = 7,
  unts = "in",
  dpi = 600
)

# Forest dot plot (7×5)
data(effects_table)
prepared_data <- prepare_forest_dot_data(effects_table)
fonts_7x5 <- font_config(7, 5)
dotforest_4pub <- create_forest_dot_plot(
  prepared_data,
  outcomes_with_thresholds = list(
    "Benefit 1" = 0.10,
    "Benefit 2" = -20,
    "Risk 1" = -0.05,
    "Risk 2" = -0.07
  ),
  base_font_size = fonts_7x5$p
)

ggsave_custom(
  "inst/img/pub/image01_dotforest.png",
  imgpath = "./",
  inplot = dotforest_4pub,
  wdth = 7,
  hght = 5,
  unts = "in",
  dpi = 600
)

# Trade-off plot (5×5)
effects_table_filtered <- effects_table %>%
  filter(Outcome %in% c("Risk 1", "Benefit 1"))

fonts_5x5 <- font_config(5, 5)
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
  b1 = 0.05, b2 = 0.1, b3 = 0.15, b4 = 0.2, b5 = 0.25,
  b6 = 0.3, b7 = 0.35, b8 = 0.4, b9 = 0.45, b10 = 0.5,
  r1 = 0.09, r2 = 0.17, r3 = 0.24, r4 = 0.3, r5 = 0.35,
  r6 = 0.39, r7 = 0.42, r8 = 0.44, r9 = 0.45, r10 = 0.45,
  testdrug = "Yes",
  type_scale = "Free",
  lower_x = 0, upper_x = 0.5,
  lower_y = 0, upper_y = 0.5,
  chartcolors = colfun()$fig7_colors,
  base_font_size = fonts_5x5$p
)

ggsave_custom(
  "inst/img/pub/image02_tradeoff.png",
  imgpath = "./",
  inplot = tradeoff,
  wdth = 5,
  hght = 5,
  unts = "in",
  dpi = 600
)

# Combined survival plot (7×7)
data(cumexcess)
cumulative_excess_plot <- gensurv_combined(
  df_plot = cumexcess,
  subjects_pt = 100,
  visits_pt = 6,
  df_table = cumexcess,
  fig_colors_pt = colfun()$fig13_colors,
  mar = 30,
  mab = 10,
  mcd = 15,
  titlename_p = "",
  base_font_size = fonts_7x7$p
)

ggsave_custom(
  "inst/img/pub/image06_cumulative_excess.png",
  imgpath = "./",
  inplot = cumulative_excess_plot,
  wdth = 7,
  hght = 7,
  unts = "in",
  dpi = 600
)

# Correlogram (7×7)
ggsave_custom(
  "inst/img/pub/image03_correlogram.png",
  imgpath = "./",
  inplot = create_correlogram(corr2, base_font_size = fonts_7x7$p),
  wdth = 7,
  hght = 7,
  unts = "in",
  dpi = 600
)

# Stacked bar chart and divergent stacked bar chart combined (14×9)
data(comp_outcome)
fonts_14x9 <- font_config(14, 9)

stacked_bar_fig <- stacked_barchart(
  data = comp_outcome,
  chartcolors = colfun()$fig12_colors,
  ylabel = "Study Week",
  base_font_size = fonts_14x9$p
)

divergent_stacked_bar_fig <- divergent_stacked_barchart(
  data = comp_outcome,
  chartcolors = colfun()$fig12_colors,
  favcat = c(
    "Benefit larger than threshold, with AE",
    "Benefit larger than threshold, w/o AE"
  ),
  unfavcat = c(
    "Withdrew",
    "Benefit less than threshold, w/o AE",
    "Benefit less than threshold, with AE"
  ),
  ylabel = "Study Week",
  base_font_size = fonts_14x9$p
)

# Extract legend from one plot using ggplotGrob
library(cowplot)
library(gtable)

# Create plot with legend at top with proper label and 2 rows, centered
stacked_bar_with_legend <- stacked_bar_fig + 
  labs(fill = "Outcome") +
  theme(legend.position = "top",
        legend.justification = "center",
        legend.box.just = "center",
        legend.title.align = 0.5) +
  guides(fill = guide_legend(nrow = 2, title.position = "top", title.hjust = 0.5))

# Extract legend using ggplotGrob
g <- ggplotGrob(stacked_bar_with_legend)
legend_index <- which(g$layout$name == "guide-box-top")
legend <- g$grobs[[legend_index]]

# Remove legends from both plots
stacked_bar_no_legend <- stacked_bar_fig + theme(legend.position = "none")
divergent_stacked_bar_no_legend <- divergent_stacked_bar_fig + theme(legend.position = "none")

# Combine plots side by side
combined_plots <- plot_grid(
  stacked_bar_no_legend, 
  divergent_stacked_bar_no_legend, 
  ncol = 2
)

# Add legend on top (increased height for 2 rows)
combined_bar_charts <- plot_grid(
  legend, 
  combined_plots, 
  ncol = 1, 
  rel_heights = c(0.2, 1)
)

ggsave_custom(
  "inst/img/pub/image05_divergent_stacked_barchart.png",
  imgpath = "./",
  inplot = combined_bar_charts,
  wdth = 14,
  hght = 9,
  unts = "in",
  dpi = 600
)

# ============================================================================
# VALUE FUNCTION PLOTS (5×4 to 14×5)
# ============================================================================

# Small value function examples (5×4)
fonts_5x4 <- font_config(5, 4)

value_func_benefit <- create_value_function_plot(
  criterion_name = "Response Rate",
  min_val = 0,
  max_val = 100,
  direction = "increasing",
  x_label = "Response Rate (%)",
  show_title = TRUE,
  show_reference_line = TRUE,
  base_font_size = fonts_5x4$p
)

ggsave_custom(
  "inst/img/other/value_function_benefit_example.png",
  imgpath = "./",
  inplot = value_func_benefit,
  wdth = 5,
  hght = 4,
  unts = "in",
  dpi = 600
)

value_func_risk <- create_value_function_plot(
  criterion_name = "Adverse Events",
  min_val = 0,
  max_val = 50,
  direction = "decreasing",
  x_label = "Adverse Event Rate (%)",
  show_title = TRUE,
  show_reference_line = TRUE,
  base_font_size = fonts_5x4$p
)

ggsave_custom(
  "inst/img/other/value_function_risk_example.png",
  imgpath = "./",
  inplot = value_func_risk,
  wdth = 5,
  hght = 4,
  unts = "in",
  dpi = 600
)

# Value function comparison (10×4)
fonts_10x4 <- font_config(10, 4)
value_func_comparison <- compare_value_functions(
  benefit_name = "Efficacy",
  benefit_min = 0,
  benefit_max = 100,
  benefit_label = "Response Rate (%)",
  risk_name = "Safety",
  risk_min = 0,
  risk_max = 50,
  risk_label = "Adverse Event Rate (%)",
  show_titles = TRUE,
  show_reference_lines = TRUE,
  base_font_size = fonts_10x4$p
)

ggsave_custom(
  "inst/img/other/value_function_comparison_benefit_risk.png",
  imgpath = "./",
  inplot = value_func_comparison,
  wdth = 10,
  hght = 4,
  unts = "in",
  dpi = 600
)

# Multiple value functions (12×6)
fonts_12x6 <- font_config(12, 6)
data("mcda_data")
clinical_scales <- list(
  `Benefit 1` = list(min = 0, max = 1, direction = "increasing"),
  `Benefit 2` = list(min = 0, max = 100, direction = "decreasing"),
  `Benefit 3` = list(min = 0, max = 100, direction = "increasing"),
  `Risk 1` = list(min = 0, max = 0.5, direction = "decreasing"),
  `Risk 2` = list(min = 0, max = 0.3, direction = "decreasing")
)

value_func_multiple <- plot_multiple_value_functions(
  clinical_scales = clinical_scales,
  ncol = 3,
  show_titles = TRUE,
  show_reference_lines = TRUE,
  base_font_size = fonts_12x6$p
)

ggsave_custom(
  "inst/img/other/value_function_multiple_criteria.png",
  imgpath = "./",
  inplot = value_func_multiple,
  wdth = 12,
  hght = 6,
  unts = "in",
  dpi = 600
)

# Value function types comparison — square panels via coord_fixed()
# Figure width is proportional to combined axis ranges so each panel
# is physically square. Both axes use 0-100 range so panels are equal size.
vft_benefit_range <- 100
vft_risk_range <- 100
vft_height <- 5
vft_width <- vft_height * (vft_benefit_range + vft_risk_range) / 100
fonts_vft <- font_config(vft_width, vft_height)
value_func_types_comparison <- compare_value_function_types(
  benefit_name = "Efficacy",
  benefit_min = 0,
  benefit_max = vft_benefit_range,
  benefit_label = "Response Rate (%)",
  risk_name = "Safety",
  risk_min = 0,
  risk_max = vft_risk_range,
  risk_label = "Adverse Event Rate (%)",
  power = 2,
  show_titles = FALSE,
  show_legend = TRUE,
  base_font_size = fonts_vft$p
)

ggsave_custom(
  "inst/img/pub/image07_value_function_types_comparison.png",
  imgpath = "./",
  inplot = value_func_types_comparison,
  wdth = vft_width,
  hght = vft_height,
  unts = "in",
  dpi = 600
)

# ============================================================================
# MCDA PLOTS (8×8 to 16×6)
# ============================================================================

weights <- c(
  `Benefit 1` = 0.30, `Benefit 2` = 0.20, `Benefit 3` = 0.10,
  `Risk 1` = 0.30, `Risk 2` = 0.10
)

# MCDA Comparison Plots (16×6)
fonts_16x6 <- font_config(16, 6)

barplot_comp_a <- create_mcda_barplot_comparison(
  data = mcda_data,
  study = "Study 1",
  benefit_criteria = c("Benefit 1", "Benefit 2", "Benefit 3"),
  risk_criteria = c("Risk 1", "Risk 2"),
  comparison_drug = "Drug A",
  clinical_scales = clinical_scales,
  weights = weights,
  base_font_size = fonts_16x6$p
)

ggsave_custom(
  "inst/img/pub/image08_barplot_mcda_comparison_drug_a.png",
  imgpath = "./",
  inplot = barplot_comp_a,
  wdth = 16,
  hght = 6,
  unts = "in",
  dpi = 600
)

# Similar for drugs B, C, D...
barplot_comp_b <- create_mcda_barplot_comparison(
  data = mcda_data,
  study = "Study 2",
  benefit_criteria = c("Benefit 1", "Benefit 2", "Benefit 3"),
  risk_criteria = c("Risk 1", "Risk 2"),
  comparison_drug = "Drug B",
  clinical_scales = clinical_scales,
  weights = weights,
  base_font_size = fonts_16x6$p
)

ggsave_custom(
  "inst/img/other/barplot_mcda_comparison_drug_b.png",
  imgpath = "./",
  inplot = barplot_comp_b,
  wdth = 16,
  hght = 6,
  unts = "in",
  dpi = 600
)

barplot_comp_c <- create_mcda_barplot_comparison(
  data = mcda_data,
  study = "Study 3",
  benefit_criteria = c("Benefit 1", "Benefit 2", "Benefit 3"),
  risk_criteria = c("Risk 1", "Risk 2"),
  comparison_drug = "Drug C",
  clinical_scales = clinical_scales,
  weights = weights,
  base_font_size = fonts_16x6$p
)

ggsave_custom(
  "inst/img/other/barplot_mcda_comparison_drug_c.png",
  imgpath = "./",
  inplot = barplot_comp_c,
  wdth = 16,
  hght = 6,
  unts = "in",
  dpi = 600
)

barplot_comp_d <- create_mcda_barplot_comparison(
  data = mcda_data,
  study = "Study 4",
  benefit_criteria = c("Benefit 1", "Benefit 2", "Benefit 3"),
  risk_criteria = c("Risk 1", "Risk 2"),
  comparison_drug = "Drug D",
  clinical_scales = clinical_scales,
  weights = weights,
  base_font_size = fonts_16x6$p
)

ggsave_custom(
  "inst/img/other/barplot_mcda_comparison_drug_d.png",
  imgpath = "./",
  inplot = barplot_comp_d,
  wdth = 16,
  hght = 6,
  unts = "in",
  dpi = 600
)

# MCDA Waterfall (16×6)
waterfall_all <- create_mcda_waterfall(
  data = mcda_data,
  comparator_name = "Placebo",
  benefit_criteria = c("Benefit 1", "Benefit 2", "Benefit 3"),
  risk_criteria = c("Risk 1", "Risk 2"),
  weights = weights,
  clinical_scales = clinical_scales,
  base_font_size = fonts_16x6$p
)

ggsave_custom(
  "inst/img/pub/image09_mcda_waterfall_all_drugs.png",
  imgpath = "./",
  inplot = waterfall_all,
  wdth = 16,
  hght = 6,
  unts = "in",
  dpi = 600
)

# MCDA Benefit-Risk Map (8×8)
fonts_8x8 <- font_config(8, 8)
brmap_all <- create_mcda_brmap(
  data = mcda_data,
  comparator_name = "Placebo",
  benefit_criteria = c("Benefit 1", "Benefit 2", "Benefit 3"),
  risk_criteria = c("Risk 1", "Risk 2"),
  weights = weights,
  clinical_scales = clinical_scales,
  show_frontier = TRUE,
  show_labels = TRUE,
  base_font_size = fonts_8x8$p
)

ggsave_custom(
  "inst/img/pub/image10_mcda_benefit_risk_map.png",
  imgpath = "./",
  inplot = brmap_all,
  wdth = 8,
  hght = 8,
  unts = "in",
  dpi = 600
)

# MCDA Tornado Plots (10×6)
fonts_10x6 <- font_config(10, 6)

tornado_a <- mcda_tornado(
  data = mcda_data |> dplyr::filter(Study == "Study 1") |> dplyr::select(-Study),
  comparator_name = "Placebo",
  comparison_drug = "Drug A",
  weights = weights,
  clinical_scales = clinical_scales,
  base_font_size = fonts_10x6$p
)

ggsave_custom(
  "inst/img/pub/image11_tornado.png",
  imgpath = "./",
  inplot = tornado_a,
  wdth = 10,
  hght = 6,
  unts = "in",
  dpi = 600
)

# Similar for drugs B, C, D...
tornado_b <- mcda_tornado(
  data = mcda_data |> dplyr::filter(Study == "Study 2") |> dplyr::select(-Study),
  comparator_name = "Placebo",
  comparison_drug = "Drug B",
  weights = weights,
  clinical_scales = clinical_scales,
  base_font_size = fonts_10x6$p
)

ggsave_custom(
  "inst/img/other/mcda_tornado_drug_b.png",
  imgpath = "./",
  inplot = tornado_b,
  wdth = 10,
  hght = 6,
  unts = "in",
  dpi = 600
)

tornado_c <- mcda_tornado(
  data = mcda_data |> dplyr::filter(Study == "Study 3") |> dplyr::select(-Study),
  comparator_name = "Placebo",
  comparison_drug = "Drug C",
  weights = weights,
  clinical_scales = clinical_scales,
  base_font_size = fonts_10x6$p
)

ggsave_custom(
  "inst/img/other/mcda_tornado_drug_c.png",
  imgpath = "./",
  inplot = tornado_c,
  wdth = 10,
  hght = 6,
  unts = "in",
  dpi = 600
)

tornado_d <- mcda_tornado(
  data = mcda_data |> dplyr::filter(Study == "Study 4") |> dplyr::select(-Study),
  comparator_name = "Placebo",
  comparison_drug = "Drug D",
  weights = weights,
  clinical_scales = clinical_scales,
  base_font_size = fonts_10x6$p
)

ggsave_custom(
  "inst/img/other/mcda_tornado_drug_d.png",
  imgpath = "./",
  inplot = tornado_d,
  wdth = 10,
  hght = 6,
  unts = "in",
  dpi = 600
)

message("All publication plots generated with consistent font scaling!")
message("\nFont sizes used:")
message("  5×4 plots:  ", round(fonts_5x4$p, 1), "pt")
message("  5×5 plots:  ", round(fonts_5x5$p, 1), "pt")
message("  7×5 plots:  ", round(fonts_7x5$p, 1), "pt")
message("  7×7 plots:  ", round(fonts_7x7$p, 1), "pt (reference)")
message("  8×8 plots:  ", round(fonts_8x8$p, 1), "pt")
message(" 10×4 plots:  ", round(fonts_10x4$p, 1), "pt")
message("  ", vft_width, "×", vft_height, " plots:  ", round(fonts_vft$p, 1), "pt")
message(" 10×6 plots:  ", round(fonts_10x6$p, 1), "pt")
message(" 12×6 plots:  ", round(fonts_12x6$p, 1), "pt")
message(" 14×9 plots:  ", round(fonts_14x9$p, 1), "pt")
message(" 16×6 plots:  ", round(fonts_16x6$p, 1), "pt")
