# brpubVJCE �

The goal of brpubVJCE is to generate benefit-risk visualizations for the
publication “How to visually integrate value judgment with clinical
evidence”.

# Table of Contents

- [Installation](#installation)
- [Figure - Dot-Forest Plot](#figure---dot-forest-plot)
- [Figure - Cumulative Excess Plot](#figure---cumulative-excess-plot)

## Installation

You can install the development version of brpubVJCE from
[GitHub](https://github.com/) using the following methods:

### Recommended Installation

``` r
# Install using pak (recommended)
install.packages("pak")
pak::pak("BR-Visualization/brpubVJCE")
```

### Alternative Installation

``` r
# Install using remotes
install.packages("remotes")
remotes::install_github("BR-Visualization/brpubVJCE")
```

## Figure - Dot-Forest Plot

![](reference/figures/README-dot_forest_plot-1.png)

Click to learn more

**Getting Help**

- Documentation: Use
  [`?create_forest_dot_plot`](https://pkgdown.r-lib.org/reference/create_forest_dot_plot.md)
  or
  [`?prepare_forest_dot_data`](https://pkgdown.r-lib.org/reference/prepare_forest_dot_data.md)
  for detailed function help
- Issues: Report bugs at [GitHub
  Issues](https://github.com/BR-Visualization/brpubVJCE/issues)  
- Discussions: Join discussions at [GitHub
  Discussions](https://github.com/BR-Visualization/brpubVJCE/discussions)
- Contact: Reach out to the package maintainers via GitHub

Click to view sample code

``` r
# Load the package and create the plot
library(brpubVJCE)

# Prepare the data and create the visualization
result_plot <- create_forest_dot_plot(
  prepare_forest_dot_data(effects_table)
)

# Display the plot
result_plot
```

## Figure - Cumulative Excess Plot

![](reference/figures/README-cumulative_excess_plot-1.png)

Click to learn more

**Getting Help**

- Documentation: Use
  [`?gensurv_combined`](https://pkgdown.r-lib.org/reference/gensurv_combined.md)
  for detailed function help
- Issues: Report bugs at [GitHub
  Issues](https://github.com/BR-Visualization/brpubVJCE/issues)  
- Discussions: Join discussions at [GitHub
  Discussions](https://github.com/BR-Visualization/brpubVJCE/discussions)
- Contact: Reach out to the package maintainers via GitHub

Click to view sample code

``` r
library(brpubVJCE)

gensurv_combined(
  df_plot = cumexcess, subjects_pt = 100, visits_pt = 6,
  df_table = cumexcess, fig_colors_pt = colfun()$fig13_colors,
  rel_heights_table = c(1, 0.5),
  legend_position_p = c(.1, 1.56),
  titlename =
    "Cumulative Excess # of Subjects w/ Events (per 100 Subjects)",
  mar = 32,
  mab = 15,
  mcd = 22
)
```

## Figure - Correlogram

![](reference/figures/README-correlogram-1.png)

Click to learn more

**Getting Help**

- Documentation: Use
  [`?create_correlogram`](https://pkgdown.r-lib.org/reference/create_correlogram.md)
  for detailed function help
- Issues: Report bugs at [GitHub
  Issues](https://github.com/BR-Visualization/brpubVJCE/issues)  
- Discussions: Join discussions at [GitHub
  Discussions](https://github.com/BR-Visualization/brpubVJCE/discussions)
- Contact: Reach out to the package maintainers via GitHub

Click to view sample code

``` r
library(brpubVJCE)

create_correlogram(corr)
```

## Citation

If you use this package in your research, please cite:

``` r
citation("brpubVJCE")
```

## License

This package is licensed under the MIT License. See the
[LICENSE](https://pkgdown.r-lib.org/LICENSE.md) file for details.

------------------------------------------------------------------------

*Built with ❤️ for the benefit-risk visualization community*
