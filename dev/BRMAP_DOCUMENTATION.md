# Benefit-Risk Map Implementation Documentation

## Overview

The `create_mcda_brmap()` function visualizes MCDA benefit-risk analysis results on a 2D scatter plot where both axes represent "higher is better". This implementation follows FDA/EMA guidance for benefit-risk assessment visualization.

## Core Functionality

### Location
- **Function**: `R/mcda_brmap.R`
- **Documentation**: `man/create_mcda_brmap.Rd`
- **Test Script**: `dev/test_mcda_brmap.R`

### Key Features
1. **Clinical threshold-based normalization** (recommended by FDA/EMA)
2. **Direct score transformation** for intuitive interpretation
3. **Efficiency frontier visualization** highlighting favorable profiles
4. **Multi-study support** with automatic comparator matching

## Scaling Formulas

### Benefits (X-axis)
```r
benefits_scaled = benefit_score  # Direct use, capped at [0, 100]
```
- Range: 0-100
- 0 = No benefit vs comparator
- 100 = Maximum benefit vs comparator

### Risks (Y-axis)
```r
risks_scaled = 100 + risk_score  # Transform to positive scale
```
- Range: 0-100
- 0 = Much worse risk profile (many adverse events)
- 100 = Same as comparator (ideal)
- Formula converts negative risk scores to positive scale

**Example:**
- Risk score: -10 → Y-axis: 100 + (-10) = 90 (excellent safety, only 10 points worse than comparator)
- Risk score: -50 → Y-axis: 100 + (-50) = 50 (moderate safety concerns)
- Risk score: -90 → Y-axis: 100 + (-90) = 10 (poor safety profile)

## Efficiency Frontier

### Purpose
The shaded region highlights the "good" benefit-risk area where favorable profiles exist.

### Construction Method
1. Find treatment with **maximum benefits** (best X-coordinate)
2. Find treatment with **maximum risks** (best Y-coordinate, best safety)
3. Create polygon connecting:
   - Origin (0, 0)
   - (0, max_risk) - up to best safety
   - (max_risk_point$Benefits, max_risk) - to safest treatment
   - (max_benefit, max_benefit_point$Risks) - to most effective treatment
   - (max_benefit, 0) - down to x-axis
   - Back to origin

### Why Not Convex Hull?
Convex hull wraps around all points, including dominated solutions. This approach instead defines a region representing favorable benefit-risk territory, appropriate for "higher is better on both axes" interpretation.

## Interpretation Guide

### Map Quadrants

**Upper-Right (High Benefits, High Risks)**
- High benefits vs comparator
- Good risk profile (few adverse events)
- **BEST** - Preferred treatments

**Upper-Left (Low Benefits, High Risks)**
- Low benefits vs comparator
- Good risk profile
- Safe but not very effective

**Lower-Right (High Benefits, Low Risks)**
- High benefits vs comparator
- Poor risk profile (many adverse events)
- Effective but risky - use with caution

**Lower-Left (Low Benefits, Low Risks)**
- Low benefits vs comparator
- Poor risk profile
- **WORST** - Avoid these treatments

### Frontier Region
- **Inside/on frontier**: Favorable benefit-risk profiles
- **Outside frontier**: Suboptimal profiles
- **On frontier edge**: Best-in-class on at least one dimension

## Usage Example

```r
library(BRpub)
data(mcda_data)

# Define clinical scales (recommended approach)
clinical_scales <- list(
  `Benefit 1` = list(min = 0, max = 1, direction = "increasing"),
  `Benefit 2` = list(min = 0, max = 100, direction = "decreasing"),
  `Benefit 3` = list(min = 0, max = 100, direction = "increasing"),
  `Risk 1` = list(min = 0, max = 0.5, direction = "decreasing"),
  `Risk 2` = list(min = 0, max = 0.3, direction = "decreasing")
)

# Define weights (from stakeholder elicitation)
weights <- c(
  `Benefit 1` = 0.30,
  `Benefit 2` = 0.20,
  `Benefit 3` = 0.10,
  `Risk 1` = 0.30,
  `Risk 2` = 0.10
)

# Create benefit-risk map
brmap <- create_mcda_brmap(
  data = mcda_data,
  comparator_name = "Placebo",
  benefit_criteria = c("Benefit 1", "Benefit 2", "Benefit 3"),
  risk_criteria = c("Risk 1", "Risk 2"),
  weights = weights,
  clinical_scales = clinical_scales,
  show_frontier = TRUE,
  show_labels = TRUE
)

print(brmap)
```

## Publication Plots

The `generate_publication_plots.R` script generates all MCDA visualizations including:

### MCDA Plots Generated
- **Individual drug comparisons**: 3-panel barplots (Placebo | Drug | Difference) for Drugs A-D
- **Individual drug walkthroughs**: 3-panel barplots (Difference | Weights | Benefit-Risk) for Drugs A-D
- **Waterfall plot**: Cumulative contribution of criteria across all drugs
- **Benefit-risk map**: 2D scatter plot showing all drugs positioned by benefits vs risks

### Plot Specifications
- **Individual plots**: 16" × 6", 600 DPI
- **Benefit-risk map**: 8" × 8", 600 DPI (square format)
- **Format**: PNG, publication quality

### Running
```r
source("generate_publication_plots.R")
```

Expected output: 15 PNG files in `inst/img/`

## Implementation Notes

### Fixed Issues
1. **Risk Score Scaling**: Now uses direct transformation `100 + risk_score` instead of relative scaling
2. **Frontier Construction**: Based on max benefit/risk points, not convex hull
3. **Documentation**: Updated to clearly explain transformations and interpretation

### Key Design Decisions
- **Higher is better on both axes**: Intuitive for clinical decision-making
- **Clinical thresholds**: Preferred over data-driven normalization per FDA/EMA guidance
- **Consistent with MCDA theory**: Weighted contributions reflect stakeholder preferences
- **Multi-study support**: Each treatment compared to its study-specific comparator

## Testing

```r
# Test the function
devtools::load_all()
source("dev/test_mcda_brmap.R")

# Verify scaling with example
# Drug with benefit=26.4, risk=-10 should appear at (26.4, 90)
```

## References
- FDA Benefit-Risk Framework
- EMA Benefit-Risk Methodology Project
- Multi-Criteria Decision Analysis (MCDA) for healthcare decisions

---

*Last updated: 2026-01-08*
*Implementation: R/mcda_brmap.R (lines 102-637)*
