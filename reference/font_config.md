# Calculate Font Size Based on Figure Dimensions

Scales font size proportionally to figure dimensions to maintain visual
consistency across plots of different sizes. Font size scales with the
square root of the area to ensure readability.

## Usage

``` r
font_config(
  width,
  height,
  reference_font_size = 9,
  reference_width = 7,
  reference_height = 7,
  min_font_size = 6,
  max_font_size = 14
)
```

## Arguments

- width:

  Figure width in inches

- height:

  Figure height in inches

- reference_font_size:

  Base font size for reference dimensions (default: 9pt)

- reference_width:

  Reference width in inches (default: 7)

- reference_height:

  Reference height in inches (default: 7)

- min_font_size:

  Minimum font size to prevent text being too small (default: 6)

- max_font_size:

  Maximum font size to prevent text being too large (default: 14)

## Value

List containing font configuration from control_fonts()

## Examples

``` r
# Font config for a small 5×4 plot
font_config(5, 4)
#> $p
#> [1] 6
#> 
#> $h1
#> [1] 17.4072
#> 
#> $h2
#> [1] 15.11042
#> 
#> $label
#> [1] 3.579356
#> 
#> $rel
#> [1] 7.253
#> 

# Font config for a large 16×6 plot
font_config(16, 6)
#> $p
#> [1] 12.59738
#> 
#> $h1
#> [1] 8.29087
#> 
#> $h2
#> [1] 7.196935
#> 
#> $label
#> [1] 3.311563
#> 
#> $rel
#> [1] 7.253
#> 
```
