# Derive minimum boundary value for axis Derive boundary value to include all values

Derive minimum boundary value for axis Derive boundary value to include
all values

## Usage

``` r
relmin(rmin, type_scale)
```

## Arguments

- rmin:

  (`numeric`) number to evaluate

- type_scale:

  (`character`) selected scale display type

## Value

numeric

## Examples

``` r
relmin(0.5, "Free")
#> [1] 0.5
relmin(0.5, "Fixed")
#> [1] 0
relmin(-0.3, "Free")
#> [1] -0.3
relmin(-0.3, "Fixed")
#> [1] -0.3
```
