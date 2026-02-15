# Stacked Bar Chart

Stacked Bar Chart

## Usage

``` r
stacked_barchart(data, chartcolors, ylabel = "Visit", base_font_size = 9)
```

## Arguments

- data:

  `dataframe` a data frame with a minimum of 4 variables named the
  following:

  1.  usubjid: unique subject ID

  2.  visit: visit ID

  3.  trt: treatment group

  4.  brcat: composite benefit-risk category

- chartcolors:

  `vector` a vector of colors, the same number of levels as the brcat
  variable

- ylabel:

  `character` y label name, default is "Visit"

- base_font_size:

  Numeric; base font size in points for all text elements in the plot
  (default: 9).

## Value

a ggplot object

## Examples

``` r
stacked_barchart(
  data = comp_outcome,
  chartcolors = colfun()$fig12_colors,
  ylabel = "Study Week"
)

```
