
<!-- README.md is generated from README.Rmd. Please edit that file -->

# brpubVJCE 📊

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

## Quick Start

Here’s how to create your first benefit-risk visualization:

``` r
create_forest_dot_plot(
  prepare_forest_dot_data(effects_table)
)
```

<img src="man/figures/README-example-1.png" width="100%" />

## Getting Help

- 📖 **Documentation**: Use `?create_forest_dot_plot` or
  `?prepare_forest_dot_data` for detailed function help
- 🐛 **Issues**: Report bugs at [GitHub
  Issues](https://github.com/BR-Visualization/brpubVJCE/issues)  
- 💬 **Discussions**: Join discussions at [GitHub
  Discussions](https://github.com/BR-Visualization/brpubVJCE/discussions)
- 📧 **Contact**: Reach out to the package maintainers via GitHub

## Citation

If you use this package in your research, please cite:

``` r
citation("brpubVJCE")
```

## Contributing

We welcome contributions! Please see our [Contributing
Guidelines](https://github.com/BR-Visualization/brpubVJCE/blob/main/CONTRIBUTING.md)
for details on:

- 🔧 How to submit bug reports and feature requests
- 📝 How to contribute code and documentation  
- 🧪 How to run tests and ensure code quality
- 📋 Our code of conduct and style guidelines

## License

This package is licensed under the MIT License. See the
[LICENSE](LICENSE.md) file for details.

------------------------------------------------------------------------

*Built with ❤️ for the benefit-risk visualization community*
