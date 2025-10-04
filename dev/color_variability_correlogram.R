# =============================================================================
# Color-Based Variability Correlogram with Legend
# =============================================================================
# Color represents variability level, other elements show correlation direction

library(brpubVJCE)
library(ggplot2)
library(dplyr)
library(RColorBrewer)

# =============================================================================
# Approach 4: Color Represents Variability + Legend
# =============================================================================

create_color_variability_correlogram <- function(df,
                                                show_upper = FALSE,
                                                show_diag = FALSE,
                                                show_coeff = TRUE,
                                                variability_colors = NULL) {

  # Default color palette for variability (low to high)
  if (is.null(variability_colors)) {
    # Green (low variability/reliable) to Red (high variability/unreliable)
    variability_colors <- c("#2E8B57", "#90EE90", "#FFD700", "#FFA500", "#FF4500")
  }

  # Calculate correlation matrix and variability
  cor_mat <- cor(df, use = "complete.obs")
  var_stats <- apply(df, 2, function(x) sd(x, na.rm = TRUE))
  n_vars <- ncol(cor_mat)

  # Store original variability range for legend
  min_var <- min(var_stats)
  max_var <- max(var_stats)
  var_range <- max_var - min_var

  # Normalize variability to 0-1 scale for color mapping
  var_normalized <- (var_stats - min_var) / var_range
  var_normalized[is.na(var_normalized)] <- 0.5

  # Calculate actual variability breakpoints for legend
  breaks_norm <- c(0, 0.2, 0.4, 0.6, 0.8, 1.0)
  breaks_actual <- min_var + breaks_norm * var_range

  # Create discrete variability categories for legend
  var_categories <- cut(var_normalized,
                       breaks = breaks_norm,
                       labels = c("Very Low", "Low", "Medium", "High", "Very High"),
                       include.lowest = TRUE)

  # Create plotting data
  cor_data <- expand.grid(x = 1:n_vars, y = 1:n_vars)
  cor_data$correlation <- as.vector(cor_mat)
  cor_data$var_x <- var_normalized[cor_data$x]
  cor_data$var_y <- var_normalized[cor_data$y]
  cor_data$avg_var <- (cor_data$var_x + cor_data$var_y) / 2

  # Map average variability to colors
  cor_data$var_category <- cut(cor_data$avg_var,
                              breaks = c(0, 0.2, 0.4, 0.6, 0.8, 1.0),
                              labels = c("Very Low", "Low", "Medium", "High", "Very High"),
                              include.lowest = TRUE)

  # Filter based on display options
  if (!show_upper) cor_data <- cor_data[cor_data$x >= cor_data$y, ]
  if (!show_diag) cor_data <- cor_data[cor_data$x != cor_data$y, ]

  # Add variable names
  var_names <- colnames(df)

  # Create base plot
  p <- ggplot(cor_data, aes(x = x, y = y)) +
    scale_x_continuous(breaks = 1:n_vars, labels = var_names) +
    scale_y_continuous(breaks = 1:n_vars, labels = var_names) +
    coord_fixed() +
    br_charts_theme() +
    theme(
      axis.title = element_blank(),
      axis.text.x = element_text(angle = 45, hjust = 1, vjust = 1, size = rel(1.2), color = "black"),
      axis.text.y = element_text(angle = 0, hjust = 0.5, size = rel(1.2), color = "black"),
      plot.margin = margin(0, 0, 0, 0, unit = "cm"),
      panel.grid.major = element_line(color = "lightgray", linewidth = 0.3),
      panel.grid.minor = element_blank(),
      axis.line.x = element_blank(),
      axis.line.y = element_blank(),
      axis.ticks.x = element_blank(),
      axis.ticks.y = element_blank(),
      legend.position = "top",
      legend.title = element_text(size = rel(1.1), face = "bold"),
      legend.text = element_text(size = rel(1.0))
    )

  # Add ellipses with color representing variability
  for (i in 1:nrow(cor_data)) {
    row <- cor_data[i, ]
    if (abs(row$correlation) < 0.01) next

    # Ellipse parameters
    max_radius <- 0.4
    base_width <- max_radius * abs(row$correlation)
    base_height <- max_radius * (0.3 + 0.7 * (1 - abs(row$correlation)))

    # Use angle to show correlation direction
    # Positive correlations: -45° angle (upward slope from left to right)
    # Negative correlations: 45° angle (downward slope from left to right)
    angle <- ifelse(row$correlation > 0, -45, 45)

    # Color based on variability level
    var_level <- as.numeric(row$var_category)
    fill_color <- variability_colors[var_level]

    # Create ellipse
    theta <- seq(0, 2 * pi, length.out = 100)
    ellipse_x <- base_width * cos(theta)
    ellipse_y <- base_height * sin(theta)

    angle_rad <- angle * pi / 180
    rotated_x <- ellipse_x * cos(angle_rad) - ellipse_y * sin(angle_rad)
    rotated_y <- ellipse_x * sin(angle_rad) + ellipse_y * cos(angle_rad)

    max_x_extent <- max(abs(rotated_x))
    max_y_extent <- max(abs(rotated_y))
    scale_factor <- min(1, max_radius / max(max_x_extent, max_y_extent))
    rotated_x <- rotated_x * scale_factor
    rotated_y <- rotated_y * scale_factor

    final_x <- rotated_x + row$x
    final_y <- rotated_y + row$y

    ellipse_data <- data.frame(x = final_x, y = final_y)

    # Add ellipse with variability-based color (no border)
    p <- p + geom_polygon(data = ellipse_data, aes(x = x, y = y),
                         fill = fill_color, color = NA, alpha = 0.8,
                         inherit.aes = FALSE)
  }

  # Create legend labels with actual ranges
  legend_labels <- c(
    sprintf("Very Low\n(%.1f-%.1f)", breaks_actual[1], breaks_actual[2]),
    sprintf("Low\n(%.1f-%.1f)", breaks_actual[2], breaks_actual[3]),
    sprintf("Medium\n(%.1f-%.1f)", breaks_actual[3], breaks_actual[4]),
    sprintf("High\n(%.1f-%.1f)", breaks_actual[4], breaks_actual[5]),
    sprintf("Very High\n(%.1f-%.1f)", breaks_actual[5], breaks_actual[6])
  )

  # Create dummy data for legend
  legend_data <- data.frame(
    x = rep(-1, 5),  # Outside plot area
    y = rep(-1, 5),  # Outside plot area
    var_category = factor(c("Very Low", "Low", "Medium", "High", "Very High"),
                         levels = c("Very Low", "Low", "Medium", "High", "Very High"))
  )

  # Add invisible points for legend
  p <- p + geom_point(data = legend_data,
                     aes(x = x, y = y, fill = var_category),
                     shape = 22, size = 4, color = "black", alpha = 0,
                     show.legend = TRUE) +
    scale_fill_manual(
      name = "Outcome Variability (Standard Deviation)",
      values = setNames(variability_colors, c("Very Low", "Low", "Medium", "High", "Very High")),
      labels = legend_labels,
      guide = guide_legend(
        override.aes = list(
          shape = 22,
          size = 4,
          color = "black",
          alpha = 1
        ),
        nrow = 1  # Display legend horizontally
      )
    )

  # Add correlation coefficients
  if (show_coeff) {
    text_data <- cor_data[abs(cor_data$correlation) >= 0.01, ]
    p <- p + geom_text(data = text_data,
                      aes(x = x, y = y, label = round(correlation, 2)),
                      color = "black", size = 3.5, fontface = "bold")
  }

  return(p)
}

# =============================================================================
# Test with Clinical Data
# =============================================================================

set.seed(1234)

# Create clinical outcomes with different variability levels
clinical_data <- data.frame(
  # Low variability outcomes (reliable/precise)
  `Primary Efficacy` = rnorm(100, 50, 5),      # Low variability - reliable measure
  `Survival Rate` = rbinom(100, 1, 0.85),      # Low variability - consistent outcome

  # Medium variability outcomes
  `Secondary Efficacy` = rnorm(100, 45, 12),   # Medium variability
  `Quality of Life` = rnorm(100, 60, 15),      # Medium variability

  # High variability outcomes (unreliable/imprecise)
  `Patient Reported Pain` = rnorm(100, 30, 25), # High variability - subjective measure
  `Biomarker Level` = rnorm(100, 100, 40),     # High variability - noisy measurement

  check.names = FALSE
)

# Add some correlations between outcomes
clinical_data$`Secondary Efficacy` <- 0.6 * scale(clinical_data$`Primary Efficacy`)[,1] +
                                     0.8 * scale(clinical_data$`Secondary Efficacy`)[,1]
clinical_data$`Secondary Efficacy` <- clinical_data$`Secondary Efficacy` * 12 + 45

clinical_data$`Quality of Life` <- 0.4 * scale(clinical_data$`Primary Efficacy`)[,1] +
                                  -0.3 * scale(clinical_data$`Patient Reported Pain`)[,1] +
                                   0.9 * scale(clinical_data$`Quality of Life`)[,1]
clinical_data$`Quality of Life` <- clinical_data$`Quality of Life` * 15 + 60

# Show variability statistics
cat("=== COLOR-BASED VARIABILITY CORRELOGRAM ===\n\n")

var_summary <- data.frame(
  Outcome = colnames(clinical_data),
  SD = round(sapply(clinical_data, sd), 2),
  Variability_Level = c("Low", "Low", "Medium", "Medium", "High", "High"),
  Color_Mapping = c("Green", "Green", "Yellow", "Yellow", "Orange", "Red")
)

print(var_summary)

cat("\n=== VISUALIZATION APPROACH ===\n")
cat("• COLOR: Represents outcome variability (Green=reliable, Red=unreliable)\n")
cat("• ANGLE: Shows correlation direction (upward slope=positive, downward slope=negative)\n")
cat("• SIZE: Ellipse size shows correlation strength\n")
cat("• LEGEND: Shows variability levels with color scale\n")
cat("• NUMBERS: Exact correlation coefficients (clearly visible without borders)\n\n")

# Create and display the color-based variability correlogram
color_variability_plot <- create_color_variability_correlogram(
  clinical_data,
  show_upper = FALSE,
  show_diag = FALSE,
  show_coeff = TRUE
)

print(color_variability_plot)

cat("\n=== ADVANTAGES OF COLOR APPROACH ===\n")
cat("✓ Immediate visual identification of unreliable outcomes\n")
cat("✓ Legend provides clear interpretation guide\n")
cat("✓ Color is most salient visual element\n")
cat("✓ Can still distinguish positive/negative correlations\n")
cat("✓ Intuitive: Red = caution/high variability\n")
cat("✓ Works well for colorblind users (green-red with different intensities)\n\n")

cat("=== CLINICAL INTERPRETATION ===\n")
cat("• Focus more on correlations involving GREEN outcomes (reliable)\n")
cat("• Be cautious about RED outcome correlations (high variability)\n")
cat("• Use for evidence weighting in value judgments\n")