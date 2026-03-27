# Font Scaling Proposal for valueJudgementCE

## Problem

Current plots use the same base font size (9pt) regardless of figure dimensions, causing:
- **Smaller plots** (5×4"): Text appears too large relative to plot area
- **Larger plots** (16×6"): Text appears too small and hard to read
- **Inconsistent visual hierarchy** across the publication

## Solution: Scale Fonts Based on Figure Dimensions

### Principle

Font size should be **proportional to the square root of the figure area** to maintain visual consistency across different plot sizes. This ensures that:

1. Text remains readable at the final print size
2. Visual hierarchy (title > subtitle > axis labels) is consistent
3. Plots look cohesive when placed side-by-side in the publication

### Formula

```r
base_font_size = reference_font_size × sqrt(figure_area / reference_area)
```

Where:
- `reference_font_size` = 9pt (current default)
- `reference_area` = 49 sq inches (7×7" plot)
- `figure_area` = width × height

### Implementation Strategy

**Option A: Add parameters to ggsave_custom()** (RECOMMENDED)

```r
ggsave_custom(
  save_name,
  inplot = NULL,
  wdth = 7,
  hght = 4.1,
  base_font_size = NULL,  # NEW: auto-calculate if NULL
  scale_fonts = TRUE,     # NEW: enable font scaling
  ...
)
```

**Option B: Add font_scale parameter to each plot function**

Each visualization function accepts `base_font_size` parameter, calculated before plotting.

**Option C: Create font_config() helper**

```r
font_config <- function(width, height, reference_size = 9, reference_dim = 7) {
  area_ratio <- sqrt((width * height) / (reference_dim^2))
  base_font_size <- reference_size * area_ratio
  control_fonts(base_font_size = base_font_size)
}
```

## Recommended Font Sizes by Plot Type

| Plot Type | Dimensions | Current | Proposed | Change |
|-----------|------------|---------|----------|--------|
| Small (5×4) | 20 sq in | 9pt | 6.4pt | -29% |
| Medium (7×7) | 49 sq in | 9pt | 9pt | 0% (reference) |
| Large (10×6) | 60 sq in | 9pt | 9.9pt | +10% |
| XL (16×6) | 96 sq in | 9pt | 11.6pt | +29% |

## Publication-Specific Adjustments

If journal specifies actual print sizes different from creation sizes:

```r
# Example: 16×6" figure will print at 10×3.75" (2-column width)
final_width <- 10
final_height <- 3.75
creation_width <- 16
creation_height <- 6

# Calculate font size for legibility at final print size
base_font_size <- font_config(final_width, final_height)$p
```

## Action Items

1. **Create font scaling utility** (Option C)
2. **Update generate_publication_plots.R** to use scaled fonts
3. **Document font sizing in vignette**
4. **Test visual consistency** across all 22 plots
