## Code to prepare `clinical_scales` and `weights` datasets
## These companion objects match the mcda_data example dataset

clinical_scales <- list(
  `Benefit 1` = list(min = 0, max = 1,   direction = "increasing"),
  `Benefit 2` = list(min = 0, max = 100, direction = "decreasing"),
  `Benefit 3` = list(min = 0, max = 100, direction = "increasing"),
  `Risk 1`    = list(min = 0, max = 0.5, direction = "decreasing"),
  `Risk 2`    = list(min = 0, max = 0.3, direction = "decreasing")
)

weights <- c(
  `Benefit 1` = 0.30,
  `Benefit 2` = 0.20,
  `Benefit 3` = 0.10,
  `Risk 1`    = 0.30,
  `Risk 2`    = 0.10
)

usethis::use_data(clinical_scales, weights, overwrite = TRUE)
