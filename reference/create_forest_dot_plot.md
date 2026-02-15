# Create Forest and Dot Plots for Treatment Effects

Generates side-by-side forest and dot plots for specified outcomes,
grouped by factor and type. Displays treatment effects, confidence
intervals, and optional clinical thresholds.

**AXIS REVERSAL**: For benefit outcomes with clinical meaningful
difference direction = "less", the x-axis automatically reverses
(positive values on left, negative on right) and green shading extends
towards decreasing x values. This handles cases where lower values
indicate better outcomes (e.g., cholesterol reduction).

## Usage

``` r
create_forest_dot_plot(
  data,
  outcomes_with_thresholds = NULL,
  treatment1 = "Drug A",
  treatment2 = "Placebo",
  filter_value = "None",
  precalculated_stats = FALSE,
  forest_upper_limit = NULL,
  base_font_size = 9
)
```

## Arguments

- data:

  A data frame prepared using
  [`prepare_forest_dot_data()`](https://pkgdown.r-lib.org/reference/prepare_forest_dot_data.md)
  or with matching structure.

- outcomes_with_thresholds:

  Either NULL (uses all available outcomes with no thresholds), a
  character vector of outcome names to include (with no thresholds), or
  a named list where names are outcomes and values are thresholds. For
  lists, directions default to "greater" for positive values and "less"
  for negative values, or can be specified as list(outcome =
  list(threshold = 0.1, direction = "greater")).

- treatment1:

  Character; label of the first treatment group (default: `"Drug A"`).

- treatment2:

  Character; label of the second treatment group (default: `"Placebo"`).

- filter_value:

  Character; value used to filter the `Filter` column (default:
  `"None"`).

- precalculated_stats:

  Logical; if `TRUE`, skips calculation and uses provided statistics.

- forest_upper_limit:

  Numeric; optional upper limit for the forest plot, adds a reference
  line at this value if provided.

- base_font_size:

  Numeric; base font size in points for all text elements in the plot
  (default: 9).

## Value

A patchwork object containing combined dot and forest plots with a
shared legend.

## Examples

``` r
# First, prepare the data
prepared_data <- prepare_forest_dot_data(effects_table)

# Generate the plot using all available outcomes with no thresholds
dotforest <- create_forest_dot_plot(prepared_data)
if (FALSE) { # \dontrun{
ggsave_custom("dotforest.png", imgpath = "./", inplot = dotforest, dpi = 300)
} # }

# Use only specific outcomes with no thresholds
create_forest_dot_plot(prepared_data,
  outcomes_with_thresholds = c("Benefit 1", "Benefit 2")
)
#> `height` was translated to `width`.
#> `height` was translated to `width`.


# Custom thresholds with automatic direction detection
dotforest_4pub <- create_forest_dot_plot(prepared_data,
  outcomes_with_thresholds = list(
    "Benefit 1" = 0.10,
    "Benefit 2" = -20,
    "Risk 1" = -0.05,
    "Risk 2" = -0.07
  )
)

if (FALSE) { # \dontrun{
ggsave_custom("inst/img/dotforest.png",
  imgpath = "./",
  inplot = dotforest_4pub, dpi = 300
)
} # }

# Custom thresholds with explicit directions
create_forest_dot_plot(prepared_data,
  outcomes_with_thresholds = list(
    "Benefit 1" = list(threshold = 0.10, direction = "greater"),
    "Risk 1" = list(threshold = -0.05, direction = "less")
  )
)
#> `height` was translated to `width`.
#> `height` was translated to `width`.


# AXIS REVERSAL: Benefit outcomes with direction "less"
# When benefit outcomes have clinical meaningful difference
# direction = "less", the x-axis reverses (positive left, negative right)
# and green shading
# extends towards negative values (decreasing x direction)
create_forest_dot_plot(prepared_data,
  outcomes_with_thresholds = list(
    "Benefit 1" = list(threshold = -0.15, direction = "less"),
    "Benefit 2" = list(threshold = -0.10, direction = "less")
  )
)
#> `height` was translated to `width`.
#> `height` was translated to `width`.


# Example: Lower cholesterol levels are better (benefit with negative
# direction)
# Treatment difference: Drug A - Placebo = -20 mg/dL (Drug A better)
# Clinical threshold: -15 mg/dL with direction "less" (values < -15 are
# meaningful)
# Result: X-axis reverses, green shading extends towards negative values
```
