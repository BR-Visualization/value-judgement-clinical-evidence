testthat::test_that("create_forest_dot_plot returns patchwork object", {
  test_data <- data.frame(
    Outcome = rep(c("Primary Efficacy", "Secondary Efficacy"), each = 2),
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
    Outcome = c("Reoccurring AE", "Rare SAE"),
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

  # Define direction as a named vector
  directions <- c(
    "Primary Efficacy" = "greater",
    "Secondary Efficacy" = "greater",
    "Reoccurring AE" = "less",
    "Rare SAE" = "less"
  )

  # Create the plot with custom direction
  plot <- brpubVJCE::create_forest_dot_plot(prepared, direction = directions)

  testthat::expect_s3_class(plot, "patchwork")
})
