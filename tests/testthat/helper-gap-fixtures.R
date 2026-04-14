create_sample_mcda_data_gap <- function() {
  data.frame(
    Treatment = c("Placebo", "Drug A", "Drug B"),
    `Benefit 1` = c(0.05, 0.46, 0.20),
    `Benefit 2` = c(65, 20, 50),
    `Benefit 3` = c(9, 60, 58),
    `Risk 1` = c(0.03, 0.19, 0.18),
    `Risk 2` = c(0.002, 0.015, 0.010),
    check.names = FALSE,
    stringsAsFactors = FALSE
  )
}

create_sample_clinical_scales_gap <- function() {
  list(
    `Benefit 1` = list(min = 0, max = 1, direction = "increasing"),
    `Benefit 2` = list(min = 0, max = 100, direction = "decreasing"),
    `Benefit 3` = list(min = 0, max = 100, direction = "increasing"),
    `Risk 1` = list(min = 0, max = 0.5, direction = "decreasing"),
    `Risk 2` = list(min = 0, max = 0.3, direction = "decreasing")
  )
}

create_sample_weights_gap <- function() {
  c(
    `Benefit 1` = 0.30,
    `Benefit 2` = 0.20,
    `Benefit 3` = 0.10,
    `Risk 1` = 0.30,
    `Risk 2` = 0.10
  )
}

create_supplied_ci_effects_gap <- function() {
  data("effects_table", package = "valueJudgementCE", envir = environment())
  df <- subset(effects_table, Trt1 == "Drug A")
  bin <- df$Type == "Binary"
  df$Diff_LowerCI[bin] <- (df$Prop1[bin] - df$Prop2[bin]) - 0.05
  df$Diff_UpperCI[bin] <- (df$Prop1[bin] - df$Prop2[bin]) + 0.05
  df$RelRisk_LowerCI[bin] <- pmax(0.01, (df$Prop1[bin] / df$Prop2[bin]) * 0.8)
  df$RelRisk_UpperCI[bin] <- (df$Prop1[bin] / df$Prop2[bin]) * 1.2
  odds <- (df$Prop1[bin] * (1 - df$Prop2[bin])) /
    (df$Prop2[bin] * (1 - df$Prop1[bin]))
  df$OddsRatio_LowerCI[bin] <- pmax(0.01, odds * 0.8)
  df$OddsRatio_UpperCI[bin] <- odds * 1.2
  cont <- df$Type == "Continuous"
  df$Diff_LowerCI[cont] <- (df$Mean1[cont] - df$Mean2[cont]) - 1
  df$Diff_UpperCI[cont] <- (df$Mean1[cont] - df$Mean2[cont]) + 1
  er <- !is.na(df$Rate_Type) & df$Rate_Type == "EventRate"
  df$Diff_EventRate_LowerCI[er] <- (df$EventRate1[er] - df$EventRate2[er]) - 0.05
  df$Diff_EventRate_UpperCI[er] <- (df$EventRate1[er] - df$EventRate2[er]) + 0.05
  ir <- !is.na(df$Rate_Type) & df$Rate_Type == "IncRate"
  df$Diff_IncRate_LowerCI[ir] <- (df$IncRate1[ir] - df$IncRate2[ir]) - 0.05
  df$Diff_IncRate_UpperCI[ir] <- (df$IncRate1[ir] - df$IncRate2[ir]) + 0.05
  df
}

create_subgroup_effects_gap <- function() {
  data("effects_table", package = "valueJudgementCE", envir = environment())
  base <- subset(effects_table, Trt1 == "Drug A")
  male <- base
  male$Filter <- "Sex"
  male$Category <- "Male"
  female <- base
  female$Filter <- "Sex"
  female$Category <- "Female"
  female$Prop1 <- pmin(0.99, female$Prop1 * 1.1)
  rbind(base, male, female)
}

create_tradeoff_args_gap <- function(data) {
  list(
    data = data,
    filter = "None",
    category = "All",
    benefit = "Benefit 1",
    risk = "Risk 1",
    type_risk = "Crude proportions",
    type_graph = "Absolute risk",
    ci = "Yes",
    ci_method = "Calculated",
    cl = 0.95,
    mab = 0.05,
    mar = 0.45,
    threshold = "Segmented line",
    ratio = 4,
    b1 = 0.05,
    b2 = 0.10,
    b3 = 0.15,
    b4 = 0.20,
    b5 = 0.25,
    b6 = 0.30,
    b7 = 0.35,
    b8 = 0.40,
    b9 = 0.45,
    b10 = 0.50,
    r1 = 0.09,
    r2 = 0.17,
    r3 = 0.24,
    r4 = 0.30,
    r5 = 0.35,
    r6 = 0.39,
    r7 = 0.42,
    r8 = 0.44,
    r9 = 0.45,
    r10 = 0.45,
    testdrug = "Yes",
    type_scale = "Free",
    lower_x = 0,
    upper_x = 0.5,
    lower_y = 0,
    upper_y = 0.5,
    chartcolors = colfun()$fig7_colors
  )
}
