# Clinical Reference Scales for MCDA

A named list of clinical reference levels used to normalize each
criterion in the
[`mcda_data`](https://pkgdown.r-lib.org/reference/mcda_data.md) example
dataset. Each element specifies the minimum value, maximum value, and
direction of benefit for the corresponding criterion.

## Usage

``` r
data(clinical_scales)
```

## Format

A named list with 5 elements (one per criterion):

- Benefit 1:

  list(min = 0, max = 1, direction = "increasing")

- Benefit 2:

  list(min = 0, max = 100, direction = "decreasing")

- Benefit 3:

  list(min = 0, max = 100, direction = "increasing")

- Risk 1:

  list(min = 0, max = 0.5, direction = "decreasing")

- Risk 2:

  list(min = 0, max = 0.3, direction = "decreasing")

## Details

Example clinical scales for MCDA normalization

## See also

[`mcda_data`](https://pkgdown.r-lib.org/reference/mcda_data.md),
[`weights`](https://pkgdown.r-lib.org/reference/weights.md),
[`create_mcda_barplot_comparison`](https://pkgdown.r-lib.org/reference/create_mcda_barplot_comparison.md)
