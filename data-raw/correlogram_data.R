## code to prepare `correlogram` dataset goes here
library(faux)

set.seed(1234)

# Only generate the columns we actually need
corr <- data.frame(
  `Benefit 1` = rnorm(100, runif(1, 0, 100), runif(1, 0, 100)),
  `Benefit 2` = rnorm(100, runif(1, 0, 100), runif(1, 0, 100)),
  `Benefit 3` = rnorm(100, runif(1, 0, 100), runif(1, 0, 100)),
  `Risk 1` = rnorm(100, runif(1, 0, 100), runif(1, 0, 100)),
  `Risk 2` = rnorm(100, runif(1, 0, 100), runif(1, 0, 100)),
  `Risk 3` = rnorm(100, runif(1, 0, 100), runif(1, 0, 100)),
  check.names = FALSE
)

# Create correlations between variables
corr$`Benefit 2` <- rnorm_pre(
  corr$`Benefit 1`,
  mean(corr$`Benefit 2`),
  sd(corr$`Benefit 2`),
  r = 0.6
)
corr$`Risk 1` <- rnorm_pre(
  corr[, c("Benefit 1", "Benefit 2", "Benefit 3")],
  mean(corr$`Risk 1`),
  sd(corr$`Risk 1`),
  r = c(0.3, 0.2, -0.5)
)
corr$`Risk 2` <- rnorm_pre(
  corr[, c("Benefit 1", "Benefit 2", "Benefit 3", "Risk 1")],
  mean(corr$`Risk 2`),
  sd(corr$`Risk 2`),
  r = c(0.13, 0.3, -0.09, -0.1)
)
corr$`Risk 3` <- rnorm_pre(
  corr[, c("Benefit 1", "Benefit 2", "Benefit 3", "Risk 1", "Risk 2")],
  mean(corr$`Risk 3`),
  sd(corr$`Risk 3`),
  r = c(-0.13, -0.1, -0.5, -0.1, 0)
)
usethis::use_data(corr, overwrite = TRUE)
