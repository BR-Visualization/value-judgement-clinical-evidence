# CI for log odds ratio for binary outcomes

Derive log odds ratio and associated confidence intervals for binary
outcomes

## Usage

``` r
calculate_log_odds_ratio_bin(prop1, prop2, n1, n2, cl = 0.95)
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
calculate_log_odds_ratio_bin(
  prop1 = .45, prop2 = 0.25, n1 = 500, n2 = 500,
  cl = 0.95
)
#> [2026-02-16 00:08:41] > log odds ratio CI for binary outcomes is calculated and saved
#>        diff        se     lower    upper
#> 1 0.8979416 0.1369214 0.6295805 1.166303
```
