
<!-- README.md is generated from README.Rmd. Please edit that file -->

# brpubVJCE

<!-- badges: start -->

[![Codecov test
coverage](https://codecov.io/gh/BR-Visualization/brpubVJCE/graph/badge.svg)](https://app.codecov.io/gh/BR-Visualization/brpubVJCE)
[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
<!-- badges: end -->

The goal of brpubVJCE is to generate benefit-risk visualizations for the
publication “How to visually integrate value judgment with clinical
evidence”.

## Installation

You can install the development version of brpubVJCE from
[GitHub](https://github.com/) with:

``` r
# install.packages("pak")
pak::pak("BR-Visualization/brpubVJCE")
```

## Example

This is a basic example which shows you how to solve a common problem:

``` r
library(brpubVJCE)

gensurv_combined(
  df_plot = cumexcess, subjects_pt = 500, visits_pt = 6,
  df_table = cumexcess, fig_colors_pt = colfun()$fig13_colors,
  rel_heights_table = c(1, 0.4),
  legend_position_p = c(.02, 1.5),
  titlename =
    "Cumulative Excess # of Subjects w/ Events (per 100 Subjects)",
  mar = 30,
  mab = 20,
  mcd = 35
)
#> Warning: Removed 4 rows containing missing values or values outside the scale range
#> (`geom_line()`).
#> Removed 4 rows containing missing values or values outside the scale range
#> (`geom_line()`).
#> Removed 4 rows containing missing values or values outside the scale range
#> (`geom_line()`).
#> Removed 4 rows containing missing values or values outside the scale range
#> (`geom_line()`).
#> `geom_line()`: Each group consists of only one observation.
#> ℹ Do you need to adjust the group aesthetic?
```

<img src="man/figures/README-example-1.png" width="100%" />
