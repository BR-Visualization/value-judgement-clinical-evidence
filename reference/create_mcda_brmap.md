# Create MCDA Benefit-Risk Map

Creates a benefit-risk map showing the trade-off between aggregated
benefits and risks for each treatment. Each treatment is plotted as a
point where the x-axis represents the total weighted benefit score
(0-100 scale) and the y-axis represents the transformed risk score
(0-100 scale, calculated as 100 + risk_score). Higher is better on both
axes: high benefit scores indicate more benefits vs comparator, high
risk scores indicate better risk profiles (fewer/less severe adverse
events) vs comparator. For example, a risk score of -10 (slightly worse
than placebo) becomes 90 on the map. Treatments in the upper-right
region offer both high benefits and low risks. This function reuses the
calculation logic from
[`create_mcda_walkthrough`](https://pkgdown.r-lib.org/reference/create_mcda_walkthrough.md)
to ensure consistency.

## Usage

``` r
create_mcda_brmap(
  data = NULL,
  study = NULL,
  comparator_name = "Placebo",
  benefit_criteria = NULL,
  risk_criteria = NULL,
  weights = NULL,
  clinical_scales = NULL,
  show_frontier = TRUE,
  show_labels = TRUE,
  show_title = FALSE,
  show_subtitle = FALSE,
  fig_colors = NULL
)
```

## Arguments

- data:

  A data frame in wide format with Study, Treatment, and criteria
  columns. Required parameter - must be provided. Each row should
  contain raw values for a treatment on their original measurement
  scales. See
  [`mcda_data`](https://pkgdown.r-lib.org/reference/mcda_data.md) for
  example format.

- study:

  Character string specifying which study to analyze. If NULL, analyzes
  all studies (each active treatment will be compared to its
  study-specific comparator). Default is NULL.

- comparator_name:

  Character string specifying the name of the reference treatment (e.g.,
  placebo or active control) in the data. Required. Default is
  "Placebo".

- benefit_criteria:

  Character vector of benefit criterion names (column names in data).

- risk_criteria:

  Character vector of risk criterion names (column names in data).

- weights:

  Named numeric vector of criterion weights. Must sum to 1. If NULL,
  uses equal weights.

- clinical_scales:

  List defining clinical reference levels for each criterion. Each
  element should be a list with: min (lower threshold), max (upper
  threshold), direction ("increasing" for higher is better, "decreasing"
  for lower is better), and optionally allow_extrapolation (default
  TRUE). If NULL, uses data-driven normalization (not recommended per
  FDA/EMA guidance).

- show_frontier:

  Logical indicating whether to show the efficiency frontier region
  (shaded area representing good benefit-risk profiles, bounded by the
  treatments with maximum benefits and maximum risk scores). Default is
  TRUE.

- show_labels:

  Logical indicating whether to show treatment labels on points. Default
  is TRUE.

- show_title:

  Logical indicating whether to show the plot title. Default is FALSE.

- show_subtitle:

  Logical indicating whether to show the plot subtitle. Default is
  FALSE.

- fig_colors:

  A vector specifying colors for each treatment. If NULL, uses default
  color palette.

## Value

A ggplot object showing the benefit-risk map, or NULL if data is not
provided.

## Examples

``` r
# Load example MCDA data
data(mcda_data)

# Define clinical scales
clinical_scales <- list(
  `Benefit 1` = list(min = 0, max = 1, direction = "increasing"),
  `Benefit 2` = list(min = 0, max = 100, direction = "decreasing"),
  `Benefit 3` = list(min = 0, max = 100, direction = "increasing"),
  `Risk 1` = list(min = 0, max = 0.5, direction = "decreasing"),
  `Risk 2` = list(min = 0, max = 0.3, direction = "decreasing")
)

# Create benefit-risk map (no title/subtitle by default)
brmap_plot <- create_mcda_brmap(
  data = mcda_data,
  comparator_name = "Placebo",
  benefit_criteria = c("Benefit 1", "Benefit 2", "Benefit 3"),
  risk_criteria = c("Risk 1", "Risk 2"),
  clinical_scales = clinical_scales
)

# With title and subtitle
brmap_with_titles <- create_mcda_brmap(
  data = mcda_data,
  comparator_name = "Placebo",
  benefit_criteria = c("Benefit 1", "Benefit 2", "Benefit 3"),
  risk_criteria = c("Risk 1", "Risk 2"),
  clinical_scales = clinical_scales,
  show_title = TRUE,
  show_subtitle = TRUE
)

# With custom weights and colors
if (FALSE) { # \dontrun{
weights <- c(
  `Benefit 1` = 0.30,
  `Benefit 2` = 0.20,
  `Benefit 3` = 0.10,
  `Risk 1` = 0.30,
  `Risk 2` = 0.10
)

# Custom colors for treatments
custom_colors <- c(
  "Drug A" = "#FF6B6B",
  "Drug B" = "#4ECDC4",
  "Drug C" = "#45B7D1",
  "Drug D" = "#96CEB4"
)

brmap_custom <- create_mcda_brmap(
  data = mcda_data,
  benefit_criteria = c("Benefit 1", "Benefit 2", "Benefit 3"),
  risk_criteria = c("Risk 1", "Risk 2"),
  weights = weights,
  clinical_scales = clinical_scales,
  fig_colors = custom_colors,
  show_frontier = TRUE
)

# Show only title without subtitle
brmap_title_only <- create_mcda_brmap(
  data = mcda_data,
  comparator_name = "Placebo",
  benefit_criteria = c("Benefit 1", "Benefit 2", "Benefit 3"),
  risk_criteria = c("Risk 1", "Risk 2"),
  clinical_scales = clinical_scales,
  show_title = TRUE,
  show_subtitle = FALSE
)
} # }
```
