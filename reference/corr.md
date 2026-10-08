# Simulated benefit-risk correlation data for correlogram visualization

Simulated benefit-risk correlation data for correlogram visualization

## Usage

``` r
corr
```

## Format

A data frame with 100 rows and 6 columns:

- Primary Efficacy:

  Continuous variable representing first benefit measure

- Secondary Efficacy:

  Continuous variable representing second benefit measure, correlated
  with Primary Efficacy (r = 0.6)

- Quality of Life:

  Continuous variable representing third benefit measure

- Recurring AE:

  Continuous variable representing first risk measure, correlated with
  all three benefits (r = 0.3, 0.2, -0.5)

- Rare SAE:

  Continuous variable representing second risk measure, correlated with
  benefits and Recurring AE

- Liver Toxicity:

  Continuous variable representing third risk measure, correlated with
  all previous variables

## Details

This dataset contains simulated data with all continuous variables and
controlled correlation structures. The data is generated using the faux
package to create specific correlations between benefit and risk
outcomes, demonstrating both positive and negative relationships
suitable for correlogram analysis.
