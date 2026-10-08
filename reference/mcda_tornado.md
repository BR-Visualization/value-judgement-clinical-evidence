# Create MCDA Tornado Plot

Create MCDA Tornado Plot

## Usage

``` r
mcda_tornado(
  data,
  comparator_name = "Placebo",
  comparison_drug,
  weights,
  clinical_scales,
  fig_colors = c("#0571b0", "#ca0020"),
  weight_change = 20,
  base_font_size = 9
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

- weights:

  Named numeric vector of criterion weights. Must sum to 1. If NULL,
  uses equal weights.

- clinical_scales:

  List defining clinical reference levels for each criterion. Each
  element should be a list with: min (lower threshold), max (upper
  threshold), direction ("increasing" for higher is better, "decreasing"
  for lower is better).

- fig_colors:

  A vector of length 2 specifying colors for benefits and risks. Default
  is c("#0571b0", "#ca0020") to match correlogram colors.

- weight_change:

  A numerical input specifying the percentage change in weight that will
  be observed across the criterion. Default is 20.

- base_font_size:

  Numeric; base font size in points for all text elements in the plot
  (default: 9).

## Value

A ggplot object displaying criterion-specific weights toggled by a
specified percentage (default is 20), and the corresponding difference
in BRScore between the comparison and comparator treatments.

## Examples

``` r
# Load example MCDA data
data(mcda_data)

# View the data structure - each row has raw values for a treatment
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

# Define weights
weights <- c(
  `Primary Efficacy` = 0.30,
  `Secondary Efficacy` = 0.20,
  `Quality of Life` = 0.10,
  `Recurring AE` = 0.30,
  `Rare SAE` = 0.10
)

# Create sensitivity plot toggling criterion weight by 20 percent
sensitivity_plot <- mcda_tornado(
  data = mcda_data |>
           dplyr::filter(Study == "Study 1") |>
             dplyr::select(-Study),
  comparison_drug = "Drug A",
  clinical_scales = clinical_scales,
  weights = weights
)
```
