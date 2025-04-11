# Load necessary libraries
library(ggplot2)
library(dplyr)
library(patchwork) # For combining plots side by side

# Function to create dot plots and forest plots split by Factor and Type with free x-axis scales
create_forest_dot_plot <- function(data) {
  # Define the outcomes of interest
  outcomes_of_interest <- c(
    "A (Primary Clinical Assessment)",
    "B (A Secondary Clinical Assessment)",
    "C (Quality of Life)",
    "D (Convenience)",
    "K (A Rare SAE)"
  ) # Update names as per your dataset

  # Filter and arrange the data for the specified outcomes and treatments
  filtered_data <- data %>%
    filter(
      Outcome %in% outcomes_of_interest,
      Trt1 == "Drug 1",
      Trt2 == "Placebo",
      Filter == "None"
    ) %>%
    arrange(match(Outcome, outcomes_of_interest)) # Ensure the order matches the specified outcomes

  # Split the data by Factor and Type
  factors <- unique(filtered_data$Factor)
  plots <- list()

  for (factor in factors) {
    factor_data <- filtered_data %>% filter(Factor == factor)
    types <- unique(factor_data$Type)

    for (type in types) {
      type_data <- factor_data %>% filter(Type == type)

      # Determine the columns to use based on the Type
      if (type == "Binary") {
        estimate1 <- "Prop1"
        estimate2 <- "Prop2"
      } else if (type == "Continuous") {
        estimate1 <- "Mean1"
        estimate2 <- "Mean2"
      } else {
        next # Skip unknown types
      }

      # Create the dot plot (showing both Placebo and Drug 1)
      dot_plot <- ggplot(type_data) +
        geom_point(aes_string(y = "Outcome", x = estimate1, color = "Trt1"), size = 3) + # Drug 1
        geom_point(aes_string(y = "Outcome", x = estimate2, color = "Trt2"), size = 3) + # Placebo
        labs(
          title = paste("Dot Plot for", type, factor, "Outcomes"),
          x = "Effect Estimate",
          y = "Outcome",
          color = "Treatment"
        ) +
        theme_minimal()

      # Create the forest plot (showing treatment difference)
      forest_plot <- ggplot(type_data, aes_string(y = "Outcome", x = paste0("(", estimate1, " - ", estimate2, ")"), color = "Trt1")) +
        geom_point(size = 3) + # Dot for the treatment difference
        geom_errorbarh(aes(xmin = Diff_LowerCI, xmax = Diff_UpperCI), height = 0.2) + # Horizontal error bars
        labs(
          title = paste("Forest Plot for", type, factor, "Outcomes"),
          x = "Treatment Difference",
          y = "Outcome"
        ) +
        theme_minimal()

      # Combine the dot plot and forest plot for this Type and Factor
      combined_plot <- patchwork::wrap_plots(dot_plot, forest_plot, ncol = 2) &
        theme(plot.margin = unit(c(1, 1, 1, 1), "cm")) # Add consistent margins

      # Add to the list of plots
      plots[[paste(factor, type, sep = "_")]] <- combined_plot
    }
  }

  # Combine all plots for all Factors and Types
  final_plot <- patchwork::wrap_plots(plots, ncol = 1)

  return(final_plot)
}

# Example usage
plot <- create_forest_dot_plot(brdata)
print(plot)
