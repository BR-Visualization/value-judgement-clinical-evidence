# CI for odds ratio for binary outcomes

Derive odds ratio and associated confidence intervals for binary
outcomes

## Usage

``` r
calculate_odds_ratio_bin(prop1, prop2, n1, n2, cl = 0.95)
```

## Arguments

- prop1:

  (`numeric`)  
  Proportion of cases in active treatment

- prop2:

  (`numeric`)  
  Proportion of cases in comparator treatment

- n1:

  (`numeric`)  
  Total number of subjects in active treatment

- n2:

  (`numeric`)  
  Total number of subjects in comparator treatment

- cl:

  (`numeric`)  
  confidence level

## Examples

``` r
calculate_odds_ratio_bin(
  prop1 = .45, prop2 = 0.25, n1 = 500, n2 = 500,
  cl = 0.95
)
#> [2025-12-08 09:43:13] > CI for odds ratio for binary outcomes is calculated and saved
#>         or        se    lower    upper
#> 1 2.454545 0.1369214 1.876823 3.210102
```
