# Generate publication plots for valueJudgementCE package WITH CONSISTENT FONT SCALING
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
  "inst/img/other/value_function_multiple_criteria.png",
  "inst/img/pub/image01_dotforest.tiff",
  "inst/img/pub/image02_tradeoff.tiff",
  "inst/img/pub/image03_correlogram.tiff",
  "inst/img/pub/image04_scatter.tiff",
  "inst/img/pub/image05_divergent_stacked_barchart.tiff",
  "inst/img/pub/image06_cumulative_excess.tiff",
  "inst/img/pub/image07_value_function_types_comparison.tiff",
  "inst/img/pub/image08_barplot_mcda_comparison_drug_a.tiff",
  "inst/img/pub/image09_mcda_waterfall_all_drugs.tiff",
  "inst/img/pub/image10_mcda_benefit_risk_map.tiff",
  "inst/img/pub/image11_tornado.tiff"
)

for (f in old_files) {
  if (file.exists(f)) {
    file.remove(f)
    message("Removed old file: ", f)
  }
}

# ============================================================================
# JOURNAL EXPORT CONFIGURATION
# ============================================================================
# Drug Safety / Springer targets:
# - single column: 84 mm
# - double column: 174 mm
# - final printed text target: ~7-9 pt

journal_single_width_mm <- 84
journal_double_width_mm <- 174
journal_reference_height_mm <- 120

mm_to_in <- function(mm) {
  mm / 25.4
}

journal_dims <- function(layout = c("single", "double"), original_width_in, original_height_in) {
  layout <- match.arg(layout)
  target_width_mm <- if (layout == "single") {
    journal_single_width_mm
  } else {
    journal_double_width_mm
  }
  target_width_in <- mm_to_in(target_width_mm)

  list(
    width_mm = target_width_mm,
    height_mm = target_width_mm * (original_height_in / original_width_in),
    width_in = target_width_in,
    height_in = target_width_in * (original_height_in / original_width_in)
  )
}

journal_fonts <- function(
  layout = c("single", "double"),
  original_width_in,
  original_height_in,
  ncol = 1,
  nrow = 1,
  target_font_size = 8
) {
  dims <- journal_dims(layout, original_width_in, original_height_in)
  font_config(
    width = dims$width_in,
    height = dims$height_in,
    ncol = ncol,
    nrow = nrow,
    reference_font_size = target_font_size,
    reference_width = mm_to_in(journal_double_width_mm),
    reference_height = mm_to_in(journal_reference_height_mm),
    min_font_size = 7,
    max_font_size = 9
  )
}

save_pub_plot <- function(
  save_name,
  inplot,
  layout = c("single", "double"),
  original_width_in,
  original_height_in,
  width_mm = NULL,
  height_mm = NULL,
  dpi = 600
) {
  dims <- journal_dims(layout, original_width_in, original_height_in)
  out_width_mm <- if (is.null(width_mm)) dims$width_mm else width_mm
  out_height_mm <- if (is.null(height_mm)) dims$height_mm else height_mm
  ggsave_custom(
    save_name = save_name,
    imgpath = "./",
    inplot = inplot,
    wdth = out_width_mm,
    hght = out_height_mm,
    unts = "mm",
    dpi = dpi
  )

  png_name <- sub("\\.[Tt][Ii][Ff]{1,2}$", ".png", save_name)
  if (!identical(png_name, save_name)) {
    ggsave_custom(
      save_name = png_name,
      imgpath = "./",
      inplot = inplot,
      wdth = out_width_mm,
      hght = out_height_mm,
      unts = "mm",
      dpi = dpi
    )
  }
}

# ============================================================================
# FONT SCALING CONFIGURATION
# ============================================================================
# Font sizes are automatically scaled based on figure dimensions using font_config()
# Reference: 9pt font for 7×7" figure
# Formula: base_font_size = 9 × sqrt((width × height) / 49)

# ============================================================================
# OUTCOME LABELS USED IN THE MANUSCRIPT
# ============================================================================
# The manuscript (Figs 2, 8, 9 and 11) labels the recurring risk outcome
# "AESI". Relabel copies of the example data for those figures only; the
# package datasets keep "Recurring AE".
pub_risk_label <- "AESI"
relabel_risk <- function(x) {
  x[x == "Recurring AE"] <- pub_risk_label
  x
}

# ============================================================================
# SINGLE-COLUMN PLOTS (5-7 inches wide)
# ============================================================================

# Scatter plot (7×7)
data(scatterplot)
outcome <- c("Benefit", "Risk")
fonts_7x7 <- journal_fonts("double", 7, 7)
font_image03 <- max(11, fonts_7x7$p)
scatter_plot_fig <- scatter_plot(
  scatterplot,
  outcome,
  mab = 0.2,
  mar = 0.6,
  base_font_size = fonts_7x7$p,
  style = "publication"
)
save_pub_plot(
  "inst/img/pub/image04_scatter.tiff",
  scatter_plot_fig,
  layout = "double",
  original_width_in = 7,
  original_height_in = 7
)

# Forest dot plot (7×5)
data(effects_table)
effects_table_pub <- effects_table
effects_table_pub$Outcome <- relabel_risk(effects_table_pub$Outcome)
prepared_data <- prepare_forest_dot_data(effects_table_pub)
fonts_7x5 <- journal_fonts("double", 7, 5)
font_image01 <- max(10, fonts_7x5$p)
dotforest_4pub <- create_forest_dot_plot(
  prepared_data,
  outcomes_with_thresholds = list(
    "Primary Efficacy" = 0.10,
    "Secondary Efficacy" = -20,
    "Quality of Life" = 10,
    "AESI" = -0.05,
    "Rare SAE" = -0.07
  ),
  base_font_size = font_image01
)

save_pub_plot(
  "inst/img/pub/image01_dotforest.tiff",
  dotforest_4pub,
  layout = "double",
  original_width_in = 7,
  original_height_in = 5
)

# Trade-off plot (5×5)
effects_table_filtered <- effects_table %>%
  filter(Outcome %in% c("Recurring AE", "Primary Efficacy"))

fonts_5x5 <- journal_fonts("double", 5, 5)
font_image02 <- max(10, fonts_5x5$p)
tradeoff <- tradeoff_utility_plot(
  data = effects_table_filtered,
  benefit = "Primary Efficacy",
  risk = "Recurring AE",
  mab = 0.05,
  mar = 0.45,
  tc_benefit = c(0.05, 0.1, 0.15, 0.2, 0.25, 0.3, 0.35, 0.4, 0.45),
  tc_risk = c(0.09, 0.17, 0.24, 0.3, 0.35, 0.39, 0.42, 0.44, 0.45),
  utility_levels = c(0.1, 0.2, 0.3),
  x_limits = c(0, 0.5),
  y_limits = c(0, 0.5),
  chartcolors = colfun()$fig7_colors,
  base_font_size = font_image02
)

save_pub_plot(
  "inst/img/pub/image02_tradeoff.tiff",
  tradeoff,
  layout = "double",
  original_width_in = 5,
  original_height_in = 5
)

# Combined survival plot (7×7)
data(cumexcess)
# Cumulative incidence with a fixed denominator (N randomized per arm);
# MAB0 = 10 and MARmax = 5 percentage points
cumulative_excess_plot <- cumexcess_incidence_plot(
  data = cumexcess,
  mab = 10,
  mar = 5,
  visits = 6,
  fig_colors = colfun()$fig13_colors,
  base_font_size = fonts_7x7$p
)

save_pub_plot(
  "inst/img/pub/image06_cumulative_excess.tiff",
  cumulative_excess_plot,
  layout = "double",
  original_width_in = 7,
  original_height_in = 7
)

# Correlogram (7×7)
save_pub_plot(
  "inst/img/pub/image03_correlogram.tiff",
  create_correlogram(corr, base_font_size = font_image03),
  layout = "double",
  original_width_in = 7,
  original_height_in = 7
)

# Stacked bar chart and divergent stacked bar chart combined (14×9)
data(comp_outcome)
fonts_14x9 <- journal_fonts("double", 14, 9, ncol = 2)

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
  base_font_size = fonts_14x9$p,
  fav_side = "left"
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

# Remove legends from both plots and add a single frame around each full plot
stacked_bar_no_legend <- stacked_bar_fig +
  theme(
    legend.position = "none",
    plot.background = element_rect(color = "black", fill = NA, linewidth = 0.5)
  )
divergent_stacked_bar_no_legend <- divergent_stacked_bar_fig +
  theme(
    legend.position = "none",
    plot.background = element_rect(color = "black", fill = NA, linewidth = 0.5)
  )

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

save_pub_plot(
  "inst/img/pub/image05_divergent_stacked_barchart.tiff",
  combined_bar_charts,
  layout = "double",
  original_width_in = 14,
  original_height_in = 9,
  height_mm = 145
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
  `Primary Efficacy` = list(min = 0, max = 1, direction = "increasing"),
  `Secondary Efficacy` = list(min = 0, max = 100, direction = "decreasing"),
  `Quality of Life` = list(min = 0, max = 100, direction = "increasing"),
  `Recurring AE` = list(min = 0, max = 0.5, direction = "decreasing"),
  `Rare SAE` = list(min = 0, max = 0.3, direction = "decreasing")
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
fonts_vft <- journal_fonts("double", vft_width, vft_height, ncol = 2)
font_image07 <- max(10, fonts_vft$p)
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
  base_font_size = font_image07
)

save_pub_plot(
  "inst/img/pub/image07_value_function_types_comparison.tiff",
  value_func_types_comparison,
  layout = "double",
  original_width_in = vft_width,
  original_height_in = vft_height
)

# ============================================================================
# MCDA PLOTS (8×8 to 16×6)
# ============================================================================

weights <- c(
  `Primary Efficacy` = 0.30, `Secondary Efficacy` = 0.20, `Quality of Life` = 0.10,
  `Recurring AE` = 0.30, `Rare SAE` = 0.10
)

# Copies with the manuscript risk label for Figs 8, 9 and 11 (and the
# matching Drug B-D versions). Weight sensitivity plots keep the dataset names.
mcda_data_pub <- mcda_data
names(mcda_data_pub) <- relabel_risk(names(mcda_data_pub))
clinical_scales_pub <- clinical_scales
names(clinical_scales_pub) <- relabel_risk(names(clinical_scales_pub))
weights_pub <- weights
names(weights_pub) <- relabel_risk(names(weights_pub))
risk_criteria_pub <- relabel_risk(c("Recurring AE", "Rare SAE"))

# MCDA Comparison Plots (16×6)
fonts_16x6 <- journal_fonts("double", 16, 6, ncol = 2)

barplot_comp_a <- create_mcda_barplot_comparison(
  data = mcda_data_pub,
  study = "Study 1",
  benefit_criteria = c("Primary Efficacy", "Secondary Efficacy", "Quality of Life"),
  risk_criteria = risk_criteria_pub,
  comparison_drug = "Drug A",
  clinical_scales = clinical_scales_pub,
  weights = weights_pub,
  base_font_size = fonts_16x6$p
)

save_pub_plot(
  "inst/img/pub/image08_barplot_mcda_comparison_drug_a.tiff",
  barplot_comp_a,
  layout = "double",
  original_width_in = 16,
  original_height_in = 6
)

# Similar for drugs B, C, D...
barplot_comp_b <- create_mcda_barplot_comparison(
  data = mcda_data_pub,
  study = "Study 2",
  benefit_criteria = c("Primary Efficacy", "Secondary Efficacy", "Quality of Life"),
  risk_criteria = risk_criteria_pub,
  comparison_drug = "Drug B",
  clinical_scales = clinical_scales_pub,
  weights = weights_pub,
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
  data = mcda_data_pub,
  study = "Study 3",
  benefit_criteria = c("Primary Efficacy", "Secondary Efficacy", "Quality of Life"),
  risk_criteria = risk_criteria_pub,
  comparison_drug = "Drug C",
  clinical_scales = clinical_scales_pub,
  weights = weights_pub,
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
  data = mcda_data_pub,
  study = "Study 4",
  benefit_criteria = c("Primary Efficacy", "Secondary Efficacy", "Quality of Life"),
  risk_criteria = risk_criteria_pub,
  comparison_drug = "Drug D",
  clinical_scales = clinical_scales_pub,
  weights = weights_pub,
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
  data = mcda_data_pub,
  comparator_name = "Placebo",
  benefit_criteria = c("Primary Efficacy", "Secondary Efficacy", "Quality of Life"),
  risk_criteria = risk_criteria_pub,
  weights = weights_pub,
  clinical_scales = clinical_scales_pub,
  base_font_size = fonts_16x6$p
)

save_pub_plot(
  "inst/img/pub/image09_mcda_waterfall_all_drugs.tiff",
  waterfall_all,
  layout = "double",
  original_width_in = 16,
  original_height_in = 6
)

# MCDA Benefit-Risk Map (8×8)
fonts_8x8 <- journal_fonts("double", 8, 8)
brmap_all <- create_mcda_brmap(
  data = mcda_data,
  comparator_name = "Placebo",
  benefit_criteria = c("Primary Efficacy", "Secondary Efficacy", "Quality of Life"),
  risk_criteria = c("Recurring AE", "Rare SAE"),
  weights = weights,
  clinical_scales = clinical_scales,
  show_frontier = TRUE,
  show_labels = TRUE,
  base_font_size = max(10, fonts_8x8$p)
)

save_pub_plot(
  "inst/img/pub/image10_mcda_benefit_risk_map.tiff",
  brmap_all,
  layout = "double",
  original_width_in = 8,
  original_height_in = 8
)

# MCDA Tornado Plots (10×6)
fonts_10x6 <- journal_fonts("double", 10, 6)

tornado_a <- mcda_tornado(
  data = mcda_data_pub |> dplyr::filter(Study == "Study 1") |> dplyr::select(-Study),
  comparator_name = "Placebo",
  comparison_drug = "Drug A",
  weights = weights_pub,
  clinical_scales = clinical_scales_pub,
  base_font_size = fonts_10x6$p
)

save_pub_plot(
  "inst/img/pub/image11_tornado.tiff",
  tornado_a,
  layout = "double",
  original_width_in = 10,
  original_height_in = 6
)

# Similar for drugs B, C, D...
tornado_b <- mcda_tornado(
  data = mcda_data_pub |> dplyr::filter(Study == "Study 2") |> dplyr::select(-Study),
  comparator_name = "Placebo",
  comparison_drug = "Drug B",
  weights = weights_pub,
  clinical_scales = clinical_scales_pub,
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
  data = mcda_data_pub |> dplyr::filter(Study == "Study 3") |> dplyr::select(-Study),
  comparator_name = "Placebo",
  comparison_drug = "Drug C",
  weights = weights_pub,
  clinical_scales = clinical_scales_pub,
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
  data = mcda_data_pub |> dplyr::filter(Study == "Study 4") |> dplyr::select(-Study),
  comparator_name = "Placebo",
  comparison_drug = "Drug D",
  weights = weights_pub,
  clinical_scales = clinical_scales_pub,
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

# MCDA Weight Sensitivity Plots (7×7), one chart per outcome for Drug A
weight_sensitivity_data <- mcda_data |> dplyr::filter(Study == "Study 1")

weight_sensitivity_sae <- mcda_weight_sensitivity(
  data = weight_sensitivity_data,
  weights = weights,
  clinical_scales = clinical_scales,
  criteria = "Rare SAE",
  shading = "hiview",
  base_font_size = fonts_7x7$p
)

save_pub_plot(
  "inst/img/pub/image12_weight_sensitivity.tiff",
  weight_sensitivity_sae,
  layout = "double",
  original_width_in = 7,
  original_height_in = 7
)

for (criterion in setdiff(names(weights), "Rare SAE")) {
  weight_sensitivity <- mcda_weight_sensitivity(
    data = weight_sensitivity_data,
    weights = weights,
    clinical_scales = clinical_scales,
    criteria = criterion,
    shading = "hiview",
    base_font_size = fonts_7x7$p
  )

  ggsave_custom(
    paste0(
      "inst/img/other/mcda_weight_sensitivity_drug_a_",
      gsub(" ", "_", tolower(criterion)),
      ".png"
    ),
    imgpath = "./",
    inplot = weight_sensitivity,
    wdth = 7,
    hght = 7,
    unts = "in",
    dpi = 600
  )
}

# MCDA Weight Sensitivity Plots (7×7), Drugs A-D compared on one chart as
# differences from each study's placebo, matching the waterfall and tornado
weight_sensitivity_drugs_sae <- mcda_weight_sensitivity(
  data = mcda_data,
  weights = weights,
  clinical_scales = clinical_scales,
  comparator_name = "Placebo",
  criteria = "Rare SAE",
  shading = "hiview",
  base_font_size = fonts_7x7$p
)

save_pub_plot(
  "inst/img/pub/image13_weight_sensitivity_drugs.tiff",
  weight_sensitivity_drugs_sae,
  layout = "double",
  original_width_in = 7,
  original_height_in = 7
)

for (criterion in setdiff(names(weights), "Rare SAE")) {
  weight_sensitivity <- mcda_weight_sensitivity(
    data = mcda_data,
    weights = weights,
    clinical_scales = clinical_scales,
    comparator_name = "Placebo",
    criteria = criterion,
    shading = "hiview",
    base_font_size = fonts_7x7$p
  )

  ggsave_custom(
    paste0(
      "inst/img/other/mcda_weight_sensitivity_drugs_",
      gsub(" ", "_", tolower(criterion)),
      ".png"
    ),
    imgpath = "./",
    inplot = weight_sensitivity,
    wdth = 7,
    hght = 7,
    unts = "in",
    dpi = 600
  )
}

# MCDA Weight Sensitivity Plot (7×7), overall scores of Drugs A-D
ws_treatments_sae <- mcda_weight_sensitivity(
  data = mcda_data |> dplyr::filter(Treatment != "Placebo"),
  weights = weights,
  clinical_scales = clinical_scales,
  criteria = "Rare SAE",
  shading = "hiview",
  base_font_size = fonts_7x7$p
)

save_pub_plot(
  "inst/img/pub/image14_weight_sensitivity_treatments.tiff",
  ws_treatments_sae,
  layout = "double",
  original_width_in = 7,
  original_height_in = 7
)

for (criterion in setdiff(names(weights), "Rare SAE")) {
  weight_sensitivity <- mcda_weight_sensitivity(
    data = mcda_data |> dplyr::filter(Treatment != "Placebo"),
    weights = weights,
    clinical_scales = clinical_scales,
    criteria = criterion,
    shading = "hiview",
    base_font_size = fonts_7x7$p
  )

  ggsave_custom(
    paste0(
      "inst/img/other/mcda_weight_sensitivity_treatments_",
      gsub(" ", "_", tolower(criterion)),
      ".png"
    ),
    imgpath = "./",
    inplot = weight_sensitivity,
    wdth = 7,
    hght = 7,
    unts = "in",
    dpi = 600
  )
}

message("All publication plots generated with journal-ready widths and consistent font scaling.")
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
