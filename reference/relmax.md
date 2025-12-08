# Derive maximum boundary value for axis Derive boundary value to include all values

Derive maximum boundary value for axis Derive boundary value to include
all values

## Usage

``` r
relmax(rmax, type_scale)
```

## Arguments

- rmax:

  (`numeric`) number to evaluate

- type_scale:

  (`character`) selected scale display type

## Value

numeric

## Examples

``` r
relmax(0.5, "Free")
#> [1] 0.5
relmax(0.5, "Fixed")
#> [1] 0.5
relmax(-0.3, "Free")
#> [1] -0.3
relmax(-0.3, "Fixed")
#> [1] 0
```
