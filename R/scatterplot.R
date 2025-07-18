#' Create a scatterplot from a given dataframe.
#'
#' @param df_diff A dataframe containing two vectors, each of which displays the
#' difference between incremental probabilities in active and control effects
#' for a specified outcome.
#' @param outcome A vector of two strings that describes the two outcomes
#' associated with the difference in active and control effects, where the first
#' outcome corresponds to `diff1` and the second to `diff2`.
#' @param MAB A numerical value that specifies the mimimum acceptable benefit.
#' @param MAR A numerical value that specifies the maximum acceptable risk.
#' @param type Type of marginal plot to show. One of: [density, histogram,
#' boxplot, violin, densigram] (a 'densigram' is when a density plot is overlaid
#' on a histogram)
#' @param legend_position Allows user to specify legend position. Must be a
#' vector of length 2, with the first numeric value corresponding to the
#' position of the legend relative to the x-axis, and the second numeric value
#' corresponding to the position of the legend relative to the y-axis (defaults
#' are given).
#' @param fig_colors Allows user to change colors of the figure (defaults are
#' provided). Must be a vector of length 3, with the first color corresponding
#' to the scatter plot points, the second corresponding to the overall mean, and
#' third to the written probability text color.
#'
#'
#' @return A scatterplot.
#' @export
#' @import ggplot2 ggExtra
#'
#' @examples
#' outcome <- c("Benefit", "Risk")
#' scatter_plot(scatterplot, outcome, MAB = 0.2, MAR = 0.6, type = "density")
#'
scatter_plot <- function(df_diff, outcome, MAB, MAR, type, legend_position = c(0, 1.05),
                         fig_colors = colfun()$fig11_colors) {
  mdiff1 <- mdiff2 <- label <- NULL

  df_diff <- as.data.frame(df_diff)

  if (ncol(df_diff) < 2) {
    error_message <- paste0("You are missing incremental probabilities
                            corresponding to an outcome.")
    stop(error_message)
  }

  if (ncol(df_diff) > 2) {
    error_message <- paste0("You have excess incremental probabilities, decide
                            between two outcomes.")
    stop(error_message)
  }

  diff1 <- df_diff[, 1]
  diff2 <- df_diff[, 2]

  if (identical(diff1, diff2)) {
    stop("Please enter two different vectors of incremental probabilities
         based on their respective outcomes, as specified in the 'outcome'
         argument.")
  }

  if (any(is.na(diff1))) {
    ind <- which(is.na(diff1))
    warning(paste(
      "you have a missing value in diff1, index",
      ind, " "
    ))
    for (i in seq_along(length(diff2))) {
      if (i == ind) {
        diff2[ind] <- NA
      }
    }
    diff2 <- na.omit(diff2)
    diff1 <- na.omit(diff1)
  }

  if (any(is.na(diff2))) {
    ind <- which(is.na(diff2))
    warning(paste(
      "you have a missing value in diff2, index",
      which(is.na(diff2)), " "
    ))
    for (i in seq_along(length(diff2))) {
      if (i == ind) {
        diff1[ind] <- NA
      }
    }
    diff1 <- na.omit(diff1)
    diff2 <- na.omit(diff2)
  }

  diffratio <- diff1 - diff2

  # calculate probability of ratio being in NE and below threshold=1
  good <- ifelse(bdiff > MAB & rdiff < MAR & diffratio > 0, 1, 0)
  prob_good <- sum(good) / length(diffratio)

  dfdiff <- data.frame(diff1, diff2, diffratio)

  max1 <- max(diff1, diff2)
  min1 <- min(diff1, diff2)

  meanbfdiff <- data.frame(
    mdiff1 = mean(diff1),
    mdiff2 = mean(diff2),
    label = paste0(
      "Overall Mean: (",
      sprintf("%1.2f", mean(diff1)),
      ", ",
      sprintf("%1.2f", mean(diff2)),
      ")"
    )
  )

  scatter <- ggplot(dfdiff, aes(x = diff1, y = diff2)) +
    geom_point(color = fig_colors[1], size = 2, shape = 1) +
    geom_point(
      data = meanbfdiff,
      aes(
        x = mdiff1,
        y = mdiff2,
        shape = label
      ),
      color = fig_colors[2],
      size = 2.4,
      show.legend = TRUE
    ) +
    scale_shape_manual(values = 17, name = NULL) +
    stat_ellipse(type = "norm", level = 0.95, color = fig11_colors[1], linewidth = 0.5) +

    scale_y_continuous(limits = c(min1, max1)) +
    scale_x_continuous(limits = c(min1, max1)) +

    geom_hline(yintercept = 0, size = 1) +
    geom_vline(xintercept = 0, size = 1) +
    geom_abline(intercept = 0, slope = 1, linetype = 2, size = 1) +

    geom_hline(yintercept = MAR, size = 1, linetype = 2, colour = "darkorange3") +
    geom_vline(xintercept = MAB, size = 1, linetype = 2, colour = "darkorange3") +

    annotate(
      "ribbon",
      x = c(-Inf, MAB),
      ymin = -Inf,
      ymax = Inf,
      fill = "gray", alpha = 0.3
    ) +
    annotate(
      "ribbon",
      x = c(-Inf, Inf),
      ymin = MAR,
      ymax = Inf,
      fill = "gray", alpha = 0.3
    ) +
    annotate(
      "ribbon",
      x = c(-Inf, Inf),
      ymin = c(-Inf, Inf),
      ymax = Inf,
      fill = "gray", alpha = 0.3
    ) +

    annotate("text", x = min(diff1, diff2) - 0.1, y = MAR + 0.01, label =  "MAR", color = fig11_colors[3], size = 9*0.35, vjust = -0.25) +
    annotate("text", x = MAB, y = min(diff1, diff2) - 0.1, label =  "MAB", color = fig11_colors[3], size = 9*0.35, hjust = -0.25) +

    labs(y = paste("Incremental", outcome[2], " ")) +
    labs(x = paste("Incremental", outcome[1], " ")) +

    annotate(
      "text",
      x = max1 * 0.9,
      y = max1 * 0.6,
      label = paste0("Prob.==", sprintf("%1.1f", 100 * prob_good), "*\'%\'"),
      parse = TRUE,
      color = fig_colors[3],
      size = 9 * 0.35,
      fontface = "bold"
    ) +
    annotate(
      "text",
      x = max1*0.9,
      y = max1*0.55,
      label = paste0("Corr.==", sprintf("%1.1f", 100*cor(diff1, diff2)), "*\'%\'"),
      parse = TRUE,
      color = fig11_colors[3],
      size = 9 * 0.35,
      fontface = "bold") +

    coord_fixed(5.3 / 5) +

    annotate("text",
             x = 0.85 * max1,
             y = 0.89 * max1,
             label = "Benefit = Risk",
             color = fig_colors[3], size = 9 * 0.35, vjust = 0,
             angle = 45
    ) +

    br_charts_theme() +

    theme(
      axis.line.x = element_blank(),
      axis.line.y = element_blank(),
      axis.ticks.x = element_blank(),
      axis.ticks.y = element_blank(),
      legend.position = legend_position,
      legend.justification = c(0, 1),
      legend.box.just = "left",
      legend.margin = margin(0, 0, 0, 0),
      legend.box.margin = margin(0, 0, 0, 0),
      legend.key.size = unit(0.5, "cm"),
      plot.margin = margin(20, 0, 0, 0)
    )

    scatter <- ggExtra::ggMarginal(scatter, type = type, fill = fig11_colors[1])
    scatter

}
