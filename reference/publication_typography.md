# Publication Typography Profile

Defines a consistent publication typography scale for common plot
element classes.

## Usage

``` r
publication_typography(
  base_font_size = 9,
  title_ratio = 1.15,
  subtitle_ratio = 1.05,
  axis_title_ratio = 1.05,
  annotation_ratio = 0.95
)
```

## Arguments

- base_font_size:

  Base printed font size in points.

- title_ratio:

  Ratio for plot titles.

- subtitle_ratio:

  Ratio for subtitles and strip labels.

- axis_title_ratio:

  Ratio for axis and legend titles.

- annotation_ratio:

  Ratio for annotations and in-panel value labels.

## Value

Named list of point sizes for publication text elements.
