# CI for absolute risk for binary outcomes

Derive mean difference and associated confidence intervals for binary
outcomes

## Usage

``` r
calculate_diff_bin(prop1, prop2, n1, n2, cl = 0.95)
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
calculate_diff_bin(
  prop1 = .45, prop2 = 0.25, n1 = 500, n2 = 500,
  cl = 0.95
)
#> [2026-03-13 21:33:55] > absolute risk CI for binary outcomes is calculated and saved
#>   diff         se     lower     upper
#> 1  0.2 0.02949576 0.1421894 0.2578106
```
