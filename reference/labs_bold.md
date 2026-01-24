# Create expression

Selectively bold label for
[`ggplot2::ggplot2()`](https://ggplot2.tidyverse.org/reference/ggplot2-package.html).

## Usage

``` r
labs_bold(cond, bold, nonbold)
```

## Arguments

- cond:

  (`numeric`) expected conditional variable bold(1), not to bold(0)

- bold:

  (`character`) level to bold

- nonbold:

  (`character`)  
  which level to bold.

## Details

The function bold text in variable (`bold`) and concatenates it with
string in (`nonbold`) and returns a `dataframe`.

## See also

[`?plotmath`](https://rdrr.io/r/grDevices/plotmath.html).

## Examples

``` r
library(dplyr)
#> 
#> Attaching package: ‘dplyr’
#> The following objects are masked from ‘package:stats’:
#> 
#>     filter, lag
#> The following objects are masked from ‘package:base’:
#> 
#>     intersect, setdiff, setequal, union
library(ggplot2)

xxx <- tribble(
  ~x, ~z, ~w, ~y,
  1, "BOLD_AA", " plain", 1,
  2, "b", "b", 0,
  3, "c", "c", 0
)
ggplot(xxx, aes_string(x = "x", y = "z")) +
  geom_point() +
  scale_y_discrete(
    label = labs_bold(cond = xxx[["y"]], xxx[["z"]], nonbold = xxx[["w"]])
  )
#> [2026-01-24 18:49:14] > Dataout object from
#> the labs_bold function is created

```
