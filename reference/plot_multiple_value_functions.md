# Compare Multiple Value Functions

Creates a multi-panel plot comparing value functions for multiple
criteria from MCDA clinical scales. This function takes the
clinical_scales list structure used in MCDA functions and creates
visualizations for all criteria.

## Usage

``` r
plot_multiple_value_functions(
  clinical_scales = NULL,
  criteria = NULL,
  ncol = 2,
  show_titles = TRUE,
  show_reference_lines = TRUE,
  base_font_size = 9
)
```

## Arguments

- clinical_scales:

  List defining clinical reference levels for each criterion. Each
  element should be a list with: min (lower threshold), max (upper
  threshold), and direction ("increasing" for higher is better,
  "decreasing" for lower is better). Required.

- criteria:

  Character vector of criterion names to plot. If NULL, plots all
  criteria in clinical_scales. Default is NULL.

- ncol:

  Integer specifying number of columns in the grid layout. Default is 2.

- show_titles:

  Logical indicating whether to show individual plot titles. Default is
  TRUE.

- show_reference_lines:

  Logical indicating whether to show horizontal reference lines at value
  = 50. Default is TRUE.

- base_font_size:

  Numeric; base font size in points for all text elements in the plot
  (default: 9).

## Value

A combined plot (using patchwork) showing all value functions in a grid
layout.

## Examples

``` r
# Define clinical scales
clinical_scales <- list(
  `Benefit 1` = list(min = 0, max = 1, direction = "increasing"),
  `Benefit 2` = list(min = 0, max = 100, direction = "decreasing"),
  `Risk 1` = list(min = 0, max = 0.5, direction = "decreasing"),
  `Risk 2` = list(min = 0, max = 0.3, direction = "decreasing")
)

# Plot all criteria
all_plots <- plot_multiple_value_functions(
  clinical_scales = clinical_scales
)

# Plot specific criteria only
if (FALSE) { # \dontrun{
selected_plots <- plot_multiple_value_functions(
  clinical_scales = clinical_scales,
  criteria = c("Benefit 1", "Risk 1"),
  ncol = 2
)
} # }
```
