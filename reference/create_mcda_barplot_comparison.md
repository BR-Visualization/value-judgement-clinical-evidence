# Create MCDA Bar Chart: Normalized Values Comparison

Create MCDA Bar Chart: Normalized Values Comparison

## Usage

``` r
create_mcda_barplot_comparison(
  data = NULL,
  study = NULL,
  comparator_name = "Placebo",
  comparison_drug = "Drug A",
  benefit_criteria = NULL,
  risk_criteria = NULL,
  clinical_scales = NULL,
  weights = NULL,
  fig_colors = c("#0571b0", "#ca0020"),
  base_font_size = 9
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

  Character string specifying which study to analyze. If NULL, uses all
  data (assumes single comparator). Default is NULL.

- comparator_name:

  Character string specifying the name of the reference treatment (e.g.,
  placebo or active control) in the data. Required. Default is
  "Placebo".

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

- weights:

  Named numeric vector of criterion weights. Must sum to 1. If NULL,
  uses equal weights. Default is NULL.

- fig_colors:

  A vector of length 2 specifying colors for benefits and risks. Default
  is c("#0571b0", "#ca0020") to match correlogram colors.

- base_font_size:

  Numeric; base font size in points for all text elements in the plot
  (default: 9).

## Value

A patchwork object showing four panels: Normalized Values (side-by-side
bars for Comparator and Drug), Difference of Normalized Values (Drug -
Comparator), Weights, and Benefit-Risk scores, or NULL if data is not
provided.

## Examples

``` r
# Load example MCDA data
data(mcda_data)

# View the data structure - each study has comparator and active treatment
head(mcda_data)
#>     Study Treatment Primary Efficacy Secondary Efficacy Quality of Life
#> 1 Study 1   Placebo             0.05                 65               9
#> 2 Study 1    Drug A             0.46                 20              60
#> 3 Study 2   Placebo             0.06                 50              15
#> 4 Study 2    Drug B             0.20                 14              18
#> 5 Study 3   Placebo             0.04                 57              44
#> 6 Study 3    Drug C             0.46                 50              45
#>   Recurring AE Rare SAE
#> 1         0.03    0.002
#> 2         0.19    0.015
#> 3         0.01    0.001
#> 4         0.18    0.010
#> 5         0.05    0.001
#> 6         0.36    0.020
#     Study Treatment Primary Efficacy Secondary Efficacy Quality of Life
# 1 Study 1   Placebo             0.05                 65               9
# 2 Study 1    Drug A             0.46                 20              60
# 3 Study 2   Placebo             0.06                 50              15
# 4 Study 2    Drug B             0.20                 14              18
# (plus columns `Recurring AE` and `Rare SAE`)

# Define clinical scales
clinical_scales <- list(
  `Primary Efficacy` = list(min = 0, max = 1, direction = "increasing"),
  `Secondary Efficacy` = list(min = 0, max = 100, direction = "decreasing"),
  `Quality of Life` = list(min = 0, max = 100, direction = "increasing"),
  `Recurring AE` = list(min = 0, max = 0.5, direction = "decreasing"),
  `Rare SAE` = list(min = 0, max = 0.3, direction = "decreasing")
)

# Define weights from stakeholder elicitation
weights <- c(
  `Primary Efficacy` = 0.30,
  `Secondary Efficacy` = 0.20,
  `Quality of Life` = 0.10,
  `Recurring AE` = 0.30,
  `Rare SAE` = 0.10
)

# Create comparison barplot for a specific study
# Side-by-side Normalized Values | Difference | Weight | Benefit-Risk
barplot_comp_a <- create_mcda_barplot_comparison(
  data = mcda_data,
  study = "Study 1",
  benefit_criteria = c("Primary Efficacy", "Secondary Efficacy", "Quality of Life"),
  risk_criteria = c("Recurring AE", "Rare SAE"),
  comparison_drug = "Drug A",
  clinical_scales = clinical_scales,
  weights = weights
)

# Save the plot
if (FALSE) { # \dontrun{
ggsave(
  "inst/img/barplot_mcda_comparison_drug_a.png",
  barplot_comp_a,
  width = 16,
  height = 6,
  dpi = 600
)
} # }
```
