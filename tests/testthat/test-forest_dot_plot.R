testthat::test_that("create_forest_dot_plot returns patchwork object", {
  test_data <- data.frame(
    Outcome = rep(c("Benefit 1", "Benefit 2"), each = 2),
    Type = rep("Continuous", 4),
    Factor = rep("Benefit", 4),
    Trt1 = rep("Drug A", 4),
    Trt2 = rep("Placebo", 4),
    Filter = rep("None", 4),
    Mean1 = c(0.6, 0.55, 0.45, 0.43),
    Mean2 = c(0.4, 0.5, 0.3, 0.33),
    Sd1 = c(0.1, 0.1, 0.12, 0.11),
    Sd2 = c(0.1, 0.1, 0.11, 0.12),
    N1 = c(100, 100, 80, 80),
    N2 = c(100, 100, 80, 80)
  )

  test_data_bin <- data.frame(
    Outcome = c("Risk 1", "Risk 2"),
    Type = rep("Binary", 2),
    Factor = rep("Risk", 2),
    Trt1 = rep("Drug A", 2),
    Trt2 = rep("Placebo", 2),
    Filter = rep("None", 2),
    Prop1 = c(0.10, 0.05),
    Prop2 = c(0.15, 0.08),
    N1 = c(100, 100),
    N2 = c(100, 100)
  )

  full_data <- dplyr::bind_rows(test_data, test_data_bin)

  # Prepare the data using the package function
  prepared <- brpubVJCE::prepare_forest_dot_data(full_data)

  # Use outcomes_with_thresholds with explicit directions instead of direction parameter
  outcomes_with_thresholds <- list(
    "Benefit 1" = list(threshold = 0.10, direction = "greater"),
    "Benefit 2" = list(threshold = 0.08, direction = "greater"),
    "Risk 1" = list(threshold = -0.05, direction = "less"),
    "Risk 2" = list(threshold = -0.03, direction = "less")
  )

  # Create the plot with the correct parameter
  plot <- brpubVJCE::create_forest_dot_plot(prepared, outcomes_with_thresholds = outcomes_with_thresholds)

  testthat::expect_s3_class(plot, "patchwork")
})

