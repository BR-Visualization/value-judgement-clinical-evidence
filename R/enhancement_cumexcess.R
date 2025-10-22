#' Create a cumulative excess plot from a given dataframe
#'
#' @param df_outcome A dataframe with 6 variables named the following:
#' 1) eventtime: A vector of time points at which an event occurred.
#' 2) diff: A vector containing the difference in active and control effects.
#' 3) obsv_duration: A variable that specifies the duration of the
#' observational period (numerical).
#' 4) obsv_unit: A variable that specifies the unit for the duration of the
#' observational period (this is a non-numerical input).
#' 5) outcome: A vector containing whether the outcome is a "Benefit" or "Risk".
#' 6) eff_diff_lbl: A vector containing the label for effect difference.
#' @param base_subjects A numerical input that specifies the baseline proportion
#' of subjects in the study (for example, "per 100 subjects")
#' @param visits A numerical input that is the length between normal visits.
#' @param fig_colors Allows the user to change the colors of the figure
#' (defaults are provided). Must be vector of length 2, with color corresponding
#' to benefit first and risk second.
#' @param titlename Allows the user to change the documentation of the title
#' (default is provided).
#' @param ben_name Allows user to specify benefit of interest
#' (default is provided).
#' @param risk_name Allows user to specify risk of interest
#' (default is provided).
#' @param legend_position Allows user to specify legend position. Must be a
#' vector of length 2, with the first value corresponding to the position of the
#' legend relative to the x-axis, and the second corresponding to the position
#' of the legend relative to the y-axis (numeric).
#' @param mar The maximum acceptable risk for the treatment, as discussed by the
#' team, must be numerical.
#' @param mab The minimum acceptable benefit for the treatment, as discussed by
#' the team, must be numerical.
#' @param mcd The minimum clinically important difference of the treatment, as
#' discussed by the team, must be numerical.
#'
#' @return A cumulative excess plot.
#' @export
#' @import ggplot2
#' @import zoo
#' @import simsurv
#' @importFrom cowplot ggdraw draw_label plot_grid draw_plot
#' @importFrom dplyr filter case_when mutate slice distinct
#' @importFrom stats sd
#' @importFrom ggrepel geom_label_repel
#' @importFrom forcats fct_reorder
#' @import reshape2
#' @import colorBlindness
#' @import ggtext
#'
#' @examples
#' gensurv_plot(cumexcess, 100, 6,
#'   titlename =
#'     "Cumulative Excess # of Subjects w/ Events (per 100 Subjects)",
#'   mar = 40,
#'   mab = 10,
#'   mcd = 20
#' )
gensurv_plot <- function(
    df_outcome,
    base_subjects,
    visits,
    fig_colors = c("#0571b0", "#ca0020"),
    titlename = NULL, ben_name = "Primary Efficacy",
    risk_name = "Recurring AE",
    legend_position = c(-0.03, 1.15),
    mar,
    mab,
    mcd) {
  outcome <- active <- control <- sd_diff <- lower_ci <- upper_ci <- NULL
  eventtime <- obsv_duration <- obsv_unit <- eff_diff_lbl <- color_group <- NULL

  all_columns <- c(
    "obsv_duration", "eventtime", "diff", "obsv_unit",
    "outcome", "eff_diff_lbl"
  )
  nonexistent_columns <- setdiff(all_columns, colnames(df_outcome))

  if (length(nonexistent_columns) > 0) {
    error_message <- paste0("You are missing a required variable in your
                            dataframe:", nonexistent_columns)
    stop(error_message)
  }

  df_outcome %>% select(
    eventtime, diff, obsv_duration, obsv_unit, outcome,
    eff_diff_lbl
  )

  if (any(is.na(df_outcome))) {
    warning(paste(
      "you have a missing value in row(s)",
      which(rowSums(is.na(df_outcome)) > 0)
    ))
    df_outcome <- na.omit(df_outcome)
  }

  active <- strsplit(unique(df_outcome$eff_diff_lbl), "-")[[1]][1]
  control <- strsplit(unique(df_outcome$eff_diff_lbl), "-")[[1]][2]

  df_ben <- df_outcome %>% dplyr::filter(outcome == "Benefit")
  mean1 <- mean(df_ben$diff)
  std1 <- sd(df_ben$diff)
  bmin <- mean1 - (3 * std1)
  bmax <- mean1 + (3 * std1)
  error_rows <- which(!(df_ben$diff > bmin) | !(df_ben$diff < bmax))
  if (!all(df_ben$diff > bmin) && !all(df_ben$diff < bmax)) {
    stop(paste("Custom error message: there is an outlier in your benefit data
    in rows", error_rows))
  }

  df_risk <- df_outcome %>% dplyr::filter(outcome == "Risk")
  mean2 <- mean(df_risk$diff)
  std2 <- sd(df_risk$diff)
  rmin <- mean2 - (3 * std2)
  rmax <- mean2 + (3 * std2)
  error_rows <- which(!(df_risk$diff > rmin) | !(df_risk$diff < rmax))
  if (!all(df_risk$diff > rmin) && !all(df_risk$diff < rmax)) {
    stop(paste("Custom error message: there is an outlier in your risk data
               in rows", error_rows))
  }

  stopifnot(all(df_outcome$outcome == "Benefit" | df_outcome$outcome == "Risk"))

  obsv_dur <- unique(df_outcome$obsv_duration)
  min1 <- min((df_outcome$diff) * base_subjects)
  num_break <- ifelse(((min1 * (-2)) %% 6 == 0), 6,
    ifelse(((min1 * (-2)) %% 4 == 0), 4,
      ifelse(((min1 * (-2)) %% 5 == 0), 5, 7)
    )
  )

  actual_min <- (min1 %% (-num_break)) + (min1)
  max1 <- max((df_outcome$diff) * base_subjects)

  breaks2 <- pretty(range(actual_min, max1), n = num_break)
  mytitle <- cowplot::ggdraw() + cowplot::draw_label(
    titlename,
    fontface = "bold", size = 12
  )

  window_size <- 5

  df_ben <- df_ben %>%
    mutate(
      sd_diff = rollapply(diff, window_size, sd, fill = NA, align = "right")
    ) %>%
    mutate(
      lower_ci = diff - 5 * sd_diff,
      upper_ci = diff + 5 * sd_diff
    )

  df_risk <- df_risk %>%
    mutate(
      sd_diff = rollapply(diff, window_size, sd, fill = NA, align = "right")
    ) %>%
    mutate(
      lower_ci = diff - 10 * sd_diff,
      upper_ci = diff + 10 * sd_diff
    )

  plot_temp <- ggplot() +
    geom_line(
      aes(
        x = df_ben$eventtime, y = df_ben$diff * base_subjects,
        color = "Benefit"
      )
    ) +
    geom_line(
      aes(
        x = df_risk$eventtime, y = df_risk$diff * base_subjects,
        color = "Risk"
      )
    ) +
    scale_y_continuous(
      sec.axis = sec_axis(trans = ~., breaks = breaks2),
      breaks = breaks2
    )

  y_limits <- ggplot_build(plot_temp)$layout$panel_params[[1]]$y.range
  y_range <- y_limits[2] - y_limits[1]

  adjustment <- y_range * 0.06

  legend_levels <- c(
    "Benefit_Acceptable",
    "Risk_Acceptable",
    "Nonacceptable"
  )

  legend_data <- data.frame(
    eventtime = 1:6,
    diff = c(1, 2, 3, 4, 5, 6),
    color_group = c(
      "Benefit_Acceptable",
      "Risk_Acceptable",
      "Nonacceptable"
    )
  )

  legend_data$color_group <- factor(legend_data$color_group,
    levels = legend_levels
  )

  plot1 <- ggplot() +
    geom_hline(
      yintercept = mab, color = "#0571b0", linetype = "dashed",
      size = 1
    ) +
    geom_hline(
      yintercept = mar, color = "#ca0020", linetype = "dashed",
      size = 1
    ) +
    annotate("text",
      x = -0.5, y = ifelse(mar > mab, mab - adjustment,
        mab + adjustment
      ), color = "#0571b0",
      label = "MAB", size = 3
    ) +
    annotate("text",
      x = (.95 * obsv_dur),
      y = ifelse(mar > mab, mar + adjustment, mar - adjustment),
      color = "#ca0020", label = "MAR", size = 3
    ) +
    geom_ribbon(
      data = df_ben %>% filter(diff * base_subjects >= mab),
      aes(
        x = eventtime, ymin = lower_ci * base_subjects,
        ymax = upper_ci * base_subjects
      ),
      fill = "#0571b0",
      alpha = 0.2
    ) +
    geom_ribbon(
      data = df_ben %>% filter(diff * base_subjects < mab),
      aes(
        x = eventtime, ymin = lower_ci * base_subjects,
        ymax = upper_ci * base_subjects
      ),
      fill = "#504D4E",
      alpha = 0.2
    ) +
    geom_ribbon(
      data = df_risk %>% filter(diff * base_subjects <= mar),
      aes(
        x = eventtime, ymin = lower_ci * base_subjects,
        ymax = upper_ci * base_subjects
      ),
      fill = "#ca0020",
      alpha = 0.2
    ) +
    geom_ribbon(
      data = df_risk %>% filter(diff * base_subjects > mar),
      aes(
        x = eventtime, ymin = lower_ci * base_subjects,
        ymax = upper_ci * base_subjects
      ),
      fill = "#504D4E",
      alpha = 0.2
    ) +
    geom_text(
      data = df_ben %>% filter(abs(diff * base_subjects - mcd) == min(
        abs(diff * base_subjects - mcd)
      )) %>%
        slice(1),
      aes(x = eventtime, y = diff * base_subjects, label = "MCD"),
      color = "black",
      vjust = -1,
      size = 3
    ) +
    geom_line(
      data = legend_data,
      aes(x = eventtime, y = diff, color = color_group),
      size = 0, alpha = 0
    ) +
    scale_color_manual(
      name = "",
      values = c(
        "Benefit_Acceptable" = "#0571b0",
        "Risk_Acceptable" = "#ca0020",
        "Nonacceptable" = "#504D4E"
      ),
      labels = c(
        "Acceptable Benefit",
        "Acceptable Risk",
        "Nonacceptable Region"
      )
    ) +
    guides(
      color = guide_legend(
        title = "",
        ncol = 3,
        byrow = TRUE,
        override.aes = list(
          linetype = c(1, 1, 1),
          linewidth = c(0.75, 0.75, 0.75),
          alpha = c(1, 1, 1)
        )
      )
    ) +
    geom_hline(yintercept = 0, color = "grey") +
    coord_cartesian(
      ylim =
        c(
          (actual_min - adjustment),
          max(breaks2)
        )
    ) +
    scale_x_continuous(
      limits = c(-1.5, obsv_dur),
      breaks = seq(0, obsv_dur, visits)
    ) +
    scale_y_continuous(
      sec.axis = sec_axis(trans = ~., breaks = breaks2),
      breaks = breaks2,
      labels = breaks2
    ) +
    xlab(paste("Time in", df_outcome$obsv_unit[1])) +
    labs(
      y = NULL,
      title = paste0(ben_name, "\n(>0: Favours ", active, ")"),
      subtitle = paste0(risk_name, "\n(>0: Favours ", control, ")")
    ) +
    br_charts_theme() +
    theme(
      axis.ticks.x = element_blank(),
      axis.ticks.y = element_blank(),
      axis.text.y = element_text(color = fig_colors[1]),
      axis.text.y.right = element_text(color = fig_colors[2]),
      axis.line = element_blank(),
      panel.grid.minor.y = element_blank(),
      legend.position = legend_position,
      legend.justification = "left",
      legend.direction = "horizontal",
      plot.title = element_text(
        size = 10,
        face = "plain",
        color = fig_colors[1],
        hjust = 0,
        vjust = -12,
        margin = ggplot2::margin(
          t = -1,
          unit = "pt"
        )
      ),
      plot.subtitle = element_text(
        color = fig_colors[2], size = 10,
        vjust = 0,
        hjust = 1
      ),
      plot.margin = margin(14.506, 30, 14.506, 14.506),
      axis.title.y = element_text(color = fig_colors[1]),
      axis.title.y.right = element_text(color = fig_colors[2])
    ) +
    geom_line(
      data = df_risk %>%
        filter(diff * base_subjects <= mar),
      aes(x = eventtime, y = diff * base_subjects, color = "Risk_Acceptable"),
      size = 0.5
    ) +
    geom_line(
      data = df_ben %>%
        filter(diff * base_subjects >= mab),
      aes(
        x = eventtime, y = diff * base_subjects,
        color = "Benefit_Acceptable"
      ), size = 0.5
    ) +
    geom_line(
      data = df_risk %>%
        filter(diff * base_subjects > mar),
      aes(x = eventtime, y = diff * base_subjects, color = "Nonacceptable"),
      size = 0.5
    ) +
    geom_line(
      data = df_ben %>%
        filter(diff * base_subjects < mab),
      aes(x = eventtime, y = diff * base_subjects, color = "Nonacceptable"),
      size = 0.5
    ) +
    geom_point(
      data = df_ben %>%
        filter(abs(diff * base_subjects - mcd) == min(
          abs(diff * base_subjects - mcd)
        )) %>%
        slice(1),
      aes(x = eventtime, y = diff * base_subjects),
      shape = 23, fill = "black", size = 2
    )

  plot1 <- ggdraw() +
    draw_plot(plot1, 0, 0, 1, 1)

  if (!is.null(titlename)) {
    plot_grid(
      mytitle,
      plot1,
      ncol = 1,
      align = "v",
      axis = "l",
      rel_heights = c(0.1, 2)
    )
  } else {
    plot1
  }
}

#' Create a table that corresponds to the cumulative excess plot
#'
#' @param df_table A dataframe with 6 variables named the following:
#' 1) obsv_duration: A variable that specifies the duration of the
#' observational period (numerical).
#' 2) n: A vector containing a number of subjects who experienced an event
#' at a given time (numerical).
#' 3) effect: specifies between an active or control effect.
#' 4) outcome: specifies whether the an outcome should be classified as a
#' "Benefit" or "Risk" (this must have either "Benefit" or "Risk" as values).
#' 5) eff_code: 0 for control and 1 for active effect.
#' 6) subjects: A vector containing the total number of active/placebo subjects
#' in the study at a given time.
#' @param base_subjects A numerical input that specifies the baseline proportion
#' of subjects in the study (for example, "per 100 subjects")
#' @param visits A numerical input that is the length between observational
#' periods.
#' @param fig_colors Allows the user to change the colors of the table
#' (defaults are provided). Must be vector of length 2, with color corresponding
#' to benefit second and risk first.
#'
#' @return A table.
#' @export
#' @examples
#' gensurv_table(cumexcess, 100, 6)
gensurv_table <- function(df_table,
                          base_subjects,
                          visits,
                          fig_colors = c("#0571b0", "#ca0020")) {
  effect <- outcome <- visit <- y <- color_ctrl_var <- z <- NULL
  eff_code <- eventtime <- obsv_duration <- subjects <- NULL

  if (!is.null(df_table$eventtime)) {
    all_columns <- c(
      "obsv_duration", "n", "effect", "outcome", "eff_code",
      "eventtime", "subjects"
    )
    nonexistent_columns <- setdiff(all_columns, colnames(df_table))
    if (length(nonexistent_columns) > 0) {
      error_message <- paste0("You are missing a required variable in your
                              dataframe:", nonexistent_columns)
      stop(error_message)
    } else {
      df_table <- df_table %>%
        select(obsv_duration, n, effect, outcome, eff_code, eventtime, subjects)
    }
  } else {
    all_columns <- c(
      "obsv_duration", "n", "effect", "outcome", "eff_code",
      "subjects"
    )
    nonexistent_columns <- setdiff(all_columns, colnames(df_table))
    if (length(nonexistent_columns) > 0) {
      error_message <- paste0("You are missing a required variable in your
                              dataframe:", nonexistent_columns)
      stop(error_message)
    } else {
      df_table <- df_table %>%
        select(obsv_duration, n, effect, outcome, eff_code)
    }
  }

  if (any(is.na(df_table))) {
    miss_vars <- colnames(df_table)[colSums(is.na(df_table) > 0)]
    warning(paste(
      "you have a missing value in row(s)",
      which(rowSums(is.na(df_table)) > 0)
    ))
    df_table[miss_vars] <- lapply(df_table[miss_vars], function(x) {
      ifelse(is.na(x), "NA", x)
    })
  }

  df_table1 <- df_table %>%
    mutate(
      y = dplyr::case_when(
        eff_code == 0 & outcome == "Benefit" ~ 3,
        eff_code == 1 & outcome == "Benefit" ~ 4,
        eff_code == 1 & outcome == "Risk" ~ 2,
        eff_code == 0 & outcome == "Risk" ~ 1
      ),
      color_ctrl_var = dplyr::case_when(
        eff_code == 0 & outcome == "Benefit" ~ fig_colors[1],
        eff_code == 1 & outcome == "Benefit" ~ fig_colors[1],
        eff_code == 1 & outcome == "Risk" ~ fig_colors[2],
        eff_code == 0 & outcome == "Risk" ~ fig_colors[2]
      )
    ) %>%
    mutate(effect = forcats::fct_reorder(
      as.factor(paste(effect, outcome,
        sep = " "
      )), y,
      .na_rm = FALSE
    ))

  df_table1 <- df_table1 %>%
    mutate(
      effect = factor(effect, levels = unique(effect[order(y)]))
    )

  len <- df_table$obsv_duration[1]
  visit <- seq.default(0, len, by = visits)

  if (!is.null(df_table1$eventtime)) {
    df_table1 <- df_table1 %>%
      filter(eventtime %in% unlist(visit)) %>%
      mutate(visit = eventtime) %>%
      select(visit, n, effect, y, color_ctrl_var, subjects) %>%
      distinct()
  } else {
    df_table1$visit <- visit
    df_table1 <- df_table1 %>%
      select(visit, n, effect, y, color_ctrl_var, subjects)
  }

  geom_text_ctrl <- list(
    aes_string(
      x = "visit",
      label = "n",
      y = "y"
    ),
    color = df_table1$color_ctrl_var,
    family = "sans",
    size = 3
  )

  x_ctrl <- list(
    limits = c(-0.25, (len + 1.5)),
    breaks = seq(0, len, visits),
    labels = NULL
  )


  if (any(is.na(df_table))) {
    df_table3 <- na.omit(df_table1)
    df_table3 <- droplevels(df_table3)

    y_ctrl <- list(
      name = "",
      breaks = c(1, 2, 3, 4),
      limits = c(0, 4.5),
      labels = levels(df_table3$effect)
    )
  } else {
    y_ctrl <- list(
      name = "",
      breaks = c(1, 2, 3, 4),
      limits = c(0, 4.5),
      labels = levels(df_table1$effect)
    )
  }

  extra_code2 <- labs(titles = "Number With Event")
  geom_text_control <- do.call(geom_text, geom_text_ctrl)
  scale_x_control <- do.call(scale_x_continuous, x_ctrl)
  scale_y_control <- do.call(scale_y_continuous, y_ctrl)

  og_table1 <- ggplot(data = df_table1) +
    geom_text_control +
    scale_x_control +
    scale_y_control +
    extra_code2 +
    br_charts_theme() +
    theme(
      plot.title = ggplot2::element_text(size = 8),
      axis.ticks.x = element_blank(),
      axis.ticks.y = element_blank(),
      panel.grid.major = element_blank(),
      panel.grid.minor = element_blank(),
      panel.border = element_blank(),
      axis.title.x = element_blank(),
      axis.line = element_blank(),
      plot.margin = margin(2, 30, 14.506, 14.506),
      plot.caption = element_text(hjust = 0.42),
      legend.position = "none"
    )

  df_table2 <- df_table %>%
    mutate(z = dplyr::case_when(
      eff_code == 0 ~ 1,
      eff_code == 1 ~ 2
    ))

  df_table2 <- df_table2 %>%
    mutate(
      effect = factor(effect, levels = unique(effect[order(z)]))
    )

  if (!is.null(df_table2$eventtime)) {
    df_table2 <- df_table2 %>%
      filter(eventtime %in% unlist(visit)) %>%
      mutate(visit = eventtime) %>%
      select(visit, n, effect, z, subjects) %>%
      distinct(visit, effect, z, .keep_all = TRUE)
  } else {
    df_table2$visit <- visit
    df_table2 <- df_table2 %>%
      select(visit, n, effect, z, subjects) %>%
      distinct(visit, effect, z, .keep_all = TRUE)
  }

  geom_text_subjects_ctrl <- list(
    aes_string(
      x = "visit",
      label = "subjects",
      y = "z"
    ),
    color = "black",
    family = "sans",
    size = 3
  )

  extra_code1 <- labs(titles = "Number of Subjects")

  if (any(is.na(df_table))) {
    df_table3 <- na.omit(df_table2)
    df_table3 <- droplevels(df_table3)

    y_ctrl_2 <- list(
      name = "",
      breaks = c(1, 2),
      limits = c(0, 2.5),
      labels = levels(factor(df_table2$effect))
    )
  } else {
    y_ctrl_2 <- list(
      name = "",
      breaks = c(1, 2),
      limits = c(0, 2.5),
      labels = levels(factor(df_table2$effect))
    )
  }

  geom_text_subj_control <- do.call(geom_text, geom_text_subjects_ctrl)
  scale_x_control1 <- do.call(scale_x_continuous, x_ctrl)
  scale_y_control1 <- do.call(scale_y_continuous, y_ctrl_2)

  subj_table <- ggplot(data = df_table2) +
    geom_text_subj_control +
    scale_x_control1 +
    scale_y_control1 +
    extra_code1 +
    br_charts_theme() +
    theme(
      plot.title = ggplot2::element_text(size = 8),
      axis.ticks.x = element_blank(),
      axis.ticks.y = element_blank(),
      panel.grid.major = element_blank(),
      panel.grid.minor = element_blank(),
      panel.border = element_blank(),
      axis.title.x = element_blank(),
      axis.line = element_blank(),
      plot.margin = margin(2, 15, 0.1, 8),
      plot.caption = element_text(hjust = 0.42),
      legend.position = "none"
    )

  cowplot::plot_grid(
    subj_table,
    og_table1,
    ncol = 1,
    align = "v",
    rel_heights = c(0.55, 1) # Adjust to control height ratio
  )
}

#' Combine the cumulative excess plot and corresponding table into one figure
#'
#' @param df_plot A dataframe with 6 variables named the following:
#' 1) eventtime: A vector of time points at which an event occurred.
#' 2) diff: A vector containing the difference in active and control effects.
#' 3) obsv_duration: A variable that specifies the duration of the
#' observational period (numerical).
#' 4) obsv_unit: A variable that specifies the unit for the duration of the
#' observational period (this is a non-numerical input).
#' 5) outcome: A vector containing whether the outcome is a "Benefit" or "Risk".
#' 6) eff_diff_lbl: A vector containing the label for effect difference.
#' @param df_table A dataframe with 6 variables named the following:
#' 1) obsv_duration: A variable that specifies the duration of the
#' observational period (numerical).
#' 2) n: A vector containing a number of subjects who experienced an event
#' at a given time (numerical).
#' 3) effect: specifies between an active or control effect.
#' 4) outcome: specifies whether the an outcome should be classified as a
#' "Benefit" or "Risk" (this must have either "Benefit" or "Risk" as values).
#' 5) eff_code: 0 for control and 1 for active effect.
#' 6) subjects: A vector containing the total number of active/placebo subjects
#' in the study at a given time.
#' @param subjects_pt A numerical input that specifies the baseline proportion
#' of subjects in the study.
#' @param visits_pt A numerical input that is the length between observational
#' periods.
#' @param fig_colors_pt Allows user to change the colors of the figure (defaults
#' are provided). Must be vector of length 2, with color corresponding to
#' benefit first and risk second.
#' @param titlename_p Allows user to change the documentation of title (default
#' is provided)
#' @param rel_adjust Allows user to specify the figure and table alignment. Must
#' be a single number, corresponding to the space to the left of the figure,
#' relative to the figure's width (denoted as 1).
#' @param rel_heights_table Elements for fig vs table size.
#' @param ben_name_p Allows user to specify benefit of interest
#' (default is provided).
#' @param risk_name_p Allows user to specify risk of interest
#' (default is provided).
#' @param legend_position_p Allows user to specify legend position. Must be a
#' vector of length 2, with the first value corresponding to the position of the
#' legend relative to the x-axis, and the second corresponding to the position
#' of the legend relative to the y-axis (numeric).
#' @param mar The maximum acceptable risk for the treatment, as discussed by the
#' team, must be numerical.
#' @param mab The minimum acceptable benefit for the treatment, as discussed by
#' the team, must be numerical.
#' @param mcd The minimum clinically important difference of the treatment, as
#' discussed by the team, must be numerical.
#'
#' @return A combined cumulative excess plot and table.
#' @export
#' @examples
#' gensurv_combined(
#'   df_plot = cumexcess, subjects_pt = 100, visits_pt = 6,
#'   df_table = cumexcess, fig_colors_pt = colfun()$fig13_colors,
#'   mar = 30, mab = 10, mcd = 15
#' )
#'
gensurv_combined <- function(df_plot,
                             df_table,
                             subjects_pt,
                             visits_pt,
                             fig_colors_pt = c("#0571b0", "#ca0020"),
                             titlename_p =
                               "Cumulative Excess # of Subjects w/ Events
                             (per 1000 Subjects)",
                             mar,
                             mab,
                             mcd,
                             rel_adjust = .12,
                             rel_heights_table = c(1, 0.4),
                             ben_name_p = "Primary Efficacy",
                             risk_name_p = "Recurring AE",
                             legend_position_p = c(-0.03, 1.15)) {
  if (!is.null(df_table$eventtime)) {
    all_columns <- c(
      "obsv_duration", "n", "effect", "outcome", "eff_code",
      "eventtime", "subjects"
    )
    nonexistent_columns <- setdiff(all_columns, colnames(df_table))
    if (length(nonexistent_columns) > 0) {
      error_message <- paste0("You are missing a required variable in your
                              table dataframe:", nonexistent_columns)
      stop(error_message)
    }
  } else {
    all_columns <- c(
      "obsv_duration", "n", "effect", "outcome", "eff_code",
      "subjects"
    )
    nonexistent_columns <- setdiff(all_columns, colnames(df_table))
    if (length(nonexistent_columns) > 0) {
      error_message <- paste0("You are missing a required variable in your
                              table dataframe:", nonexistent_columns)
      stop(error_message)
    }
  }

  all_columns <- c(
    "obsv_duration", "eventtime", "diff", "obsv_unit",
    "outcome", "eff_diff_lbl"
  )
  nonexistent_columns <- setdiff(all_columns, colnames(df_plot))
  if (length(nonexistent_columns) > 0) {
    error_message <- paste0("You are missing a required variable in your
                            plot dataframe:", nonexistent_columns)
    stop(error_message)
  }

  plot <- gensurv_plot(
    df_plot, subjects_pt, visits_pt,
    fig_colors = fig_colors_pt,
    ben_name = ben_name_p, risk_name = risk_name_p,
    legend_position = legend_position_p,
    mab = mab,
    mar = mar,
    mcd = mcd
  )

  mytitle <- cowplot::ggdraw() + cowplot::draw_label(
    titlename_p,
    fontface = "bold", size = 12
  )

  plot <- cowplot::plot_grid(
    mytitle,
    plot,
    ncol = 1,
    align = "v",
    axis = "l",
    rel_heights = c(0.2, 2)
  )

  table <- gensurv_table(
    df_table, subjects_pt, visits_pt,
    fig_colors = fig_colors_pt
  )

  plot <- cowplot::plot_grid(
    NULL,
    plot + ggplot2::theme(legend.position = legend_position_p),
    ncol = 2,
    rel_widths = c(rel_adjust, 1)
  )

  fig_plot <- cowplot::plot_grid(
    plot,
    table,
    ncol = 1,
    align = "v",
    axis = "l",
    rel_heights = rel_heights_table
  )

  return(fig_plot)
}

#' Simulate data (utilized for function tests)
#'
#' @param seed A numerical input or object that will set the standard for data
#' simulation.
#' @param n1 A numerical input or object that represents the desired total
#' population for the simulated data (for treatment group 1).
#' @param n2 A numerical input or object that represents the desired total
#' population for the simulated data (for treatment group 2).
#' @param obsv_duration A numerical input or object that is the maximum time
#' the observational period will span for the simulated data.
#' @param lambda1 A numerical input or object that is the first lambda that will
#'  be used in the data simulation (used as the first parameter for simulation).
#' @param lambda2 A numerical input or object that is the second lambda that
#' will be used in the data simulation (used as the second parameter
#' for simulation).
#' @param unit A non-numerical input that specifies the length of the
#' observational period ("Week", "Month", etc.).
#'
#' @return A simulated dataframe.
#' @export
#'
#' @examples
#' gensurv(111, 2000, 1000, 36, .005, .0048, "Weeks")
gensurv <- function(
    seed, n1, n2, obsv_duration, lambda1, lambda2, unit = "Months") {
  diff_sim <- NULL
  stopifnot(is.numeric(seed))
  stopifnot(is.numeric(n1))
  stopifnot(is.numeric(n2))
  stopifnot(is.numeric(obsv_duration))
  stopifnot(is.numeric(lambda1))
  stopifnot(is.numeric(lambda2))
  stopifnot(is.character(unit))
  set.seed(seed)
  sim1 <- simsurv(
    dist = "exponential",
    lambdas = lambda1,
    x = data.frame(id = 1:n1),
    maxt = obsv_duration
  )
  sim2 <- simsurv(
    dist = "exponential",
    lambdas = lambda2,
    x = data.frame(id = 1:n2),
    maxt = obsv_duration
  )

  eventtime_sim <- sort(unique(c(sim1$eventtime, sim2$eventtime)))
  df_sim <- data.frame(matrix(0, length(eventtime_sim), 2))
  names(df_sim) <- c("eventtime_sim", "diff_sim")
  df_sim$eventtime_sim <- eventtime_sim

  for (t in seq_along(df_sim$eventtime_sim)) {
    df_sim$diff_sim[t] <- sum(
      sim1$eventtime < eventtime_sim[t] & sim1$status == 1
    ) /
      n1 - sum(sim2$eventtime < eventtime_sim[t] & sim2$status == 1) / n2
  }
  df_sim %>%
    mutate(obsv_duration = obsv_duration, obsv_unit = unit) %>%
    rename(eventtime = eventtime_sim, diff = diff_sim)
}
