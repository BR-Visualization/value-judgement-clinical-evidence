## Code to prepare `clinical_scales` and `weights` datasets
## These companion objects match the mcda_data example dataset

clinical_scales <- list(
  `Primary Efficacy` = list(min = 0, max = 1,   direction = "increasing"),
  `Secondary Efficacy` = list(min = 0, max = 100, direction = "decreasing"),
  `Quality of Life` = list(min = 0, max = 100, direction = "increasing"),
  `Recurring AE`    = list(min = 0, max = 0.5, direction = "decreasing"),
  `Rare SAE`    = list(min = 0, max = 0.3, direction = "decreasing")
)

weights <- c(
  `Primary Efficacy` = 0.30,
  `Secondary Efficacy` = 0.20,
  `Quality of Life` = 0.10,
  `Recurring AE`    = 0.30,
  `Rare SAE`    = 0.10
)

usethis::use_data(clinical_scales, weights, overwrite = TRUE)
