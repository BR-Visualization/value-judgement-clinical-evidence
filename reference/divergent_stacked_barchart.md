# Divergent Stacked Bar Chart

Divergent Stacked Bar Chart

## Usage

``` r
divergent_stacked_barchart(
  data,
  chartcolors,
  favcat,
  unfavcat,
  ylabel = "Visit"
)
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

- favcat:

  `vector` a vector of favorable categories in the desired plot order

- unfavcat:

  `vector` a vector of unfavorable categories in the desired plot order

- ylabel:

  `character` y label name, default is "Visit"

## Value

a ggplot object

## Examples

``` r
divergent_stacked_barchart(
  data = comp_outcome,
  chartcolors = colfun()$fig12_colors,
  favcat = c("Benefit larger than threshold, with AE",
  "Benefit larger than threshold, w/o AE"),
  unfavcat = c("Withdrew",
  "Benefit less than threshold, w/o AE",
  "Benefit less than threshold, with AE"),
  ylabel = "Study Week"
)
#> Warning: The `size` argument of `element_line()` is deprecated as of ggplot2 3.4.0.
#> ℹ Please use the `linewidth` argument instead.
#> ℹ The deprecated feature was likely used in the brpubVJCE package.
#>   Please report the issue to the authors.
#> Warning: The `size` argument of `element_rect()` is deprecated as of ggplot2 3.4.0.
#> ℹ Please use the `linewidth` argument instead.
#> ℹ The deprecated feature was likely used in the brpubVJCE package.
#>   Please report the issue to the authors.

```
