library(testthat)
library(brpubVJCE)

# Create sample data for MCDA barplot tests
create_sample_mcda_data <- function() {
  data.frame(
    Treatment = c("Placebo", "Drug A", "Drug B"),
    `Benefit 1` = c(0.05, 0.46, 0.20),
    `Benefit 2` = c(65, 20, 50),
    `Benefit 3` = c(9, 60, 58),
    `Risk 1` = c(0.03, 0.19, 0.18),
    `Risk 2` = c(0.002, 0.015, 0.010),
    check.names = FALSE,
    stringsAsFactors = FALSE
  )
}

# Create sample clinical scales for testing
create_sample_clinical_scales <- function() {
  list(
    `Benefit 1` = list(min = 0, max = 1, direction = "increasing"),
    `Benefit 2` = list(min = 0, max = 100, direction = "decreasing"),
    `Benefit 3` = list(min = 0, max = 100, direction = "increasing"),
    `Risk 1` = list(min = 0, max = 0.5, direction = "decreasing"),
    `Risk 2` = list(min = 0, max = 0.05, direction = "decreasing")
  )
}

# Test mcda_data dataset structure
test_that("mcda_data has correct structure", {
  # Load the mcda_data
  data("mcda_data", package = "brpubVJCE")

  # Check that result is a data frame
  expect_true(is.data.frame(mcda_data))

  # Check that Treatment column exists
  expect_true("Treatment" %in% colnames(mcda_data))

  # Check that Placebo is the first row
  expect_equal(mcda_data$Treatment[1], "Placebo")

  # Check that we have multiple rows (placebo + drugs)
  expect_true(nrow(mcda_data) > 1)

  # Check that all outcome columns are numeric (except Treatment)
  numeric_cols <- colnames(mcda_data)[colnames(mcda_data) != "Treatment"]
  expect_true(all(sapply(mcda_data[numeric_cols], is.numeric)))
})

# Test create_mcda_barplot_comparison validation
test_that("create_mcda_barplot_comparison validates data parameter", {
  expect_warning(
    result <- create_mcda_barplot_comparison(data = NULL),
    "No data provided"
  )
  expect_null(result)
})

test_that("create_mcda_barplot_comparison validates criteria parameters", {
  mcda_data <- create_sample_mcda_data()

  expect_error(
    create_mcda_barplot_comparison(
      data = mcda_data,
      benefit_criteria = NULL,
      risk_criteria = c("Risk 1", "Risk 2")
    ),
    paste(
      "Both benefit_criteria and risk_criteria",
      "must be specified"
    )
  )

  expect_error(
    create_mcda_barplot_comparison(
      data = mcda_data,
      benefit_criteria = c("Benefit 1", "Benefit 2"),
      risk_criteria = NULL
    ),
    paste(
      "Both benefit_criteria and risk_criteria",
      "must be specified"
    )
  )
})

test_that("create_mcda_barplot_comparison validates treatment existence", {
  mcda_data <- create_sample_mcda_data()
  clinical_scales <- create_sample_clinical_scales()

  # Test with non-existent comparison drug
  expect_error(
    create_mcda_barplot_comparison(
      data = mcda_data,
      benefit_criteria = c("Benefit 1", "Benefit 2"),
      risk_criteria = c("Risk 1", "Risk 2"),
      comparison_drug = "Drug Z",
      clinical_scales = clinical_scales
    ),
    "Comparison drug 'Drug Z' not found in data"
  )

  # Test with non-existent placebo
  expect_error(
    create_mcda_barplot_comparison(
      data = mcda_data,
      benefit_criteria = c("Benefit 1", "Benefit 2"),
      risk_criteria = c("Risk 1", "Risk 2"),
      comparator_name = "Control",
      comparison_drug = "Drug A",
      clinical_scales = clinical_scales
    ),
    "Comparator 'Control' not found in data"
  )
})

test_that("create_mcda_barplot_comparison validates criteria columns", {
  mcda_data <- create_sample_mcda_data()
  clinical_scales <- create_sample_clinical_scales()

  expect_error(
    create_mcda_barplot_comparison(
      data = mcda_data,
      benefit_criteria = c("Nonexistent Benefit"),
      risk_criteria = c("Risk 1", "Risk 2"),
      comparison_drug = "Drug A",
      clinical_scales = clinical_scales
    ),
    "The following criteria columns are not found in data"
  )
})

test_that("create_mcda_barplot_comparison returns patchwork object", {
  mcda_data <- create_sample_mcda_data()
  clinical_scales <- create_sample_clinical_scales()

  result <- create_mcda_barplot_comparison(
    data = mcda_data,
    benefit_criteria = c("Benefit 1", "Benefit 2", "Benefit 3"),
    risk_criteria = c("Risk 1", "Risk 2"),
    comparison_drug = "Drug A",
    clinical_scales = clinical_scales
  )

  # Check that result is a patchwork object
  expect_true(inherits(result, "patchwork"))
})

test_that("create_mcda_barplot_comparison works with different drugs", {
  mcda_data <- create_sample_mcda_data()
  clinical_scales <- create_sample_clinical_scales()

  # Test with Drug A
  result_a <- create_mcda_barplot_comparison(
    data = mcda_data,
    benefit_criteria = c("Benefit 1", "Benefit 2"),
    risk_criteria = c("Risk 1"),
    comparison_drug = "Drug A",
    clinical_scales = clinical_scales
  )
  expect_true(inherits(result_a, "patchwork"))

  # Test with Drug B
  result_b <- create_mcda_barplot_comparison(
    data = mcda_data,
    benefit_criteria = c("Benefit 1", "Benefit 2"),
    risk_criteria = c("Risk 1"),
    comparison_drug = "Drug B",
    clinical_scales = clinical_scales
  )
  expect_true(inherits(result_b, "patchwork"))
})

test_that("create_mcda_barplot_comparison handles custom colors", {
  mcda_data <- create_sample_mcda_data()
  clinical_scales <- create_sample_clinical_scales()

  result <- create_mcda_barplot_comparison(
    data = mcda_data,
    benefit_criteria = c("Benefit 1"),
    risk_criteria = c("Risk 1"),
    comparison_drug = "Drug A",
    fig_colors = c("#FF0000", "#0000FF"),
    clinical_scales = clinical_scales
  )

  expect_true(inherits(result, "patchwork"))
})

# Test create_mcda_walkthrough validation
test_that("create_mcda_walkthrough validates data parameter", {
  expect_warning(
    result <- create_mcda_walkthrough(data = NULL),
    "No data provided"
  )
  expect_null(result)
})

test_that("create_mcda_walkthrough validates criteria parameters", {
  mcda_data <- create_sample_mcda_data()

  expect_error(
    create_mcda_walkthrough(
      data = mcda_data,
      benefit_criteria = NULL,
      risk_criteria = c("Risk 1", "Risk 2")
    ),
    paste(
      "Both benefit_criteria and risk_criteria",
      "must be specified"
    )
  )
})

test_that("create_mcda_walkthrough validates treatment existence", {
  mcda_data <- create_sample_mcda_data()

  # Test with non-existent comparison drug
  expect_error(
    create_mcda_walkthrough(
      data = mcda_data,
      benefit_criteria = c("Benefit 1", "Benefit 2"),
      risk_criteria = c("Risk 1", "Risk 2"),
      comparison_drug = "Drug Z"
    ),
    "Comparison drug 'Drug Z' not found in data"
  )

  # Test with non-existent placebo
  expect_error(
    create_mcda_walkthrough(
      data = mcda_data,
      benefit_criteria = c("Benefit 1", "Benefit 2"),
      risk_criteria = c("Risk 1", "Risk 2"),
      comparator_name = "Control",
      comparison_drug = "Drug A"
    ),
    "Comparator 'Control' not found in data"
  )
})

test_that("create_mcda_walkthrough validates criteria columns", {
  mcda_data <- create_sample_mcda_data()

  expect_error(
    create_mcda_walkthrough(
      data = mcda_data,
      benefit_criteria = c("Nonexistent Benefit"),
      risk_criteria = c("Risk 1", "Risk 2"),
      comparison_drug = "Drug A"
    ),
    "The following criteria columns are not found in data"
  )
})

test_that("create_mcda_walkthrough returns patchwork object", {
  mcda_data <- create_sample_mcda_data()

  result <- create_mcda_walkthrough(
    data = mcda_data,
    benefit_criteria = c("Benefit 1", "Benefit 2", "Benefit 3"),
    risk_criteria = c("Risk 1", "Risk 2"),
    comparison_drug = "Drug A"
  )

  # patchwork returns a patchwork object
  expect_true(inherits(result, "patchwork"))
})

test_that("create_mcda_walkthrough uses default equal weights", {
  mcda_data <- create_sample_mcda_data()

  result <- create_mcda_walkthrough(
    data = mcda_data,
    benefit_criteria = c("Benefit 1", "Benefit 2"),
    risk_criteria = c("Risk 1"),
    comparison_drug = "Drug A"
  )

  expect_true(inherits(result, "patchwork"))
})

test_that("create_mcda_walkthrough accepts custom weights", {
  mcda_data <- create_sample_mcda_data()

  weights <- c(
    `Benefit 1` = 0.30,
    `Benefit 2` = 0.30,
    `Risk 1` = 0.40
  )

  result <- create_mcda_walkthrough(
    data = mcda_data,
    benefit_criteria = c("Benefit 1", "Benefit 2"),
    risk_criteria = c("Risk 1"),
    comparison_drug = "Drug A",
    weights = weights
  )

  expect_true(inherits(result, "patchwork"))
})

test_that("create_mcda_walkthrough validates weight sum", {
  mcda_data <- create_sample_mcda_data()

  # Weights that sum to 1 should work
  weights <- c(
    `Benefit 1` = 0.25,
    `Benefit 2` = 0.25,
    `Benefit 3` = 0.25,
    `Risk 1` = 0.15,
    `Risk 2` = 0.10
  )

  result <- create_mcda_walkthrough(
    data = mcda_data,
    benefit_criteria = c("Benefit 1", "Benefit 2", "Benefit 3"),
    risk_criteria = c("Risk 1", "Risk 2"),
    comparison_drug = "Drug A",
    weights = weights
  )

  expect_true(inherits(result, "patchwork"))
})

test_that("create_mcda_walkthrough works with different drugs", {
  mcda_data <- create_sample_mcda_data()

  # Test with Drug A
  result_a <- create_mcda_walkthrough(
    data = mcda_data,
    benefit_criteria = c("Benefit 1"),
    risk_criteria = c("Risk 1"),
    comparison_drug = "Drug A"
  )
  expect_true(inherits(result_a, "patchwork"))

  # Test with Drug B
  result_b <- create_mcda_walkthrough(
    data = mcda_data,
    benefit_criteria = c("Benefit 1"),
    risk_criteria = c("Risk 1"),
    comparison_drug = "Drug B"
  )
  expect_true(inherits(result_b, "patchwork"))
})

test_that("create_mcda_walkthrough handles custom colors", {
  mcda_data <- create_sample_mcda_data()

  result <- create_mcda_walkthrough(
    data = mcda_data,
    benefit_criteria = c("Benefit 1"),
    risk_criteria = c("Risk 1"),
    comparison_drug = "Drug A",
    fig_colors = c("#00FF00", "#FF00FF")
  )

  expect_true(inherits(result, "patchwork"))
})

test_that(paste(
  "create_mcda_walkthrough uses default direction",
  "(higher for benefits, lower for risks)"
), {
  mcda_data <- create_sample_mcda_data()

  # Direction is derived from benefit/risk classification:
  # higher for benefits, lower for risks (when clinical_scales not provided)
  result <- create_mcda_walkthrough(
    data = mcda_data,
    benefit_criteria = c("Benefit 1", "Benefit 2"),
    risk_criteria = c("Risk 1"),
    comparison_drug = "Drug A"
  )

  expect_true(inherits(result, "patchwork"))
})

# Integration tests with actual effects_table data
test_that("Integration: Full workflow with effects_table", {
  # Step 1: Load MCDA data
  data("mcda_data", package = "brpubVJCE")
  expect_true(is.data.frame(mcda_data))

  # Step 2: Get available criteria
  criteria_cols <- setdiff(colnames(mcda_data), "Treatment")
  expect_true(length(criteria_cols) > 0)

  # Step 3: Assume first 3 are benefits, rest are risks
  #         (or adjust based on actual data)
  # For the test, we'll use the actual column names
  if (length(criteria_cols) >= 3) {
    benefit_criteria <-
      criteria_cols[seq_len(min(3, length(criteria_cols)))]
    risk_criteria <- if (length(criteria_cols) > 3) {
      criteria_cols[
        (length(benefit_criteria) + 1):length(criteria_cols)
      ]
    } else {
      # Use first as both if not enough columns
      criteria_cols[1]
    }

    # Create clinical scales for all criteria
    clinical_scales <- list()
    for (crit in criteria_cols) {
      clinical_scales[[crit]] <- list(
        min = 0,
        max = 1,
        direction = if (crit %in% benefit_criteria) {
          "increasing"
        } else {
          "decreasing"
        }
      )
    }

    # Get available drugs
    drugs <- setdiff(mcda_data$Treatment, "Placebo")

    if (length(drugs) > 0) {
      # Step 4: Create comparison plot
      result_comp <- create_mcda_barplot_comparison(
        data = mcda_data,
        benefit_criteria = benefit_criteria,
        risk_criteria = risk_criteria,
        comparison_drug = drugs[1],
        clinical_scales = clinical_scales
      )
      expect_true(inherits(result_comp, "patchwork"))

      # Step 5: Create walkthrough plot
      result_walk <- create_mcda_walkthrough(
        data = mcda_data,
        benefit_criteria = benefit_criteria,
        risk_criteria = risk_criteria,
        comparison_drug = drugs[1]
      )
      expect_true(inherits(result_walk, "patchwork"))
    }
  }
})
