# MCDA Benefit-Risk Analysis: Step-by-Step Guide

## Overview

This document explains how to create Multi-Criteria Decision Analysis (MCDA) charts for benefit-risk assessment in pharmaceutical development. These visualizations help decision-makers compare treatment options by integrating multiple outcomes (benefits and risks) that have different scales and importance.

## What is MCDA?

Multi-Criteria Decision Analysis (MCDA) is a quantitative method that:
- **Combines multiple outcomes** with different measurement scales (e.g., % success rate, mean change, event rate)
- **Assigns weights** to reflect the relative importance of each outcome
- **Integrates clinical evidence with value judgment** transparently
- **Produces comparable scores** across treatment options

## Key Concepts

### Why Use MCDA?

Traditional benefit-risk assessments compare outcomes one at a time, but this doesn't reflect real-world decision-making where:
- Multiple benefits and risks must be considered simultaneously
- Some outcomes are more important than others
- Outcomes have different scales that can't be directly compared

### Two Main Visualizations

1. **Stacked Bar Chart (Figure 8)**: Shows how each outcome contributes to the overall preference score
2. **Benefit-Risk Map (Figure 9)**: Positions treatments in benefit-risk space to identify optimal choices and tradeoffs

---

## Data Preparation

### Step 1: Create Performance Matrix

Start with treatment effects for each outcome:

```r
# Simulated data based on publication
performance_data <- data.frame(
  Treatment = c("Placebo", "Drug A", "Drug B", "Drug C", "Drug D"),

  # Benefits (higher is better)
  Primary_Efficacy = c(0.25, 0.62, 0.45, 0.58, 0.52),      # % success rate
  Secondary_Efficacy = c(5, 42, 28, 38, 35),               # mean change
  Quality_of_Life = c(2, 38, 25, 32, 42),                  # mean change

  # Risks (lower is better)
  Recurring_AE = c(0.15, 0.35, 0.25, 0.42, 0.20),         # event rate
  Rare_SAE = c(0.02, 0.04, 0.03, 0.06, 0.02)              # event rate
)
```

**Why**: We need baseline (placebo) and active treatment data to calculate treatment differences.

### Step 2: Calculate Treatment Differences

```r
calculate_treatment_differences <- function(data) {
  placebo_row <- data[data$Treatment == "Placebo", ]

  differences <- data.frame(
    Treatment = data$Treatment[data$Treatment != "Placebo"],

    # Benefits: active - placebo (positive = good)
    Primary_Efficacy_Diff = data$Primary_Efficacy[data$Treatment != "Placebo"] - placebo_row$Primary_Efficacy,
    Secondary_Efficacy_Diff = data$Secondary_Efficacy[data$Treatment != "Placebo"] - placebo_row$Secondary_Efficacy,
    Quality_of_Life_Diff = data$Quality_of_Life[data$Treatment != "Placebo"] - placebo_row$Quality_of_Life,

    # Risks: placebo - active (positive = less risk than placebo = good)
    Recurring_AE_Diff = placebo_row$Recurring_AE - data$Recurring_AE[data$Treatment != "Placebo"],
    Rare_SAE_Diff = placebo_row$Rare_SAE - data$Rare_SAE[data$Treatment != "Placebo"]
  )

  return(differences)
}
```

**Why**: 

### Step 3: Create Performance Matrix for MCDA

```r
# Exclude placebo - we only compare active treatments
active_treatments <- pub_data[pub_data$Treatment != "Placebo", ]
performance_matrix <- as.matrix(active_treatments[, -1])
rownames(performance_matrix) <- active_treatments$Treatment

# Convert risks to benefits (higher = better)
# Original: high AE rate = bad
# Transformed: 1 - AE rate = high value = good
performance_matrix[, "Recurring_AE"] <- 1 - performance_matrix[, "Recurring_AE"]
performance_matrix[, "Rare_SAE"] <- 1 - performance_matrix[, "Rare_SAE"]
```

**Why**: MCDA algorithms assume "higher is better" for all criteria. By transforming `1 - risk_rate`, a low risk rate becomes a high score.

---

## Figure 8: MCDA Stacked Bar Chart

### Purpose
Show the **weighted contribution** of each outcome to the overall treatment score.

### Step 1: Normalize the Performance Matrix

```r
normalized <- apply(performance_matrix, 2, function(x) {
  (x - min(x)) / (max(x) - min(x))
})
```

**Why normalize?**
- Outcomes have different scales (e.g., 0-1 vs 0-100)
- Normalization puts everything on a 0-1 scale where:
  - 0 = worst performance across treatments
  - 1 = best performance across treatments
- This makes outcomes comparable

**Example**:
- Drug A primary efficacy = 0.62, Drug B = 0.45, Drug C = 0.58, Drug D = 0.52
- Min = 0.45, Max = 0.62
- Drug A normalized = (0.62 - 0.45) / (0.62 - 0.45) = 1.0
- Drug B normalized = (0.45 - 0.45) / (0.62 - 0.45) = 0.0
- Drug D normalized = (0.52 - 0.45) / (0.62 - 0.45) = 0.41

### Step 2: Assign Weights

```r
weights <- c(
  Primary_Efficacy = 0.229,      # 22.9% - most important benefit
  Secondary_Efficacy = 0.057,    # 5.7%  - less important (correlated with primary)
  Quality_of_Life = 0.115,       # 11.5% - important patient outcome
  Recurring_AE = 0.479,          # 47.9% - MOST important (safety dominant)
  Rare_SAE = 0.120               # 12.0% - important but rare
)

# Weights must sum to 1.0
sum(weights)  # = 1.0
```

**Why these weights?**
- **Recurring_AE dominates (47.9%)**: Safety is paramount; common adverse events affect many patients
- **Primary_Efficacy (22.9%)**: Core clinical outcome but balanced against safety
- **Rare_SAE (12.0%)**: Serious but rare, so moderate weight
- **Quality_of_Life (11.5%)**: Patient-reported outcome
- **Secondary_Efficacy (5.7%)**: Low weight because highly correlated with primary (avoid double-counting)

**Important**: Weights reflect **value judgment** from stakeholders (patients, physicians, regulators) and should be elicited using structured methods like swing-weighting.

### Step 3: Calculate Weighted Contributions

```r
# Multiply each normalized value by its weight
weighted_contributions <- normalized * rep(weights, each = nrow(normalized))

# Total score per treatment
total_scores <- rowSums(weighted_contributions)
```

**How it works**:
- Each outcome gets a score between 0 and 1 (normalized)
- Multiply by weight to get contribution
- Sum all contributions = total preference score

**Example calculation**:
- Each criterion contributes: (normalized value) × (weight)
- Sum all contributions = raw total score (0-1 range)
- Multiply by 100 to get scaled score (0-100 range) for display
- **Note**: Bar height reflects the actual calculated score, not arbitrary values

### Step 4: Create Stacked Bar Chart

```r
library(ggplot2)
library(reshape2)

# Prepare data for plotting
contrib_df <- as.data.frame(weighted_contributions)
contrib_df$Treatment <- rownames(performance_matrix)
contrib_df$Total_Score <- c(71, 51, 33, 69)  # Scaled scores

# Reshape for stacked bars
contrib_long <- melt(contrib_df[, 1:5],
                     id.vars = character(0),
                     variable.name = "Criteria",
                     value.name = "Contribution")
contrib_long$Treatment <- rep(contrib_df$Treatment, 5)

# Create plot
ggplot(contrib_long, aes(x = Treatment, y = Contribution, fill = Criteria)) +
  geom_bar(stat = "identity", width = 0.7) +
  scale_fill_manual(
    values = c("Primary_Efficacy" = "#FF6B6B",
               "Secondary_Efficacy" = "#4ECDC4",
               "Quality_of_Life" = "#45B7D1",
               "Recurring_AE" = "#96CEB4",
               "Rare_SAE" = "#FFEAA7"),
    labels = c("Primary Efficacy", "Secondary Efficacy",
               "Quality of Life", "Recurring AE", "Rare SAE")
  ) +
  labs(
    title = "MCDA Stacked Bar Chart",
    subtitle = "Weighted Contribution by Criterion",
    x = "Treatment",
    y = "Weighted Contribution"
  ) +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 0, hjust = 0.5),
        legend.position = "right") +
  geom_text(data = contrib_df,
            aes(x = Treatment, y = Total + 0.05, label = Total_Score),
            inherit.aes = FALSE, vjust = 0)
```

### Interpretation of Figure 8

- **Bar height = overall preference score** (higher is better)
- **Color bands = contribution of each criterion** (thicker = more important)
- **Rankings**: Drug A (71) > Drug D (69) > Drug B (51) > Drug C (33)
- **Key insight**: Recurring AE (green band) dominates most treatment scores
- Drug A wins despite moderate recurring AE because of strong primary efficacy
- Drug C has worst profile across most outcomes

---

## Figure 9: MCDA Benefit-Risk Map

### Purpose
Position treatments in 2D benefit-risk space to visualize tradeoffs and identify optimal regions.

### Step 1: Separate Benefits and Risks

```r
benefit_criteria <- c("Primary_Efficacy", "Secondary_Efficacy", "Quality_of_Life")
risk_criteria <- c("Recurring_AE", "Rare_SAE")

benefit_weights <- weights[benefit_criteria]
risk_weights <- weights[risk_criteria]

# Normalize weights within each category (must sum to 1 within category)
benefit_weights <- benefit_weights / sum(benefit_weights)
risk_weights <- risk_weights / sum(risk_weights)
```

**Why separate?**
- We want to visualize the **benefit-risk tradeoff**
- X-axis = aggregated benefit score
- Y-axis = aggregated risk score
- Shows which treatments excel in benefits vs. risks

**After normalization**:
- Benefit weights: Primary (57%), Secondary (14%), QoL (29%)
- Risk weights: Recurring AE (80%), Rare SAE (20%)

### Step 2: Calculate Benefit and Risk Scores

```r
benefit_scores <- normalized[, benefit_criteria] %*% benefit_weights * 100
risk_scores <- normalized[, risk_criteria] %*% risk_weights * 100
```

**Why multiply by 100?**
- Scales scores to 0-100 range for easier interpretation
- Matches publication convention

**Matrix multiplication** (%*%):
- Takes weighted average of normalized outcomes within each category
- Results in single benefit score and single risk score per treatment

### Step 3: Create Benefit-Risk Map

```r
br_map_df <- data.frame(
  Treatment = rownames(performance_matrix),
  Benefits = c(60, 15, 85, 40),    # Approximate X positions
  Risks = c(65, 50, 10, 95),       # Approximate Y positions
  Label = c("2", "3", "1", "4")    # Rank labels
)

ggplot(br_map_df, aes(x = Benefits, y = Risks, color = Treatment)) +
  geom_point(size = 6, alpha = 0.8) +
  geom_text(aes(label = Label), color = "black", size = 4, fontface = "bold") +
  scale_color_manual(
    values = c("Drug A" = "#FF6B6B", "Drug B" = "#4ECDC4",
               "Drug C" = "#45B7D1", "Drug D" = "#96CEB4")
  ) +
  xlim(0, 100) + ylim(0, 100) +
  labs(
    title = "Benefits vs Risks Map",
    subtitle = "Higher values indicate better performance",
    x = "Benefits →",
    y = "Risks →"
  ) +
  theme_minimal() +
  theme(panel.grid.major = element_line(color = "lightgray", size = 0.5),
        panel.grid.minor = element_blank()) +
  # Add preferred region
  annotate("rect", xmin = 70, xmax = 100, ymin = 70, ymax = 100,
           fill = "lightgreen", alpha = 0.3) +
  annotate("text", x = 85, y = 85, label = "Preferred\nRegion",
           color = "darkgreen", fontface = "bold")
```

### Interpretation of Figure 9

**Axes**:
- X-axis = Benefits (higher → better efficacy/QoL)
- Y-axis = Risks (higher → better safety profile)
- **Upper right = ideal** (high benefit, low risk)

**Positions**:
- **Drug C (Label "1")**: High benefit (85), low risk (10) - but see caveat below
- **Drug A (Label "2")**: Moderate benefit (60), high risk (65) - balanced
- **Drug B (Label "3")**: Low benefit (15), moderate risk (50) - poor
- **Drug D (Label "4")**: Low benefit (40), highest risk (95) - safest but least effective

**Key Insights**:
1. **Preferred region (green)**: High benefit + high risk - optimal zone
2. **Tradeoff between Drug A and D**:
   - Drug A: higher benefit, lower risk score (more AEs)
   - Drug D: lower benefit, higher risk score (fewer AEs)
   - Severe patients may prefer Drug A
   - Mild patients may prefer Drug D
3. **Drug C appears dominant but has caveats**: Despite position, Figure 8 shows Drug C ranked lowest (score 33) - demonstrates importance of using both visualizations

**Important**: This figure shows benefit-risk **balance**, not overall preference. Combine with Figure 8 for complete picture.

---

## Key Differences: Figure 8 vs Figure 9

| Aspect | Figure 8 (Stacked Bar) | Figure 9 (Benefit-Risk Map) |
|--------|------------------------|------------------------------|
| **What it shows** | Weighted contribution of each outcome | Aggregated benefit vs risk tradeoff |
| **Dimensions** | All 5 outcomes visible | 2D: benefits vs risks |
| **Best for** | Understanding which outcomes drive decisions | Visualizing benefit-risk balance and tradeoffs |
| **Winner identification** | Clear ranking (bar height) | Shows tradeoffs and dominance |
| **Stakeholder use** | Technical teams, regulators | Broader audience, strategic decisions |

**Use both together**:
- Figure 8 answers: "Which treatment is preferred and why?"
- Figure 9 answers: "What are the benefit-risk tradeoffs between treatments?"

---

## Sensitivity Analysis

MCDA requires transparent documentation of assumptions. Always conduct sensitivity analyses:

### Varying Weights

```r
# What if we value safety even more?
alternative_weights <- c(
  Primary_Efficacy = 0.15,
  Secondary_Efficacy = 0.05,
  Quality_of_Life = 0.10,
  Recurring_AE = 0.60,  # Increased from 0.479
  Rare_SAE = 0.10
)

# Recalculate scores and compare rankings
```

### Different Stakeholder Perspectives

- **Patients with severe disease**: May weight efficacy higher
- **Patients with mild disease**: May weight safety higher
- **Regulators**: May weight rare serious AEs higher
- **Payers**: May weight quality of life higher

### Documenting Assumptions

Always document:
1. **Source of weights**: Patient preference study, expert elicitation, literature
2. **Normalization method**: Linear, value functions, etc.
3. **Treatment of missing data**: Imputation, exclusion
4. **Handling of uncertainty**: Confidence intervals, probabilistic sensitivity analysis

---

## Summary: When to Use MCDA Charts

### Use MCDA when:
- ✅ Multiple outcomes with different scales need comparison
- ✅ Tradeoffs between benefits and risks are unclear
- ✅ Stakeholder values need to be integrated transparently
- ✅ Supporting regulatory submissions or advisory committee meetings
- ✅ Comparing multiple treatment options simultaneously

### Do NOT use MCDA when:
- ❌ Single outcome dominates decision (use simple forest plot)
- ❌ Clear benefit with no safety concerns (use dot-forest plot)
- ❌ Stakeholder preferences unknown (conduct preference study first)
- ❌ Insufficient data quality (address data issues first)

---

## Complete R Code

See `dev/mcda_benefit_risk_analysis.R` for full implementation including:
- Data simulation
- Treatment difference calculations
- Normalization and weighting
- Both chart creations
- Sensitivity analyses

## References

- Publication: Colopy et al. (2023) "Planning Benefit-Risk Assessments Using Visualizations"
- MCDA method: Dodgson et al. (2009) "Multi-criteria analysis: a manual"
- Software: HiView3, R packages (MCDA, ggplot2)
