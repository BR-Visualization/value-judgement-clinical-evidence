# CI for treatment difference in continuous outcomes

Derive mean difference and associated confidence intervals for
continuous outcomes

## Usage

``` r
calculate_diff_con(mean1, mean2, sd1, sd2, n1, n2, cl = 0.95)
```

## Arguments

- mean1:

  (`numeric`)  
  Mean of measure in active treatment

- mean2:

  (`numeric`)  
  Mean of measure in comparator treatment

- sd1:

  (`numeric`)  
  Standard deviation of measure in active treatment

- sd2:

  (`numeric`)  
  Standard deviation of measure in comparator treatment

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
calculate_diff_con(
  mean1 = 0.6, mean2 = 0.5, sd1 = 0.1, sd2 = 0.3,
  n1 = 400, n2 = 500, cl = 0.95
)
#> [2026-04-13 15:58:47] > CI for treatment difference in continuous outcomes is calculated
#>   diff        se      lower     upper
#> 1  0.1 0.0156539 0.06927751 0.1307225
```
