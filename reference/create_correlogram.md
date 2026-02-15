# Create a correlogram from a given dataframe

Create a correlogram from a given dataframe

## Usage

``` r
create_correlogram(
  df,
  br = c("Benefit", "Benefit", "Benefit", "Risk", "Risk", "Risk"),
  diagonal = FALSE,
  method = "square",
  type_c = "lower",
  fig_colors = c("#0571b0", "#ca0020"),
  base_font_size = 9
)
```

## Arguments

- df:

  A dataframe containing desired variables. Can be inputted as
  continuous, binary, or ordinal variables. Note: Binary variables must
  have a value of 0 or 1. Note: Ordinal variables must be formatted as
  factors.

- br:

  An character vector labeling each variable in df as a "Benefit" or
  "Risk".

- diagonal:

  Allows user to choose to view the correlogram with diagonal entries.
  Default is FALSE.

- method:

  Allows user to modify the visualization method of the correlogram.
  Default is "square".

- type_c:

  Allows user to revise the display. Default is "lower".

- fig_colors:

  Allows the user to change the colors of the figure (defaults are
  provided). Must be vector of length 2, with the first color
  corresponding to benefits, the second to risks.

- base_font_size:

  Numeric; base font size in points for all text elements in the plot
  (default: 9).

## Value

A correlogram.

## Details

Different correlation coefficients are calculated based on the nature of
the variables: For two continuous variables, the Pearson correlation
coefficient is used. For two binary variables, the Phi correlation
coefficient is implemented. For one binary and one continuous variable,
point biserial correlation is utilized. For two ordinal variables,
Spearman rank correlation is utilized. For one continuous and one
ordinal variable, a modified Pearson correlation combined with the
nonparametric Spearman rank correlation is used. For one binary and one
ordinal variable, Glass rank biserial correlation is implemented.

## Examples

``` r
create_correlogram(corr2)
```
