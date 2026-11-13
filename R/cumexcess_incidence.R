#' Cumulative excess incidence plot with acceptability thresholds
#'
#' Publication version of the cumulative excess plot. For one benefit and one
#' risk, the cumulative incidence in each arm is calculated with a fixed
#' denominator of all randomized patients, so patients who withdraw without
#' the event count as event-free for the rest of follow-up. Each curve is the
#' difference in cumulative incidence (active minus control) in percentage
#' points. Shaded bands are pointwise Wald confidence intervals for that
#' difference. The minimum acceptable benefit (MAB\eqn{_0}) and maximum
#' acceptable risk (MAR\eqn{_{max}}) are drawn on the same scale. The benefit
#' curve is grey until it first reaches MAB\eqn{_0}. A table of the number of
#' patients remaining and the cumulative number with each event is shown
#' beneath the plot.
#'
#' @param data A data frame in the format of [cumexcess] with columns
#'   `effect` (arm name), `eff_code` (1 = active, 0 = control), `outcome`
#'   ("Benefit" or "Risk"), `eventtime`, `n` (cumulative number of patients
#'   with the event in that arm), `subjects` (patients remaining),
#'   `obsv_duration` and `obsv_unit`.
#' @param mab,mar Minimum acceptable benefit and maximum acceptable risk, in
#'   percentage points.
#' @param n_randomized Named numeric vector of the number randomized per arm
#'   (names matching `effect`). By default, the number of patients remaining at
#'   time 0 in each arm.
#' @param visits Interval between table columns and x-axis breaks.
#' @param smooth If `TRUE` (default), the weekly cumulative incidence in each
#'   arm is joined by a monotone spline; if `FALSE`, step functions are used.
#' @param conf_level Confidence level for the bands.
#' @param ben_name,risk_name Names of the benefit and risk outcomes.
#' @param fig_colors Colours for benefit and risk.
#' @param base_font_size Base font size in points.
#'
#' @return A cowplot object combining the legend, plot and table. The plotted
#'   differences and confidence limits are attached as the `"curves"`
#'   attribute.
#' @export
#'
#' @examples
#' cumexcess_incidence_plot(cumexcess, mab = 10, mar = 5)
cumexcess_incidence_plot <- function(
  data,
  mab,
  mar,
  n_randomized = NULL,
  visits = 6,
  smooth = TRUE,
  conf_level = 0.95,
  ben_name = "Primary efficacy",
  risk_name = "AESI",
  fig_colors = colfun()$fig13_colors,
  base_font_size = 9
) {
  required <- c("effect", "eff_code", "outcome", "eventtime", "n", "subjects",
                "obsv_duration", "obsv_unit")
  missing_cols <- setdiff(required, colnames(data))
  if (length(missing_cols) > 0) {
    stop("You are missing required variable(s) in your dataframe: ",
         paste(missing_cols, collapse = ", "))
  }
  stopifnot(all(data$outcome %in% c("Benefit", "Risk")))

  data <- as.data.frame(data)
  duration <- data$obsv_duration[1]
  unit <- tolower(data$obsv_unit[1])
  active <- unique(data$effect[data$eff_code == 1])[1]
  control <- unique(data$effect[data$eff_code == 0])[1]
  fonts <- control_fonts(base_font_size = base_font_size)
  text_size <- fonts$label * 0.85
  grey_col <- "#504D4E"

  # value of a cumulative column at given times (last record at or before t)
  value_at <- function(d, column, times) {
    d <- d[order(d$eventtime), ]
    vapply(times, function(t) {
      v <- d[[column]][d$eventtime <= t]
      if (length(v) == 0) d[[column]][1] else v[length(v)]
    }, numeric(1))
  }

  if (is.null(n_randomized)) {
    n_randomized <- vapply(c(active, control), function(arm) {
      d <- data[data$effect == arm, ]
      max(d$subjects[d$eventtime == min(d$eventtime)])
    }, numeric(1))
  }

  weeks <- seq(0, duration, by = 1)
  fine <- seq(0, duration, length.out = 361)
  z <- stats::qnorm(1 - (1 - conf_level) / 2)

  curve_for <- function(out) {
    p <- lapply(c(active, control), function(arm) {
      d <- data[data$outcome == out & data$effect == arm, ]
      if (isTRUE(smooth)) {
        pw <- value_at(d, "n", weeks) / n_randomized[[arm]]
        stats::splinefun(weeks, pw, method = "monoH.FC")(fine)
      } else {
        value_at(d, "n", fine) / n_randomized[[arm]]
      }
    })
    diff <- p[[1]] - p[[2]]
    se <- sqrt(p[[1]] * (1 - p[[1]]) / n_randomized[[active]] +
                 p[[2]] * (1 - p[[2]]) / n_randomized[[control]])
    data.frame(
      time = fine,
      diff = 100 * diff,
      lower = 100 * (diff - z * se),
      upper = 100 * (diff + z * se),
      outcome = out
    )
  }

  ben <- curve_for("Benefit")
  risk <- curve_for("Risk")

  # benefit: grey until it first reaches MAB0, then the benefit colour
  cross <- which(ben$diff >= mab)[1]
  if (is.na(cross)) {
    ben$segment <- "below"
  } else {
    ben$segment <- ifelse(seq_len(nrow(ben)) < cross, "below", "above")
    ben <- rbind(ben, transform(ben[cross, ], segment = "below"))
  }

  y_top <- max(c(ben$upper, risk$upper, mab, mar), na.rm = TRUE)
  y_bottom <- min(c(0, ben$lower, risk$lower), na.rm = TRUE)
  y_breaks <- pretty(c(0, y_top), n = 8)
  x_limits <- c(-0.5, duration + 0.5)

  p <- ggplot() +
    geom_hline(yintercept = 0, colour = "gray60", linewidth = 0.3) +
    geom_ribbon(
      aes(x = .data$time, ymin = .data$lower, ymax = .data$upper),
      data = ben[ben$segment == "above", ], fill = fig_colors[1], alpha = 0.2
    ) +
    geom_ribbon(
      aes(x = .data$time, ymin = .data$lower, ymax = .data$upper),
      data = ben[ben$segment == "below", ], fill = grey_col, alpha = 0.2
    ) +
    geom_ribbon(
      aes(x = .data$time, ymin = .data$lower, ymax = .data$upper),
      data = risk, fill = fig_colors[2], alpha = 0.2
    ) +
    geom_hline(yintercept = mab, colour = fig_colors[1], linetype = "dashed",
               linewidth = 0.6) +
    geom_hline(yintercept = mar, colour = fig_colors[2], linetype = "dashed",
               linewidth = 0.6) +
    geom_line(aes(x = .data$time, y = .data$diff),
              data = ben[ben$segment == "below", ], colour = grey_col,
              linewidth = 0.8) +
    geom_line(aes(x = .data$time, y = .data$diff),
              data = ben[ben$segment == "above", ], colour = fig_colors[1],
              linewidth = 0.8) +
    geom_line(aes(x = .data$time, y = .data$diff), data = risk,
              colour = fig_colors[2], linewidth = 0.8) +
    annotate("text", x = 0.5, y = mab, label = "MAB[0]", parse = TRUE,
             hjust = 0, vjust = -0.4, colour = fig_colors[1],
             size = text_size) +
    annotate("text", x = duration, y = mar, label = "MAR[max]", parse = TRUE,
             hjust = 1, vjust = -0.4, colour = fig_colors[2],
             size = text_size) +
    scale_x_continuous(limits = x_limits, breaks = seq(0, duration, visits),
                       expand = c(0, 0)) +
    scale_y_continuous(breaks = y_breaks,
                       limits = c(y_bottom, max(y_breaks))) +
    labs(
      x = paste("Time in", unit),
      y = "Difference in cumulative incidence (percentage points)"
    ) +
    br_charts_theme(
      base_font_size = base_font_size,
      axis_line = element_blank(),
      axis.ticks.x = element_blank(),
      axis.ticks.y = element_blank(),
      axis.title.x = element_text(size = fonts$h2, face = "bold"),
      axis.title.y = element_text(size = fonts$p, face = "plain"),
      panel.grid.minor = element_blank(),
      panel.grid.major = element_line(colour = "gray85", linetype = "dotted",
                                      linewidth = 0.3),
      plot.margin = margin(0, 10, 2, 75)
    )

  header <- ggplot() +
    annotate("text", x = 0, y = 0.5, hjust = 0, colour = fig_colors[1],
             size = text_size, lineheight = 0.95,
             label = paste0(ben_name, "\n(>0: favours ", tolower(active),
                            ")")) +
    annotate("text", x = 1, y = 0.5, hjust = 1, colour = fig_colors[2],
             size = text_size, lineheight = 0.95,
             label = paste0(risk_name, "\n(>0: favours ", tolower(control),
                            ")")) +
    scale_x_continuous(limits = c(0, 1), expand = c(0, 0)) +
    scale_y_continuous(limits = c(0, 1), expand = c(0, 0)) +
    theme_void() +
    theme(plot.margin = margin(0, 10, 0, 5))

  key <- cumexcess_incidence_key(
    ben_name, risk_name, fig_colors, grey_col, conf_level, text_size
  )

  table <- cumexcess_incidence_table(
    data, active, control, risk_name, visits, duration, x_limits,
    fig_colors, value_at, base_font_size
  )

  body <- cowplot::plot_grid(
    header, p, table,
    ncol = 1, rel_heights = c(0.09, 1, 0.42),
    align = "v", axis = "lr"
  )
  out <- cowplot::plot_grid(key, body, ncol = 1, rel_heights = c(0.13, 1.51))
  attr(out, "curves") <- rbind(ben[ben$segment != "below" | is.na(cross),
                                   names(risk)], risk)
  out
}

#' Legend for the cumulative excess incidence plot
#' @noRd
cumexcess_incidence_key <- function(
  ben_name, risk_name, fig_colors, grey_col, conf_level, text_size
) {
  rows <- c(0.82, 0.5, 0.18)
  lab <- function(x) paste0("'", x, "'")
  left <- c(
    lab(paste0("Excess benefit (", tolower(ben_name), ")")),
    "'Excess benefit below '*MAB[0]",
    lab(paste0("Excess risk (", risk_name, ")"))
  )
  right <- c(
    "MAB[0]*': minimum acceptable benefit'",
    "MAR[max]*': maximum acceptable risk'",
    lab(paste0(round(100 * conf_level), "% confidence band"))
  )
  ggplot() +
    annotate("segment", x = 0.08, xend = 0.13, y = rows, yend = rows,
             colour = c(fig_colors[1], grey_col, fig_colors[2]),
             linewidth = 0.8) +
    annotate("text", x = 0.145, y = rows, label = left, parse = TRUE,
             hjust = 0, size = text_size) +
    annotate("segment", x = 0.5, xend = 0.55, y = rows[1:2], yend = rows[1:2],
             colour = fig_colors[1:2], linetype = "dashed", linewidth = 0.6) +
    annotate("rect", xmin = 0.5, xmax = 0.55, ymin = rows[3] - 0.1,
             ymax = rows[3] + 0.1, fill = "gray80") +
    annotate("text", x = 0.565, y = rows, label = right, parse = TRUE,
             hjust = 0, size = text_size) +
    scale_x_continuous(limits = c(0, 1), expand = c(0, 0)) +
    scale_y_continuous(limits = c(0, 1), expand = c(0, 0)) +
    theme_void()
}

#' Table beneath the cumulative excess incidence plot
#' @noRd
cumexcess_incidence_table <- function(
  data, active, control, risk_name, visits, duration, x_limits, fig_colors,
  value_at, base_font_size
) {
  times <- seq(0, duration, by = visits)
  arm_rows <- function(out, arm) data[data$outcome == out & data$effect == arm, ]

  rows <- list(
    list(label = "Number of subjects", header = TRUE),
    list(label = active,
         values = value_at(arm_rows("Benefit", active), "subjects", times),
         colour = "black"),
    list(label = control,
         values = value_at(arm_rows("Benefit", control), "subjects", times),
         colour = "black"),
    list(label = "Number with event", header = TRUE),
    list(label = paste(active, "benefit"),
         values = value_at(arm_rows("Benefit", active), "n", times),
         colour = fig_colors[1]),
    list(label = paste(control, "benefit"),
         values = value_at(arm_rows("Benefit", control), "n", times),
         colour = fig_colors[1]),
    list(label = paste(active, risk_name),
         values = value_at(arm_rows("Risk", active), "n", times),
         colour = fig_colors[2]),
    list(label = paste(control, risk_name),
         values = value_at(arm_rows("Risk", control), "n", times),
         colour = fig_colors[2])
  )

  y <- rev(seq_along(rows))
  cells <- do.call(rbind, lapply(seq_along(rows), function(i) {
    r <- rows[[i]]
    if (isTRUE(r$header)) return(NULL)
    data.frame(x = times, y = y[i], label = format(r$values, trim = TRUE),
               colour = r$colour)
  }))
  is_header <- vapply(rows, function(r) isTRUE(r$header), logical(1))
  row_labels <- data.frame(
    y = y,
    label = vapply(rows, `[[`, character(1), "label"),
    header = is_header
  )
  fonts <- control_fonts(base_font_size = base_font_size)
  span <- diff(x_limits)

  ggplot(cells) +
    geom_text(aes(x = .data$x, y = .data$y, label = .data$label),
              colour = cells$colour, size = fonts$label * 0.8) +
    geom_text(aes(x = x_limits[1] - 0.02 * span, y = .data$y,
                  label = .data$label),
              data = row_labels[!row_labels$header, ], hjust = 1,
              colour = "gray25", size = fonts$label * 0.8) +
    geom_text(aes(x = x_limits[1] - 0.25 * span, y = .data$y,
                  label = .data$label),
              data = row_labels[row_labels$header, ], hjust = 0,
              fontface = "bold", size = fonts$label * 0.85) +
    scale_x_continuous(breaks = NULL, expand = c(0, 0)) +
    scale_y_continuous(expand = c(0, 0)) +
    labs(x = NULL, y = NULL) +
    coord_cartesian(xlim = x_limits, ylim = c(0.5, length(rows) + 0.5),
                    clip = "off") +
    theme_void() +
    theme(plot.margin = margin(4, 10, 2, 5))
}
