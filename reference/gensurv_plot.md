# Create a cumulative excess plot from a given dataframe

Create a cumulative excess plot from a given dataframe

## Usage

``` r
gensurv_plot(
  df_outcome,
  base_subjects,
  visits,
  fig_colors = c("#0571b0", "#ca0020"),
  titlename = NULL,
  ben_name = "Primary Efficacy",
  risk_name = "Recurring AE",
  legend_position = c(-0.03, 1.15),
  mar,
  mab,
  mcd,
  base_font_size = 9
)
```

## Arguments

- df_outcome:

  A dataframe with 6 variables named the following:

  1.  eventtime: A vector of time points at which an event occurred.

  2.  diff: A vector containing the difference in active and control
      effects.

  3.  obsv_duration: A variable that specifies the duration of the
      observational period (numerical).

  4.  obsv_unit: A variable that specifies the unit for the duration of
      the observational period (this is a non-numerical input).

  5.  outcome: A vector containing whether the outcome is a "Benefit" or
      "Risk".

  6.  eff_diff_lbl: A vector containing the label for effect difference.

- base_subjects:

  A numerical input that specifies the baseline proportion of subjects
  in the study (for example, "per 100 subjects")

- visits:

  A numerical input that is the length between normal visits.

- fig_colors:

  Allows the user to change the colors of the figure (defaults are
  provided). Must be vector of length 2, with color corresponding to
  benefit first and risk second.

- titlename:

  Allows the user to change the documentation of the title (default is
  provided).

- ben_name:

  Allows user to specify benefit of interest (default is provided).

- risk_name:

  Allows user to specify risk of interest (default is provided).

- legend_position:

  Allows user to specify legend position. Must be a vector of length 2,
  with the first value corresponding to the position of the legend
  relative to the x-axis, and the second corresponding to the position
  of the legend relative to the y-axis (numeric).

- mar:

  The maximum acceptable risk for the treatment, as discussed by the
  team, must be numerical.

- mab:

  The minimum acceptable benefit for the treatment, as discussed by the
  team, must be numerical.

- mcd:

  The minimum clinically important difference of the treatment, as
  discussed by the team, must be numerical.

- base_font_size:

  Numeric; base font size in points for all text elements in the plot
  (default: 9).

## Value

A cumulative excess plot.

## Examples

``` r
gensurv_plot(cumexcess, 100, 6,
  titlename =
    "Cumulative Excess # of Subjects w/ Events (per 100 Subjects)",
  mar = 40,
  mab = 10,
  mcd = 20
)
```
