testthat::test_that("prepare_forest_dot_data computes CIs correctly", {
  # Test data with mixed continuous and binary data structure like real data
  test_data <- data.frame(
    Outcome = c("Benefit 1", "Benefit 2", "Risk 1", "Risk 2"),
    Type = c("Continuous", "Continuous", "Binary", "Binary"),
    Factor = c("Benefit", "Benefit", "Risk", "Risk"),
    Trt1 = rep("Drug A", 4),
    Trt2 = rep("Placebo", 4),
    Filter = rep("None", 4),
    # Continuous data columns (for rows 1-2)
    Mean1 = c(0.6, 0.55, NA, NA),
    Mean2 = c(0.4, 0.5, NA, NA),
    Sd1 = c(0.1, 0.1, NA, NA),
    Sd2 = c(0.1, 0.1, NA, NA),
    # Binary data columns (for rows 3-4)
    Prop1 = c(NA, NA, 0.45, 0.43),
    Prop2 = c(NA, NA, 0.3, 0.33),
    N1 = rep(100, 4),
    N2 = rep(100, 4),
    stringsAsFactors = FALSE
  )

  result <- brpubVJCE::prepare_forest_dot_data(
    test_data,
    outcomes_of_interest = c("Benefit 1", "Benefit 2", "Risk 1", "Risk 2"),
    treatment1 = "Drug A",
    treatment2 = "Placebo",
    filter_value = "None",
    precalculated_stats = FALSE
  )

  testthat::expect_equal(nrow(result), 4)
  testthat::expect_true(all(c("Diff", "Diff_LowerCI", "Diff_UpperCI") %in%
    names(result)))
})

testthat::test_that("prepare_forest_dot_data handles binary data", {
  test_data_bin <- data.frame(
    Outcome = c("Risk 1", "Risk 2"),
    Type = rep("Binary", 2),
    Factor = rep("Risk", 2),
    Trt1 = rep("Drug A", 2),
    Trt2 = rep("Placebo", 2),
    Filter = rep("None", 2),
    Mean1 = c(NA, NA),
    Mean2 = c(NA, NA),
    Sd1 = c(NA, NA),
    Sd2 = c(NA, NA),
    Prop1 = c(0.1, 0.15),
    Prop2 = c(0.2, 0.25),
    N1 = rep(100, 2),
    N2 = rep(100, 2),
    stringsAsFactors = FALSE
  )

  result <- brpubVJCE::prepare_forest_dot_data(test_data_bin)
  testthat::expect_equal(nrow(result), 2)
})

testthat::test_that("prepare_forest_dot_data validates precalculated data", {
  test_data_bin <- data.frame(
    Outcome = c("Risk 1"),
    Type = "Binary",
    Factor = "Risk",
    Trt1 = "Drug A",
    Trt2 = "Placebo",
    Filter = "None",
    Mean1 = NA,
    Mean2 = NA,
    Sd1 = NA,
    Sd2 = NA,
    Prop1 = 0.1,
    Prop2 = 0.2,
    N1 = 100,
    N2 = 100,
    stringsAsFactors = FALSE
  )

  bad_data <- test_data_bin[, -which(names(test_data_bin) == "Prop1")]

  testthat::expect_error(
    brpubVJCE::prepare_forest_dot_data(bad_data,
      precalculated_stats = TRUE
    ),
    "Missing required precalculated columns"
  )
})

testthat::test_that("prepare_forest_dot_data works with precalculated stats", {
  test_data <- data.frame(
    Outcome = c("Benefit 1", "Benefit 2"),
    Type = rep("Continuous", 2),
    Factor = rep("Benefit", 2),
    Trt1 = rep("Drug A", 2),
    Trt2 = rep("Placebo", 2),
    Filter = rep("None", 2),
    Mean1 = c(0.6, 0.45),
    Mean2 = c(0.4, 0.3),
    Sd1 = c(0.1, 0.1),
    Sd2 = c(0.1, 0.1),
    Prop1 = c(NA, NA),
    Prop2 = c(NA, NA),
    N1 = rep(100, 2),
    N2 = rep(100, 2),
    Diff = c(0.2, 0.15),
    Diff_LowerCI = c(0.1, 0.05),
    Diff_UpperCI = c(0.3, 0.25),
    stringsAsFactors = FALSE
  )

  result <- brpubVJCE::prepare_forest_dot_data(test_data,
    precalculated_stats = TRUE
  )
  testthat::expect_equal(nrow(result), 2)
  testthat::expect_true(all(c(
    "Diff", "Diff_LowerCI",
    "Diff_UpperCI"
  ) %in% names(result)))
})
