# CI for treatment difference in exposure-adjusted rates

Derive mean difference and associated confidence intervals for
exposure-adjusted rates (per 100 PYs)

## Usage

``` r
calculate_diff_rates(rate1, rate2, py1, py2, cl = 0.95)
```

## Arguments

- rate1:

  (`numeric`)  
  Event or incidence rate (per 100 PYs) in active treatment

- rate2:

  (`numeric`)  
  Event or incidence rate (per 100 PYs) in comparatortreatment

- py1:

  (`numeric`)  
  100PEY or 100PYAR in active treatment

- py2:

  (`numeric`)  
  100PEY or 100PYAR in comparator treatment

- cl:

  (`numeric`)  
  confidence level

## Examples

``` r
calculate_diff_rates(
  rate1 = 152.17, rate2 = 65.21, py1 = 230, py2 = 230,
  cl = 0.95
)
#> [2026-02-15 16:57:40] > CI for treatment difference in exposure-adjusted rates is calculated and saved in a dataframe
#>    diff        se    lower    upper
#> 1 86.96 0.9721782 85.05457 88.86543
```
