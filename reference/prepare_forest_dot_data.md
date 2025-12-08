# Prepare Data for Forest and Dot Plots

Prepares and optionally calculates treatment effect differences and
confidence intervals for specified outcomes, based on whether a higher
value indicates risk or benefit.

## Usage

``` r
prepare_forest_dot_data(
  data,
  outcomes_of_interest = NULL,
  treatment1 = "Drug A",
  treatment2 = "Placebo",
  filter_value = "None",
  precalculated_stats = FALSE
)
```

## Arguments

- data:

  A data frame containing treatment comparisons, estimates, and
  metadata.

- outcomes_of_interest:

  Character vector of outcome names to include. If NULL (default), uses
  all available outcomes from the data.

- treatment1:

  Character; label of the first treatment group (default: `"Drug A"`).

- treatment2:

  Character; label of the second treatment group (default: `"Placebo"`).

- filter_value:

  Character; value to filter the `Filter` column (default: `"None"`).

- precalculated_stats:

  Logical; if `TRUE`, assumes data already contains `Diff`,
  `Diff_LowerCI`, and `Diff_UpperCI`.

## Value

A filtered data frame with computed or validated treatment differences
and 95% confidence intervals. Includes directionally colored confidence
intervals for plotting.

## Examples

``` r
# Load or create a sample dataset `effects_table`
head(effects_table)
#>    Factor     Grouped_Outcome   Outcome                Statistics       Type
#> 1 Benefit Clinical Assessment Benefit 1     % Achieving Remission     Binary
#> 2 Benefit Clinical Assessment Benefit 2 Mean Change from Baseline Continuous
#> 3 Benefit     Quality of Life Benefit 3 Mean Change from Baseline Continuous
#> 4    Risk       Adverse Event    Risk 1                Event Rate     Binary
#> 5    Risk       Adverse Event    Risk 2            Incidence Rate     Binary
#> 6    Risk            Toxicity    Risk 3            Incidence Rate     Binary
#>   Rate_Type Outcome_Status Filter Category   Trt1 nSub1   N1 Prop1 Dur1
#> 1      <NA>     Identified   None      All Drug A   300 1000 0.460  365
#> 2      <NA>     Identified   None      All Drug A    NA 1000    NA  365
#> 3      <NA>     Identified   None      All Drug A    NA 1000    NA   NA
#> 4 EventRate     Identified   None      All Drug A   300 1000 0.190  365
#> 5   IncRate     Identified   None      All Drug A    15 1000 0.015  365
#> 6   IncRate      Potential   None      All Drug A     4 1000 0.004  365
#>   100PYAR1 IncRate1 nEvent1 100PEY1 EventRate1 Mean1 Se1 Sd1 Drug_Status
#> 1       NA       NA      NA      NA         NA    NA  NA  NA    Approved
#> 2       NA       NA      NA      NA         NA    20  NA  16    Approved
#> 3       NA       NA      NA      NA         NA    60  NA  60    Approved
#> 4       NA       NA     750    1000       0.75    NA  NA  NA    Approved
#> 5     1000    0.300      NA      NA         NA    NA  NA  NA    Approved
#> 6     1000    0.015      NA      NA         NA    NA  NA  NA    Approved
#>      Trt2 nSub2   N2 Prop2 Dur2 100PYAR2 IncRate2 nEvent2 100PEY2 EventRate2
#> 1 Placebo    50 1000 0.050  365       NA       NA      NA      NA         NA
#> 2 Placebo    NA 1000    NA   NA       NA       NA      NA      NA         NA
#> 3 Placebo    NA 1000    NA   NA       NA       NA      NA      NA         NA
#> 4 Placebo    30 1000 0.030  365       NA       NA      30    1000       0.03
#> 5 Placebo     1 1000 0.002  365     1000    0.001      NA      NA         NA
#> 6 Placebo     1 1000 0.001  365     1000    0.001      NA      NA         NA
#>   Mean2 Se2 Sd2 Diff_LowerCI Diff_UpperCI Diff_IncRate_LowerCI
#> 1    NA  NA  NA           NA           NA                   NA
#> 2    65  NA  63           NA           NA                   NA
#> 3     9  NA   8           NA           NA                   NA
#> 4    NA  NA  NA           NA           NA                   NA
#> 5    NA  NA  NA           NA           NA                   NA
#> 6    NA  NA  NA           NA           NA                   NA
#>   Diff_IncRate_UpperCI Diff_EventRate_LowerCI Diff_EventRate_UpperCI
#> 1                   NA                     NA                     NA
#> 2                   NA                     NA                     NA
#> 3                   NA                     NA                     NA
#> 4                   NA                     NA                     NA
#> 5                   NA                     NA                     NA
#> 6                   NA                     NA                     NA
#>   RelRisk_LowerCI RelRisk_UpperCI OddsRatio_LowerCI OddsRatio_UpperCI
#> 1              NA              NA                NA                NA
#> 2              NA              NA                NA                NA
#> 3              NA              NA                NA                NA
#> 4              NA              NA                NA                NA
#> 5              NA              NA                NA                NA
#> 6              NA              NA                NA                NA
#>   MCDA_Weight Population Data_Source Quality Notes
#> 1          NA         NA          NA      NA    NA
#> 2          NA         NA          NA      NA    NA
#> 3          NA         NA          NA      NA    NA
#> 4          NA         NA          NA      NA    NA
#> 5          NA         NA          NA      NA    NA
#> 6          NA         NA          NA      NA    NA

# Prepare using all available outcomes and calculate statistics
prepared_data <- prepare_forest_dot_data(effects_table)

# Use precalculated stats
prepared_data2 <- prepare_forest_dot_data(effects_table,
  precalculated_stats = TRUE
)
```
