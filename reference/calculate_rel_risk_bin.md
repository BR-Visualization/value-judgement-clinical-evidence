# CI for relative risk for binary outcomes

Derive relative risk and associated confidence intervals for binary
outcomes

## Usage

``` r
calculate_rel_risk_bin(prop1, prop2, n1, n2, cl = 0.95)
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
calculate_rel_risk_bin(
  prop1 = .45, prop2 = 0.25, n1 = 500, n2 = 500,
  cl = 0.95
)
#> [2026-02-15 22:50:56] > CI for relative risk for binary outcomes is calculated
#>    rr         se    lower    upper
#> 1 1.8 0.09189366 1.503324 2.155225
```
