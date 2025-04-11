# Load necessary libraries
library(ggplot2)
library(dplyr)
library(patchwork) # For combining plots side by side
library(cowplot)   # For legend extraction
library(rlang)     # For tidy evaluation with sym()

# Uncomment and adjust the next line if reading data from CSV
# effects_table <- read.csv("effects_table.csv", stringsAsFactors = FALSE)

# Function to create dot plots and forest plots split by Factor and Type with free x-axis scales
create_forest_dot_plot <- function(data) {
  # Define the outcomes of interest
  outcomes_of_interest <- c(
    "Primary Efficacy",
    "Secondary Efficacy",
    "HR Quality of Life",
    "Reoccurring AE",
    "Rare SAE"
  ) # Update names as per your dataset

  # Filter and arrange the data for the specified outcomes and treatments
  filtered_data <- data %>%
    filter(
      Outcome %in% outcomes_of_interest,
      Trt1 == "Drug A",  # Only include Drug A
      Trt2 == "Placebo",
      Filter == "None"
    ) %>%
    arrange(match(Outcome, outcomes_of_interest)) # Ensure order matches the specified outcomes

  # Split the data by Factor and Type and initialize an empty list for plots
  factors <- unique(filtered_data$Factor)
  plots <- list()

  for (factor in factors) {
    factor_data <- filtered_data %>% filter(Factor == factor)
    types <- unique(factor_data$Type)

    for (type in types) {
      type_data <- factor_data %>% filter(Type == type)

      # Determine which columns to use based on the Type
      if (type == "Binary") {
        estimate1 <- "Prop1"
        estimate2 <- "Prop2"
      } else if (type == "Continuous") {
        estimate1 <- "Mean1"
        estimate2 <- "Mean2"
      } else {
        next # Skip unknown types
      }

      # Create the dot plot showing values for both treatments
      dot_plot <- ggplot(type_data) +
        geom_point(aes(
          y = Outcome,
          x = !!sym(estimate1),
          color = Trt1
        ), size = 3) +  # Drug A
        geom_point(aes(
          y = Outcome,
          x = !!sym(estimate2),
          color = Trt2
        ), size = 3) +  # Placebo
        labs(
          title = paste("Dot Plot for", type, factor, "Outcomes"),
          x = "Effect Estimate"
        ) +
        theme_minimal() +
        theme(
          legend.position = "none",         # Remove legend from individual plots
          axis.title.y = element_blank()      # Remove y-axis label
        )

      # Create the forest plot showing the treatment difference and CI error bars (if available)
      forest_plot <- ggplot(type_data) +
        geom_point(aes(
          y = Outcome,
          x = !!sym(estimate1) - !!sym(estimate2),
          color = Trt1
        ), size = 3) +
        geom_errorbarh(
          data = type_data %>% filter(!is.na(Diff_LowerCI) & !is.na(Diff_UpperCI)),
          aes(
            y = Outcome,
            xmin = Diff_LowerCI,
            xmax = Diff_UpperCI
          ),
          height = 0.2
        ) +
        labs(
          title = paste("Forest Plot for", type, factor, "Outcomes"),
          x = "Treatment Difference"
        ) +
        theme_minimal() +
        theme(
          axis.title.y = element_blank(),   # Remove y-axis label
          legend.position = "none"            # Remove legend
        )

      # Combine the dot plot and forest plot for this Type and Factor
      combined_plot <- wrap_plots(dot_plot, forest_plot, ncol = 2) &
        theme(plot.margin = unit(c(1, 1, 1, 1), "cm"))

      # Store the combined plot in the list
      plots[[paste(factor, type, sep = "_")]] <- combined_plot
    }
  }

  # Create a dummy dataset for the legend
  legend_data <- data.frame(
    x = c(1, 1),
    y = c(1, 1),
    Treatment = c("Drug A", "Placebo")
  )

  # Create a standalone legend plot with an explicit guide so only one component is generated
  legend_plot <- ggplot(legend_data, aes(x = x, y = y, color = Treatment)) +
    geom_point() +
    scale_color_manual(values = c("Drug A" = "red", "Placebo" = "blue")) +
    theme_void() +
    theme(
      legend.position = "bottom",
      legend.box.just = "center",
      legend.title = element_text(size = 10),
      legend.text = element_text(size = 9)
    ) +
    guides(color = guide_legend(nrow = 1))  # Force a single row for the legend

  # Extract the legend grob and wrap it with patchwork so it's recognized as a single panel
  legend <- cowplot::get_legend(legend_plot)
  legend_wrapped <- wrap_elements(legend)

  # Combine all plots for all Factors and Types into one final patchwork plot
  final_plot <- wrap_plots(plots, ncol = 1)

  # Add the legend panel at the bottom with adjusted relative heights
  result <- final_plot / legend_wrapped +
    plot_layout(heights = c(20, 1))

  return(result)
}

# Example usage:
# Assuming effects_table is loaded, generate and display the plot:
# plot <- create_forest_dot_plot(effects_table)
# print(plot)
