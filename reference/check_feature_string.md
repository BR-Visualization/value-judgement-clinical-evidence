# intermediate function used to display log messages check if a specific feature exist in the data

intermediate function used to display log messages check if a specific
feature exist in the data

## Usage

``` r
check_feature_string(
  data,
  feature,
  plots,
  func,
  na_check,
  values,
  check_same,
  check_range,
  check_positive,
  check_unique,
  add_msg = ""
)
```

## Arguments

- data:

  dataset

- feature:

  (`data.frame`) feature to display analysis

- plots:

  (`function`) type of analysis (graph) either `forest`, `tradeoff`,
  `contour`, `value_tree`

- func:

  function to check data type

- na_check:

  (`logical`) check if the feature has missing values

- values:

  (`vector`) check if the feature contains specified values

- check_same:

  (`logical`) check if the feature has the same value across all rows

- check_range:

  (`vector`) check if the feature is in the specified range

- check_positive:

  (`logical`) check if the feature is positive

- check_unique:

  (`vector`) check if unique values of a feature is associated with
  unique values of linked features

- add_msg:

  (`character`) added error message for empty feature

## Value

error message(s), if any
