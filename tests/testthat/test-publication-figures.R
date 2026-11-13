library(testthat)
library(valueJudgementCE)

tc_benefit <- c(0.05, 0.1, 0.15, 0.2, 0.25, 0.3, 0.35, 0.4, 0.45)
tc_risk <- c(0.09, 0.17, 0.24, 0.3, 0.35, 0.39, 0.42, 0.44, 0.45)

test_that("tradeoff_utility_plot returns ggplot with utilities", {
  data("effects_table", package = "valueJudgementCE")
  et <- effects_table[
    effects_table$Outcome %in% c("Primary Efficacy", "Recurring AE"),
  ]

  result <- suppressMessages(tradeoff_utility_plot(
    et,
    benefit = "Primary Efficacy", risk = "Recurring AE",
    mab = 0.05, mar = 0.45,
    tc_benefit = tc_benefit, tc_risk = tc_risk
  ))

  expect_true(inherits(result, "ggplot"))
  u <- attr(result, "utilities")
  expect_equal(u$treatment, c("Drug A", "Drug B", "Drug C", "Drug D"))
  # U = TC(benefit) - risk, values reported in the manuscript
  expect_equal(round(u$utility, 2), c(0.28, 0.06, 0.13, 0.10))
  expect_silent(ggplot2::ggplot_build(result))
})

test_that("tradeoff_utility_plot validates the trade-off curve", {
  data("effects_table", package = "valueJudgementCE")
  expect_error(
    tradeoff_utility_plot(
      effects_table,
      benefit = "Primary Efficacy", risk = "Recurring AE",
      mab = 0.05, mar = 0.45,
      tc_benefit = c(0.2, 0.1), tc_risk = c(0.3, 0.2)
    )
  )
})

test_that("scatter_plot publication style returns a plot", {
  data("scatterplot", package = "valueJudgementCE")

  result <- scatter_plot(
    scatterplot,
    outcome = c("Benefit", "Risk"),
    mab = 0.2,
    mar = 0.6,
    marginal_type = NULL,
    style = "publication"
  )

  expect_true(inherits(result, "ggplot"))
  expect_error(
    scatter_plot(scatterplot, c("Benefit", "Risk"), 0.2, 0.6,
                 style = "other")
  )
})

test_that("divergent_stacked_barchart fav_side flips the sides", {
  data("comp_outcome", package = "valueJudgementCE")
  favcat <- c(
    "Benefit larger than threshold, with AE",
    "Benefit larger than threshold, w/o AE"
  )
  unfavcat <- c(
    "Withdrew",
    "Benefit less than threshold, w/o AE",
    "Benefit less than threshold, with AE"
  )

  right <- divergent_stacked_barchart(
    comp_outcome, colfun()$fig12_colors, favcat, unfavcat
  )
  left <- divergent_stacked_barchart(
    comp_outcome, colfun()$fig12_colors, favcat, unfavcat,
    fav_side = "left"
  )

  fav_right <- right$data$percentage[right$data$brcat %in% favcat]
  fav_left <- left$data$percentage[left$data$brcat %in% favcat]
  expect_true(all(fav_right > 0))
  expect_true(all(fav_left < 0))
  expect_true(all(left$data$percentage[left$data$brcat %in% unfavcat] > 0))
})

test_that("cumexcess_incidence_plot uses a fixed denominator", {
  data("cumexcess", package = "valueJudgementCE")

  result <- cumexcess_incidence_plot(cumexcess, mab = 10, mar = 5)
  expect_true(inherits(result, "ggplot"))
  curves <- attr(result, "curves")
  end_ben <- tail(curves[curves$outcome == "Benefit", ], 1)
  end_risk <- tail(curves[curves$outcome == "Risk", ], 1)
  # week 36: (248 - 50) / 500 and (44 - 24) / 500, in percentage points
  expect_equal(end_ben$diff, 39.6)
  expect_equal(end_risk$diff, 4)

  step <- cumexcess_incidence_plot(cumexcess, mab = 10, mar = 5,
                                   smooth = FALSE)
  expect_true(inherits(step, "ggplot"))

  expect_error(
    cumexcess_incidence_plot(cumexcess[, c("eventtime", "n")], 10, 5),
    "missing required variable"
  )
})
