# Prepare data for the tradeoff plot

Prepare data for the tradeoff plot

## Usage

``` r
prepare_tradeoff_data(
  data,
  filter,
  category,
  benefit,
  risk,
  ci_method,
  cl,
  type_risk,
  type_graph
)
```

## Arguments

- data:

  (`data.frame`) dataset

- filter:

  (`character`) selected filter

- category:

  (`character`) selected category

- benefit:

  (`character`) selected benefit outcome

- risk:

  (`character`) selected risk outcome

- ci_method:

  (`character`) selected method to display confidence intervals

- cl:

  (`numeric`) confidence level

- type_risk:

  (`character`) selected way to display risk outcomes (crude
  proportions, Exposure-adjusted rates (per 100 PYs))

- type_graph:

  (`character`) selected way to display binary outcomes (Absolute risk,
  Relative risk, Odds ratio)

## Value

df_br (`data.frame`) benefit/risk metrics for all treatment given the
selected benefit (respectively risk) outcome

## Details

This function processes the input dataset for trade-off plot based on
the selected benefit and risk outcomes, the specified filters,
confidence interval methods, and display types.
