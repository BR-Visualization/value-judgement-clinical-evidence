library(testthat)
library(valueJudgementCE)

create_sensitivity_data <- function() {
  data.frame(
    Treatment = c("Placebo", "Drug A", "Drug B"),
    `Primary Efficacy` = c(0.05, 0.46, 0.20),
    `Secondary Efficacy` = c(65, 20, 50),
    `Quality of Life` = c(9, 60, 58),
    `Recurring AE` = c(0.03, 0.19, 0.18),
    `Rare SAE` = c(0.002, 0.015, 0.010),
    check.names = FALSE,
    stringsAsFactors = FALSE
  )
}

create_sensitivity_scales <- function() {
  list(
    `Primary Efficacy` = list(min = 0, max = 1, direction = "increasing"),
    `Secondary Efficacy` = list(min = 0, max = 100, direction = "decreasing"),
    `Quality of Life` = list(min = 0, max = 100, direction = "increasing"),
    `Recurring AE` = list(min = 0, max = 0.5, direction = "decreasing"),
    `Rare SAE` = list(min = 0, max = 0.3, direction = "decreasing")
  )
}

create_sensitivity_weights <- function() {
  c(
    `Primary Efficacy` = 0.30,
    `Secondary Efficacy` = 0.20,
    `Quality of Life` = 0.10,
    `Recurring AE` = 0.30,
    `Rare SAE` = 0.10
  )
}

test_that("mcda_weight_sensitivity returns a ggplot with one panel per criterion", {
  p <- mcda_weight_sensitivity(
    data = create_sensitivity_data(),
    weights = create_sensitivity_weights(),
    clinical_scales = create_sensitivity_scales()
  )

  expect_s3_class(p, "ggplot")
  expect_s3_class(p$facet, "FacetWrap")
  lines <- attr(p, "sensitivity_lines")
  expect_equal(nrow(lines), 5 * 3)
  expect_no_error(ggplot2::ggplot_build(p))
})

test_that("current scores match the weighted sum at the original weights", {
  dat <- create_sensitivity_data()
  scales <- create_sensitivity_scales()
  w <- create_sensitivity_weights()

  p <- mcda_weight_sensitivity(dat, w, scales)
  lines <- attr(p, "sensitivity_lines")

  # Placebo by hand: 0.3*5 + 0.2*35 + 0.1*9 + 0.3*94 + 0.1*(100 - 0.2/0.3)
  expected_placebo <- 0.3 * 5 + 0.2 * 35 + 0.1 * 9 + 0.3 * 94 +
    0.1 * (100 * (0.3 - 0.002) / 0.3)
  placebo_scores <- lines$current_score[lines$Treatment == "Placebo"]
  expect_equal(placebo_scores, rep(expected_placebo, 5), tolerance = 1e-8)
})

test_that("line endpoints follow proportional reweighting", {
  dat <- create_sensitivity_data()
  scales <- create_sensitivity_scales()
  w <- create_sensitivity_weights()

  p <- mcda_weight_sensitivity(dat, w, scales, criteria = "Rare SAE")
  lines <- attr(p, "sensitivity_lines")
  drug_a <- lines[lines$Treatment == "Drug A", ]

  # At 100% the score is the preference value on the varied criterion
  expect_equal(drug_a$score_at_100, 100 * (0.3 - 0.015) / 0.3)

  # At 0% the other weights are rescaled to sum to 1
  others <- c(
    `Primary Efficacy` = 46, `Secondary Efficacy` = 80,
    `Quality of Life` = 60, `Recurring AE` = 62
  )
  w_others <- w[names(others)] / sum(w[names(others)])
  expect_equal(drug_a$score_at_0, sum(others * w_others))
})

test_that("crossovers are where the leading treatment changes", {
  p <- mcda_weight_sensitivity(
    data = create_sensitivity_data(),
    weights = create_sensitivity_weights(),
    clinical_scales = create_sensitivity_scales(),
    criteria = "Recurring AE"
  )
  lines <- attr(p, "sensitivity_lines")
  cross <- attr(p, "crossovers")

  expect_true(nrow(cross) >= 1)
  for (i in seq_len(nrow(cross))) {
    score_at <- function(wt) {
      lines$score_at_0 + wt * (lines$score_at_100 - lines$score_at_0)
    }
    w0 <- cross$weight[i]
    expect_equal(max(score_at(w0)), cross$score[i], tolerance = 1e-8)
    expect_equal(
      as.character(lines$Treatment[which.max(score_at(w0 - 1e-4))]),
      cross$from[i]
    )
    expect_equal(
      as.character(lines$Treatment[which.max(score_at(w0 + 1e-4))]),
      cross$to[i]
    )
  }
})

test_that("crossover and shading layers can be turned off", {
  p <- mcda_weight_sensitivity(
    data = create_sensitivity_data(),
    weights = create_sensitivity_weights(),
    clinical_scales = create_sensitivity_scales(),
    criteria = "Recurring AE",
    show_crossovers = FALSE,
    shading = "none"
  )
  expect_equal(length(p$layers), 3)

  layer_geoms <- function(plot) {
    vapply(plot$layers, function(l) class(l$geom)[1], character(1))
  }
  p_default <- mcda_weight_sensitivity(
    data = create_sensitivity_data(),
    weights = create_sensitivity_weights(),
    clinical_scales = create_sensitivity_scales(),
    criteria = "Recurring AE"
  )
  expect_true("GeomRibbon" %in% layer_geoms(p_default))
  expect_false("GeomRibbon" %in% layer_geoms(p))
})

test_that("shaded regions are where a different treatment is preferred", {
  w <- create_sensitivity_weights()
  p <- mcda_weight_sensitivity(
    data = create_sensitivity_data(),
    weights = w,
    clinical_scales = create_sensitivity_scales()
  )
  regions <- attr(p, "preferred_regions")
  lines <- attr(p, "sensitivity_lines")

  for (cr in names(w)) {
    r <- regions[regions$Criterion == cr, ]
    # Regions tile the full weight range
    expect_equal(r$weight_from[1], 0)
    expect_equal(r$weight_to[nrow(r)], 1)
    expect_equal(r$weight_from[-1], r$weight_to[-nrow(r)])

    # The region containing the current weight is never shaded
    in_current <- r$weight_from <= w[[cr]] & w[[cr]] <= r$weight_to
    expect_false(any(r$differs_from_current[in_current]))

    # Shading follows the upper envelope of the lines
    d <- lines[lines$Criterion == cr, ]
    top_at <- function(wt) {
      max(d$score_at_0 + wt * (d$score_at_100 - d$score_at_0))
    }
    expect_equal(r$score_from, vapply(r$weight_from, top_at, 1))
    expect_equal(r$score_to, vapply(r$weight_to, top_at, 1))
  }
  expect_true(any(regions$differs_from_current))
  expect_equal(regions$shaded, regions$differs_from_current)
})

test_that("hiview shading alternates bands starting from the first", {
  # Three treatments whose lead changes twice as the weight on Risk rises,
  # as in Figure 7 of Angelis and Phillips (2021)
  dat <- data.frame(
    Treatment = c("High dose", "Low dose", "Placebo"),
    Benefit = c(90, 60, 30),
    Risk = c(0, 90, 100)
  )
  scales <- list(
    Benefit = list(min = 0, max = 100, direction = "increasing"),
    Risk = list(min = 0, max = 100, direction = "increasing")
  )
  w <- c(Benefit = 0.7, Risk = 0.3)

  p <- mcda_weight_sensitivity(
    dat, w, scales, criteria = "Risk", shading = "hiview"
  )
  r <- attr(p, "preferred_regions")
  expect_equal(r$preferred, c("High dose", "Low dose", "Placebo"))
  expect_equal(r$shaded, c(TRUE, FALSE, TRUE))

  # Default shading marks the bands that differ from the current leader
  p_change <- mcda_weight_sensitivity(dat, w, scales, criteria = "Risk")
  r_change <- attr(p_change, "preferred_regions")
  expect_equal(r_change$shaded, r_change$preferred != "Low dose")
})

test_that("hiview shading leaves panels without a change unshaded", {
  p <- mcda_weight_sensitivity(
    data = create_sensitivity_data(),
    weights = create_sensitivity_weights(),
    clinical_scales = create_sensitivity_scales(),
    shading = "hiview"
  )
  r <- attr(p, "preferred_regions")
  n_bands <- table(r$Criterion)
  single <- names(n_bands)[n_bands == 1]
  expect_false(any(r$shaded[r$Criterion %in% single]))
  multi <- r[!r$Criterion %in% single, ]
  first_band <- !duplicated(multi$Criterion)
  expect_true(all(multi$shaded[first_band]))
})

test_that("shading argument is validated", {
  expect_error(
    mcda_weight_sensitivity(
      create_sensitivity_data(), create_sensitivity_weights(),
      create_sensitivity_scales(), shading = "stripes"
    ),
    "should be one of"
  )
})

test_that("works with a single study from mcda_data", {
  data("mcda_data", package = "valueJudgementCE")
  p <- mcda_weight_sensitivity(
    data = dplyr::filter(mcda_data, Study == "Study 2"),
    weights = create_sensitivity_weights(),
    clinical_scales = create_sensitivity_scales()
  )
  expect_s3_class(p, "ggplot")
  expect_true(nrow(attr(p, "crossovers")) > 0)
})

test_that("mcda_weight_sensitivity validates inputs", {
  dat <- create_sensitivity_data()
  scales <- create_sensitivity_scales()
  w <- create_sensitivity_weights()

  expect_error(
    mcda_weight_sensitivity(dat, unname(w), scales),
    "named numeric vector"
  )
  expect_error(
    mcda_weight_sensitivity(dat, w * 2, scales),
    "must sum to 1"
  )
  expect_error(
    mcda_weight_sensitivity(dat, w, "not a list"),
    "must be a named list"
  )
  expect_error(
    mcda_weight_sensitivity(dat, w, scales, criteria = "Unknown"),
    "not found in `weights`"
  )
  expect_error(
    mcda_weight_sensitivity(dat[1, ], w, scales),
    "at least two treatments"
  )

  data("mcda_data", package = "valueJudgementCE")
  expect_error(
    mcda_weight_sensitivity(mcda_data, w, scales),
    "must be unique"
  )
})
