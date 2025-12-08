# Create MCDA Bar Chart: Normalized Values Comparison

Create MCDA Bar Chart: Normalized Values Comparison

## Usage

``` r
create_mcda_barplot_comparison(
  data = NULL,
  comparator_name = "Placebo",
  comparison_drug = "Drug A",
  benefit_criteria = NULL,
  risk_criteria = NULL,
  clinical_scales = NULL,
  fig_colors = c("#0571b0", "#ca0020")
)
```

## Arguments

- data:

  A data frame in wide format with Treatment column and criteria
  columns. Required parameter - must be provided. Each row should
  contain raw values for a treatment on their original measurement
  scales. See
  [`mcda_data`](https://pkgdown.r-lib.org/reference/mcda_data.md) for
  example format.

- comparator_name:

  Character string specifying the name of the reference treatment (e.g.,
  placebo or active control) in the data. Default is "Placebo".

- comparison_drug:

  Character string specifying which drug to compare with the reference
  treatment in the visualization. Default is "Drug A".

- benefit_criteria:

  Character vector of benefit criterion names (column names in data).

- risk_criteria:

  Character vector of risk criterion names (column names in data).

- clinical_scales:

  List defining clinical reference levels for each criterion. Each
  element should be a list with: min (lower threshold), max (upper
  threshold), direction ("increasing" for higher is better, "decreasing"
  for lower is better).

- fig_colors:

  A vector of length 2 specifying colors for benefits and risks. Default
  is c("#0571b0", "#ca0020") to match correlogram colors.

## Value

A patchwork object showing three panels: Normalized Comparator values,
Normalized Drug values, and Difference of Normalized Values (Drug -
Comparator), or NULL if data is not provided.

## Examples

``` r
# Load example MCDA data
data(mcda_data)

# View the data structure - each row has raw values for a treatment
head(mcda_data)
#>   Treatment Benefit 1 Benefit 2 Benefit 3 Risk 1 Risk 2
#> 1   Placebo      0.05        65         9   0.03  0.002
#> 2    Drug A      0.46        20        60   0.19  0.015
#> 3    Drug B      0.20        50        58   0.18  0.010
#> 4    Drug C      0.46        57        45   0.36  0.020
#> 5    Drug D      0.14        40        55   0.11  0.012
#   Treatment Benefit 1 Benefit 2 Benefit 3 Risk 1 Risk 2
# 1   Placebo      0.05        65         9   0.30  0.087
# 2    Drug A      0.46        20        60   0.46  0.100
# 3    Drug B      ...

# Define clinical scales
clinical_scales <- list(
  `Benefit 1` = list(min = 0, max = 1, direction = "increasing"),
  `Benefit 2` = list(min = 0, max = 100, direction = "decreasing"),
  `Benefit 3` = list(min = 0, max = 100, direction = "increasing"),
  `Risk 1` = list(min = 0, max = 0.5, direction = "decreasing"),
  `Risk 2` = list(min = 0, max = 0.3, direction = "decreasing")
)

# Create comparison barplot showing
# Normalized Comparator | Normalized Drug B | Difference
barplot_comp <- create_mcda_barplot_comparison(
  data = mcda_data,
  benefit_criteria = c("Benefit 1", "Benefit 2", "Benefit 3"),
  risk_criteria = c("Risk 1", "Risk 2"),
  comparison_drug = "Drug B",
  clinical_scales = clinical_scales
)

# Compare a different drug
if (FALSE) { # \dontrun{
barplot_comp_a <- create_mcda_barplot_comparison(
  data = mcda_data,
  benefit_criteria = c("Benefit 1", "Benefit 2", "Benefit 3"),
  risk_criteria = c("Risk 1", "Risk 2"),
  comparison_drug = "Drug A",
  clinical_scales = clinical_scales
)
ggsave(
  "inst/img/barplot_mcda_comparison_drug_a.png",
  barplot_comp_a,
  width = 12,
  height = 6,
  dpi = 300
)
} # }
```
