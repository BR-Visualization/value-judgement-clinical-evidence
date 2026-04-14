library(testthat)
library(valueJudgementCE)

test_that("prepare_tradeoff_data returns processed tradeoff table", {
  data("effects_table", package = "valueJudgementCE")

  tradeoff_data <- prepare_tradeoff_data(
    data = subset(effects_table, Trt1 == "Drug A"),
    filter = "None",
    category = "All",
    benefit = "Benefit 1",
    risk = "Risk 1",
    ci_method = "Calculated",
    cl = 0.95,
    type_risk = "Crude proportions",
    type_graph = "Absolute risk"
  )

  expect_true(is.data.frame(tradeoff_data))
  expect_true(all(
    c("benefit", "risk", "benefit_lowerCI", "risk_lowerCI") %in%
      colnames(tradeoff_data)
  ))
})

test_that("generate_tradeoff_plot returns ggplot object", {
  data("effects_table", package = "valueJudgementCE")

  args <- create_tradeoff_args_gap(subset(effects_table, Trt1 == "Drug A"))
  result <- do.call(generate_tradeoff_plot, args)

  expect_true(inherits(result, "ggplot"))
})

test_that("generate_tradeoff_plot validates free scale bounds", {
  data("effects_table", package = "valueJudgementCE")

  args <- create_tradeoff_args_gap(subset(effects_table, Trt1 == "Drug A"))
  args$lower_x <- 0.5
  args$upper_x <- 0.2

  expect_error(
    do.call(generate_tradeoff_plot, args),
    "lower limit x axis should be less than upper limit x axis"
  )
})

test_that("generate_tradeoff_plot renders with fixed scale", {
  data("effects_table", package = "valueJudgementCE")

  args <- create_tradeoff_args_gap(subset(effects_table, Trt1 == "Drug A"))
  args$type_scale <- "Fixed"
  args$lower_x <- NA_real_
  args$upper_x <- NA_real_
  args$lower_y <- NA_real_
  args$upper_y <- NA_real_

  expect_true(inherits(do.call(generate_tradeoff_plot, args), "ggplot"))
})

test_that("prepare_tradeoff_data handles supplied CI for binary outcomes", {
  df <- create_supplied_ci_effects_gap()

  for (tg in c("Absolute risk", "Relative risk", "Odds ratio")) {
    td <- prepare_tradeoff_data(
      data = df,
      filter = "None",
      category = "All",
      benefit = "Benefit 1",
      risk = "Risk 1",
      ci_method = "Supplied",
      cl = 0.95,
      type_risk = "Crude proportions",
      type_graph = tg
    )
    expect_true(is.data.frame(td))
    expect_true(nrow(td) >= 1)
    expect_true(all(
      c("benefit", "risk", "benefit_lowerCI", "risk_lowerCI") %in%
        colnames(td)
    ))
  }
})

test_that("prepare_tradeoff_data handles supplied CI for continuous benefit", {
  df <- create_supplied_ci_effects_gap()

  td <- prepare_tradeoff_data(
    data = df,
    filter = "None",
    category = "All",
    benefit = "Benefit 2",
    risk = "Risk 1",
    ci_method = "Supplied",
    cl = 0.95,
    type_risk = "Crude proportions",
    type_graph = "Absolute risk"
  )

  expect_true(is.data.frame(td))
  expect_true("benefit" %in% colnames(td))
})

test_that("prepare_tradeoff_data handles exposure-adjusted rates", {
  df <- create_supplied_ci_effects_gap()

  for (meth in c("Calculated", "Supplied")) {
    td <- prepare_tradeoff_data(
      data = df,
      filter = "None",
      category = "All",
      benefit = "Benefit 1",
      risk = "Risk 2",
      ci_method = meth,
      cl = 0.95,
      type_risk = "Exposure-adjusted rates (per 100 PYs)",
      type_graph = "Absolute risk"
    )
    expect_true(is.data.frame(td))
    expect_true("risk" %in% colnames(td))
  }
})

test_that("prepare_tradeoff_data handles subgroup filter and category", {
  df <- create_subgroup_effects_gap()

  td <- prepare_tradeoff_data(
    data = df,
    filter = "Sex",
    category = c("Male", "Female"),
    benefit = "Benefit 1",
    risk = "Risk 1",
    ci_method = "Calculated",
    cl = 0.95,
    type_risk = "Crude proportions",
    type_graph = "Absolute risk"
  )

  expect_true(is.data.frame(td))
  expect_true("category" %in% tolower(colnames(td)) ||
    any(grepl("ategory", colnames(td))))
  expect_true(nrow(td) >= 2)
})

test_that("generate_tradeoff_plot renders subgroup plot without CI", {
  df <- create_subgroup_effects_gap()

  args <- create_tradeoff_args_gap(df)
  args$filter <- "Sex"
  args$category <- c("Male", "Female")
  args$ci <- "No"

  expect_true(inherits(do.call(generate_tradeoff_plot, args), "ggplot"))
})
