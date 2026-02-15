# Compare Value Functions for Benefits and Risks

Creates a side-by-side comparison of value functions for benefit and
risk criteria, showing how the normalization differs based on whether
higher or lower raw values are favorable. This is useful for educational
purposes and for communicating the MCDA normalization approach to
stakeholders.

## Usage

``` r
compare_value_functions(
  benefit_name = "Benefits",
  benefit_min = 0,
  benefit_max = 100,
  benefit_label = NULL,
  risk_name = "Risks",
  risk_min = 0,
  risk_max = 50,
  risk_label = NULL,
  show_titles = TRUE,
  show_reference_lines = TRUE,
  base_font_size = 9
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

- show_titles:

  Logical indicating whether to show plot titles. Default is TRUE.

- show_reference_lines:

  Logical indicating whether to show horizontal reference lines at value
  = 50. Default is TRUE.

- base_font_size:

  Numeric; base font size in points for all text elements in the plot
  (default: 9).

## Value

A combined plot (using patchwork) showing both value functions side by
side.

## Examples

``` r
# Default comparison
comparison_plot <- compare_value_functions()

# Custom comparison with specific criteria
custom_comparison <- compare_value_functions(
  benefit_name = "Response Rate",
  benefit_min = 0,
  benefit_max = 100,
  benefit_label = "Response Rate (%)",
  risk_name = "Adverse Events",
  risk_min = 0,
  risk_max = 50,
  risk_label = "AE Rate (%)"
)

# Without titles for cleaner display
if (FALSE) { # \dontrun{
comparison_clean <- compare_value_functions(
  show_titles = FALSE
)
} # }
```
