# Drug Safety Journal — Figure Specifications & R Workflow

## Journal Details
- **Publisher:** Springer / Adis
- **ISSN:** 0114-5916
- **Submission portal:** https://www.editorialmanager.com/drsa

---

## Official Figure Requirements

| Requirement | Specification |
|---|---|
| Submission format | Electronic only |
| Vector format | EPS (preferred) |
| Raster/halftone format | TIFF (preferred) |
| Other accepted formats | MS Office files |
| Font embedding | Required for vector files |
| File naming | `Fig1.eps`, `Fig2.tiff`, etc. |
| Colour charge | Free |
| Figure count limit | None |

> **Resolution guidance (Springer standard):**
> - Line art: 600–1200 dpi
> - Halftones / photos: 300 dpi
> - Combination (line + tone): 300–600 dpi

---

## Springer Column Widths

| Layout | Width |
|---|---|
| Single column | ~84 mm |
| Double column | ~174 mm |

**Font size in final printed figure:** target **7–9 pt**.

---

## R Output — Recommended Approach

### Global Font Setup (showtext)

```r
library(showtext)
showtext_auto()
font_add_google("Source Sans Pro")  # or preferred font

theme_set(theme_minimal(base_family = "Source Sans Pro", base_size = 9))
```

### TIFF Output (raster — halftone/combination figures)

```r
tiff("Fig1.tiff",
     width  = 174,      # mm — use 84 for single column
     height = 120,      # mm — adjust as needed
     units  = "mm",
     res    = 300,      # increase to 600 for line art
     compression = "lzw")
print(your_plot)
dev.off()
```

### EPS Output (vector — line art / simple plots)

```r
# cairo_ps() is preferred over postscript() — handles font embedding reliably
cairo_ps("Fig1.eps",
         width  = 6.85,   # inches (174 mm)
         height = 4.72,   # inches (~120 mm)
         family = "sans",
         onefile = FALSE)
print(your_plot)
dev.off()
```

---

## Combined Figures (patchwork / cowplot)

### patchwork

```r
library(patchwork)

theme_journal <- theme_minimal(base_family = "Source Sans Pro", base_size = 9)

p1 <- p1 + theme_journal
p2 <- p2 + theme_journal

combined <- p1 | p2   # or p1 / p2 for stacked

tiff("Fig1.tiff", width = 174, height = 90, units = "mm", res = 300)
print(combined)
dev.off()
```

### cowplot

```r
library(cowplot)

combined <- plot_grid(p1, p2, labels = "AUTO", label_size = 9)

tiff("Fig1.tiff", width = 174, height = 90, units = "mm", res = 300)
print(combined)
dev.off()
```

---

## Tips & Gotchas

- **Always explicitly open and close a graphics device** — avoids stray `Rplots.pdf` artifacts
- **Apply themes before combining** — set `base_family` and `base_size` on each sub-plot before passing to `patchwork`/`cowplot`
- **Check final rendered font size** — 9 pt in R device units does not always equal 9 pt at print size; verify after export
- **`cairo_ps()` over `postscript()`** — better font embedding, handles UTF-8 characters
- **`showtext` + `ragg`** — alternative high-quality raster pipeline:

```r
library(ragg)
agg_tiff("Fig1.tiff", width = 174, height = 120, units = "mm",
         res = 300, scaling = 1)
print(your_plot)
dev.off()
```

---

## Quick Reference — mm to inches

| mm | inches |
|---|---|
| 84 | 3.31 |
| 120 | 4.72 |
| 174 | 6.85 |
| 200 | 7.87 |

---

*Source: Drug Safety submission guidelines (link.springer.com/journal/40264/submission-guidelines)*

---

## Codebase Assessment

Current package state is close, but not yet submission-ready for typography consistency.

### What is already in place

- The package already exposes a shared font-scaling helper via `font_config()`
- Most plotting functions accept a `base_font_size` parameter
- The repository already has a publication export script in `dev/generate_publication_plots.R`

### Main issues identified

1. **Internal scaling reference is not aligned to the journal spec**

The current `font_config()` logic uses a package-specific reference of `9 pt` text for a `7 x 7 in` figure. That is not tied to the journal's final print widths of approximately `84 mm` and `174 mm`, so the same nominal font size can render too small once figures are reduced to publication size.

2. **Publication exports use arbitrary figure sizes**

The export script currently saves figures at sizes such as `7 x 7 in`, `7 x 5 in`, `5 x 5 in`, and `14 x 9 in`. Those sizes do not map cleanly to the Springer/Drug Safety single-column and double-column layouts, making final font appearance unpredictable after placement in the manuscript.

3. **Combined figures are not consistently panel-aware**

`font_config()` supports `ncol` and `nrow`, but the publication script does not consistently use that for patchwork/cowplot outputs. In side-by-side figures, text is therefore sized for the full canvas and then visually shrunk when each panel is compressed into a subplot region.

4. **Some plotting functions override the shared font scale**

Several functions still hard-code text sizes or call font helpers without passing the plot's `base_font_size`. The trade-off plot is the clearest example: some axis and title sizes are fixed at literal values, and the `MAR` / `MAB` labels use the default `control_fonts()` scaling instead of the user-supplied size.

5. **Mixed sizing systems remain in a few plots**

Some figures rely on `theme_minimal(base_size = base_font_size)`, others use `br_charts_theme()`, and some also layer fixed `geom_text(size = ...)` calls on top. That mix is the main reason fonts look inconsistent across charts even when the same export DPI is used.

6. **Submission-oriented export support is incomplete**

The current custom save helper is oriented around common raster formats but does not yet cleanly support the journal's preferred `TIFF` and `EPS` workflow with device choices appropriate for print submission.

### Conclusion

The figures should not yet be treated as submission-ready.

The main work required is:

- align exported figure dimensions to `84 mm` and `174 mm` layouts
- standardize font scaling around final print size rather than arbitrary canvas size
- remove hard-coded text-size overrides inside plot functions
- ensure combined plots scale text per panel
- extend export helpers to support submission-ready `TIFF` and `EPS` output

### Recommended implementation plan

1. Update the publication export workflow to use journal-width outputs in millimetres.
2. Refactor plotting functions so all text sizing flows from `base_font_size`.
3. Use panel-aware font sizing for patchwork/cowplot figures.
4. Add or extend save helpers for `TIFF` and `EPS` export.
5. Regenerate the publication figures and visually verify printed-size readability.

---

## Implementation Update

The typography and export workflow have now been updated in code.

### What was implemented

- Publication exports are now generated from `dev/generate_publication_plots.R` using journal-oriented dimensions and written to `inst/img/pub`.
- `ggsave_custom()` was extended to support submission-oriented `TIFF` and `EPS` output.
- A shared publication typography system was added so equivalent text classes render more consistently across figures.
- Plot functions were refactored to use shared publication typography rather than mixed hard-coded text sizes.
- Combined figures were adjusted to use panel-aware sizing where needed.
- The forest/dot plot export warning was removed by fixing the underlying horizontal error-bar implementation.

### Current export state

The current publication outputs are:

- `image01_dotforest.tiff`
- `image02_tradeoff.tiff`
- `image03_correlogram.tiff`
- `image04_scatter.tiff`
- `image05_divergent_stacked_barchart.tiff`
- `image06_cumulative_excess.tiff`
- `image07_value_function_types_comparison.tiff`
- `image08_barplot_mcda_comparison_drug_a.tiff`
- `image09_mcda_waterfall_all_drugs.tiff`
- `image10_mcda_benefit_risk_map.tiff`
- `image11_tornado.tiff`

### Figure review outcomes

The figures were reviewed one by one and the following decisions were locked:

- `image01`: kept with stronger panel-aware typography; export warning fixed.
- `image02`: locked after normalizing trade-off plot text sizing.
- `image03`: enlarged so axis tick labels function as primary labels at publication size.
- `image04`: annotation text increased without enlarging the whole figure.
- `image05`: in-bar labels enlarged, very small labels suppressed, treatment strip labels balanced, and figure height increased to reduce panel compression.
- `image06`: accepted as-is after normalized export.
- `image07`: base text increased, legend enlarged, legend title removed, and legend entries shortened for a compact multi-row layout.
- `image08`: internal legend compacted, right-side value labels strengthened, and total subtitle slightly reduced.
- `image09`: small waterfall labels enlarged, negative-side spacing improved, and facet spacing increased so labels stay inside frame.
- `image10`: redundant legend removed and replaced with direct treatment labels; treatment and axis labels then increased slightly.
- `image11`: redundant legend title removed, table header softened, and legend order fixed to `low` then `high`.

### Remaining technical cleanup

The figures are in much better submission shape, but a few non-blocking codebase issues remain:

- ggplot deprecation warnings still exist for `size` vs `linewidth`
- some `element_line(size = ...)` and `element_rect(size = ...)` usage still needs modernization
- some code paths still rely on `aes_string()`

These do not block figure generation, but they should be cleaned up in a later maintenance pass.

### Repository placement note

`dev/generate_publication_plots.R` is an appropriate location for the publication export workflow because it is a developer-side asset-generation script rather than package runtime code.
