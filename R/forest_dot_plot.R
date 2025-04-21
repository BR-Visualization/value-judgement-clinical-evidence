#' Create Forest and Dot Plots for Treatment Effects
#'
#' @description
#' Creates a visualization combining dot plots and forest plots to display treatment effects
#' across multiple outcomes. The function presents treatment values (dot plots) alongside
#' treatment differences with confidence intervals (forest plots), and includes clinically
#' meaningful difference thresholds.
#'
#' @param data A data frame containing treatment effect data with the following required columns:
#'   \itemize{
#'     \item Outcome: Character, name of the outcome measure
#'     \item Factor: Character, category or domain of the outcome
#'     \item Type: Character, type of outcome ("Binary" or "Continuous")
#'     \item Trt1: Character, name of the first treatment (e.g., "Drug A")
#'     \item Trt2: Character, name of the second treatment (e.g., "Placebo")
#'     \item Filter: Character, indicates data filtering status (use "None" for unfiltered data)
#'     \item Mean1, Mean2: Numeric, mean values for continuous outcomes
#'     \item Sd1, Sd2: Numeric, standard deviations for continuous outcomes
#'     \item N1, N2: Numeric, sample sizes for each treatment group
#'     \item Prop1, Prop2: Numeric, proportions for binary outcomes
#'   }
#' @param clin_thresholds A data frame with columns 'Outcome' and 'Threshold' defining
#'   clinically meaningful difference thresholds for each outcome
#' @param outcomes_of_interest Character vector of outcome names to include in the plots
#' @param treatment1 Character, name of the first treatment (default: "Drug A")
#' @param treatment2 Character, name of the second treatment (default: "Placebo")
#' @param filter_value Character, value for the Filter column to include (default: "None")
#' @param precalculated_stats Logical, whether the input data already contains calculated statistics
#'   (Diff, Diff_LowerCI, Diff_UpperCI) (default: FALSE)
#'
#' @return A patchwork plot object combining dot plots and forest plots with a shared legend
#'
#' @details
#' The function performs the following steps:
#' 1. Filters data for specified outcomes and treatments
#' 2. Calculates treatment differences and confidence intervals (if not already provided)
#' 3. Creates dot plots showing individual treatment values
#' 4. Creates forest plots showing treatment differences with confidence intervals
#' 5. Adds clinically meaningful difference thresholds as black diamonds
#' 6. Combines plots with a shared legend
#'
#' @import ggplot2
#' @import dplyr
#' @import patchwork
#' @import rlang
#'
#' @examples
#' \dontrun{
#' # Create sample data
#' effects_table <- data.frame(
#'   Outcome = rep(c("Primary Efficacy", "Secondary Efficacy"), each = 2),
#'   Factor = rep("Efficacy", 4),
#'   Type = rep(c("Binary", "Continuous"), 2),
#'   Trt1 = rep("Drug A", 4),
#'   Trt2 = rep("Placebo", 4),
#'   Filter = rep("None", 4),
#'   Mean1 = c(NA, 12.3, NA, 8.7),
#'   Mean2 = c(NA, 7.8, NA, 6.2),
#'   Sd1 = c(NA, 3.2, NA, 2.1),
#'   Sd2 = c(NA, 2.9, NA, 1.8),
#'   N1 = rep(150, 4),
#'   N2 = rep(150, 4),
#'   Prop1 = c(0.75, NA, 0.62, NA),
#'   Prop2 = c(0.55, NA, 0.48, NA),
#'   stringsAsFactors = FALSE
#' )
#'
#' # Define clinical thresholds
#' thresholds <- data.frame(
#'   Outcome = c("Primary Efficacy", "Secondary Efficacy", "HR Quality of Life", "Reoccurring AE", "Rare SAE"),
#'   Threshold = c(0.10, 0.08, 5, -0.10, -0.05),
#'   stringsAsFactors = FALSE
#' )
#'
#' # Using data with statistics to be calculated
#' plot1 <- create_forest_dot_plot(effects_table, thresholds)
#' print(plot1)
#'
#' # Example with precalculated statistics
#' # (assuming the data has Diff, Diff_LowerCI, and Diff_UpperCI columns)
#' precalculated_data <- prepare_forest_dot_data(effects_table)
#' plot2 <- create_forest_dot_plot(precalculated_data, thresholds, precalculated_stats = TRUE)
#' print(plot2)
#' }
#'
#' @export
create_forest_dot_plot <- function(data, 
  clin_thresholds = NULL,
  outcomes_of_interest = c("Primary Efficacy", "Secondary Efficacy", 
                          "HR Quality of Life", "Reoccurring AE", "Rare SAE"),
  treatment1 = "Drug A", 
  treatment2 = "Placebo",
  filter_value = "None",
  precalculated_stats = FALSE) {

# Required libraries
requireNamespace("ggplot2")
requireNamespace("dplyr")
requireNamespace("patchwork")
requireNamespace("rlang")

# Create default clinical thresholds if not provided
if (is.null(clin_thresholds)) {
clin_thresholds <- data.frame(
Outcome = c("Primary Efficacy", "Secondary Efficacy", "HR Quality of Life", "Reoccurring AE", "Rare SAE"),
Threshold = c(0.10, 0.08, 5, -0.10, -0.05),
stringsAsFactors = FALSE
)
}

# Prepare the data using the separate function
filtered_data <- prepare_forest_dot_data(
data, 
outcomes_of_interest, 
treatment1, 
treatment2, 
filter_value,
precalculated_stats
)

# Identify unique Factors and prepare an empty list for plots.
factors <- unique(filtered_data$Factor)
plots <- list()

# Create the shared color and shape scales that will be used across all plots
color_scale <- scale_color_manual(
name = "",
values = c(treatment1 = "red", treatment2 = "blue", "Clinical Meaningful Difference" = "black")
)

shape_scale <- scale_shape_manual(
name = "",
values = c(treatment1 = 16, treatment2 = 16, "Clinical Meaningful Difference" = 18)
)

for (factor in factors) {
factor_data <- filtered_data %>% filter(Factor == factor)
types <- unique(factor_data$Type)

for (type in types) {
type_data <- factor_data %>% filter(Type == type)

# Determine which columns to use based on outcome type:
# For Binary outcomes, use the proportion columns; for Continuous outcomes, use the mean columns.
if (type == "Binary") {
estimate1 <- "Prop1"
estimate2 <- "Prop2"
} else if (type == "Continuous") {
estimate1 <- "Mean1"
estimate2 <- "Mean2"
} else {
next  # Skip unknown types
}

# Prepare data for dot plot in long format (without dummy data)
dot_data <- rbind(
data.frame(
Outcome = type_data$Outcome,
x = type_data[[estimate1]],
Treatment = rep(treatment1, nrow(type_data)),
stringsAsFactors = FALSE
),
data.frame(
Outcome = type_data$Outcome,
x = type_data[[estimate2]],
Treatment = rep(treatment2, nrow(type_data)),
stringsAsFactors = FALSE
)
)

## Dot Plot Setup without dummy point
  dot_plot <- ggplot(dot_data) +
    geom_point(aes(y = Outcome, x = x, color = Treatment, shape = Treatment), size = 3) +
    scale_color_manual(
      name = "",
      values = c("Drug A" = "red", "Placebo" = "blue", "Clinical Meaningful Difference" = "black")
    ) +
    scale_shape_manual(
      name = "",
      values = c("Drug A" = 16, "Placebo" = 16, "Clinical Meaningful Difference" = 18)
    ) +
    labs() + # No axis titles or plot titles.
    theme_minimal() +
    theme(
      axis.title.y = element_blank(),
      axis.title.x = element_blank(),
      legend.position = "bottom"
    )
## Forest Plot Setup with Clinical Meaningful Difference showing in plot and legend ##
# Add the clinical thresholds data with Treatment column for legend
thresholds_with_treatment <- clin_thresholds %>% 
filter(Outcome %in% type_data$Outcome) %>%
mutate(Treatment = "Clinical Meaningful Difference")

forest_plot <- ggplot() +
# Add the treatment difference points and error bars
geom_point(data = type_data, 
aes(y = Outcome, x = Diff), 
color = "red", size = 3) +
geom_errorbarh(data = type_data,
aes(y = Outcome, xmin = Diff_LowerCI, xmax = Diff_UpperCI),
color = "red", height = 0.2) +
# Add clinical meaningful difference markers with aesthetics for legend
geom_point(data = thresholds_with_treatment,
aes(x = Threshold, y = Outcome, color = Treatment, shape = Treatment),
size = 4) +
color_scale +
shape_scale +
labs() +  # No axis titles or plot titles.
theme_minimal() +
theme(
axis.title.y = element_blank(),
axis.title.x = element_blank(),
axis.text.y = element_blank(),   # Remove y-axis text so labels come only from dot plot.
axis.ticks.y = element_blank(),
legend.position = "bottom"       # Include legend in forest plot
)

# Combine the dot and forest plots side-by-side with aligned y-axes.
combined_plot <- wrap_plots(dot_plot, forest_plot, ncol = 2, widths = c(1, 1)) &
theme(plot.margin = unit(c(1, 1, 1, 1), "cm"))

plots[[paste(factor, type, sep = "_")]] <- combined_plot
}
}

# Combine all the factor/type plots vertically and collect only the legend from both plots.
final_plot <- wrap_plots(plots, ncol = 1) +
plot_layout(guides = "collect") &
theme(legend.position = "bottom")

return(final_plot)
}