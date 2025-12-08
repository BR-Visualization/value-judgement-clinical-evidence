# Prepare data analysis for binary and continuous outcomes with Supplied interval confidence identifies whether the dataframe is for Benefit or Risk analysis

Prepare data analysis for binary and continuous outcomes with Supplied
interval confidence identifies whether the dataframe is for Benefit or
Risk analysis

## Usage

``` r
prepare_br_supplied_ci(df, colname, metric_name, func)
```

## Arguments

- df:

  (`data.frame`) dataset either `df_benefit` (selected benefit) or
  `df_risk` (select risk).

- colname:

  (`character`) feature to fetch for the analysis either `Mean`, `Prop`,
  `Rate`

- metric_name:

  (`character`) metric for which we must fetch the confidence interval
  if supplied (taken from the effect table) either `Diff`, `RelRisk`,
  `OddsRatio`, `Diff_Rates`

- func:

  (`function`) function used to calculate metrics (or BR points)

## Value

data frame for specified type of analysis

## Details

DETAILS
