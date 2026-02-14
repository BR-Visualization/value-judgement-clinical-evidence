# CI for log relative risk for binary outcomes

Derive log relative risk and associated confidence intervals for binary
outcomes

## Usage

``` r
calculate_log_rel_risk_bin(prop1, prop2, n1, n2, cl = 0.95)
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
calculate_log_rel_risk_bin(
  prop1 = .45, prop2 = 0.25, n1 = 500, n2 = 500,
  cl = 0.95
)
#> [2026-02-14 18:27:00] > log relative risk CI for binary outcomes is calculated and saved
#>        diff         se     lower     upper
#> 1 0.5877867 0.09189366 0.4076784 0.7678949
```
