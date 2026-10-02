## code to prepare `correlogram` dataset goes here
library(faux)

set.seed(1234)

# Only generate the columns we actually need
corr <- data.frame(
  `Primary Efficacy` = rnorm(100, runif(1, 0, 100), runif(1, 0, 100)),
  `Secondary Efficacy` = rnorm(100, runif(1, 0, 100), runif(1, 0, 100)),
  `Quality of Life` = rnorm(100, runif(1, 0, 100), runif(1, 0, 100)),
  `Recurring AE` = rnorm(100, runif(1, 0, 100), runif(1, 0, 100)),
  `Rare SAE` = rnorm(100, runif(1, 0, 100), runif(1, 0, 100)),
  `Liver Toxicity` = rnorm(100, runif(1, 0, 100), runif(1, 0, 100)),
  check.names = FALSE
)

# Create correlations between variables
corr$`Secondary Efficacy` <- rnorm_pre(
  corr$`Primary Efficacy`,
  mean(corr$`Secondary Efficacy`),
  sd(corr$`Secondary Efficacy`),
  r = 0.6
)
corr$`Recurring AE` <- rnorm_pre(
  corr[, c("Primary Efficacy", "Secondary Efficacy", "Quality of Life")],
  mean(corr$`Recurring AE`),
  sd(corr$`Recurring AE`),
  r = c(0.3, 0.2, -0.5)
)
corr$`Rare SAE` <- rnorm_pre(
  corr[, c("Primary Efficacy", "Secondary Efficacy", "Quality of Life", "Recurring AE")],
  mean(corr$`Rare SAE`),
  sd(corr$`Rare SAE`),
  r = c(0.13, 0.3, -0.09, -0.1)
)
corr$`Liver Toxicity` <- rnorm_pre(
  corr[, c(
    "Primary Efficacy", "Secondary Efficacy", "Quality of Life",
    "Recurring AE", "Rare SAE"
  )],
  mean(corr$`Liver Toxicity`),
  sd(corr$`Liver Toxicity`),
  r = c(-0.13, -0.1, -0.5, -0.1, 0)
)
usethis::use_data(corr, overwrite = TRUE)
