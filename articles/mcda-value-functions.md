# MCDA Clinical Threshold-Based Normalization

``` r
library(brpubVJCE)
```

## Overview

This package provides two MCDA visualization functions that implement
**clinical threshold-based normalization**:

1.  **[`create_mcda_barplot_comparison()`](https://pkgdown.r-lib.org/reference/create_mcda_barplot_comparison.md)**:
    Shows normalized values for Placebo and Drug side-by-side with their
    difference
2.  **`create_mcda_barplot_walkthrough()`**: Shows the complete MCDA
    calculation from normalized differences through weighted scores

Both functions use fixed clinical scales (global scales) rather than
treatment-relative normalization (local scales), as recommended by
FDA/EMA best practices and the PROTECT framework.

## The Normalization Approach

### Value Function

For each criterion, we apply a linear value function based on clinical
thresholds:

**For “increasing” direction (higher is better):**

``` r
v(x) = 100 * (x - min) / (max - min)
```

**For “decreasing” direction (lower is better):**

``` r
v(x) = 100 * (max - x) / (max - min)
```

Where `min` and `max` are clinically meaningful thresholds, not observed
treatment values.

### Key Steps

1.  **Normalize actual values separately**
    - Apply value function to drug’s actual values → Drug normalized
      (0-100)
    - Apply value function to placebo’s actual values → Placebo
      normalized (0-100)
2.  **Compute normalized differences**
    - Normalized difference = Drug normalized - Placebo normalized
    - Positive = Drug performs better than Placebo
    - Negative = Drug performs worse than Placebo
3.  **Apply weights and aggregate**
    - Weighted contribution = Normalized difference × Weight
    - Total benefit-risk score = Sum of weighted contributions

## Defining Clinical Scales

Each criterion requires three parameters:

``` r
clinical_scales <- list(
  `Criterion Name` = list(
    min = 0,                  # Lower threshold
    max = 100,                # Upper threshold
    direction = "increasing"  # "increasing" or "decreasing"
  )
)
```

**Direction:** - `"increasing"`: Higher raw values are better (e.g.,
efficacy) - `"decreasing"`: Lower raw values are better (e.g., adverse
events)

Thresholds should be based on clinical guidelines, Minimum Clinically
Important Difference (MCID), or regulatory precedents.

## Example

### Prepare Data

``` r
mcda_data <- prepare_mcda_data(effects_table)
```

### Define Clinical Scales

``` r
clinical_scales <- list(
  `Benefit 1` = list(min = 0, max = 1, direction = "increasing"),
  `Benefit 2` = list(min = 0, max = 100, direction = "decreasing"),
  `Benefit 3` = list(min = 0, max = 100, direction = "increasing"),
  `Risk 1` = list(min = 0, max = 0.5, direction = "decreasing"),
  `Risk 2` = list(min = 0, max = 0.15, direction = "decreasing")
)
```

### Define Weights

``` r
weights <- c(
  `Benefit 1` = 0.30,
  `Benefit 2` = 0.20,
  `Benefit 3` = 0.10,
  `Risk 1` = 0.30,
  `Risk 2` = 0.10
)
```

### Create Visualizations

**Comparison Plot: Shows normalized values and their difference**

``` r
barplot_comparison <- create_mcda_barplot_comparison(
  data = mcda_data,
  benefit_criteria = c("Benefit 1", "Benefit 2", "Benefit 3"),
  risk_criteria = c("Risk 1", "Risk 2"),
  comparison_drug = "Drug A",
  clinical_scales = clinical_scales
)
```

This shows 3 columns for each criterion: - Normalized Placebo (0-100
scale) - Normalized Drug (0-100 scale) - Normalized Difference (Drug -
Placebo)

**Walkthrough Plot: Shows complete MCDA calculation**

``` r
barplot_walkthrough <- create_mcda_barplot_walkthrough(
  data = mcda_data,
  benefit_criteria = c("Benefit 1", "Benefit 2", "Benefit 3"),
  risk_criteria = c("Risk 1", "Risk 2"),
  comparison_drug = "Drug A",
  weights = weights,
  clinical_scales = clinical_scales
)
```

## Interpreting the Walkthrough Output

The plot shows 3 panels representing the MCDA calculation steps:

**Panel 1: Normalized Difference** - Shows: (Drug normalized - Placebo
normalized) - Positive values = Drug performs better than Placebo -
Negative values = Drug performs worse than Placebo - Scale is symmetric
around zero

**Panel 2: Weight** - Shows: Relative importance (must sum to 100%) -
Each criterion’s contribution to final score

**Panel 3: Benefit-Risk** - Shows: Normalized Difference × Weight -
Weighted contribution for each criterion - Total score = Sum of all
contributions - Positive total = Drug has better overall benefit-risk
profile - Negative total = Placebo has better overall benefit-risk
profile

## Understanding Negative Normalized Values

Example: Drug has 19% adverse events, Placebo has 3% adverse events

``` r
# Clinical scale: min=0%, max=50%, direction="decreasing"

# Step 1: Normalize separately
Drug_normalized = 100 * (50-19) / 50 = 62
Placebo_normalized = 100 * (50-3) / 50 = 94

# Step 2: Compute difference
Normalized_difference = 62 - 94 = -32  # Drug performs worse
```

The -32 indicates Drug has worse safety than Placebo (higher AE rate)

## Key Points

**Setting Thresholds:** - Base on clinical guidelines, MCID, or
regulatory precedents - Do NOT use observed min/max from your data -
Document rationale

**Validation:** - Check face validity (does it make clinical sense?) -
Perform sensitivity analysis on weights - Ensure stakeholder acceptance

## References

- Mussen F, et al. (2007). *Pharmacoepidemiol Drug Saf*, 16 Suppl
  1:S2-15
- PROTECT Benefit-Risk Framework (2012)
- Thokala P, et al. (2016). *Value in Health*, 19(1):1-13
- FDA Benefit-Risk Assessment Framework (2013)
- EMA Benefit-Risk Methodology Project (2011)

For detailed implementation reference:
`dev/references/MCDA_Value_Function_Implementation.md`
