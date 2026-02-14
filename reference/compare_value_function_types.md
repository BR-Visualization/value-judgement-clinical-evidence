# Compare Different Value Function Types

Creates a comparison plot showing multiple value function types (Linear,
Piecewise Linear, Exponential, Sigmoid, Step) overlaid on the same plot.
This visualization helps stakeholders understand how different
functional forms would transform the same raw clinical data, and
demonstrates why linear functions are the regulatory-preferred default.
Creates separate plots for benefits (increasing direction) and risks
(decreasing direction).

## Usage

``` r
compare_value_function_types(
  benefit_name = "Benefits",
  benefit_min = 0,
  benefit_max = 100,
  benefit_label = NULL,
  risk_name = "Risks",
  risk_min = 0,
  risk_max = 50,
  risk_label = NULL,
  n_points = 100,
  show_titles = TRUE,
  show_legend = TRUE,
  power = 2
)
```

## Arguments

- benefit_name:

  Character string for the benefit criterion name. Default is
  "Benefits".

- benefit_min:

  Numeric value for benefit minimum threshold. Default is 0.

- benefit_max:

  Numeric value for benefit maximum threshold. Default is 100.

- benefit_label:

  Character string for benefit x-axis label. If NULL, uses benefit_name.
  Default is NULL.

- risk_name:

  Character string for the risk criterion name. Default is "Risks".

- risk_min:

  Numeric value for risk minimum threshold. Default is 0.

- risk_max:

  Numeric value for risk maximum threshold. Default is 50.

- risk_label:

  Character string for risk x-axis label. If NULL, uses risk_name.
  Default is NULL.

- n_points:

  Integer specifying number of points for plotting. Default is 100.

- show_titles:

  Logical indicating whether to show plot titles. Default is TRUE.

- show_legend:

  Logical indicating whether to show the legend. Default is TRUE.

- power:

  Numeric value for the power/exponential function exponent. Default is
  2 (risk-averse, diminishing returns).

## Value

A combined plot (using patchwork) showing value function type
comparisons for both benefits and risks side by side.

## Examples

``` r
# Default comparison
comparison_plot <- compare_value_function_types()

# Custom comparison with specific criteria
custom_comparison <- compare_value_function_types(
  benefit_name = "Efficacy",
  benefit_min = 0,
  benefit_max = 100,
  benefit_label = "Response Rate (%)",
  risk_name = "Safety",
  risk_min = 0,
  risk_max = 50,
  risk_label = "Adverse Event Rate (%)"
)

# Without titles for cleaner display
if (FALSE) { # \dontrun{
comparison_clean <- compare_value_function_types(
  show_titles = FALSE
)
} # }
```
