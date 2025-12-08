# Prepare trade-off plot

Add points and dual CIs to trade-off plot

## Usage

``` r
prepare_tradeoff_plot(
  myplot,
  data,
  df_br,
  drug_status,
  filter,
  ci,
  chartcolors
)
```

## Arguments

- myplot:

  raw plot

- data:

  (`data.frame`) input dataset

- df_br:

  (`data.frame`) processed dataset

- drug_status:

  (`character`) selected status of drug to display (Approved, Test)

- filter:

  (`character`) selected filter

- ci:

  (`character`) selected choice to display confidence intervals or not
  (Yes, No)

- chartcolors:

  (`vector`) a vector of colors, the same number of levels as the number
  of treatments
