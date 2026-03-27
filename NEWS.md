# valueJudgementCE (Development)

## ✨ New Features

### Value Function Visualization

- `create_value_function_plot()`: Creates visualizations showing how raw clinical values are transformed to normalized scores (0-100) using linear value functions
  - Supports both increasing direction (benefits - higher is better) and decreasing direction (risks - lower is better)
  - Customizable colors, labels, and reference lines
  - Useful for explaining MCDA normalization to stakeholders

- `compare_value_functions()`: Creates side-by-side comparison of benefit and risk value functions
  - Shows how the same transformation applies differently based on favorable direction
  - Educational tool for demonstrating MCDA principles

- `plot_multiple_value_functions()`: Generates multi-panel plots for all criteria in clinical scales
  - Takes MCDA clinical_scales structure as input
  - Creates comprehensive visualization of all value function transformations
  - Flexible grid layout options

- `compare_value_function_types()`: Creates side-by-side comparison plots showing different value function types
  - Compares Linear (current standard), Piecewise Linear, Exponential, Sigmoid, and Step functions
  - Shows how each function type transforms the same raw data differently
  - Generates separate plots for benefits (increasing direction) and risks (decreasing direction)
  - Helps demonstrate why linear functions are the regulatory-preferred default
  - Educational tool for explaining trade-offs between different MCDA approaches

### MCDA Benefit-Risk Map Enhancements

- `create_mcda_brmap()`: Added `show_title` and `show_subtitle` parameters
  - Default: both set to FALSE for cleaner plots
  - Allows flexible control of plot annotations

### Documentation

- Updated vignette `mcda-value-function-types.Rmd` with examples of new value function visualization functions
- Added comprehensive test suite for value function plotting functions

---

# valueJudgementCE 0.0.0.1

## 📦 Initial Release

This version introduces the first implementation of the `valueJudgementCE` package, providing visualization tools for treatment effect analysis.

### ✨ New Features

- `prepare_forest_dot_data()`: Prepares treatment effect data for plotting.
  - Supports continuous and binary outcomes
  - Computes direction-aware differences and confidence intervals
  - Handles both precalculated and raw input formats

- `create_forest_dot_plot()`: Generates a combined dot and forest plot.
  - Shows comparative treatment effects with CI bars
  - Visualizes thresholds for clinical relevance
  - Custom color-coding and direction markers (e.g., ← Favours Placebo, Favours Drug A →)

### 🛠 Infrastructure

- Uses `ggplot2`, `patchwork`, and `ggtext` for flexible plotting
- Input validation with helpful error messages
- Ready for use in publications and Shiny apps

### 📄 Documentation

- Added `@examples` and data format descriptions
- All functions are fully documented and exported
