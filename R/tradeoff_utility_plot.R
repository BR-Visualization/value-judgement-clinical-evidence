#' Trade-off plot with iso-utility curves
#'
#' Draws the publication version of the trade-off plot: incremental benefit
#' and risk (with confidence intervals) for each treatment, the acceptability
#' boundaries MAB\eqn{_0} and MAR\eqn{_{max}}, the trade-off curve (TC), and
#' dashed iso-utility curves that rank acceptable treatments.
#'
#' Utility is measured as the vertical distance below the trade-off curve,
#' \eqn{U = TC(\Delta B) - \Delta R}, where \eqn{TC(\Delta B)} is the largest
#' acceptable incremental risk at incremental benefit \eqn{\Delta B} and
#' \eqn{\Delta R} is the observed incremental risk. The trade-off curve is
#' therefore \eqn{U = 0}, and each iso-utility curve is the trade-off curve
#' shifted down by a constant amount. Each treatment is labelled with its
#' \eqn{U}.
#'
#' @param data (`data.frame`) effects table, as used by
#'   [generate_tradeoff_plot()].
#' @param benefit,risk (`character`) benefit and risk outcomes to plot.
#' @param mab (`numeric`) minimum acceptable benefit at zero incremental risk
#'   (MAB\eqn{_0}).
#' @param mar (`numeric`) maximum acceptable risk at the maximum benefit
#'   evaluated (MAR\eqn{_{max}}).
#' @param tc_benefit,tc_risk (`numeric`) points defining the trade-off curve,
#'   from MAB\eqn{_0} to MAR\eqn{_{max}}. Linear interpolation is used between
#'   points.
#' @param utility_levels (`numeric`) utilities at which to draw iso-utility
#'   curves. Use `NULL` to omit them.
#' @param x_limits,y_limits (`numeric(2)`) axis limits.
#' @param filter,category (`character`) subgroup filter, as in
#'   [generate_tradeoff_plot()].
#' @param ci (`logical`) draw confidence intervals.
#' @param cl (`numeric`) confidence level.
#' @param chartcolors (`character`) one colour per treatment.
#' @param x_label,y_label (`character`) axis titles. Default to
#'   "Incremental <benefit>" and "Incremental <risk>".
#' @param label_treatments (`logical`) label each treatment with its utility.
#' @param show_direction (`logical`) add the "Higher utility" arrow.
#' @param base_font_size (`numeric`) base font size in points.
#'
#' @return A ggplot object. The treatment utilities are attached as the
#'   `"utilities"` attribute.
#' @export
#'
#' @examples
#' et <- effects_table[effects_table$Outcome %in%
#'   c("Primary Efficacy", "Recurring AE"), ]
#' tradeoff_utility_plot(
#'   et,
#'   benefit = "Primary Efficacy", risk = "Recurring AE",
#'   mab = 0.05, mar = 0.45,
#'   tc_benefit = c(0.05, 0.1, 0.15, 0.2, 0.25, 0.3, 0.35, 0.4, 0.45),
#'   tc_risk = c(0.09, 0.17, 0.24, 0.3, 0.35, 0.39, 0.42, 0.44, 0.45)
#' )
tradeoff_utility_plot <- function(
  data,
  benefit,
  risk,
  mab,
  mar,
  tc_benefit,
  tc_risk,
  utility_levels = c(0.1, 0.2, 0.3),
  x_limits = c(0, 0.5),
  y_limits = c(0, 0.5),
  filter = "None",
  category = "All",
  ci = TRUE,
  cl = 0.95,
  chartcolors = colfun()$fig7_colors,
  x_label = paste("Incremental", benefit),
  y_label = paste("Incremental", risk),
  label_treatments = TRUE,
  show_direction = TRUE,
  base_font_size = 9
) {
  stopifnot(
    length(tc_benefit) == length(tc_risk),
    length(tc_benefit) >= 2,
    !is.unsorted(tc_benefit)
  )

  fonts <- control_fonts(base_font_size = base_font_size)
  text_size <- fonts$label * 0.85
  x_min <- x_limits[1]
  x_max <- x_limits[2]
  y_min <- y_limits[1]
  y_max <- y_limits[2]

  df_br <- suppressMessages(prepare_tradeoff_data(
    data, filter, category, benefit, risk,
    ci_method = "Calculated", cl = cl,
    type_risk = "Crude proportions", type_graph = "Absolute risk"
  ))
  df_br$treatment <- factor(df_br$treatment, levels = unique(df_br$treatment))

  tc_fun <- function(x) {
    stats::approx(tc_benefit, tc_risk, xout = x, rule = 2)$y
  }

  # utilities: vertical distance below the trade-off curve
  df_br$utility <- tc_fun(df_br$benefit) - df_br$risk
  # labels go above-right of a treatment, or below-right in the upper half
  df_br$nudge_y <- ifelse(
    df_br$risk > (y_min + y_max) / 2,
    -0.045 * (y_max - y_min),
    0.03 * (y_max - y_min)
  )
  df_br$label <- paste0(
    df_br$treatment, "\nU = ",
    sprintf("%+.2f", df_br$utility)
  )

  # trade-off curve on a fine grid, from MAB0 to MAR_max
  grid_x <- seq(min(tc_benefit), max(tc_benefit), length.out = 400)
  df_tc <- data.frame(x = c(tc_benefit), y = c(tc_risk))

  # region above the trade-off curve (not acceptable), drawn light grey
  df_above <- data.frame(
    x = c(min(tc_benefit), tc_benefit, max(tc_benefit)),
    y = c(mar, tc_risk, mar)
  )

  # iso-utility curves: trade-off curve shifted down by u, kept inside panel
  df_iso <- do.call(rbind, lapply(utility_levels, function(u) {
    y <- tc_fun(grid_x) - u
    keep <- y >= y_min
    data.frame(x = grid_x[keep], y = y[keep], u = u)
  }))
  df_iso_lab <- if (!is.null(df_iso) && nrow(df_iso) > 0) {
    do.call(rbind, lapply(split(df_iso, df_iso$u), function(d) d[nrow(d), ]))
  } else {
    NULL
  }

  # label for the trade-off curve, placed and rotated along its steep part
  lab_x <- stats::quantile(tc_benefit, 0.3)
  lab_slope <- (tc_fun(lab_x + 0.02) - tc_fun(lab_x - 0.02)) / 0.04
  lab_angle <- atan(lab_slope * (x_max - x_min) / (y_max - y_min)) * 180 / pi

  my_colors <- chartcolors[seq_len(nlevels(df_br$treatment))]
  names(my_colors) <- levels(df_br$treatment)
  my_shapes <- c(16, 17, 15, 18, 3, 4, 8, 11)[seq_len(nlevels(df_br$treatment))]
  names(my_shapes) <- levels(df_br$treatment)

  p <- ggplot() +
    # not acceptable: below MAB0 and above MAR_max
    annotate("rect",
      xmin = x_min, xmax = mab, ymin = y_min, ymax = y_max,
      fill = "gray75"
    ) +
    annotate("rect",
      xmin = mab, xmax = x_max, ymin = mar, ymax = y_max,
      fill = "gray75"
    ) +
    geom_polygon(
      aes(x = .data$x, y = .data$y),
      data = df_above, fill = "gray86"
    )

  if (!is.null(df_iso) && nrow(df_iso) > 0) {
    p <- p +
      geom_line(
        aes(x = .data$x, y = .data$y, group = .data$u),
        data = df_iso, linetype = "dashed", colour = "gray40",
        linewidth = 0.45
      ) +
      geom_text(
        aes(
          x = x_max - 0.01 * (x_max - x_min), y = .data$y,
          label = paste0("U = +", format(.data$u))
        ),
        # right-aligned against the panel edge, level with the end of each
        # curve, so the label stays inside the panel at any font size
        data = df_iso_lab, hjust = 1, vjust = 0.5, size = text_size,
        colour = "gray30"
      )
  }

  p <- p +
    geom_line(
      aes(x = .data$x, y = .data$y),
      data = df_tc, colour = "maroon4", linewidth = 1.1
    ) +
    annotate("text",
      x = lab_x - 0.012, y = tc_fun(lab_x) + 0.012,
      label = "Trade-off curve (U = 0)", angle = lab_angle,
      colour = "maroon4", size = text_size, hjust = 0.5, vjust = 0
    ) +
    geom_vline(
      xintercept = mab, linetype = "dashed", colour = "darkorange3",
      linewidth = 0.9
    ) +
    geom_hline(
      yintercept = mar, linetype = "dashed", colour = "darkorange3",
      linewidth = 0.9
    ) +
    annotate("text",
      x = mab, y = y_max, label = "MAB[0]", parse = TRUE,
      hjust = -0.15, vjust = 1.4, size = fonts$label
    ) +
    annotate("text",
      x = x_max, y = mar, label = "MAR[max]", parse = TRUE,
      hjust = 1.05, vjust = -0.4, size = fonts$label
    )

  if (isTRUE(ci)) {
    p <- p +
      geom_segment(
        aes(
          x = .data$benefit_lowerCI, xend = .data$benefit_upperCI,
          y = .data$risk, yend = .data$risk, colour = .data$treatment
        ),
        data = df_br, linewidth = 1, show.legend = FALSE
      ) +
      geom_segment(
        aes(
          x = .data$benefit, xend = .data$benefit,
          y = .data$risk_lowerCI, yend = .data$risk_upperCI,
          colour = .data$treatment
        ),
        data = df_br, linewidth = 1, show.legend = FALSE
      )
  }

  p <- p +
    geom_point(
      aes(
        x = .data$benefit, y = .data$risk,
        colour = .data$treatment, shape = .data$treatment
      ),
      data = df_br, size = 2.6
    )

  if (isTRUE(label_treatments)) {
    p <- p +
      ggrepel::geom_text_repel(
        aes(x = .data$benefit, y = .data$risk, label = .data$label),
        data = df_br, size = text_size, hjust = 0, lineheight = 0.9,
        nudge_x = 0.025 * (x_max - x_min), nudge_y = df_br$nudge_y, min.segment.length = 0.5,
        box.padding = 0.4, point.padding = 0.6,
        segment.colour = "gray60", seed = 1, colour = "gray20"
      )
  }

  if (isTRUE(show_direction)) {
    p <- p +
      annotate("segment",
        x = x_max - 0.06 * (x_max - x_min), y = y_min + 0.035 * (y_max - y_min),
        xend = x_max - 0.01 * (x_max - x_min),
        yend = y_min + 0.01 * (y_max - y_min),
        arrow = grid::arrow(length = grid::unit(0.15, "cm")),
        colour = "gray25", linewidth = 0.4
      ) +
      annotate("text",
        x = x_max - 0.07 * (x_max - x_min), y = y_min + 0.045 * (y_max - y_min),
        label = "Higher utility\n(more efficacy, fewer AEs)",
        hjust = 1, vjust = 0, size = text_size * 0.9, colour = "gray25",
        lineheight = 0.9
      )
  }

  p <- p +
    scale_colour_manual(values = my_colors, name = "Treatment:") +
    scale_shape_manual(values = my_shapes, name = "Treatment:") +
    scale_x_continuous(limits = x_limits, expand = c(0, 0)) +
    scale_y_continuous(limits = y_limits, expand = c(0, 0)) +
    coord_cartesian(clip = "off") +
    labs(x = x_label, y = y_label) +
    br_charts_theme(
      base_font_size = base_font_size,
      axis_line = element_blank(),
      axis.ticks.x = element_blank(),
      axis.ticks.y = element_blank(),
      axis.title.x = element_text(size = fonts$h2, face = "bold"),
      axis.title.y = element_text(size = fonts$h2, face = "bold"),
      legend.title = element_text(size = fonts$p, face = "bold"),
      panel.border = element_rect(colour = "black", fill = NA,
                                  linewidth = 0.6),
      panel.grid.minor = element_blank(),
      panel.grid.major = element_line(colour = "gray80", linetype = "dotted",
                                      linewidth = 0.3),
      plot.margin = margin(5, 12, 5, 5)
    )

  attr(p, "utilities") <- data.frame(
    treatment = as.character(df_br$treatment),
    benefit = df_br$benefit,
    risk = df_br$risk,
    utility = df_br$utility
  )
  p
}
