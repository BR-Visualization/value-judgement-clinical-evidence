# =============================================================================
# Color-Based Variability Correlogram with Violin Plots on Diagonals
# =============================================================================
# Color represents variability level, violin plots show distribution on diagonals

library(brpubVJCE)
library(ggplot2)
library(dplyr)
library(RColorBrewer)
library(patchwork)

# =============================================================================
# Enhanced Correlogram with Violin Plots
# =============================================================================

create_color_variability_correlogram_with_violin <- function(
  df,
  show_upper = FALSE,
  show_coeff = TRUE,
  fill_color = "white"
) {
  # Use white background for all elements
  if (is.null(fill_color)) {
    fill_color <- "white"
  }

  # Calculate correlation matrix
  cor_mat <- cor(df, use = "complete.obs")
  n_vars <- ncol(cor_mat)

  # Create plotting data for off-diagonal elements
  cor_data <- expand.grid(x = 1:n_vars, y = 1:n_vars)
  cor_data$correlation <- as.vector(cor_mat)

  # Filter for off-diagonal elements only
  if (!show_upper) {
    cor_data <- cor_data[cor_data$x >= cor_data$y, ]
  }
  cor_data <- cor_data[cor_data$x != cor_data$y, ] # Remove diagonal

  # Add variable names with text wrapping for overflow
  wrap_text <- function(text, width = 12) {
    sapply(
      text,
      function(x) {
        if (nchar(x) <= width) {
          return(x)
        } else {
          # Split long text into multiple lines
          words <- strsplit(x, "\\s+")[[1]]
          if (length(words) == 1) {
            # Single long word - break it
            return(paste(
              substr(x, 1, width),
              substr(x, width + 1, nchar(x)),
              sep = "\n"
            ))
          } else {
            # Multiple words - wrap intelligently
            lines <- character(0)
            current_line <- ""
            for (word in words) {
              if (nchar(paste(current_line, word)) <= width) {
                current_line <- if (current_line == "") {
                  word
                } else {
                  paste(current_line, word)
                }
              } else {
                lines <- c(lines, current_line)
                current_line <- word
              }
            }
            if (current_line != "") {
              lines <- c(lines, current_line)
            }
            return(paste(lines, collapse = "\n"))
          }
        }
      },
      USE.NAMES = FALSE
    )
  }

  var_names <- wrap_text(colnames(df))

  # Define benefit/risk classification and colors
  benefit_outcomes <- c("Primary Efficacy", "Secondary Efficacy", "Survival Rate", "Quality of Life")
  risk_outcomes <- c("Patient Reported Pain", "Biomarker Level")

  # Create color vectors for axis labels
  label_colors <- sapply(colnames(df), function(name) {
    if (name %in% benefit_outcomes) return("#1E90FF")  # Blue for benefits
    if (name %in% risk_outcomes) return("#DC143C")     # Red for risks
    return("black")  # Default black
  })

  # Create base plot with colored labels using scale_*_discrete
  p <- ggplot(cor_data, aes(x = x, y = y)) +
    scale_x_continuous(
      breaks = 1:n_vars,
      labels = var_names,
      expand = c(0, 0.5)
    ) +
    scale_y_continuous(
      breaks = 1:n_vars,
      labels = var_names,
      expand = c(0, 0.5)
    ) +
    coord_fixed(clip = "off") +
    br_charts_theme() +
    theme(
      axis.title.x = element_blank(),
      axis.title.y = element_blank(),
      axis.text.x = element_text(
        angle = 0,
        hjust = 0,
        vjust = 1,
        size = rel(0.8),
        color = label_colors,
        margin = margin(t = 2, b = 5)
      ),
      axis.text.y = element_text(
        hjust = 0,
        size = rel(0.8),
        color = label_colors
      ),
      plot.margin = margin(15, 0, 0, 0, unit = "pt"),
      panel.spacing = unit(0, "pt"),
      panel.grid.major = element_line(color = "lightgray", linewidth = 0.3),
      panel.grid.minor = element_blank(),
      axis.line.x = element_blank(),
      axis.line.y = element_blank(),
      axis.ticks.x = element_blank(),
      axis.ticks.y = element_blank(),
      legend.position = "none"
    )

  # Add violin plots on the diagonal
  for (i in 1:n_vars) {
    # Get data for this variable
    var_data <- df[, i]
    var_data <- var_data[!is.na(var_data)]

    # Skip violin for binary variables or variables with very low variability
    if (length(unique(var_data)) <= 2) {
      # For binary variables, create a proper bar chart
      value_counts <- table(var_data)
      unique_vals <- as.numeric(names(value_counts))
      proportions <- as.numeric(value_counts) / length(var_data)

      # Create bar chart data
      bar_width <- 0.3
      bar_spacing <- 0.1
      n_bars <- length(unique_vals)

      # Calculate bar positions
      if (n_bars == 2) {
        bar_x_positions <- c(i - bar_spacing/2 - bar_width/2, i + bar_spacing/2 + bar_width/2)
      } else {
        bar_x_positions <- i
      }

      # Create bars for each unique value
      for (j in 1:n_bars) {
        val <- unique_vals[j]
        prop <- proportions[j]
        bar_height <- prop * 0.6  # Scale to fit within cell

        # Bar coordinates
        bar_data <- data.frame(
          x = c(bar_x_positions[j] - bar_width/2,
                bar_x_positions[j] + bar_width/2,
                bar_x_positions[j] + bar_width/2,
                bar_x_positions[j] - bar_width/2),
          y = c(i - 0.3, i - 0.3, i - 0.3 + bar_height, i - 0.3 + bar_height)
        )

        # Add bar
        p <- p +
          geom_polygon(
            data = bar_data,
            aes(x = x, y = y),
            fill = fill_color,
            color = "black",
            linewidth = 0.3,
            inherit.aes = FALSE
          )

        # Add value label at bottom of bar
        p <- p +
          annotate(
            "text",
            x = bar_x_positions[j],
            y = i - 0.32,
            label = val,
            size = 2,
            hjust = 0.5,
            vjust = 1,
            fontface = "bold"
          )
      }

      next
    }

    # Calculate density for continuous variables (for violin plot)
    density_obj <- density(var_data, n = 100)

    # Normalize density values to fit within cell bounds (create violin shape)
    max_density <- max(density_obj$y)
    normalized_density <- density_obj$y / max_density * 0.3 # Scale to 30% of cell width on each side

    # Create violin plot (symmetric density on both sides)
    # y-coordinates: original data values (scaled to fit cell)
    min_y <- min(density_obj$x)
    max_y <- max(density_obj$x)
    range_y <- max_y - min_y
    if (range_y > 0) {
      scaled_y <- i + (density_obj$x - min_y) / range_y * 0.6 - 0.3
    } else {
      scaled_y <- rep(i, length(density_obj$x))
    }

    # x-coordinates: density values on both sides (symmetric violin)
    left_x <- i - normalized_density  # Left side of violin
    right_x <- i + normalized_density # Right side of violin

    # Create violin polygon data (symmetric shape)
    violin_data <- data.frame(
      x = c(left_x, rev(right_x)),  # Left side, then right side reversed
      y = c(scaled_y, rev(scaled_y))  # Data values
    )

    # Add violin plot with neutral color
    p <- p +
      geom_polygon(
        data = violin_data,
        aes(x = x, y = y),
        fill = fill_color,
        color = "black",
        alpha = 0.7,
        linewidth = 0.3,
        inherit.aes = FALSE
      )

    # Add median line for better interpretation
    median_val <- median(var_data)
    if (range_y > 0) {
      median_y <- i + (median_val - min_y) / range_y * 0.6 - 0.3
    } else {
      median_y <- i
    }

    # Add median line
    p <- p +
      annotate(
        "segment",
        x = i - 0.25, xend = i + 0.25,
        y = median_y, yend = median_y,
        color = "white",
        linewidth = 1
      )
  }

  # Add ellipses for off-diagonal correlations with color representing variability
  for (i in 1:nrow(cor_data)) {
    row <- cor_data[i, ]
    if (abs(row$correlation) < 0.01) {
      next
    }

    # Ellipse parameters
    max_radius <- 0.4
    base_width <- max_radius * abs(row$correlation)
    base_height <- max_radius * (0.3 + 0.7 * (1 - abs(row$correlation)))

    # Use angle to show correlation direction
    angle <- ifelse(row$correlation > 0, -45, 45)

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

    # Add ellipse with neutral color and black border
    p <- p +
      geom_polygon(
        data = ellipse_data,
        aes(x = x, y = y),
        fill = fill_color,
        color = "black",
        alpha = 0.7,
        linewidth = 0.3,
        inherit.aes = FALSE
      )
  }


  # Add correlation coefficients for off-diagonal elements
  if (show_coeff) {
    text_data <- cor_data[abs(cor_data$correlation) >= 0.01, ]
    p <- p +
      geom_text(
        data = text_data,
        aes(x = x, y = y, label = round(correlation, 2)),
        color = "black",
        size = 2,
        fontface = "bold"
      )
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
  `Primary Efficacy` = rnorm(100, 50, 5), # Low variability - reliable measure
  `Survival Rate` = rbinom(100, 1, 0.85), # Low variability - consistent outcome

  # Medium variability outcomes
  `Secondary Efficacy` = rnorm(100, 45, 12), # Medium variability
  `Quality of Life` = rnorm(100, 60, 15), # Medium variability

  # High variability outcomes (unreliable/imprecise)
  `Patient Reported Pain` = rnorm(100, 30, 25), # High variability - subjective measure
  `Biomarker Level` = rnorm(100, 100, 40), # High variability - noisy measurement

  check.names = FALSE
)

# Add some correlations between outcomes
clinical_data$`Secondary Efficacy` <- 0.6 *
  scale(clinical_data$`Primary Efficacy`)[, 1] +
  0.8 * scale(clinical_data$`Secondary Efficacy`)[, 1]
clinical_data$`Secondary Efficacy` <- clinical_data$`Secondary Efficacy` *
  12 +
  45

clinical_data$`Quality of Life` <- 0.4 *
  scale(clinical_data$`Primary Efficacy`)[, 1] +
  -0.3 * scale(clinical_data$`Patient Reported Pain`)[, 1] +
  0.9 * scale(clinical_data$`Quality of Life`)[, 1]
clinical_data$`Quality of Life` <- clinical_data$`Quality of Life` * 15 + 60

# Show basic statistics
cat("=== CORRELOGRAM WITH VIOLIN PLOTS ===\n\n")

var_summary <- data.frame(
  Outcome = colnames(clinical_data),
  SD = round(sapply(clinical_data, sd), 2)
)

print(var_summary)

cat("\n=== VISUALIZATION APPROACH ===\n")
cat("• DIAGONALS: Violin plots for continuous variables, bar charts for binary variables\n")
cat("• ELLIPSES: White background with black borders\n")
cat("• LABELS: Blue for benefit outcomes, red for risk outcomes\n")
cat(
  "• ANGLE: Shows correlation direction (upward slope=positive, downward slope=negative)\n"
)
cat("• SIZE: Ellipse size shows correlation strength\n")
cat("• NUMBERS: Exact correlation coefficients\n\n")

# Create and display the enhanced correlogram
violin_correlogram_plot <- create_color_variability_correlogram_with_violin(
  clinical_data,
  show_upper = FALSE,
  show_coeff = TRUE
)

print(violin_correlogram_plot)

ggsave_custom(
  "violin_correlogram_plot.png",
  imgpath = "./",
  inplot = violin_correlogram_plot,
  dpi = 300
)

cat("\n=== ADVANTAGES OF VIOLIN DIAGONAL APPROACH ===\n")
cat(
  "✓ Shows distribution shape of each outcome (normal, skewed, bimodal, etc.)\n"
)
cat("✓ Reveals outliers and data quality issues\n")
cat("✓ Symmetric violin shape provides intuitive distribution view\n")
cat("✓ White median lines show central tendency clearly\n")
cat("✓ Clean, white background appearance without color distractions\n")
cat("✓ Proper bar charts for binary/categorical variables\n")
cat("✓ More informative than just showing variable names on diagonal\n")
cat(
  "✓ Helps identify transformation needs (e.g., log transform for skewed data)\n\n"
)

cat("=== CLINICAL INTERPRETATION ===\n")
cat("• Examine violin shapes for data quality assessment\n")
cat("• All correlations displayed with equal visual weight\n")
cat("• Consider transformations for highly skewed distributions\n")
cat("• Use violin information to identify potential outliers\n")
cat("• White median lines help assess central tendency vs. mean\n")
