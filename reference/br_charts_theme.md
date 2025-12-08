# BR charts theme

BR charts theme

## Usage

``` r
br_charts_theme(
  base_family = "",
  base_font_size = 9,
  base_stroke = 1,
  margin = 1,
  get_fonts = control_fonts,
  get_colors = colfun()[["control_palettes"]],
  axis_text_x = ggplot2::element_text(colour = black),
  axis_line = ggplot2::element_line(colour = black, size = stroke_size),
  axis_title_y = ggplot2::element_text(),
  axis_text_y_left = ggplot2::element_text(margin = ggplot2::margin(t = 0, r = spacing/2,
    l = 0, b = 0, unit = "pt")),
  legend_position = "top",
  panel_grid_minor = ggplot2::element_line(colour = grey_2, size = stroke_size/2,
    linetype = "dashed"),
  panel_grid_major = ggplot2::element_line(colour = grey_2, size = stroke_size/2,
    linetype = "dashed"),
  ...
)
```

## Arguments

- base_family:

  - font

- base_font_size:

  (unit)  
  Font-size of normal paragraph text.

- base_stroke:

  (unit)  
  line thickness

- margin:

  (unit)  
  margin around entire plot (unit with the sizes of the top, right,
  bottom, and left margins)

- get_fonts:

  fonts

- get_colors:

  colors

- axis_text_x:

  tick labels along axes

- axis_line:

  all line elements

- axis_title_y:

  labels of axes

- axis_text_y_left:

  tick labels along axes

- legend_position:

  position

- panel_grid_minor:

  grid lines

- panel_grid_major:

  grid lines

- ...:

  Additional arguments passed to other methods.

## Value

theme for chart
