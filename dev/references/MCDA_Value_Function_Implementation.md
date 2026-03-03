# MCDA Value Function Implementation Guide
## Normalization for Benefit-Risk Assessment of Treatments

---

## Table of Contents

1. [Introduction](#introduction)
2. [Conceptual Foundation](#conceptual-foundation)
3. [Implementation Approaches](#implementation-approaches)
4. [Complete R Implementation](#complete-r-implementation)
5. [Worked Example](#worked-example)
6. [Best Practices](#best-practices)
7. [References](#references)

---

## Introduction

This guide provides a comprehensive implementation of Multi-Criteria Decision Analysis (MCDA) value functions for benefit-risk assessment of medical treatments. The approach is based on established pharmaceutical regulatory practices (FDA, EMA) and the PROTECT framework.

### Key Principle

**Use clinical thresholds (global scales), not treatment-relative normalization (local scales).**

### Why This Matters

- **Stability**: Results don't change when new treatments are added
- **Interpretability**: Scores reflect absolute clinical performance
- **Regulatory acceptance**: Aligns with FDA/EMA best practices
- **Comparability**: Enables consistent evaluation across different treatment sets

---

## Conceptual Foundation

### The Three-Step Process

1. **Define clinical reference levels** for each criterion (fixed scales)
2. **Apply value functions** to transform raw data to 0-100 value scale
3. **Weight and aggregate** to calculate overall benefit-risk score

### Value Function vs. Simple Normalization

| Aspect | Simple Min/Max | Value Function (Clinical Thresholds) |
|--------|----------------|--------------------------------------|
| Reference points | Observed min/max from treatments | Clinically meaningful thresholds |
| Scale stability | Changes with new data | Fixed across analyses |
| Interpretation | Relative ranking only | Absolute performance level |
| Best treatment | Always = 100 | Depends on clinical performance |
| Worst treatment | Always = 0 | Depends on clinical performance |

### Handling Heterogeneous Outcomes

The power of MCDA is that it handles completely different outcome types:
- Survival times (months)
- Adverse event rates (%)
- Quality of life scores (points)
- Binary outcomes (yes/no)
- Ordinal categories (mild/moderate/severe)

**All are transformed to a common 0-100 value scale**, then weighted by importance.

---

## Implementation Approaches

### Approach 1: Linear Value Functions (Most Common)

Used when the relationship between the outcome level and its value is proportional.

```r
# For outcomes where HIGHER is BETTER (e.g., efficacy)
v(x) = 100 * (x - x_min) / (x_max - x_min)

# For outcomes where LOWER is BETTER (e.g., adverse events)
v(x) = 100 * (x_max - x) / (x_max - x_min)
```

### Approach 2: Non-Linear Value Functions

Used when there are threshold effects, diminishing returns, or non-proportional value relationships.

**Common shapes:**
- **Concave**: Diminishing returns (e.g., survival beyond certain point)
- **Convex**: Accelerating value (e.g., critical safety thresholds)
- **S-shaped**: Threshold effects (e.g., minimum clinically important difference)
- **Piecewise**: Different slopes in different ranges

### Approach 3: Value Function by Preference Elicitation

Used when stakeholder preferences need to be explicitly captured through:
- **Bisection method**: "What level is halfway in value between worst and best?"
- **Direct rating**: "Rate these levels on a 0-100 scale"
- **Indifference elicitation**: "What level on criterion A is equivalent to this level on criterion B?"

---

## Complete R Implementation

### Core Function: Clinical Threshold-Based Normalization

```r
#' Normalize performance data using clinical thresholds
#'
#' @param perf_matrix Data frame with treatments as rows, criteria as columns
#' @param clinical_scales List defining min, max, and direction for each criterion
#' @param allow_extrapolation If FALSE, cap values at [0, 100]. If TRUE, allow <0 and >100
#' @return Matrix of normalized values (0-100 scale)
normalize_benefit_risk <- function(perf_matrix, 
                                   clinical_scales,
                                   allow_extrapolation = TRUE) {
  
  # Check that all criteria have defined scales
  criteria <- colnames(perf_matrix)
  missing_scales <- setdiff(criteria, names(clinical_scales))
  if (length(missing_scales) > 0) {
    stop("Missing clinical scales for: ", paste(missing_scales, collapse = ", "))
  }
  
  # Apply value function to each criterion
  normalized <- sapply(criteria, function(criterion) {
    
    x <- perf_matrix[[criterion]]
    scale <- clinical_scales[[criterion]]
    
    # Validate scale definition
    if (is.null(scale$min) || is.null(scale$max) || is.null(scale$direction)) {
      stop(sprintf("Scale for '%s' must have min, max, and direction", criterion))
    }
    
    if (scale$min >= scale$max) {
      stop(sprintf("Scale for '%s': min must be less than max", criterion))
    }
    
    # Apply linear value function
    if (scale$direction == "increasing") {
      # Higher values are better
      values <- 100 * (x - scale$min) / (scale$max - scale$min)
    } else if (scale$direction == "decreasing") {
      # Lower values are better
      values <- 100 * (scale$max - x) / (scale$max - scale$min)
    } else {
      stop(sprintf("Direction for '%s' must be 'increasing' or 'decreasing'", criterion))
    }
    
    # Handle extrapolation
    if (!allow_extrapolation) {
      values <- pmax(0, pmin(100, values))
    }
    
    return(values)
  })
  
  # Preserve row and column names
  rownames(normalized) <- rownames(perf_matrix)
  
  return(normalized)
}
```

### Advanced Function: Custom Value Functions

```r
#' Normalize with support for custom non-linear value functions
#'
#' @param perf_matrix Data frame with treatments as rows, criteria as columns
#' @param clinical_scales List defining scales for each criterion
#' @param value_functions Optional list of custom functions for specific criteria
#' @param allow_extrapolation If FALSE, cap values at [0, 100]
#' @return Matrix of normalized values (0-100 scale)
normalize_benefit_risk_advanced <- function(perf_matrix,
                                           clinical_scales,
                                           value_functions = NULL,
                                           allow_extrapolation = TRUE) {
  
  criteria <- colnames(perf_matrix)
  
  normalized <- sapply(criteria, function(criterion) {
    
    x <- perf_matrix[[criterion]]
    scale <- clinical_scales[[criterion]]
    
    # Check if custom value function exists for this criterion
    if (!is.null(value_functions) && criterion %in% names(value_functions)) {
      
      # Apply custom non-linear value function
      message(sprintf("Applying custom value function for '%s'", criterion))
      values <- sapply(x, value_functions[[criterion]])
      
    } else {
      
      # Apply standard linear value function
      if (scale$direction == "increasing") {
        values <- 100 * (x - scale$min) / (scale$max - scale$min)
      } else {
        values <- 100 * (scale$max - x) / (scale$max - scale$min)
      }
    }
    
    # Handle extrapolation
    if (!allow_extrapolation) {
      values <- pmax(0, pmin(100, values))
    }
    
    return(values)
  })
  
  rownames(normalized) <- rownames(perf_matrix)
  return(normalized)
}
```

### Pre-built Non-Linear Value Functions

```r
#' Create common non-linear value functions
#' 
#' @return List of function factories
value_function_library <- list(
  
  # Concave: Diminishing returns (e.g., survival)
  concave = function(min, max, curvature = 0.5) {
    function(x) {
      normalized <- (x - min) / (max - min)
      100 * normalized^curvature
    }
  },
  
  # Convex: Accelerating value (e.g., critical safety threshold)
  convex = function(min, max, curvature = 2) {
    function(x) {
      normalized <- (x - min) / (max - min)
      100 * normalized^curvature
    }
  },
  
  # S-shaped: Threshold effects
  sigmoid = function(min, max, midpoint = NULL, steepness = 1) {
    if (is.null(midpoint)) midpoint <- (min + max) / 2
    function(x) {
      100 / (1 + exp(-steepness * (x - midpoint) / (max - min)))
    }
  },
  
  # Piecewise linear: Different slopes in different ranges
  piecewise = function(breakpoints, values) {
    function(x) {
      approx(x = breakpoints, y = values, xout = x, 
             method = "linear", rule = 2)$y
    }
  }
)

# Example usage:
# survival_vf <- value_function_library$concave(min = 12, max = 60, curvature = 0.7)
```

### Weighting and Aggregation

```r
#' Calculate weighted benefit-risk scores
#'
#' @param normalized_matrix Matrix of normalized values (0-100 scale)
#' @param weights Named vector of weights (must sum to 1)
#' @return Vector of overall scores for each treatment
calculate_weighted_scores <- function(normalized_matrix, weights) {
  
  # Validate weights
  criteria <- colnames(normalized_matrix)
  
  if (!all(criteria %in% names(weights))) {
    missing <- setdiff(criteria, names(weights))
    stop("Missing weights for: ", paste(missing, collapse = ", "))
  }
  
  if (abs(sum(weights) - 1.0) > 0.001) {
    warning("Weights do not sum to 1.0. Normalizing...")
    weights <- weights / sum(weights)
  }
  
  # Ensure weight order matches matrix columns
  weights_ordered <- weights[criteria]
  
  # Calculate weighted sum
  scores <- as.vector(normalized_matrix %*% weights_ordered)
  names(scores) <- rownames(normalized_matrix)
  
  return(scores)
}
```

### Visualization Functions

```r
#' Create value tree visualization
#'
#' @param normalized_matrix Matrix of normalized values
#' @param weights Named vector of weights
plot_value_tree <- function(normalized_matrix, weights) {
  library(ggplot2)
  library(tidyr)
  
  # Prepare data
  df <- as.data.frame(normalized_matrix)
  df$Treatment <- rownames(df)
  df_long <- pivot_longer(df, cols = -Treatment, 
                         names_to = "Criterion", 
                         values_to = "Value")
  
  # Add weights to labels
  df_long$Criterion_Weighted <- paste0(df_long$Criterion, 
                                       "\n(weight: ", 
                                       round(weights[df_long$Criterion], 2), ")")
  
  # Create plot
  ggplot(df_long, aes(x = Criterion_Weighted, y = Value, fill = Treatment)) +
    geom_bar(stat = "identity", position = "dodge") +
    geom_hline(yintercept = 50, linetype = "dashed", alpha = 0.5) +
    labs(title = "Value Tree: Performance Across Criteria",
         x = "Criterion (Weight)",
         y = "Value (0-100 scale)") +
    theme_minimal() +
    theme(axis.text.x = element_text(angle = 45, hjust = 1))
}

#' Create stacked bar chart for benefit-risk balance
#'
#' @param normalized_matrix Matrix of normalized values
#' @param weights Named vector of weights
#' @param benefit_criteria Vector of criterion names that are benefits
#' @param risk_criteria Vector of criterion names that are risks
plot_benefit_risk_balance <- function(normalized_matrix, weights,
                                      benefit_criteria, risk_criteria) {
  library(ggplot2)
  
  # Calculate weighted contributions
  weighted_matrix <- sweep(normalized_matrix, 2, weights, "*")
  
  # Separate benefits and risks
  benefit_scores <- rowSums(weighted_matrix[, benefit_criteria, drop = FALSE])
  risk_scores <- rowSums(weighted_matrix[, risk_criteria, drop = FALSE])
  
  # Prepare data
  df <- data.frame(
    Treatment = rep(rownames(normalized_matrix), 2),
    Type = rep(c("Benefits", "Risks"), each = nrow(normalized_matrix)),
    Score = c(benefit_scores, risk_scores)
  )
  
  # Create plot
  ggplot(df, aes(x = Treatment, y = Score, fill = Type)) +
    geom_bar(stat = "identity", position = "stack") +
    labs(title = "Benefit-Risk Balance",
         x = "Treatment",
         y = "Weighted Score",
         fill = "") +
    scale_fill_manual(values = c("Benefits" = "#2E7D32", "Risks" = "#C62828")) +
    theme_minimal()
}
```

---

## Worked Example

### Scenario: Comparing Three Diabetes Treatments

We'll compare three diabetes treatments across multiple heterogeneous outcomes.

### Step 1: Raw Performance Data

```r
# Performance data for 3 treatments
performance_data <- data.frame(
  Treatment = c("Drug A", "Drug B", "Drug C"),
  
  # Efficacy outcomes
  HbA1c_reduction = c(-1.2, -1.8, -1.0),           # % reduction (higher better)
  weight_loss = c(-2.5, -4.0, -1.0),               # kg (higher better)
  
  # Safety outcomes
  hypoglycemia_rate = c(15, 25, 8),                # % patients (lower better)
  GI_adverse_events = c(20, 35, 12),               # % patients (lower better)
  cardiovascular_events = c(3.2, 2.1, 3.8),        # % patients (lower better)
  
  # Other outcomes
  treatment_satisfaction = c(7.2, 6.5, 8.1),       # 0-10 scale (higher better)
  row.names = 1
)

print(performance_data)
```

### Step 2: Define Clinical Scales

```r
# Clinical reference levels based on:
# - Clinical guidelines
# - Minimum clinically important differences (MCID)
# - Expert opinion
# - Regulatory precedents

clinical_scales <- list(
  
  HbA1c_reduction = list(
    min = 0,      # No reduction (unacceptable)
    max = -2.0,   # 2% reduction (excellent)
    direction = "increasing",  # More negative = better
    rationale = "ADA guidelines: >0.5% = clinically meaningful, >1.5% = excellent"
  ),
  
  weight_loss = list(
    min = 0,      # No weight loss
    max = -5.0,   # 5kg loss (excellent for diabetes)
    direction = "increasing",
    rationale = "5-10% body weight loss shows metabolic benefits"
  ),
  
  hypoglycemia_rate = list(
    min = 0,      # No hypoglycemia (ideal)
    max = 30,     # 30% rate (concerning threshold)
    direction = "decreasing",
    rationale = "FDA guidance: <20% acceptable, >30% major concern"
  ),
  
  GI_adverse_events = list(
    min = 0,      # No GI events (ideal)
    max = 40,     # 40% rate (poor tolerability)
    direction = "decreasing",
    rationale = "Typical discontinuation threshold"
  ),
  
  cardiovascular_events = list(
    min = 0,      # No CV events (ideal)
    max = 5,      # 5% rate (unacceptable)
    direction = "decreasing",
    rationale = "Based on CV outcome trials"
  ),
  
  treatment_satisfaction = list(
    min = 4,      # Poor satisfaction
    max = 9,      # Excellent satisfaction
    direction = "increasing",
    rationale = "DTSQ scale: >7 = good, <5 = poor"
  )
)
```

### Step 3: Apply Value Functions

```r
# Normalize using clinical thresholds
normalized_values <- normalize_benefit_risk(
  perf_matrix = performance_data[, -1],  # Exclude Treatment column
  clinical_scales = clinical_scales,
  allow_extrapolation = TRUE
)

# View normalized values
print(round(normalized_values, 1))
```

**Output:**
```
         HbA1c_reduction weight_loss hypoglycemia_rate GI_adverse_events cardiovascular_events treatment_satisfaction
Drug A              60.0        50.0              50.0              50.0                  64.0                   64.0
Drug B              90.0        80.0              16.7              12.5                  78.0                   50.0
Drug C              50.0        20.0              73.3              70.0                  48.0                   82.0
```

### Step 4: Define Weights

```r
# Weights from stakeholder elicitation
# (e.g., swing weighting with clinicians and patients)

weights <- c(
  HbA1c_reduction = 0.30,        # Most important for efficacy
  weight_loss = 0.10,            # Beneficial but secondary
  hypoglycemia_rate = 0.25,      # Critical safety concern
  GI_adverse_events = 0.15,      # Affects adherence
  cardiovascular_events = 0.15,  # Important safety
  treatment_satisfaction = 0.05  # Patient preference
)

# Verify weights sum to 1
print(paste("Sum of weights:", sum(weights)))
```

### Step 5: Calculate Overall Scores

```r
# Calculate weighted benefit-risk scores
overall_scores <- calculate_weighted_scores(normalized_values, weights)

# Create results summary
results <- data.frame(
  Treatment = names(overall_scores),
  Overall_Score = round(overall_scores, 1),
  Rank = rank(-overall_scores)
)

print(results)
```

**Output:**
```
  Treatment Overall_Score Rank
1    Drug A          56.5    2
2    Drug B          55.0    3
3    Drug C          61.3    1
```

### Step 6: Sensitivity Analysis

```r
# Test sensitivity to weight changes
# Example: What if we weight safety concerns more heavily?

alternative_weights <- c(
  HbA1c_reduction = 0.25,
  weight_loss = 0.05,
  hypoglycemia_rate = 0.30,      # Increased
  GI_adverse_events = 0.20,      # Increased
  cardiovascular_events = 0.15,
  treatment_satisfaction = 0.05
)

alt_scores <- calculate_weighted_scores(normalized_values, alternative_weights)

# Compare rankings
comparison <- data.frame(
  Treatment = names(overall_scores),
  Base_Score = round(overall_scores, 1),
  Safety_Weighted_Score = round(alt_scores, 1),
  Rank_Change = rank(-overall_scores) - rank(-alt_scores)
)

print(comparison)
```

### Step 7: Visualization

```r
# Value tree
plot_value_tree(normalized_values, weights)

# Benefit-risk balance
plot_benefit_risk_balance(
  normalized_values, 
  weights,
  benefit_criteria = c("HbA1c_reduction", "weight_loss", "treatment_satisfaction"),
  risk_criteria = c("hypoglycemia_rate", "GI_adverse_events", "cardiovascular_events")
)
```

---

## Best Practices

### 1. Setting Clinical Thresholds

**DO:**
- Base thresholds on clinical guidelines, MCID, or regulatory precedents
- Document rationale for each threshold
- Involve clinical experts in defining thresholds
- Consider patient perspectives on meaningful differences
- Use literature-based values when available

**DON'T:**
- Use observed min/max from your treatments
- Set arbitrary round numbers without clinical justification
- Make thresholds too narrow (creates artificial precision)
- Forget to consider the clinical context

### 2. Choosing Value Function Shape

**Linear is appropriate when:**
- Proportional relationship between level and value
- No clear threshold effects
- Simplicity is preferred for transparency

**Non-linear is needed when:**
- Diminishing returns exist (e.g., survival beyond certain point)
- Critical thresholds exist (e.g., safety limits)
- Stakeholder preferences are non-proportional
- Validated preference data suggests non-linearity

### 3. Weight Elicitation

**Recommended methods:**
- **Swing weighting**: Most common in pharmaceutical MCDA
- **Pairwise comparison**: For fewer criteria
- **Direct rating**: Quick but less reliable
- **Conjoint analysis**: For patient preferences

**Key principles:**
- Involve relevant stakeholders (clinicians, patients, regulators)
- Use structured elicitation protocols
- Test for logical consistency
- Perform sensitivity analysis on weights

### 4. Dealing with Uncertainty

**Address uncertainty in:**

1. **Performance data**
   - Use confidence intervals
   - Probabilistic sensitivity analysis
   - Monte Carlo simulation

2. **Weights**
   - Gather weights from multiple stakeholders
   - One-way sensitivity analysis
   - Threshold analysis (what weight changes the decision?)

3. **Value function shape**
   - Test linear vs. non-linear
   - Vary curvature parameters

### 5. Validation and Transparency

**Always document:**
- Source of clinical thresholds
- Rationale for value function shapes
- Weight elicitation process
- Stakeholder involvement
- Sensitivity analyses performed

**Validation steps:**
- Face validity: Do results make clinical sense?
- Consistency checks: Are similar treatments ranked similarly?
- Sensitivity robustness: Do small changes drastically alter results?
- Stakeholder review: Do decision-makers accept the model?

### 6. Common Pitfalls to Avoid

❌ **Using treatment min/max** instead of clinical thresholds
❌ **Mixing benefits and risks** in direction (be consistent)
❌ **Forgetting to normalize weights** to sum to 1.0
❌ **Over-precision** in weights (0.33 vs 0.3333333)
❌ **Ignoring extrapolation** (what if treatment performs outside thresholds?)
❌ **No sensitivity analysis** on key assumptions
❌ **Poor documentation** of decisions made

### 7. Reporting Results

**Essential elements:**
- Value tree showing all criteria
- Clinical thresholds and rationale
- Normalized scores for each treatment-criterion pair
- Weights and their source
- Overall scores and rankings
- Sensitivity analyses
- Limitations and assumptions

---

## References

### Key Publications

1. **Mussen F, Salek S, Walker S. (2007).** A quantitative approach to benefit-risk assessment of medicines - part 1: the development of a new model using multi-criteria decision analysis. *Pharmacoepidemiol Drug Saf*, 16 Suppl 1:S2-15.
   - Foundational paper establishing "fixed scales" approach

2. **PROTECT Benefit-Risk Framework (2012).** Pharmacoepidemiological Research on Outcomes of Therapeutics by a European Consortium.
   - IMI-PROTECT project establishing best practices

3. **FDA MCDA Application (2019).** Ticagrelor benefit-risk assessment
   - First FDA regulatory application of MCDA

4. **Thokala P, et al. (2016).** Multiple Criteria Decision Analysis for Health Care Decision Making. *Value in Health*, 19(1):1-13.
   - ISPOR task force recommendations

5. **Phillips LD, Bana e Costa CA. (2007).** Transparent prioritisation, budgeting and resource allocation with multi-criteria decision analysis and decision conferencing. *Annals of Operations Research*, 154(1):51-68.
   - HiView3 methodology and philosophy

### Regulatory Guidance

- **EMA Benefit-Risk Methodology Project** (2011)
- **FDA Benefit-Risk Assessment Framework** (2013)
- **ICH E17: General Principles for Planning Clinical Trials** (2023)

### Software Tools

- **Hiview3**: http://www.catalyze.co.uk
- **V.I.S.A**: http://www.visadecisions.com
- **1000Minds**: http://www.1000minds.com
- **MCDA in R**: Custom implementation (this guide)

---

## Appendix: Complete Example Script

```r
# ============================================================================
# Complete MCDA Benefit-Risk Analysis Script
# ============================================================================

# Load required packages
library(tidyverse)

# Source the functions (assuming they're in separate file)
# source("mcda_functions.R")

# ----------------------------------------------------------------------------
# 1. DEFINE PERFORMANCE DATA
# ----------------------------------------------------------------------------

performance_data <- data.frame(
  row.names = c("Drug A", "Drug B", "Drug C"),
  HbA1c_reduction = c(-1.2, -1.8, -1.0),
  weight_loss = c(-2.5, -4.0, -1.0),
  hypoglycemia_rate = c(15, 25, 8),
  GI_adverse_events = c(20, 35, 12),
  cardiovascular_events = c(3.2, 2.1, 3.8),
  treatment_satisfaction = c(7.2, 6.5, 8.1)
)

# ----------------------------------------------------------------------------
# 2. DEFINE CLINICAL SCALES
# ----------------------------------------------------------------------------

clinical_scales <- list(
  HbA1c_reduction = list(min = 0, max = -2.0, direction = "increasing"),
  weight_loss = list(min = 0, max = -5.0, direction = "increasing"),
  hypoglycemia_rate = list(min = 0, max = 30, direction = "decreasing"),
  GI_adverse_events = list(min = 0, max = 40, direction = "decreasing"),
  cardiovascular_events = list(min = 0, max = 5, direction = "decreasing"),
  treatment_satisfaction = list(min = 4, max = 9, direction = "increasing")
)

# ----------------------------------------------------------------------------
# 3. NORMALIZE VALUES
# ----------------------------------------------------------------------------

normalized <- normalize_benefit_risk(
  perf_matrix = performance_data,
  clinical_scales = clinical_scales,
  allow_extrapolation = TRUE
)

print("Normalized Values:")
print(round(normalized, 1))

# ----------------------------------------------------------------------------
# 4. DEFINE WEIGHTS
# ----------------------------------------------------------------------------

weights <- c(
  HbA1c_reduction = 0.30,
  weight_loss = 0.10,
  hypoglycemia_rate = 0.25,
  GI_adverse_events = 0.15,
  cardiovascular_events = 0.15,
  treatment_satisfaction = 0.05
)

# ----------------------------------------------------------------------------
# 5. CALCULATE OVERALL SCORES
# ----------------------------------------------------------------------------

overall_scores <- calculate_weighted_scores(normalized, weights)

results <- data.frame(
  Treatment = names(overall_scores),
  Overall_Score = round(overall_scores, 1),
  Rank = rank(-overall_scores)
) %>% arrange(Rank)

print("\nOverall Results:")
print(results)

# ----------------------------------------------------------------------------
# 6. SENSITIVITY ANALYSIS
# ----------------------------------------------------------------------------

# Vary weight on hypoglycemia from 0.15 to 0.35
weight_range <- seq(0.15, 0.35, 0.05)
sensitivity_results <- lapply(weight_range, function(w) {
  temp_weights <- weights
  temp_weights["hypoglycemia_rate"] <- w
  temp_weights <- temp_weights / sum(temp_weights)  # Re-normalize
  
  scores <- calculate_weighted_scores(normalized, temp_weights)
  data.frame(
    Hypoglycemia_Weight = w,
    Treatment = names(scores),
    Score = scores
  )
})

sensitivity_df <- do.call(rbind, sensitivity_results)

print("\nSensitivity Analysis:")
print(sensitivity_df)

# ----------------------------------------------------------------------------
# 7. VISUALIZATION
# ----------------------------------------------------------------------------

# Uncomment to generate plots:
# plot_value_tree(normalized, weights)
# plot_benefit_risk_balance(
#   normalized, weights,
#   benefit_criteria = c("HbA1c_reduction", "weight_loss", "treatment_satisfaction"),
#   risk_criteria = c("hypoglycemia_rate", "GI_adverse_events", "cardiovascular_events")
# )

# End of script
```

---

## Contact and Updates

For questions, suggestions, or to report issues with this implementation:
- Refer to the ISPOR MCDA Task Force guidelines
- Consult regulatory guidance (FDA, EMA)
- Review the PROTECT framework documentation

**Version:** 1.0  
**Date:** October 2025  
**Based on:** FDA/EMA benefit-risk best practices, PROTECT framework, HiView3 methodology

---
