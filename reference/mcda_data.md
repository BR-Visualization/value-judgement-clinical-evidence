# Example MCDA data in wide format

Sample MCDA data frame derived from effects_table. Each study contains
two rows: one for the active treatment and one for its comparator, with
raw values for benefit and risk criteria on their original measurement
scales. This format is required for MCDA visualization functions.

## Usage

``` r
data(mcda_data)
```

## Format

A data frame with multiple rows (2 per study: comparator + active
treatment) and 7 columns:

- Study:

  Character: Study identifier (e.g., "Study 1", "Study 2")

- Treatment:

  Character: Treatment name (e.g., Placebo, Drug A, Drug B, Drug C, Drug
  D)

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

This dataset contains raw values (not differences from comparator) for
each treatment within each study. Each unique treatment comparison from
the effects_table is assigned a Study identifier, and both the active
treatment and its comparator are included as separate rows. The MCDA
visualization functions (e.g.,
[`create_mcda_barplot_comparison`](https://pkgdown.r-lib.org/reference/create_mcda_barplot_comparison.md),
[`create_mcda_walkthrough`](https://pkgdown.r-lib.org/reference/create_mcda_walkthrough.md),
[`create_mcda_waterfall`](https://pkgdown.r-lib.org/reference/create_mcda_waterfall.md))
will calculate treatment differences from the comparator and normalize
values using clinical scales.

## See also

[`create_mcda_barplot_comparison`](https://pkgdown.r-lib.org/reference/create_mcda_barplot_comparison.md),
[`create_mcda_walkthrough`](https://pkgdown.r-lib.org/reference/create_mcda_walkthrough.md),
[`create_mcda_waterfall`](https://pkgdown.r-lib.org/reference/create_mcda_waterfall.md)

## Examples

``` r
if (FALSE) { # \dontrun{
# Load the data
data(mcda_data)

# View structure - note the Study column
head(mcda_data)

# Define clinical scales
clinical_scales <- list(
  `Benefit 1` = list(min = 0, max = 1, direction = "increasing"),
  `Benefit 2` = list(min = 0, max = 100, direction = "decreasing"),
  `Benefit 3` = list(min = 0, max = 100, direction = "increasing"),
  `Risk 1` = list(min = 0, max = 0.5, direction = "decreasing"),
  `Risk 2` = list(min = 0, max = 0.3, direction = "decreasing")
)

# Analyze a specific study
barplot_study1 <- create_mcda_barplot_comparison(
  data = mcda_data,
  study = "Study 1",
  comparison_drug = "Drug A",
  benefit_criteria = c("Benefit 1", "Benefit 2", "Benefit 3"),
  risk_criteria = c("Risk 1", "Risk 2"),
  clinical_scales = clinical_scales
)

# Analyze all studies together (if they share a common comparator)
waterfall_all <- create_mcda_waterfall(
  data = mcda_data,
  comparator_name = "Placebo",
  benefit_criteria = c("Benefit 1", "Benefit 2", "Benefit 3"),
  risk_criteria = c("Risk 1", "Risk 2"),
  clinical_scales = clinical_scales
)
} # }
```
