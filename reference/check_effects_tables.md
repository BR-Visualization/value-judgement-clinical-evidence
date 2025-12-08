# Check if data contains required features to run a specific plot

Check if data contains required features to run a specific plot

## Usage

``` r
check_effects_table(df)
```

## Arguments

- df:

  (`data.frame`) dataset - effect table

## Value

missing features

## Details

This function verifies whether the input dataset (`df`) contains all the
necessary features required to generate a specific plot. It checks for
the existence of necessary features as well as the types and values of
features and display log messages if any feature does not conform to the
defined rules. This ensures that the dataset is suitable for the
intended visualization.

## Examples

``` r
check_effects_table(brdata)
#> [1] "<ol></ol>"
```
