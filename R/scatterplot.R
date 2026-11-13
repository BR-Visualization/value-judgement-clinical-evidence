#' Create a scatterplot from a given dataframe.
#'
#' @param df_diff A dataframe containing two vectors, each of which
#' displays the difference between incremental probabilities in active
#' and control effects for a specified outcome.
#' @param outcome A vector of two strings that describes the two
#' outcomes associated with the difference in active and control
#' effects, where the first outcome corresponds to `diff1` and the
#' second to `diff2`.
#' @param mab A numerical value that specifies the mimimum acceptable benefit.
#' @param mar A numerical value that specifies the maximum acceptable risk.
#' @param ellipse_type Type of confidence ellipse. The default "t"
#' assumes a multivariate t-distribution, and "norm" assumes a
#' multivariate normal distribution. "euclid" draws a circle with the
#' radius equal to level, representing the euclidean distance from the
#' center. If ellipse_type = NULL, the confidence ellipse will not be
#' showed.
#' @param ellipse_level The confidence level at which to draw an
#' ellipse (default is 0.95). If type = "euclid", the radius of the
#' circle to be drawn.
#' @param marginal_type Type of marginal plot to show. One of:
#' density, histogram, boxplot, violin, densigram (a 'densigram' is
#' when a density plot is overlaid on a histogram). If marginal_type =
#' NULL, the marginal plot will not be showed. By default, densigram
#' is displayed.
#' @param fig_colors Allows user to change colors of the figure
#' (defaults are provided). Must be a vector of length 3, with the
#' first color corresponding to the scatter plot points, the second
#' corresponding to the overall mean, and third to the written
#' probability text color.
#' @param base_font_size Numeric; base font size in points for all text
#' elements in the plot (default: 9).
#' @param style Either `"classic"` (default) or `"publication"`. The
#' publication style labels the axes as Active minus Comparator differences,
#' uses MAB\eqn{_0}, MAR\eqn{_{max}} and \eqn{\mu = 1} labels, reports
#' the proportion of patients in the acceptance region and the correlation
#' coefficient, and adds a key for the mean, the data ellipse and the
#' acceptance region below the plot.
#'
#' @return A scatterplot.
#' @export
#' @import ggplot2
#' @importFrom ggExtra ggMarginal
#'
#' @examples
#' outcome <- c("Benefit", "Risk")
#' scatter_plot(scatterplot, outcome, mab = 0.2, mar = 0.6)
#'
scatter_plot <- function(
  df_diff,
  outcome,
  mab,
  mar,
  ellipse_type = "t",
  ellipse_level = 0.95,
  marginal_type = "densigram",
  fig_colors = colfun()$fig11_colors,
  base_font_size = 9,
  style = c("classic", "publication")
) {
  style <- match.arg(style)
  publication <- style == "publication"
  typography <- publication_typography(
    base_font_size = base_font_size,
    annotation_ratio = 1.15
  )

  mdiff1 <- mdiff2 <- label <- NULL

  df_diff <- as.data.frame(df_diff)

  if (ncol(df_diff) < 2) {
    error_message <- paste0(
      "You are missing incremental probabilities corresponding to",
      "an outcome."
    )
    stop(error_message)
  }

  if (ncol(df_diff) > 2) {
    error_message <- paste0(
      "You have excess incremental probabilities, decide between",
      "two outcomes."
    )
    stop(error_message)
  }

  diff1 <- df_diff[, 1]
  diff2 <- df_diff[, 2]

  if (identical(diff1, diff2)) {
    stop(
      paste(
        "Please enter two different vectors of incremental",
        "probabilities based on their respective outcomes, as",
        "specified in the 'outcome' argument."
      )
    )
  }

  if (anyNA(diff1)) {
    ind <- which(is.na(diff1))
    warning(paste(
      "you have a missing value in diff1, index",
      ind,
      " "
    ))
    for (i in seq_along(length(diff2))) {
      if (i == ind) {
        diff2[ind] <- NA
      }
    }
    diff2 <- na.omit(diff2)
    diff1 <- na.omit(diff1)
  }

  if (anyNA(diff2)) {
    ind <- which(is.na(diff2))
    warning(paste(
      "you have a missing value in diff2, index",
      which(is.na(diff2)),
      " "
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
  good <- ifelse(diff1 > mab & diff2 < mar & diffratio > 0, 1, 0)
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

  corr_val <- stats::cor(diff1, diff2)
  if (publication) {
    mar_lab <- "MAR[max]"
    mab_lab <- "MAB[0]"
    diag_lab <- "mu == 1 ~ '(Benefit = Risk)'"
    stats_lab <- paste0(
      "Patients in acceptance\nregion: ",
      sprintf("%1.1f", 100 * prob_good), "%\n",
      "Correlation r = ", sprintf("%1.2f", corr_val)
    )
    x_lab <- paste0("Predicted Incremental ", outcome[1],
                    " (Active \u2212 Comparator)")
    y_lab <- paste0("Predicted Incremental ", outcome[2],
                    " (Active \u2212 Comparator)")
  } else {
    mar_lab <- "MAR"
    mab_lab <- "MAB"
    diag_lab <- "Benefit = Risk"
    x_lab <- paste("Predicted Incremental", outcome[1], " ")
    y_lab <- paste("Predicted Incremental", outcome[2], " ")
  }

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
    scale_y_continuous(limits = c(min1 - 0.1, max1 + 0.1)) +
    scale_x_continuous(limits = c(min1 - 0.1, max1 + 0.1)) +
    geom_hline(yintercept = 0, linewidth = 1) +
    geom_vline(xintercept = 0, linewidth = 1) +
    geom_abline(intercept = 0, slope = 1, linetype = 2, linewidth = 1) +
    geom_hline(
      yintercept = mar,
      linewidth = 1,
      linetype = 2,
      colour = "darkorange3"
    ) +
    geom_vline(
      xintercept = mab,
      linewidth = 1,
      linetype = 2,
      colour = "darkorange3"
    ) +
    annotate(
      "ribbon",
      x = c(-Inf, mab),
      ymin = -Inf,
      ymax = Inf,
      fill = "gray",
      alpha = 0.3
    ) +
    annotate(
      "ribbon",
      x = c(-Inf, Inf),
      ymin = mar,
      ymax = Inf,
      fill = "gray",
      alpha = 0.3
    ) +
    annotate(
      "ribbon",
      x = c(-Inf, Inf),
      ymin = c(-Inf, Inf),
      ymax = Inf,
      fill = "gray",
      alpha = 0.3
    ) +
    annotate(
      "text",
      x = min(diff1, diff2) - 0.1,
      y = mar + 0.01,
      label = mar_lab,
      parse = publication,
      hjust = if (publication) 0 else 0.5,
      color = colfun()$fig11_colors[3],
      size = publication_geom_text_size(typography$annotation),
      vjust = -0.25
    ) +
    annotate(
      "text",
      x = mab,
      y = min(diff1, diff2) - 0.1,
      label = mab_lab,
      parse = publication,
      vjust = if (publication) 0.2 else 0.5,
      color = colfun()$fig11_colors[3],
      size = publication_geom_text_size(typography$annotation),
      hjust = -0.25
    ) +
    labs(x = x_lab, y = y_lab) +
    coord_fixed(5.3 / 5) +
    annotate(
      "text",
      x = 0.85 * max1,
      y = 0.89 * max1,
      label = diag_lab,
      parse = publication,
      color = fig_colors[3],
      size = publication_geom_text_size(typography$annotation),
      vjust = 0,
      angle = 45
    ) +
    br_charts_theme(base_font_size = base_font_size) +
    theme(
      axis.line.x = element_blank(),
      axis.line.y = element_blank(),
      axis.ticks.x = element_blank(),
      axis.ticks.y = element_blank(),
      legend.position = "bottom",
      legend.justification = c(0, 0),
      legend.box.just = "left",
      legend.margin = margin(0, 0, 0, 0),
      legend.box.margin = margin(0, 0, 0, 0),
      legend.key.size = unit(0.5, "cm"),
      plot.margin = margin(20, 0, 0, 0)
    )

  if (publication) {
    scatter <- scatter +
      annotate(
        "text",
        x = max1 * 0.63,
        y = max1 * 0.55,
        label = stats_lab,
        hjust = 0,
        lineheight = 0.95,
        color = fig_colors[3],
        size = publication_geom_text_size(typography$annotation) * 0.85
      ) +
      theme(legend.position = "none")
  } else {
    scatter <- scatter +
      annotate(
        "text",
        x = max1 * 0.9,
        y = max1 * 0.6,
        label = paste0("Prob.==", sprintf("%1.1f", 100 * prob_good), "*\'%\'"),
        parse = TRUE,
        color = fig_colors[3],
        size = publication_geom_text_size(typography$annotation),
        fontface = "bold"
      ) +
      annotate(
        "text",
        x = max1 * 0.9,
        y = max1 * 0.55,
        label = paste0(
          "Corr.==",
          sprintf(
            "%1.1f",
            100 * stats::cor(diff1, diff2)
          ),
          "*\'%\'"
        ),
        parse = TRUE,
        color = colfun()$fig11_colors[3],
        size = publication_geom_text_size(typography$annotation),
        fontface = "bold"
      )
  }

  if (!is.null(ellipse_type)) {
    scatter <- scatter +
      stat_ellipse(
        type = ellipse_type,
        level = ellipse_level,
        color = colfun()$fig11_colors[1],
        linewidth = 0.5
      )
  }

  if (!is.null(marginal_type)) {
    scatter <- ggExtra::ggMarginal(
      scatter,
      type = marginal_type,
      color = colfun()$fig11_colors[1],
      fill = "white"
    )
  }

  if (publication) {
    scatter <- cowplot::plot_grid(
      scatter,
      scatter_publication_key(
        mean_label = paste0(
          "Mean predicted difference (",
          sprintf("%1.2f", mean(diff1)), ", ",
          sprintf("%1.2f", mean(diff2)), ")"
        ),
        point_color = fig_colors[2],
        ellipse_color = colfun()$fig11_colors[1],
        ellipse_level = ellipse_level,
        show_ellipse = !is.null(ellipse_type),
        text_size = publication_geom_text_size(typography$annotation) * 0.85
      ),
      ncol = 1,
      rel_heights = c(1, 0.09)
    )
  }

  scatter
}

#' Key drawn below the publication-style scatter plot
#' @noRd
scatter_publication_key <- function(
  mean_label,
  point_color,
  ellipse_color,
  ellipse_level,
  show_ellipse,
  text_size
) {
  theta <- seq(0, 2 * pi, length.out = 60)
  ell <- data.frame(x = 0.52 + 0.022 * cos(theta), y = 0.72 + 0.12 * sin(theta))
  p <- ggplot() +
    annotate("point", x = 0.03, y = 0.72, shape = 17, size = 2.4,
             colour = point_color) +
    annotate("text", x = 0.055, y = 0.72, label = mean_label, hjust = 0,
             size = text_size) +
    annotate("rect", xmin = 0.02, xmax = 0.04, ymin = 0.14, ymax = 0.34,
             fill = "white", colour = "gray50", linewidth = 0.3) +
    annotate("text", x = 0.055, y = 0.24, hjust = 0, size = text_size,
             parse = TRUE,
             label = paste0(
               "'Acceptance region: right of '*MAB[0]*', below the '*mu ",
               "== 1*' line, and below '*MAR[max]"
             ))
  if (isTRUE(show_ellipse)) {
    p <- p +
      geom_path(aes(x = .data$x, y = .data$y), data = ell,
                colour = ellipse_color, linewidth = 0.5) +
      annotate("text", x = 0.555, y = 0.72, hjust = 0, size = text_size,
               label = paste0(round(100 * ellipse_level),
                              "% data ellipse of predictions"))
  }
  p +
    scale_x_continuous(limits = c(0, 1), expand = c(0, 0)) +
    scale_y_continuous(limits = c(0, 1), expand = c(0, 0)) +
    theme_void()
}
