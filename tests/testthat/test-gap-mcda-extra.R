library(testthat)
library(valueJudgementCE)

test_that("create_mcda_waterfall validates missing data and criteria", {
  expect_warning(
    result <- create_mcda_waterfall(data = NULL),
    "No data provided"
  )
  expect_null(result)

  expect_error(
    create_mcda_waterfall(
      data = create_sample_mcda_data_gap(),
      benefit_criteria = NULL,
      risk_criteria = c("Risk 1")
    ),
    "Both benefit_criteria and risk_criteria must be specified"
  )
})

test_that("create_mcda_waterfall returns ggplot object", {
  data("mcda_data", package = "valueJudgementCE")

  result <- create_mcda_waterfall(
    data = mcda_data,
    comparator_name = "Placebo",
    benefit_criteria = c("Benefit 1", "Benefit 2", "Benefit 3"),
    risk_criteria = c("Risk 1", "Risk 2"),
    clinical_scales = create_sample_clinical_scales_gap()
  )

  expect_true(inherits(result, "ggplot"))
})

test_that("create_mcda_brmap validates missing data and returns ggplot", {
  expect_warning(
    result <- create_mcda_brmap(data = NULL),
    "No data provided"
  )
  expect_null(result)

  data("mcda_data", package = "valueJudgementCE")

  result <- create_mcda_brmap(
    data = mcda_data,
    comparator_name = "Placebo",
    benefit_criteria = c("Benefit 1", "Benefit 2", "Benefit 3"),
    risk_criteria = c("Risk 1", "Risk 2"),
    clinical_scales = create_sample_clinical_scales_gap(),
    show_title = TRUE,
    show_subtitle = TRUE
  )

  expect_true(inherits(result, "ggplot"))
})

test_that("mcda_tornado returns patchwork and validates weight type", {
  data("mcda_data", package = "valueJudgementCE")

  tornado <- mcda_tornado(
    data = mcda_data |>
      dplyr::filter(Study == "Study 1") |>
      dplyr::select(-Study),
    comparison_drug = "Drug A",
    clinical_scales = create_sample_clinical_scales_gap(),
    weights = create_sample_weights_gap()
  )

  expect_true(inherits(tornado, "patchwork"))

  expect_error(
    mcda_tornado(
      data = create_sample_mcda_data_gap(),
      comparison_drug = "Drug A",
      clinical_scales = create_sample_clinical_scales_gap(),
      weights = stats::weights
    ),
    "`weights` must be a named numeric vector"
  )
})
