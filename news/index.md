# Changelog

## brpubVJCE 0.0.0.1

### 📦 Initial Release

This version introduces the first implementation of the `brpubVJCE`
package, providing visualization tools for treatment effect analysis.

#### ✨ New Features

- [`prepare_forest_dot_data()`](https://pkgdown.r-lib.org/reference/prepare_forest_dot_data.md):
  Prepares treatment effect data for plotting.
  - Supports continuous and binary outcomes
  - Computes direction-aware differences and confidence intervals
  - Handles both precalculated and raw input formats
- [`create_forest_dot_plot()`](https://pkgdown.r-lib.org/reference/create_forest_dot_plot.md):
  Generates a combined dot and forest plot.
  - Shows comparative treatment effects with CI bars
  - Visualizes thresholds for clinical relevance
  - Custom color-coding and direction markers (e.g., ← Favours Placebo,
    Favours Drug A →)

#### 🛠 Infrastructure

- Uses `ggplot2`, `patchwork`, and `ggtext` for flexible plotting
- Input validation with helpful error messages
- Ready for use in publications and Shiny apps

#### 📄 Documentation

- Added `@examples` and data format descriptions
- All functions are fully documented and exported
