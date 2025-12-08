# Prepare data analysis for binary and continuous outcomes with Calculated interval confidence identifies whether the dataframe is for Benefit or Risk analysis

Prepare data analysis for binary and continuous outcomes with Calculated
interval confidence identifies whether the dataframe is for Benefit or
Risk analysis

## Usage

``` r
prepare_br_calculated_ci(df, colname1, colname2, cl = 0.95, func)
```

## Arguments

- df:

  (`data.frame`) dataset either `df_benefit` (selected benefit) or
  `df_risk` (select risk).

- colname1:

  (`character`) feature to fetch for the analysis either `Mean`, `Prop`,
  `Rate`

- colname2:

  (`character`) feature to fetch for the analysis either `nPat`, `Py`

- cl:

  (`numeric`) confidence level

- func:

  (`function`) function used to calculate metrics (or BR points)

## Value

data frame for specified type of analysis

## Details

DETAILS
