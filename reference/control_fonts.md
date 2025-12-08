# Control Fonts

`control_fonts()` calculates font-sizes depending on output size

## Usage

``` r
control_fonts(base_font_size = 9, h1 = 12, h2 = 10, label = base_font_size + 1)
```

## Arguments

- base_font_size:

  (unit)  
  Font-size of normal paragraph text. By default is 9pt. By editing this
  value, all the other parameters get updated too.

- h1:

  (unit)  
  Font-size of title of the graph, dependent of `base_font_size`. By
  default, 12pt.

- h2:

  (unit)  
  Font-size of subtitle of the graph, dependent of `base_font_size`. By
  default, 10pt.

- label:

  (unit)  
  Font-size of text that's called outside the ggplot theme. It should
  render at the same font size as base_font_size

## Details

It returns a list with the font sizes of:

- **p** - normal text elements within the ggplot theme.

- **h1** - titles.

- **h2** - subtitles.

- **label** - for text elements outside the ggplot theme. If you want to
  add an annotation or a label to your plot, use the font size `label`.
  By default, it renders at 10pt.

- **rel** - for legend elements.

## Examples

``` r
control_fonts(base_font_size = 10)
#> $p
#> [1] 10
#> 
#> $h1
#> [1] 10.44432
#> 
#> $h2
#> [1] 9.06625
#> 
#> $label
#> [1] 3.374821
#> 
#> $rel
#> [1] 7.253
#> 
```
