library(testthat)
library(valueJudgementCE)

test_that("CI helpers return data frames with expected columns", {
  diff_bin <- calculate_diff_bin(0.45, 0.25, 500, 500)
  log_rr <- calculate_log_rel_risk_bin(0.45, 0.25, 500, 500)
  rr <- calculate_rel_risk_bin(0.45, 0.25, 500, 500)
  log_or <- calculate_log_odds_ratio_bin(0.45, 0.25, 500, 500)
  or_df <- calculate_odds_ratio_bin(0.45, 0.25, 500, 500)
  diff_con <- calculate_diff_con(0.6, 0.5, 0.1, 0.3, 400, 500)
  diff_rate <- calculate_diff_rates(152.17, 65.21, 230, 230)

  expect_named(diff_bin, c("diff", "se", "lower", "upper"))
  expect_named(log_rr, c("diff", "se", "lower", "upper"))
  expect_named(rr, c("rr", "se", "lower", "upper"))
  expect_named(log_or, c("diff", "se", "lower", "upper"))
  expect_named(or_df, c("or", "se", "lower", "upper"))
  expect_named(diff_con, c("diff", "se", "lower", "upper"))
  expect_named(diff_rate, c("diff", "se", "lower", "upper"))
})

test_that("ratio CI helpers validate zero comparator risk", {
  expect_error(
    calculate_rel_risk_bin(0.45, 0, 500, 500),
    "Proportion of cases in comparator treatment equal to 0"
  )

  expect_error(
    calculate_odds_ratio_bin(0.45, 0, 500, 500),
    "Proportion of cases in comparator treatment equal to 0"
  )
})

test_that("log-scale CI helpers convert non-finite values to NA", {
  result_rr <- calculate_log_rel_risk_bin(0, 0.25, 500, 500)
  result_or <- calculate_log_odds_ratio_bin(1, 0.25, 500, 500)

  expect_true(is.na(result_rr$diff))
  expect_true(is.na(result_or$diff))
})

test_that("check_feature and check_feature_string report validation issues", {
  df_missing <- data.frame(Value = c(1, 2, 3))
  expect_match(
    check_feature(
      data = df_missing,
      feature = "Factor",
      plots = "tradeoff",
      func = is.character
    ),
    "Feature <b>Factor</b> is missing"
  )

  df_range <- data.frame(Prop1 = c(0.1, 1.2))
  expect_match(
    check_feature_string(
      data = df_range,
      feature = "Prop1",
      plots = "tradeoff",
      func = is.numeric,
      check_range = c(0, 1)
    ),
    "Feature Prop1 must be between"
  )

  df_positive <- data.frame(N1 = c(1L, -2L))
  expect_match(
    check_feature_string(
      data = df_positive,
      feature = "N1",
      plots = "tradeoff",
      func = is.integer,
      check_positive = TRUE
    ),
    "Feature N1 must be positive"
  )
})

test_that("check_effects_table returns HTML summary", {
  data("brdata", package = "valueJudgementCE")

  result <- check_effects_table(brdata)

  expect_true(is.character(result))
  expect_match(result, "<ol>", fixed = TRUE)
})
