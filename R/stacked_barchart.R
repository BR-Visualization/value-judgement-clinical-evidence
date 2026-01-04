#' Stacked Bar Chart
#'
#' @param data `dataframe` a data frame with a minimum of 4 variables named the
#' following:
#' 1) usubjid: unique subject ID
#' 2) visit: visit ID
#' 3) trt: treatment group
#' 4) brcat: composite benefit-risk category
#' @param chartcolors `vector` a vector of colors, the same number of levels as
#' the brcat variable
#' @param ylabel `character` y label name, default is "Visit"
#'
#' @return a ggplot object
#' @export
#'
#' @examples
#' stacked_barchart(
#'   data = comp_outcome,
#'   chartcolors = colfun()$fig12_colors,
#'   ylabel = "Study Week"
#' )
#'
stacked_barchart <- function(data, chartcolors, ylabel = "Visit") {
  all_columns <- c(
    "usubjid", "visit", "trt", "brcat"
  )
  nonexistent_columns <- setdiff(all_columns, colnames(data))

  if (length(nonexistent_columns) > 0) {
    error_message <- paste0(
      "You are missing a required variable in your dataframe: ",
      nonexistent_columns)
    stop(error_message)
  }

  df_n1 <- data |>
    group_by(trt, visit) |>
    dplyr::summarise(n1 = n())

  if (nrow(unique(df_n1[c("trt", "n1")])) > nrow(unique(df_n1["trt"]))) {
    warning(
      "You have unequal number of observations across visits, ",
      "please check missing data."
    )
  }

  df_n2 <- data |>
    group_by(trt, visit, brcat) |>
    dplyr::summarise(n2 = n())

  df_stacked <- merge(df_n1, df_n2, by = c("trt", "visit"))
  df_stacked$percentage <- df_stacked$n2 / df_stacked$n1 * 100

  fig <- ggplot(df_stacked, aes(x = percentage, y = visit, fill = brcat)) +
    facet_wrap(~trt, scales = "free_x", ncol = 1) +
    geom_bar(stat = "identity", color = "black") +
    scale_fill_manual(values = chartcolors,
                      breaks = rev(levels(df_stacked$brcat))) +
    geom_text(aes(label = round(percentage, 0)),
              color = ifelse(df_stacked$brcat == "Withdrew", "white", "black"),
              position = position_stack(vjust = 0.5),
              size = control_fonts()$p * 0.45
    ) +
    scale_x_continuous(expand = c(0.015, 0)) +
    xlab("Percentage") +
    ylab(ylabel) +
    guides(fill = guide_legend(title = "Outcome", nrow = 3, byrow = TRUE)) +
    labs(color = NULL) +
    br_charts_theme(
      strip.text.x = element_text(hjust = 0.5),
      panel.grid.major = element_blank(),
      panel.grid.minor = element_blank(),
      axis.ticks.y = element_blank(),
      plot.title = element_text(hjust = 0.5)
    )

  fig
}

#' Divergent Stacked Bar Chart
#'
#' @param data `dataframe` a data frame with a minimum of 4 variables named the
#' following:
#' 1) usubjid: unique subject ID
#' 2) visit: visit ID
#' 3) trt: treatment group
#' 4) brcat: composite benefit-risk category
#' @param chartcolors `vector` a vector of colors, the same number of levels as
#' the brcat variable
#' @param favcat `vector` a vector of favorable categories in the desired plot
#' order
#' @param unfavcat `vector` a vector of unfavorable categories in the desired
#' plot order
#' @param ylabel `character` y label name, default is "Visit"
#'
#' @return a ggplot object
#' @export
#'
#' @examples
#' divergent_stacked_barchart(
#'   data = comp_outcome,
#'   chartcolors = colfun()$fig12_colors,
#'   favcat = c("Benefit larger than threshold, with AE",
#'   "Benefit larger than threshold, w/o AE"),
#'   unfavcat = c("Withdrew",
#'   "Benefit less than threshold, w/o AE",
#'   "Benefit less than threshold, with AE"),
#'   ylabel = "Study Week"
#' )
#'
divergent_stacked_barchart <- function(data, chartcolors, favcat, unfavcat,
                                       ylabel = "Visit") {
  all_columns <- c(
    "usubjid", "visit", "trt", "brcat"
  )
  nonexistent_columns <- setdiff(all_columns, colnames(data))

  if (length(nonexistent_columns) > 0) {
    error_message <- paste0(
      "You are missing a required variable in your dataframe: ",
      nonexistent_columns)
    stop(error_message)
  }

  df_n1 <- data |>
    group_by(trt, visit) |>
    dplyr::summarise(n1 = n())

  if (nrow(unique(df_n1[c("trt", "n1")])) > nrow(unique(df_n1["trt"]))) {
    warning(
      "You have unequal number of observations across visits, ",
      "please check missing data."
    )
  }

  df_n2 <- data |>
    group_by(trt, visit, brcat) |>
    dplyr::summarise(n2 = n())

  df_stacked <- merge(df_n1, df_n2, by = c("trt", "visit"))
  df_stacked$percentage <- df_stacked$n2 / df_stacked$n1 * 100

  df_stacked_new <- df_stacked |>
    mutate(brcat = factor(brcat, levels = c(unfavcat, favcat))) |>
    mutate(percentage = ifelse(brcat %in% unfavcat, -percentage, percentage),
           side = ifelse(brcat %in% unfavcat, "Left", "Right"))

  fig <- ggplot(df_stacked_new, aes(x = percentage, y = visit, fill = brcat)) +
    facet_wrap(~trt, scales = "free_x", ncol = 1) +
    geom_bar(stat = "identity", color = "black") +
    scale_fill_manual(values = chartcolors,
                      breaks = rev(levels(df_stacked$brcat))) +
    geom_text(aes(label = ifelse(side == "Left", -percentage, percentage)),
              color = ifelse(df_stacked$brcat == "Withdrew", "white", "black"),
              position = position_stack(vjust = 0.5),
              size = control_fonts()$p * 0.45) +
    scale_x_continuous(breaks = seq(-100, 100, 20),
                       limits = c(-100, 100),
                       expand = c(0, 0),
                       labels = function(breaks) {
                         ifelse(breaks > 0, breaks, abs(breaks))
                         }
                       ) +
    xlab("Percentage") +
    ylab(ylabel) +
    guides(fill = guide_legend(title = "Outcome", nrow = 3, byrow = TRUE)) +
    labs(color = NULL) +
    br_charts_theme(
      strip.text.x = element_text(hjust = 0.5),
      panel.grid.major = element_blank(),
      panel.grid.minor = element_blank(),
      axis.line.y = element_blank(),
      plot.title = element_text(hjust = 0.5)
    )

  fig
}
