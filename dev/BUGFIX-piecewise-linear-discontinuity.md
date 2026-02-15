# Bug Fix: Piecewise Linear Discontinuity in Value Function Plot

**Date:** 2026-02-15
**File:** `R/value_function_plot.R`
**Function:** `compare_value_function_types()`
**Severity:** Visual / Correctness

## Summary

The piecewise linear value function had discontinuities caused by hand-picked
intercepts that did not ensure continuity between segments. The benefit panel
had a visible "dip" at x = 60% of the range. The risk panel was coincidentally
correct for the old 0–50 range but broke when the range was changed to 0–100.

Both panels now compute intercepts dynamically to guarantee continuity for any
axis range.

## Root Cause

The `piecewise_linear()` helper function defines three line segments with
breakpoints, slopes, and intercepts:

```
Segment 1: x < bp1       →  slope[1] * x + intercept[1]
Segment 2: bp1 ≤ x < bp2 →  slope[2] * (x - bp1) + intercept[2]
Segment 3: x ≥ bp2       →  slope[3] * (x - bp2) + intercept[3]
```

### Benefit panel

Breakpoints at 20% and 60% of range, slopes `c(0.5, 2, 0.5)`.

Original intercepts were hard-coded as `c(0, 10, 70)`:

| Boundary | Segment ending | Segment starting | Gap |
|----------|---------------|-----------------|-----|
| x = 20   | 0.5 × 20 + 0 = **10**  | 2 × (20-20) + 10 = **10** | None ✓ |
| x = 60   | 2 × (60-20) + 10 = **90** | 0.5 × (60-60) + 70 = **70** | **-20** ✗ |

### Risk panel

Breakpoints at 20% and 50% of range, slopes `c(-2, -3, -5)`.

Original intercepts were hard-coded as `c(100, 80, 35)`. These happened to be
correct for the old 0–50 range but failed for 0–100:

| Boundary (range 0–100) | Segment ending | Segment starting | Gap |
|------------------------|---------------|-----------------|-----|
| x = 20 | -2 × 20 + 100 = **60** | -3 × (20-20) + 80 = **80** | **+20** ✗ |
| x = 50 | -3 × (50-20) + 80 = **-10** | -5 × (50-50) + 35 = **35** | **+45** ✗ |

## Fix

Replaced all hard-coded intercepts with computed values that guarantee
continuity. Each segment's intercept is derived from where the previous
segment ends:

```r
# Benefit (before → after):
c(0, 10, 70)  →  c(0, seg1_end, seg2_end)

seg1_end <- 0.5 * (benefit_bp1 - benefit_min) + 0
seg2_end <- 2 * (benefit_bp2 - benefit_bp1) + seg1_end

# Risk (before → after):
c(100, 80, 35)  →  c(risk_seg1_start, risk_seg1_end, risk_seg2_end)

risk_seg1_start <- 100
risk_seg1_end <- -2 * (risk_bp1 - risk_min) + risk_seg1_start
risk_seg2_end <- -3 * (risk_bp2 - risk_bp1) + risk_seg1_end
```

Continuity is now guaranteed regardless of slope, breakpoint, or axis range values.

## Additional Change: Risk Axis Range 0–50 → 0–100

The adverse event rate axis was changed from 0–50 to 0–100 in both
`generate_publication_plots.R` and `README.Rmd` so that both panels use the
same 0–100 scale and render as equal-sized squares.

### Files changed

| File | Change |
|------|--------|
| `R/value_function_plot.R` | Computed intercepts for both benefit and risk piecewise linear |
| `dev/generate_publication_plots.R` | `risk_max`: 50 → 100; figure width: 7.5" → 10" |
| `README.Rmd` | `risk_max`: 50 → 100; `fig.width`: 7.5 → 10 |

## Impact

- Affects the `compare_value_function_types()` function output and any
  publication figures generated from it.
- No API changes — the piecewise fix is internal to the function.
- The risk axis range change is a parameter change in the calling scripts
  only; the function still accepts any range.

## Verification

```r
devtools::load_all()
compare_value_function_types(
  benefit_min = 0, benefit_max = 100,
  risk_min = 0, risk_max = 100,
  show_titles = FALSE, show_legend = TRUE
)
```

Confirm:
1. The blue "Piecewise Linear" curve on both panels has no dips or jumps.
2. Both panels are the same size with axes 0–100.
