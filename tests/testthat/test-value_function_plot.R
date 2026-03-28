library(testthat)
library(valueJudgementCE)

# Helper function to create sample clinical scales
create_sample_clinical_scales <- function() {
  list(
    `Benefit 1` = list(min = 0, max = 1, direction = "increasing"),
    `Benefit 2` = list(min = 0, max = 100, direction = "decreasing"),
    `Benefit 3` = list(min = 0, max = 100, direction = "increasing"),
    `Risk 1` = list(min = 0, max = 0.5, direction = "decreasing"),
    `Risk 2` = list(min = 0, max = 0.3, direction = "decreasing")
  )
}

# Tests for create_value_function_plot
test_that("create_value_function_plot validates required parameters", {
  expect_error(
    create_value_function_plot(
      criterion_name = NULL,
      min_val = 0,
      max_val = 100,
      direction = "increasing"
    ),
    "criterion_name is required"
  )

  expect_error(
    create_value_function_plot(
      criterion_name = "Test",
      min_val = NULL,
      max_val = 100,
      direction = "increasing"
    ),
    "Both min_val and max_val are required"
  )

  expect_error(
    create_value_function_plot(
      criterion_name = "Test",
      min_val = 0,
      max_val = 100,
      direction = NULL
    ),
    "direction is required"
  )
})

test_that("create_value_function_plot validates direction parameter", {
  expect_error(
    create_value_function_plot(
      criterion_name = "Test",
      min_val = 0,
      max_val = 100,
      direction = "invalid"
    ),
    "direction must be either 'increasing' or 'decreasing'"
  )
})

test_that("create_value_function_plot validates min_val < max_val", {
  expect_error(
    create_value_function_plot(
      criterion_name = "Test",
      min_val = 100,
      max_val = 0,
      direction = "increasing"
    ),
    "min_val must be less than max_val"
  )

  expect_error(
    create_value_function_plot(
      criterion_name = "Test",
      min_val = 50,
      max_val = 50,
      direction = "increasing"
    ),
    "min_val must be less than max_val"
  )
})

test_that("create_value_function_plot returns ggplot object for increasing", {
  result <- create_value_function_plot(
    criterion_name = "Efficacy",
    min_val = 0,
    max_val = 100,
    direction = "increasing"
  )

  expect_true(inherits(result, "ggplot"))
})

test_that("create_value_function_plot returns ggplot object for decreasing", {
  result <- create_value_function_plot(
    criterion_name = "Adverse Events",
    min_val = 0,
    max_val = 50,
    direction = "decreasing"
  )

  expect_true(inherits(result, "ggplot"))
})

test_that("create_value_function_plot handles custom color", {
  result <- create_value_function_plot(
    criterion_name = "Test",
    min_val = 0,
    max_val = 100,
    direction = "increasing",
    color = "#FF0000"
  )

  expect_true(inherits(result, "ggplot"))
})

test_that("create_value_function_plot handles show_title parameter", {
  result_with_title <- create_value_function_plot(
    criterion_name = "Test",
    min_val = 0,
    max_val = 100,
    direction = "increasing",
    show_title = TRUE
  )

  result_without_title <- create_value_function_plot(
    criterion_name = "Test",
    min_val = 0,
    max_val = 100,
    direction = "increasing",
    show_title = FALSE
  )

  expect_true(inherits(result_with_title, "ggplot"))
  expect_true(inherits(result_without_title, "ggplot"))
})

test_that("create_value_function_plot handles show_reference_line parameter", {
  result_with_line <- create_value_function_plot(
    criterion_name = "Test",
    min_val = 0,
    max_val = 100,
    direction = "increasing",
    show_reference_line = TRUE
  )

  result_without_line <- create_value_function_plot(
    criterion_name = "Test",
    min_val = 0,
    max_val = 100,
    direction = "increasing",
    show_reference_line = FALSE
  )

  expect_true(inherits(result_with_line, "ggplot"))
  expect_true(inherits(result_without_line, "ggplot"))
})

test_that("create_value_function_plot handles custom labels", {
  result <- create_value_function_plot(
    criterion_name = "Test",
    min_val = 0,
    max_val = 100,
    direction = "increasing",
    x_label = "Custom X Label",
    y_label = "Custom Y Label"
  )

  expect_true(inherits(result, "ggplot"))
})

test_that("create_value_function_plot handles different ranges", {
  # Small range
  result_small <- create_value_function_plot(
    criterion_name = "Test",
    min_val = 0,
    max_val = 1,
    direction = "increasing"
  )

  # Large range
  result_large <- create_value_function_plot(
    criterion_name = "Test",
    min_val = 0,
    max_val = 10000,
    direction = "increasing"
  )

  # Negative to positive range
  result_negative <- create_value_function_plot(
    criterion_name = "Test",
    min_val = -100,
    max_val = 100,
    direction = "increasing"
  )

  expect_true(inherits(result_small, "ggplot"))
  expect_true(inherits(result_large, "ggplot"))
  expect_true(inherits(result_negative, "ggplot"))
})

# Tests for compare_value_functions
test_that("compare_value_functions returns patchwork object", {
  result <- compare_value_functions()

  expect_true(inherits(result, "patchwork"))
})

test_that("compare_value_functions handles custom parameters", {
  result <- compare_value_functions(
    benefit_name = "Custom Benefit",
    benefit_min = 0,
    benefit_max = 50,
    benefit_label = "Custom Benefit Label",
    risk_name = "Custom Risk",
    risk_min = 0,
    risk_max = 25,
    risk_label = "Custom Risk Label"
  )

  expect_true(inherits(result, "patchwork"))
})

test_that("compare_value_functions handles show_titles parameter", {
  result_with_titles <- compare_value_functions(show_titles = TRUE)
  result_without_titles <- compare_value_functions(show_titles = FALSE)

  expect_true(inherits(result_with_titles, "patchwork"))
  expect_true(inherits(result_without_titles, "patchwork"))
})

test_that("compare_value_functions handles show_reference_lines parameter", {
  result_with_lines <- compare_value_functions(show_reference_lines = TRUE)
  result_without_lines <- compare_value_functions(show_reference_lines = FALSE)

  expect_true(inherits(result_with_lines, "patchwork"))
  expect_true(inherits(result_without_lines, "patchwork"))
})

test_that("compare_value_functions handles different ranges", {
  result <- compare_value_functions(
    benefit_min = 10,
    benefit_max = 90,
    risk_min = 5,
    risk_max = 45
  )

  expect_true(inherits(result, "patchwork"))
})

# Tests for plot_multiple_value_functions
test_that("plot_multiple_value_functions validates clinical_scales parameter", {
  expect_error(
    plot_multiple_value_functions(clinical_scales = NULL),
    "clinical_scales is required"
  )
})

test_that("plot_multiple_value_functions validates criteria exist", {
  clinical_scales <- create_sample_clinical_scales()

  expect_error(
    plot_multiple_value_functions(
      clinical_scales = clinical_scales,
      criteria = c("Nonexistent Criterion")
    ),
    "The following criteria are not found in clinical_scales"
  )
})

test_that("plot_multiple_value_functions returns patchwork object", {
  clinical_scales <- create_sample_clinical_scales()

  result <- plot_multiple_value_functions(
    clinical_scales = clinical_scales
  )

  expect_true(inherits(result, "patchwork"))
})

test_that("plot_multiple_value_functions handles specific criteria", {
  clinical_scales <- create_sample_clinical_scales()

  result <- plot_multiple_value_functions(
    clinical_scales = clinical_scales,
    criteria = c("Benefit 1", "Risk 1")
  )

  expect_true(inherits(result, "patchwork"))
})

test_that("plot_multiple_value_functions handles ncol parameter", {
  clinical_scales <- create_sample_clinical_scales()

  result_2col <- plot_multiple_value_functions(
    clinical_scales = clinical_scales,
    ncol = 2
  )

  result_3col <- plot_multiple_value_functions(
    clinical_scales = clinical_scales,
    ncol = 3
  )

  expect_true(inherits(result_2col, "patchwork"))
  expect_true(inherits(result_3col, "patchwork"))
})

test_that("plot_multiple_value_functions handles show_titles parameter", {
  clinical_scales <- create_sample_clinical_scales()

  result_with_titles <- plot_multiple_value_functions(
    clinical_scales = clinical_scales,
    show_titles = TRUE
  )

  result_without_titles <- plot_multiple_value_functions(
    clinical_scales = clinical_scales,
    show_titles = FALSE
  )

  expect_true(inherits(result_with_titles, "patchwork"))
  expect_true(inherits(result_without_titles, "patchwork"))
})

test_that("plot_multiple_value_functions handles show_reference_lines", {
  clinical_scales <- create_sample_clinical_scales()

  result_with_lines <- plot_multiple_value_functions(
    clinical_scales = clinical_scales,
    show_reference_lines = TRUE
  )

  result_without_lines <- plot_multiple_value_functions(
    clinical_scales = clinical_scales,
    show_reference_lines = FALSE
  )

  expect_true(inherits(result_with_lines, "patchwork"))
  expect_true(inherits(result_without_lines, "patchwork"))
})

test_that("plot_multiple_value_functions skips invalid scales", {
  clinical_scales <- list(
    `Valid Criterion` = list(min = 0, max = 100, direction = "increasing"),
    `Invalid Criterion` = list(min = 0)  # Missing max and direction
  )

  expect_warning(
    result <- plot_multiple_value_functions(
      clinical_scales = clinical_scales
    ),
    "Skipping criterion 'Invalid Criterion'"
  )

  # Should still create plot for valid criterion
  expect_true(inherits(result, "patchwork"))
})

test_that("plot_multiple_value_functions handles both directions", {
  clinical_scales <- list(
    `Increasing` = list(min = 0, max = 100, direction = "increasing"),
    `Decreasing` = list(min = 0, max = 50, direction = "decreasing")
  )

  result <- plot_multiple_value_functions(
    clinical_scales = clinical_scales
  )

  expect_true(inherits(result, "patchwork"))
})

# Integration tests
test_that("Integration: Full workflow with example data", {
  # Load example MCDA data
  data("mcda_data", package = "valueJudgementCE")

  # Define clinical scales
  clinical_scales <- list(
    `Benefit 1` = list(min = 0, max = 1, direction = "increasing"),
    `Benefit 2` = list(min = 0, max = 100, direction = "decreasing"),
    `Benefit 3` = list(min = 0, max = 100, direction = "increasing"),
    `Risk 1` = list(min = 0, max = 0.5, direction = "decreasing"),
    `Risk 2` = list(min = 0, max = 0.3, direction = "decreasing")
  )

  # Test single value function plot
  single_plot <- create_value_function_plot(
    criterion_name = "Benefit 1",
    min_val = 0,
    max_val = 1,
    direction = "increasing"
  )
  expect_true(inherits(single_plot, "ggplot"))

  # Test comparison plot
  comparison_plot <- compare_value_functions(
    benefit_name = "Efficacy",
    benefit_min = 0,
    benefit_max = 100,
    risk_name = "Adverse Events",
    risk_min = 0,
    risk_max = 50
  )
  expect_true(inherits(comparison_plot, "patchwork"))

  # Test multiple value functions
  multiple_plot <- plot_multiple_value_functions(
    clinical_scales = clinical_scales
  )
  expect_true(inherits(multiple_plot, "patchwork"))

  # Test with subset of criteria
  subset_plot <- plot_multiple_value_functions(
    clinical_scales = clinical_scales,
    criteria = c("Benefit 1", "Risk 1", "Risk 2"),
    ncol = 3
  )
  expect_true(inherits(subset_plot, "patchwork"))
})

test_that("Value function calculations are correct", {
  # Test increasing direction at min, mid, max
  plot_increasing <- create_value_function_plot(
    criterion_name = "Test",
    min_val = 0,
    max_val = 100,
    direction = "increasing"
  )

  # Test decreasing direction
  plot_decreasing <- create_value_function_plot(
    criterion_name = "Test",
    min_val = 0,
    max_val = 100,
    direction = "decreasing"
  )

  expect_true(inherits(plot_increasing, "ggplot"))
  expect_true(inherits(plot_decreasing, "ggplot"))

  # Extract data from plots to verify calculations
  data_increasing <- plot_increasing$data
  data_decreasing <- plot_decreasing$data

  # Check that values are in 0-100 range
  expect_true(all(data_increasing$value >= 0 & data_increasing$value <= 100))
  expect_true(all(data_decreasing$value >= 0 & data_decreasing$value <= 100))

  # Check that min x maps to 0 for increasing
  min_idx_inc <- which.min(data_increasing$x)
  expect_equal(data_increasing$value[min_idx_inc], 0, tolerance = 0.1)

  # Check that max x maps to 100 for increasing
  max_idx_inc <- which.max(data_increasing$x)
  expect_equal(data_increasing$value[max_idx_inc], 100, tolerance = 0.1)

  # Check that min x maps to 100 for decreasing
  min_idx_dec <- which.min(data_decreasing$x)
  expect_equal(data_decreasing$value[min_idx_dec], 100, tolerance = 0.1)

  # Check that max x maps to 0 for decreasing
  max_idx_dec <- which.max(data_decreasing$x)
  expect_equal(data_decreasing$value[max_idx_dec], 0, tolerance = 0.1)
})

# Tests for compare_value_function_types
test_that("compare_value_function_types returns patchwork object", {
  result <- compare_value_function_types()

  expect_true(inherits(result, "patchwork"))
})

test_that("compare_value_function_types handles custom parameters", {
  result <- compare_value_function_types(
    benefit_name = "Efficacy",
    benefit_min = 0,
    benefit_max = 100,
    benefit_label = "Response Rate (%)",
    risk_name = "Safety",
    risk_min = 0,
    risk_max = 50,
    risk_label = "AE Rate (%)"
  )

  expect_true(inherits(result, "patchwork"))
})

test_that("compare_value_function_types handles show_titles parameter", {
  result_with_titles <- compare_value_function_types(show_titles = TRUE)
  result_without_titles <- compare_value_function_types(show_titles = FALSE)

  expect_true(inherits(result_with_titles, "patchwork"))
  expect_true(inherits(result_without_titles, "patchwork"))
})

test_that("compare_value_function_types handles show_legend parameter", {
  result_with_legend <- compare_value_function_types(show_legend = TRUE)
  result_without_legend <- compare_value_function_types(show_legend = FALSE)

  expect_true(inherits(result_with_legend, "patchwork"))
  expect_true(inherits(result_without_legend, "patchwork"))
})

test_that("compare_value_function_types handles different power values", {
  result_power_1 <- compare_value_function_types(power = 1)
  result_power_2 <- compare_value_function_types(power = 2)
  result_power_3 <- compare_value_function_types(power = 3)

  expect_true(inherits(result_power_1, "patchwork"))
  expect_true(inherits(result_power_2, "patchwork"))
  expect_true(inherits(result_power_3, "patchwork"))
})

test_that("compare_value_function_types handles different ranges", {
  result <- compare_value_function_types(
    benefit_min = 10,
    benefit_max = 90,
    risk_min = 5,
    risk_max = 45
  )

  expect_true(inherits(result, "patchwork"))
})

test_that("compare_value_function_types handles custom n_points", {
  result_50 <- compare_value_function_types(n_points = 50)
  result_200 <- compare_value_function_types(n_points = 200)

  expect_true(inherits(result_50, "patchwork"))
  expect_true(inherits(result_200, "patchwork"))
})

# Integration test with compare_value_function_types
test_that("Integration: compare_value_function_types with realistic data", {
  # Efficacy and adverse events
  result <- compare_value_function_types(
    benefit_name = "Response Rate",
    benefit_min = 0,
    benefit_max = 100,
    benefit_label = "Response Rate (%)",
    risk_name = "Adverse Events",
    risk_min = 0,
    risk_max = 50,
    risk_label = "AE Rate (%)",
    power = 2,
    show_titles = TRUE,
    show_legend = TRUE
  )

  expect_true(inherits(result, "patchwork"))

  # Check that the plot components exist
  expect_true(length(result) > 0)
})
