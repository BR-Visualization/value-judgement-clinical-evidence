# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working
with code in this repository.

## Overview

`brpubVJCE` is an R package that generates benefit-risk visualizations
for clinical trial data. The package supports the publication “How to
visually integrate value judgment with clinical evidence” and provides
various specialized visualization types including forest/dot plots,
cumulative excess plots, correlograms, scatter plots, trade-off plots,
and MCDA (Multi-Criteria Decision Analysis) visualizations.

## Development Commands

### Package Development Workflow

``` r
# Load all package code during development
devtools::load_all()

# Install development dependencies
devtools::install_dev_deps()

# Run R CMD check (must pass before PR)
devtools::check()

# Run tests
devtools::test()

# Run specific test file
testthat::test_file("tests/testthat/test-forest_dot_plot.R")

# Build documentation from roxygen comments
devtools::document()

# Build package website (pkgdown)
pkgdown::build_site()
```

### Code Quality

``` r
# Run linter (configuration in .lintr)
lintr::lint_package()

# Apply tidyverse style
styler::style_pkg()
```

### Environment Management

This package uses `renv` for dependency management. After cloning:

``` r
# Restore package dependencies
renv::restore()

# Update lockfile after adding dependencies
renv::snapshot()
```

## Architecture

### Core Visualization Types

The package provides several main visualization categories:

1.  **Forest/Dot Plots** (`R/forest_dot_plot.R`,
    `R/prepare_forest_dot_data.R`)
    - Side-by-side forest and dot plots for treatment effects
    - Supports clinical meaningful difference thresholds
    - Handles axis reversal for “lower is better” outcomes
    - Two-step process:
      [`prepare_forest_dot_data()`](https://pkgdown.r-lib.org/reference/prepare_forest_dot_data.md)
      then
      [`create_forest_dot_plot()`](https://pkgdown.r-lib.org/reference/create_forest_dot_plot.md)
2.  **MCDA Visualizations** (`R/mcda_barplot.R`, `R/mcda_waterfall.R`,
    `R/mcda_brmap.R`)
    - Bar plots comparing normalized benefit/risk values
    - Waterfall charts showing cumulative effects
    - Benefit-risk maps visualizing trade-offs
    - All use wide-format data with Study/Treatment structure (see
      `mcda_data`)
    - Clinical scales define normalization ranges and directions
3.  **Cumulative Excess Plots** (`R/enhancement_cumexcess.R`)
    - Time-to-event visualizations with survival curves
    - Combines plot and summary table using `patchwork`
4.  **Correlograms** (`R/correlogram.R`)
    - Correlation matrices with mixed variable types (continuous/binary)
    - Uses polychoric correlations for binary variables
    - Custom layout with hierarchical structure
5.  **Scatter/Trade-off Plots** (`R/scatterplot.R`, `R/tradeoff_plot.R`)
    - Benefit-risk scatter plots with confidence ellipses
    - Interactive trade-off visualizations

### Data Architecture

**Effects Table Structure**: Most visualizations expect an “effects
table” format with required columns including: - `Factor`: “Benefit” or
“Risk” - `Outcome`: Outcome name - `Type`: “Binary” or “Continuous” -
Treatment-specific columns: `Trt1`, `Trt2`, `Prop1`, `Prop2`, `Mean1`,
`Mean2`, etc.

See `R/check_feature.R` for full validation logic and `R/data.R` for
example datasets.

**MCDA Data Structure**: MCDA functions use wide format with: - `Study`:
Study identifier - `Treatment`: Treatment name (includes both comparator
and active) - Criteria columns: Raw values on original measurement
scales - Each study has multiple rows (one per treatment)

### Shared Infrastructure

- **Colors**:
  [`colfun()`](https://pkgdown.r-lib.org/reference/colfun.md) in
  `R/utils.R` provides standardized color palettes for all figures
- **Fonts**:
  [`control_fonts()`](https://pkgdown.r-lib.org/reference/control_fonts.md)
  calculates responsive font sizes based on output dimensions
- **Custom saving**:
  [`ggsave_custom()`](https://pkgdown.r-lib.org/reference/ggsave_custom.md)
  provides consistent high-quality output
- **Feature checking**:
  [`check_feature()`](https://pkgdown.r-lib.org/reference/check_feature.md)
  and
  [`check_effects_table()`](https://pkgdown.r-lib.org/reference/check_effects_tables.md)
  validate input data structure
- **Global variables**: `R/zzz_globals.R` declares variables used in NSE
  to avoid R CMD check notes

### Directory Structure

- `R/`: Main package functions
- `data-raw/`: Scripts to generate example datasets (`.R` files that
  output `.rda`)
- `data/`: Binary `.rda` datasets loaded with
  [`data()`](https://rdrr.io/r/utils/data.html)
- `dev/`: Development/testing scripts (not part of package)
- `tests/testthat/`: Unit tests using testthat framework
- `vignettes/`: Long-form documentation (`.Rmd` files)
- `inst/img/`: Generated publication-quality plots
- `man/`: Auto-generated documentation (don’t edit directly)

### Code Style

- Follows tidyverse style guide
- Uses roxygen2 with Markdown syntax for documentation
- Imports are declared via roxygen `@import` and `@importFrom` tags
- NSE variables (e.g., `.data$column`) are used for dplyr operations

## Key Implementation Patterns

### Visualization Pipeline

Most plotting functions follow this pattern: 1. Validate input data
structure 2. Transform/prepare data into plot-ready format 3. Create
ggplot2 base plot 4. Apply custom theming (fonts, colors) 5. Combine
plots with patchwork if needed 6. Return combined object

### MCDA Normalization

MCDA functions normalize values using clinical scales: -
`direction = "increasing"`: Higher values are better -
`direction = "decreasing"`: Lower values are better - Normalized value =
(raw_value - min) / (max - min), adjusted for direction - Differences
calculated as: Drug - Comparator on normalized scale

### Data Validation

Use
[`check_feature()`](https://pkgdown.r-lib.org/reference/check_feature.md)
to validate required columns exist and have correct types/values.
Returns HTML-formatted error messages for Shiny integration.

## Testing Strategy

- Tests focus on core data preparation and plot generation functions
- Use snapshot testing for plot outputs where appropriate
- Example datasets (`effects_table`, `mcda_data`, `cumexcess`, etc.)
  provide realistic test inputs
- Tests verify both successful cases and error handling

## Publication Plot Generation

`generate_publication_plots.R` in root directory creates all publication
figures at 600 DPI. Uses
[`ggsave_custom()`](https://pkgdown.r-lib.org/reference/ggsave_custom.md)
for consistent output to `inst/img/`.

## Contributing Notes

Per `.github/CONTRIBUTING.md`: - Fork repository and create feature
branch via `usethis::pr_init()` - Ensure `devtools::check()` passes
cleanly - Add NEWS.md entry for user-facing changes - Don’t restyle
unrelated code - Include test cases with contributions
