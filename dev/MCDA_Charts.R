# ============================================================================
# MCDA Benefit-Risk Analysis - Chart Generation Script
# Creates Figures 7a, 7b, 8 (stacked bar and waterfall), and 9
# ============================================================================

# Load required libraries
library(ggplot2)
library(dplyr)
library(reshape2)
library(gridExtra)

# ============================================================================
# 1. DATA PREPARATION
# ============================================================================

# Create raw performance data
create_publication_data <- function() {
  performance_data <- data.frame(
    Treatment = c("Placebo", "Drug A", "Drug B", "Drug C", "Drug D"),
    Primary_Efficacy = c(0.25, 0.62, 0.45, 0.58, 0.52),
    Secondary_Efficacy = c(5, 42, 28, 38, 35),
    Quality_of_Life = c(2, 38, 25, 32, 42),
    Recurring_AE = c(0.15, 0.35, 0.25, 0.42, 0.20),
    Rare_SAE = c(0.02, 0.04, 0.03, 0.06, 0.02)
  )
  return(performance_data)
}

# Calculate treatment differences vs placebo
calculate_treatment_differences <- function(data) {
  placebo_row <- data[data$Treatment == "Placebo", ]

  differences <- data.frame(
    Treatment = data$Treatment[data$Treatment != "Placebo"],
    Primary_Efficacy_Diff = data$Primary_Efficacy[data$Treatment != "Placebo"] -
      placebo_row$Primary_Efficacy,
    Secondary_Efficacy_Diff = data$Secondary_Efficacy[
      data$Treatment != "Placebo"
    ] -
      placebo_row$Secondary_Efficacy,
    Quality_of_Life_Diff = data$Quality_of_Life[data$Treatment != "Placebo"] -
      placebo_row$Quality_of_Life,
    Recurring_AE_Diff = placebo_row$Recurring_AE -
      data$Recurring_AE[data$Treatment != "Placebo"],
    Rare_SAE_Diff = placebo_row$Rare_SAE -
      data$Rare_SAE[data$Treatment != "Placebo"]
  )
  return(differences)
}

# Initialize data
pub_data <- create_publication_data()
treatment_diffs <- calculate_treatment_differences(pub_data)

# Create performance matrix
performance_matrix_pub <- as.matrix(treatment_diffs[, -1])
rownames(performance_matrix_pub) <- treatment_diffs$Treatment
colnames(performance_matrix_pub) <- c(
  "Primary_Efficacy",
  "Secondary_Efficacy",
  "Quality_of_Life",
  "Recurring_AE",
  "Rare_SAE"
)

# Define weights
weights_pub <- c(
  Primary_Efficacy = 0.229,
  Secondary_Efficacy = 0.057,
  Quality_of_Life = 0.115,
  Recurring_AE = 0.479,
  Rare_SAE = 0.120
)

# Normalize performance matrix
normalized_pub <- apply(performance_matrix_pub, 2, function(x) {
  (x - min(x)) / (max(x) - min(x))
})

# Calculate weighted contributions
weighted_contributions_pub <- normalized_pub *
  rep(weights_pub, each = nrow(normalized_pub))

# Calculate total scores
total_scores_pub <- rowSums(weighted_contributions_pub)

# Create contributions data frame
contrib_df <- as.data.frame(weighted_contributions_pub)
contrib_df$Treatment <- rownames(performance_matrix_pub)
contrib_df$Total_Score <- total_scores_pub * 100
contrib_df$Rank <- rank(-total_scores_pub)

# Reshape for plotting
contrib_long <- melt(
  contrib_df[, 1:5],
  variable.name = "Criteria",
  value.name = "Contribution"
)
contrib_long$Treatment <- rep(contrib_df$Treatment, 5)

# ============================================================================
# 2. FIGURE 7a: RAW DATA TO TREATMENT DIFFERENCES
# ============================================================================

create_fig7a <- function() {
  raw_comparison <- data.frame(
    Criterion = rep(
      c(
        "Primary Efficacy",
        "Secondary Efficacy",
        "Quality of Life",
        "Recurring AE",
        "Rare SAE"
      ),
      3
    ),
    Value = c(
      0.25 * 100,
      5,
      2,
      0.15 * 100,
      0.02 * 100,
      0.62 * 100,
      42,
      38,
      0.35 * 100,
      0.04 * 100,
      (0.62 - 0.25) * 100,
      42 - 5,
      38 - 2,
      (0.15 - 0.35) * 100,
      (0.02 - 0.04) * 100
    ),
    Group = rep(c("Placebo", "Drug A", "Treatment Difference"), each = 5),
    Type = rep(c("Benefit", "Benefit", "Benefit", "Risk", "Risk"), 3)
  )

  raw_comparison$Criterion <- factor(
    raw_comparison$Criterion,
    levels = rev(c(
      "Primary Efficacy",
      "Secondary Efficacy",
      "Quality of Life",
      "Recurring AE",
      "Rare SAE"
    ))
  )
  raw_comparison$Group <- factor(
    raw_comparison$Group,
    levels = c("Placebo", "Drug A", "Treatment Difference")
  )

  p_raw <- ggplot(raw_comparison, aes(x = Value, y = Criterion, fill = Type)) +
    geom_bar(stat = "identity", width = 0.7) +
    facet_wrap(~Group, ncol = 3, scales = "free_x") +
    scale_fill_manual(values = c("Benefit" = "#4ECDC4", "Risk" = "#FF6B6B")) +
    labs(
      title = "Figure 7a: From Raw Data to Treatment Differences",
      subtitle = "Understanding what MCDA analyzes: Drug effect vs Placebo",
      x = "Value (various scales)",
      y = NULL
    ) +
    theme_minimal() +
    theme(
      strip.text = element_text(size = 12, face = "bold"),
      strip.background = element_rect(fill = "grey90", color = NA),
      axis.text.y = element_text(size = 10),
      legend.position = "bottom",
      plot.title = element_text(size = 14, face = "bold"),
      plot.subtitle = element_text(size = 11)
    ) +
    geom_vline(
      xintercept = 0,
      linetype = "dashed",
      color = "gray40",
      size = 0.5
    )

  return(p_raw)
}

# ============================================================================
# 3. FIGURE 7b: MCDA CALCULATION WALKTHROUGH (DRUG A)
# ============================================================================

create_fig7b <- function() {
  drug_a_idx <- which(rownames(performance_matrix_pub) == "Drug A")
  drug_a_weights <- weights_pub * 100
  drug_a_values <- normalized_pub[drug_a_idx, ] * 100
  drug_a_contributions <- weighted_contributions_pub[drug_a_idx, ] * 100
  drug_a_total <- sum(drug_a_contributions)

  x_max <- 100

  # Panel 1: Weights
  weights_df_plot <- data.frame(
    Criterion = factor(
      c(
        "Primary Efficacy",
        "Secondary Efficacy",
        "Quality of Life",
        "Recurring AE",
        "Rare SAE"
      ),
      levels = rev(c(
        "Primary Efficacy",
        "Secondary Efficacy",
        "Quality of Life",
        "Recurring AE",
        "Rare SAE"
      ))
    ),
    Weight = weights_pub * 100,
    Type = c("Benefit", "Benefit", "Benefit", "Risk", "Risk")
  )

  p_weights <- ggplot(
    weights_df_plot,
    aes(x = Weight, y = Criterion, fill = Type)
  ) +
    geom_bar(stat = "identity", width = 0.7) +
    scale_fill_manual(values = c("Benefit" = "#4ECDC4", "Risk" = "#FF6B6B")) +
    labs(title = "Weight", subtitle = "Importance (%)", x = NULL, y = NULL) +
    xlim(0, x_max) +
    theme_minimal() +
    theme(
      axis.text.y = element_text(size = 10),
      legend.position = "none",
      plot.title = element_text(size = 12, face = "bold", hjust = 0.5),
      plot.subtitle = element_text(size = 10, hjust = 0.5)
    ) +
    geom_text(aes(label = sprintf("%.1f", Weight)), hjust = -0.1, size = 3)

  # Panel 2: Drug A Normalized Values
  drug_a_values_df <- data.frame(
    Criterion = factor(
      c(
        "Primary Efficacy",
        "Secondary Efficacy",
        "Quality of Life",
        "Recurring AE",
        "Rare SAE"
      ),
      levels = rev(c(
        "Primary Efficacy",
        "Secondary Efficacy",
        "Quality of Life",
        "Recurring AE",
        "Rare SAE"
      ))
    ),
    Value = normalized_pub[drug_a_idx, ] * 100,
    Type = c("Benefit", "Benefit", "Benefit", "Risk", "Risk")
  )

  p_values <- ggplot(
    drug_a_values_df,
    aes(x = Value, y = Criterion, fill = Type)
  ) +
    geom_bar(stat = "identity", width = 0.7) +
    scale_fill_manual(values = c("Benefit" = "#4ECDC4", "Risk" = "#FF6B6B")) +
    labs(
      title = "Value",
      subtitle = "Drug A vs Placebo (%)",
      x = NULL,
      y = NULL
    ) +
    xlim(0, x_max) +
    theme_minimal() +
    theme(
      axis.text.y = element_blank(),
      legend.position = "none",
      plot.title = element_text(size = 12, face = "bold", hjust = 0.5),
      plot.subtitle = element_text(size = 10, hjust = 0.5)
    ) +
    geom_text(aes(label = sprintf("%.0f", Value)), hjust = -0.1, size = 3)

  # Panel 3: Drug A Weighted Contributions
  drug_a_contrib_df <- data.frame(
    Criterion = factor(
      c(
        "Primary Efficacy",
        "Secondary Efficacy",
        "Quality of Life",
        "Recurring AE",
        "Rare SAE"
      ),
      levels = rev(c(
        "Primary Efficacy",
        "Secondary Efficacy",
        "Quality of Life",
        "Recurring AE",
        "Rare SAE"
      ))
    ),
    Contribution = weighted_contributions_pub[drug_a_idx, ] * 100,
    Type = c("Benefit", "Benefit", "Benefit", "Risk", "Risk")
  )

  p_weighted <- ggplot(
    drug_a_contrib_df,
    aes(x = Contribution, y = Criterion, fill = Type)
  ) +
    geom_bar(stat = "identity", width = 0.7) +
    scale_fill_manual(values = c("Benefit" = "#4ECDC4", "Risk" = "#FF6B6B")) +
    labs(
      title = "Benefit-Risk",
      subtitle = sprintf("Weight × Value (%%)\nTotal = %.1f", drug_a_total),
      x = NULL,
      y = NULL
    ) +
    xlim(0, x_max) +
    theme_minimal() +
    theme(
      axis.text.y = element_blank(),
      legend.position = "none",
      plot.title = element_text(size = 12, face = "bold", hjust = 0.5),
      plot.subtitle = element_text(size = 10, hjust = 0.5)
    ) +
    geom_text(
      aes(label = sprintf("%.1f", Contribution)),
      hjust = -0.1,
      size = 3
    )

  # Combine panels
  combined_plot <- grid.arrange(
    p_weights,
    p_values,
    p_weighted,
    ncol = 3,
    top = "Figure 7b: How MCDA Combines Weights and Values (Drug A)"
  )

  return(combined_plot)
}

# ============================================================================
# 4. FIGURE 8: STACKED BAR CHART WITH WEIGHTS
# ============================================================================

create_fig8_stacked <- function() {
  # Create stacked bar chart
  p_stacked <- ggplot(
    contrib_long,
    aes(x = Treatment, y = Contribution * 100, fill = Criteria)
  ) +
    geom_bar(stat = "identity", width = 0.7) +
    scale_fill_manual(
      values = c(
        "Primary_Efficacy" = "#FF6B6B",
        "Secondary_Efficacy" = "#4ECDC4",
        "Quality_of_Life" = "#45B7D1",
        "Recurring_AE" = "#96CEB4",
        "Rare_SAE" = "#FFEAA7"
      ),
      labels = c(
        "Primary Efficacy",
        "Secondary Efficacy",
        "Quality of Life",
        "Recurring AE",
        "Rare SAE"
      )
    ) +
    labs(
      title = "Treatment Scores",
      x = "Treatment",
      y = "Weighted Contribution"
    ) +
    theme_minimal() +
    theme(
      legend.position = "none",
      plot.title = element_text(size = 12, face = "bold")
    ) +
    geom_text(
      data = contrib_df,
      aes(x = Treatment, y = Total_Score + 2, label = round(Total_Score, 1)),
      inherit.aes = FALSE,
      vjust = 0,
      size = 5,
      fontface = "bold"
    )

  # Create weights bar chart
  weights_chart_df <- data.frame(
    Criteria = factor(
      c(
        "Primary Efficacy",
        "Secondary Efficacy",
        "Quality of Life",
        "Recurring AE",
        "Rare SAE"
      ),
      levels = rev(c(
        "Primary Efficacy",
        "Secondary Efficacy",
        "Quality of Life",
        "Recurring AE",
        "Rare SAE"
      ))
    ),
    Weight = weights_pub * 100,
    Criteria_var = factor(
      c(
        "Primary_Efficacy",
        "Secondary_Efficacy",
        "Quality_of_Life",
        "Recurring_AE",
        "Rare_SAE"
      ),
      levels = rev(c(
        "Primary_Efficacy",
        "Secondary_Efficacy",
        "Quality_of_Life",
        "Recurring_AE",
        "Rare_SAE"
      ))
    )
  )

  p_weights_chart <- ggplot(
    weights_chart_df,
    aes(x = Weight, y = Criteria, fill = Criteria_var)
  ) +
    geom_bar(stat = "identity", width = 0.7) +
    scale_fill_manual(
      values = c(
        "Primary_Efficacy" = "#FF6B6B",
        "Secondary_Efficacy" = "#4ECDC4",
        "Quality_of_Life" = "#45B7D1",
        "Recurring_AE" = "#96CEB4",
        "Rare_SAE" = "#FFEAA7"
      )
    ) +
    labs(title = "Criterion Weights", x = "Weight (%)", y = NULL) +
    theme_minimal() +
    theme(
      legend.position = "none",
      plot.title = element_text(size = 12, face = "bold"),
      axis.text.y = element_text(size = 10)
    ) +
    geom_text(
      aes(label = sprintf("%.1f%%", Weight)),
      hjust = -0.1,
      size = 3.5
    ) +
    xlim(0, max(weights_chart_df$Weight) * 1.15)

  # Combine both plots
  library(grid)
  combined_plot <- grid.arrange(
    p_stacked,
    p_weights_chart,
    ncol = 2,
    widths = c(2.5, 1),
    top = textGrob(
      "Figure 8: MCDA Weighted Scores by Treatment",
      gp = gpar(fontsize = 14, fontface = "bold")
    )
  )

  return(combined_plot)
}

# ============================================================================
# 5. FIGURE 8: WATERFALL CHART
# ============================================================================

create_fig8_waterfall <- function() {
  # Prepare waterfall data
  waterfall_data <- contrib_long %>%
    mutate(
      Criteria = factor(
        Criteria,
        levels = c(
          "Primary_Efficacy",
          "Secondary_Efficacy",
          "Quality_of_Life",
          "Recurring_AE",
          "Rare_SAE"
        )
      )
    ) %>%
    arrange(Treatment, Criteria) %>%
    group_by(Treatment) %>%
    mutate(
      Contribution_pct = Contribution * 100,
      end = cumsum(Contribution_pct),
      start = lag(end, default = 0),
      id = 7 - row_number()
    ) %>%
    ungroup()

  # Add total bars
  totals <- contrib_df %>%
    select(Treatment, Total_Score) %>%
    mutate(
      Criteria = factor(
        "Total",
        levels = c(
          "Primary_Efficacy",
          "Secondary_Efficacy",
          "Quality_of_Life",
          "Recurring_AE",
          "Rare_SAE",
          "Total"
        )
      ),
      Contribution_pct = Total_Score,
      start = 0,
      end = Total_Score,
      id = 1
    )

  # Combine data
  waterfall_complete <- bind_rows(waterfall_data, totals) %>%
    mutate(
      Criteria = factor(
        Criteria,
        levels = c(
          "Primary_Efficacy",
          "Secondary_Efficacy",
          "Quality_of_Life",
          "Recurring_AE",
          "Rare_SAE",
          "Total"
        )
      ),
      Treatment = factor(
        Treatment,
        levels = c("Drug A", "Drug B", "Drug C", "Drug D")
      )
    )

  # Create connector lines
  connector_lines <- waterfall_data %>%
    arrange(Treatment, desc(id)) %>%
    group_by(Treatment) %>%
    mutate(
      next_start = lead(start),
      next_id = lead(id)
    ) %>%
    filter(!is.na(next_start)) %>%
    ungroup()

  # Add connectors from Rare SAE to Total
  rare_to_total <- waterfall_data %>%
    filter(Criteria == "Rare_SAE") %>%
    left_join(
      totals %>% select(Treatment, total_end = end, total_id = id),
      by = "Treatment"
    ) %>%
    mutate(
      next_start = 0,
      next_id = total_id
    ) %>%
    select(Treatment, Criteria, end, id, next_start, next_id)

  all_connectors <- bind_rows(connector_lines, rare_to_total)

  # Create plot
  p_waterfall <- ggplot(
    waterfall_complete,
    aes(
      y = id,
      fill = Criteria,
      ymin = id - 0.45,
      ymax = id + 0.45,
      xmin = start,
      xmax = end
    )
  ) +
    geom_rect(alpha = 0.9) +
    geom_segment(
      data = all_connectors,
      aes(x = end, xend = end, y = id + 0.45, yend = next_id - 0.45),
      linetype = "dotted",
      color = "gray40",
      linewidth = 0.5,
      inherit.aes = FALSE
    ) +
    facet_wrap(~Treatment, nrow = 1) +
    scale_fill_manual(
      values = c(
        "Primary_Efficacy" = "#FF6B6B",
        "Secondary_Efficacy" = "#4ECDC4",
        "Quality_of_Life" = "#45B7D1",
        "Recurring_AE" = "#96CEB4",
        "Rare_SAE" = "#FFEAA7",
        "Total" = "#34495e"
      ),
      labels = c(
        "Primary Efficacy",
        "Secondary Efficacy",
        "Quality of Life",
        "Recurring AE",
        "Rare SAE",
        "Total Score"
      ),
      drop = FALSE
    ) +
    geom_text(
      data = filter(
        waterfall_complete,
        Contribution_pct > 0.5,
        Criteria != "Total"
      ),
      aes(
        x = (start + end) / 2,
        y = id,
        label = sprintf("%.1f", Contribution_pct)
      ),
      inherit.aes = FALSE,
      size = 3.5,
      color = "black",
      fontface = "bold"
    ) +
    geom_text(
      data = filter(waterfall_complete, Criteria == "Total"),
      aes(x = end + 2, y = id, label = sprintf("%.1f", Contribution_pct)),
      inherit.aes = FALSE,
      size = 4,
      fontface = "bold",
      hjust = 0
    ) +
    scale_y_continuous(
      breaks = 1:6,
      labels = c(
        "Total\nScore",
        "Rare\nSAE",
        "Recurring\nAE",
        "Quality\nof Life",
        "Secondary\nEfficacy",
        "Primary\nEfficacy"
      ),
      expand = expansion(mult = c(0.02, 0.02))
    ) +
    scale_x_continuous(expand = expansion(mult = c(0.02, 0.15))) +
    labs(
      title = "Figure 8: MCDA Waterfall Chart - Treatment Differences vs Placebo",
      subtitle = "Each bar shows cumulative contribution of criteria to total weighted score difference",
      x = "Cumulative Weighted Score Difference",
      y = NULL
    ) +
    theme_minimal() +
    theme(
      legend.position = "none",
      plot.title = element_text(size = 14, face = "bold"),
      axis.text.y = element_text(size = 9, hjust = 1),
      panel.grid.major.y = element_blank(),
      panel.grid.minor.y = element_blank(),
      strip.text = element_text(size = 11, face = "bold"),
      strip.background = element_rect(fill = "gray90", color = NA)
    )

  return(p_waterfall)
}

# ============================================================================
# 6. FIGURE 9: BENEFIT-RISK MAP
# ============================================================================

create_fig9 <- function() {
  # Calculate benefit and risk category weights
  benefit_criteria <- c(
    "Primary_Efficacy",
    "Secondary_Efficacy",
    "Quality_of_Life"
  )
  risk_criteria <- c("Recurring_AE", "Rare_SAE")

  benefit_weights <- weights_pub[benefit_criteria]
  risk_weights <- weights_pub[risk_criteria]

  total_benefit_weight <- sum(benefit_weights) * 100 # 40.1%
  total_risk_weight <- sum(risk_weights) * 100 # 59.9%

  # Create benefit-risk map data
  br_map_df <- data.frame(
    Treatment = c("Drug A", "Drug B", "Drug C", "Drug D"),
    Benefits = c(98, 34, 68, 24),
    Risks = c(52, 62, 10, 98),
    Label = c("1", "2", "3", "4")
  )

  # Find the two outermost points
  max_y_point <- br_map_df[which.max(br_map_df$Risks), ] # Drug D at (24, 98)
  max_x_point <- br_map_df[which.max(br_map_df$Benefits), ] # Drug A at (98, 52)

  # Create frontier polygon: (0, 0) -> (0, 98) -> Drug D (24, 98) -> Drug A (98, 52) -> (98, 0) -> back to origin
  frontier_polygon <- data.frame(
    x = c(
      0,
      0,
      max_y_point$Benefits,
      max_x_point$Benefits,
      max(br_map_df$Benefits),
      0
    ),
    y = c(0, max(br_map_df$Risks), max_y_point$Risks, max_x_point$Risks, 0, 0)
  )

  p_brmap <- ggplot(
    br_map_df,
    aes(x = Benefits, y = Risks, color = Treatment)
  ) +
    # Shaded frontier region under the two outermost points
    geom_polygon(
      data = frontier_polygon,
      aes(x = x, y = y),
      inherit.aes = FALSE,
      fill = "lightgreen",
      alpha = 0.3
    ) +
    geom_point(size = 8, alpha = 0.8) +
    geom_text(
      aes(label = Label),
      color = "black",
      size = 5,
      fontface = "bold"
    ) +
    scale_color_manual(
      values = c(
        "Drug A" = "#FF6B6B",
        "Drug B" = "#4ECDC4",
        "Drug C" = "#45B7D1",
        "Drug D" = "#96CEB4"
      ),
      labels = c("Drug A (1)", "Drug B (2)", "Drug C (3)", "Drug D (4)")
    ) +
    xlim(0, 100) +
    ylim(0, 100) +
    labs(
      title = "Figure 9: Benefit-Risk Map",
      subtitle = "Higher is better on both axes (treatment differences vs placebo)",
      x = "Benefits →",
      y = "Risks →"
    ) +
    theme_minimal() +
    theme(
      panel.grid.major = element_line(color = "lightgray"),
      plot.title = element_text(size = 14, face = "bold"),
      legend.position = "right"
    )

  return(p_brmap)
}

# ============================================================================
# 7. GENERATE ALL CHARTS
# ============================================================================

# Create output directory if it doesn't exist
if (!dir.exists("output")) {
  dir.create("output")
}

# Generate and save all figures
cat("Generating Figure 7a...\n")
fig7a <- create_fig7a()
ggsave(
  "dev/figure_7a_raw_comparison.jpeg",
  fig7a,
  width = 16,
  height = 6,
  dpi = 300
)

cat("Generating Figure 7b...\n")
fig7b <- create_fig7b()
ggsave(
  "dev/figure_7b_mcda_walkthrough.jpeg",
  fig7b,
  width = 14,
  height = 5,
  dpi = 300
)

cat("Generating Figure 8 (Stacked Bar)...\n")
fig8_stacked <- create_fig8_stacked()
ggsave(
  "dev/figure_8_stacked_bar.jpeg",
  fig8_stacked,
  width = 14,
  height = 7,
  dpi = 300
)

cat("Generating Figure 8 (Waterfall)...\n")
fig8_waterfall <- create_fig8_waterfall()
ggsave(
  "dev/figure_8_waterfall.jpeg",
  fig8_waterfall,
  width = 12,
  height = 6,
  dpi = 300
)

cat("Generating Figure 9...\n")
fig9 <- create_fig9()
ggsave(
  "dev/figure_9_benefit_risk_map.jpeg",
  fig9,
  width = 8,
  height = 8,
  dpi = 300
)

cat("\nAll figures generated successfully!\n")
cat("Output saved to 'dev/' directory\n")

# Display figures (optional - comment out if running in batch mode)
print(fig7a)
print(fig7b)
print(fig8_stacked)
print(fig8_waterfall)
print(fig9)
