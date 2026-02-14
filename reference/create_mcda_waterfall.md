# Create MCDA Waterfall Chart

Creates a waterfall chart showing cumulative contribution of each
criterion to the total weighted benefit-risk score. Each bar segment
represents one criterion's weighted contribution, stacked to show how
they build up to the total score. This function reuses the calculation
logic from
[`create_mcda_walkthrough`](https://pkgdown.r-lib.org/reference/create_mcda_walkthrough.md)
to ensure consistency.

## Usage

``` r
create_mcda_waterfall(
  data = NULL,
  study = NULL,
  comparator_name = "Placebo",
  benefit_criteria = NULL,
  risk_criteria = NULL,
  weights = NULL,
  clinical_scales = NULL,
  fig_colors = NULL,
  show_total = TRUE,
  show_labels = TRUE,
  label_threshold = 0.5
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
  study-specific comparator in a faceted chart). Default is NULL.

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

- fig_colors:

  A named vector of length 2 specifying colors for benefits and risks.
  Default is c("Benefit" = "#0571b0", "Risk" = "#ca0020") to match the
  mcda_barplot colors. If NULL, uses default colors.

- show_total:

  Logical indicating whether to show total score bar. Default is TRUE.

- show_labels:

  Logical indicating whether to show value labels on bars. Default is
  TRUE.

- label_threshold:

  Minimum contribution value to show label. Default is 0.5.

## Value

A ggplot object showing the waterfall chart, or NULL if data is not
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

# Create waterfall chart for a specific study
waterfall_plot <- create_mcda_waterfall(
  data = mcda_data,
  comparator_name = "Placebo",
  study = "Study 1",
  benefit_criteria = c("Benefit 1", "Benefit 2", "Benefit 3"),
  risk_criteria = c("Risk 1", "Risk 2"),
  clinical_scales = clinical_scales
)

# Or analyze all studies together - each active treatment compared to its
# study-specific comparator
waterfall_all <- create_mcda_waterfall(
  data = mcda_data,
  comparator_name = "Placebo",
  benefit_criteria = c("Benefit 1", "Benefit 2", "Benefit 3"),
  risk_criteria = c("Risk 1", "Risk 2"),
  clinical_scales = clinical_scales
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

# Custom colors for benefits and risks
custom_colors <- c("Benefit" = "#4ECDC4", "Risk" = "#FF6B6B")

waterfall_custom <- create_mcda_waterfall(
  data = mcda_data,
  benefit_criteria = c("Benefit 1", "Benefit 2", "Benefit 3"),
  risk_criteria = c("Risk 1", "Risk 2"),
  weights = weights,
  clinical_scales = clinical_scales
)
} # }
```
