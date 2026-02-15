# Wrapper to ggsave: Save a ggplot (or other grid object) with sensible defaults

Adds customized defaults to ggsave for the BRAP Journal requirements

## Usage

``` r
ggsave_custom(
  save_name,
  inplot = NULL,
  imgpath = ".",
  wdth = 7,
  hght = 4.1,
  unts = "in",
  bgcol = "white",
  dpi = 600,
  web_suffix = FALSE,
  scale_fonts = FALSE,
  base_font_size = NULL,
  ...
)
```

## Arguments

- save_name:

  File name to create on disk.

- inplot:

  Plot to save, defaults to last plot displayed.

- imgpath:

  Path of the directory to save plot to: path

- wdth:

  width of plot

- hght:

  height of plot

- unts:

  units of plot

- bgcol:

  Background color. If NULL, uses the plot.background fill value from
  the plot theme.

- dpi:

  Resolution in dots per inch (default: 600).

- web_suffix:

  If TRUE, also saves a low-res version with "\_web" suffix (default:
  FALSE).

- scale_fonts:

  Deprecated parameter. Font scaling is now handled by passing
  base_font_size directly to plotting functions.

- base_font_size:

  Deprecated parameter. Font scaling is now handled by passing
  base_font_size directly to plotting functions.

- ...:

  Other arguments passed on to the graphics device function, as
  specified by device.
