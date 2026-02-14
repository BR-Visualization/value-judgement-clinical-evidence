# Create Value Function Visualization

Creates a visualization showing how raw clinical outcome values are
transformed into normalized value scores (0-100 scale) using linear
value functions. Supports both increasing direction (higher is better,
for benefits) and decreasing direction (lower is better, for risks).
This visualization helps stakeholders understand the normalization
process in MCDA analyses.

## Usage

``` r
create_value_function_plot(
  criterion_name = NULL,
  min_val = NULL,
  max_val = NULL,
  direction = NULL,
  n_points = 100,
  color = NULL,
  show_title = TRUE,
  show_reference_line = TRUE,
  x_label = NULL,
  y_label = "Value (0-100)"
)
```

## Arguments

- criterion_name:

  Character string specifying the name of the criterion to visualize
  (e.g., "Efficacy", "Adverse Events"). Required.

- min_val:

  Numeric value specifying the lower threshold of the clinical scale.
  Required.

- max_val:

  Numeric value specifying the upper threshold of the clinical scale.
  Required.

- direction:

  Character string specifying the favorable direction. Either
  "increasing" (higher raw values are better, used for benefits) or
  "decreasing" (lower raw values are better, used for risks). Required.

- n_points:

  Integer specifying the number of points to use for plotting the curve.
  Default is 100.

- color:

  Character string specifying the color for the value function line. If
  NULL, uses "#0571b0" (blue) for increasing and "#ca0020" (red) for
  decreasing. Default is NULL.

- show_title:

  Logical indicating whether to show the plot title. Default is TRUE.

- show_reference_line:

  Logical indicating whether to show a horizontal reference line at
  value = 50. Default is TRUE.

- x_label:

  Character string for the x-axis label. If NULL, uses criterion_name.
  Default is NULL.

- y_label:

  Character string for the y-axis label. Default is "Value (0-100)".

## Value

A ggplot object showing the value function transformation.

## Examples

``` r
# Benefit criterion: higher efficacy is better
plot_efficacy <- create_value_function_plot(
  criterion_name = "Response Rate (%)",
  min_val = 0,
  max_val = 100,
  direction = "increasing"
)

# Risk criterion: lower adverse event rate is better
plot_ae <- create_value_function_plot(
  criterion_name = "Adverse Event Rate (%)",
  min_val = 0,
  max_val = 50,
  direction = "decreasing"
)

# Custom styling
if (FALSE) { # \dontrun{
plot_custom <- create_value_function_plot(
  criterion_name = "QoL Score",
  min_val = 0,
  max_val = 100,
  direction = "increasing",
  color = "#2c7bb6",
  show_title = FALSE
)
} # }
```
