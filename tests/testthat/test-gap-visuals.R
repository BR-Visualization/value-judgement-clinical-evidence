library(testthat)
library(valueJudgementCE)

test_that("scatter_plot returns ggplot and validates inputs", {
  data("scatterplot", package = "valueJudgementCE")

  result <- scatter_plot(
    scatterplot,
    outcome = c("Benefit", "Risk"),
    mab = 0.2,
    mar = 0.6,
    marginal_type = NULL
  )

  expect_true(inherits(result, "ggplot"))

  expect_error(
    scatter_plot(
      scatterplot[, 1, drop = FALSE],
      outcome = c("Benefit", "Risk"),
      mab = 0.2,
      mar = 0.6
    ),
    "missing incremental probabilities"
  )
})

test_that("stacked bar chart functions return ggplot objects", {
  data("comp_outcome", package = "valueJudgementCE")

  stacked <- stacked_barchart(
    data = comp_outcome,
    chartcolors = colfun()$fig12_colors,
    ylabel = "Study Week"
  )

  divergent <- divergent_stacked_barchart(
    data = comp_outcome,
    chartcolors = colfun()$fig12_colors,
    favcat = c(
      "Benefit larger than threshold, with AE",
      "Benefit larger than threshold, w/o AE"
    ),
    unfavcat = c(
      "Withdrew",
      "Benefit less than threshold, w/o AE",
      "Benefit less than threshold, with AE"
    ),
    ylabel = "Study Week"
  )

  expect_true(inherits(stacked, "ggplot"))
  expect_true(inherits(divergent, "ggplot"))
})

test_that("stacked_barchart validates required columns", {
  expect_error(
    stacked_barchart(
      data = data.frame(usubjid = 1, visit = 1, trt = "A"),
      chartcolors = c("red")
    ),
    "missing a required variable"
  )
})

test_that("gensurv helpers return combined plot objects", {
  data("cumexcess", package = "valueJudgementCE")

  plot_result <- gensurv_plot(
    cumexcess,
    base_subjects = 100,
    visits = 6,
    mar = 40,
    mab = 10,
    mcd = 20
  )

  table_result <- gensurv_table(
    cumexcess,
    base_subjects = 100,
    visits = 6
  )

  combined_result <- gensurv_combined(
    df_plot = cumexcess,
    df_table = cumexcess,
    subjects_pt = 100,
    visits_pt = 6,
    mar = 30,
    mab = 10,
    mcd = 15
  )

  expect_false(is.null(plot_result))
  expect_false(is.null(table_result))
  expect_false(is.null(combined_result))
})

test_that("gensurv simulates expected columns", {
  result <- gensurv(
    seed = 111,
    n1 = 50,
    n2 = 50,
    obsv_duration = 12,
    lambda1 = 0.005,
    lambda2 = 0.0048,
    unit = "Weeks"
  )

  expect_true(is.data.frame(result))
  expect_named(
    result,
    c("eventtime", "diff", "obsv_duration", "obsv_unit")
  )
})
