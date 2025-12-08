# Example MCDA data in wide format

Sample MCDA data frame derived from effects_table. Each row represents a
treatment (placebo or active drug) with raw values for benefit and risk
criteria on their original measurement scales. This format is required
for MCDA visualization functions.

## Usage

``` r
data(mcda_data)
```

## Format

A data frame with 5 rows (Placebo + 4 drugs) and 6 columns:

- Treatment:

  Character: Treatment name (Placebo, Drug A, Drug B, Drug C, Drug D)

- Benefit 1:

  Numeric: Binary benefit outcome (proportion scale 0-1)

- Benefit 2:

  Numeric: Continuous benefit outcome (original scale)

- Benefit 3:

  Numeric: Continuous benefit outcome (original scale)

- Risk 1:

  Numeric: Binary risk outcome (proportion scale 0-1)

- Risk 2:

  Numeric: Binary risk outcome (proportion scale 0-1)

## Details

This dataset contains raw values (not differences from placebo) for each
treatment. The MCDA visualization functions (e.g.,
[`create_mcda_barplot_comparison`](https://pkgdown.r-lib.org/reference/create_mcda_barplot_comparison.md),
[`create_mcda_walkthrough`](https://pkgdown.r-lib.org/reference/create_mcda_walkthrough.md))
will calculate treatment differences from placebo and normalize values
using clinical scales.

## See also

[`create_mcda_barplot_comparison`](https://pkgdown.r-lib.org/reference/create_mcda_barplot_comparison.md),
[`create_mcda_walkthrough`](https://pkgdown.r-lib.org/reference/create_mcda_walkthrough.md)
