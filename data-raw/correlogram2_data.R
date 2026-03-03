## code to prepare `correlogram` dataset goes here
library(faux)

set.seed(1234)

# Only generate the columns we actually need
corr2 <- data.frame(
  `Benefit 1` = rnorm(100, runif(1, 0, 100), runif(1, 0, 100)),
  `Benefit 2` = rnorm(100, runif(1, 0, 100), runif(1, 0, 100)),
  `Benefit 3` = rnorm(100, runif(1, 0, 100), runif(1, 0, 100)),
  `Risk 1` = rnorm(100, runif(1, 0, 100), runif(1, 0, 100)),
  `Risk 2` = rnorm(100, runif(1, 0, 100), runif(1, 0, 100)),
  `Risk 3` = rnorm(100, runif(1, 0, 100), runif(1, 0, 100)),
  check.names = FALSE
)

# Create correlations between variables
corr2$`Benefit 2` <- rnorm_pre(
  corr2$`Benefit 1`,
  mean(corr2$`Benefit 2`),
  sd(corr2$`Benefit 2`),
  r = 0.6
)
corr2$`Risk 1` <- rnorm_pre(
  corr2[, c("Benefit 1", "Benefit 2", "Benefit 3")],
  mean(corr2$`Risk 1`),
  sd(corr2$`Risk 1`),
  r = c(0.3, 0.2, -0.5)
)
corr2$`Risk 2` <- rnorm_pre(
  corr2[, c("Benefit 1", "Benefit 2", "Benefit 3", "Risk 1")],
  mean(corr2$`Risk 2`),
  sd(corr2$`Risk 2`),
  r = c(0.13, 0.3, -0.09, -0.1)
)
corr2$`Risk 3` <- rnorm_pre(
  corr2[, c("Benefit 1", "Benefit 2", "Benefit 3", "Risk 1", "Risk 2")],
  mean(corr2$`Risk 3`),
  sd(corr2$`Risk 3`),
  r = c(-0.13, -0.1, -0.5, -0.1, 0)
)
usethis::use_data(corr2, overwrite = TRUE)
