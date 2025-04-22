testthat::test_that("prepare_forest_dot_data computes CIs correctly", {
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

  result <- brpubVJCE::prepare_forest_dot_data(full_data)

  testthat::expect_true(all(c("Diff", "Diff_LowerCI", "Diff_UpperCI", "CI_color") %in% names(result)))
  testthat::expect_equal(nrow(result), 6)
  testthat::expect_type(result$Diff, "double")
})

testthat::test_that("prepare_forest_dot_data errors on missing CI columns with precalculated", {
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

  bad_data <- test_data_bin[, -which(names(test_data_bin) == "Prop1")]

  testthat::expect_error(
    brpubVJCE::prepare_forest_dot_data(bad_data, precalculated_stats = TRUE),
    "Missing required precalculated columns"
  )
})

testthat::test_that("prepare_forest_dot_data passes with precalculated columns", {
  test_data <- data.frame(
    Outcome = rep("Primary Efficacy", 2),
    Type = rep("Binary", 2),
    Factor = rep("Benefit", 2),
    Trt1 = rep("Drug A", 2),
    Trt2 = rep("Placebo", 2),
    Filter = rep("None", 2),
    Prop1 = c(0.6, 0.65),
    Prop2 = c(0.4, 0.45),
    N1 = c(100, 100),
    N2 = c(100, 100),
    Diff = c(0.2, 0.2),
    Diff_LowerCI = c(0.1, 0.1),
    Diff_UpperCI = c(0.3, 0.3)
  )

  result <- brpubVJCE::prepare_forest_dot_data(test_data, precalculated_stats = TRUE)
  testthat::expect_equal(nrow(result), 2)
  testthat::expect_true(all(c("Diff", "Diff_LowerCI", "Diff_UpperCI") %in% names(result)))
})
