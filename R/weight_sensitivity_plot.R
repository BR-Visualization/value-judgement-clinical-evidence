#' Create MCDA Weight Sensitivity Plot
#'
#' One-way sensitivity analysis on criterion weights, in the style of
#' Figures 6 and 7 of Angelis and Phillips (2021). The weight on a single
#' criterion is varied from 0% to 100% while the remaining weights are
#' rescaled proportionally so that all weights still sum to 1. Because the
#' MCDA model is linear additive, each treatment's overall weighted score is
#' a straight line in the weight: at 0% it equals the score obtained from
#' the other criteria alone, and at 100% it equals the treatment's
#' preference value on the varied criterion. A vertical line marks the
#' current weight and points mark where the preferred treatment changes.
#' Shading under the highest line highlights weight ranges according to
#' \code{shading}. By default it marks the weights at which a different
#' treatment would be preferred than at the current weight, so the unshaded
#' band around the vertical line shows how far the weight can move before
#' the decision changes.
#'
#' With \code{comparator_name}, each treatment is instead scored by its
#' difference from the comparator in the same study (as in
#' \code{\link{create_mcda_waterfall}} and \code{\link{mcda_tornado}}).
#' The differences are also linear in the weight, so lines, crossovers and
#' shading work in the same way.
#'
#' @param data A data frame in wide format with Treatment column and
#'   criteria columns. Required parameter - must be provided. Each row
#'   should contain raw values for a treatment on their original
#'   measurement scales. Other columns are ignored, except Study when
#'   \code{comparator_name} is given. Treatment names must be unique
#'   (excluding comparator rows). See \code{\link{mcda_data}} for example
#'   format.
#' @param weights Named numeric vector of criterion weights. Must sum to 1.
#' @param clinical_scales List defining clinical reference levels for
#'   each criterion. Each element should be a list with: min (lower
#'   threshold), max (upper threshold), direction ("increasing" for
#'   higher is better, "decreasing" for lower is better).
#' @param comparator_name Character string naming the comparator treatment
#'   (e.g., "Placebo"). If NULL (default), each treatment's overall weighted
#'   score is plotted. If given, each other treatment is plotted as its
#'   score minus the score of the comparator row in the same Study (or the
#'   single comparator row when \code{data} has no Study column), and the
#'   comparator itself is not drawn.
#' @param criteria Character vector of criteria whose weight is varied.
#'   One panel is drawn per criterion. If NULL (default), all criteria in
#'   \code{weights} are shown.
#' @param fig_colors A vector of colors for the treatment lines, recycled
#'   if shorter than the number of treatments. If NULL, a default palette
#'   is used.
#' @param ref_line_color Color of the vertical line marking the current
#'   weight. Default is "#ca0020".
#' @param show_crossovers Logical; if TRUE (default), mark and label the
#'   weights at which the treatment with the highest overall score changes.
#' @param shading Character string selecting how weight ranges are shaded.
#'   The ranges are the bands between crossovers, each with one preferred
#'   treatment.
#'   \itemize{
#'     \item \code{"change"} (default): shade the bands in which a different
#'       treatment is preferred than at the current weight.
#'     \item \code{"hiview"}: shade the first band and every other band
#'       after it, as in the Hiview software used for Figures 6 and 7 of
#'       Angelis and Phillips (2021). Nothing is shaded when the preferred
#'       treatment never changes.
#'     \item \code{"none"}: no shading.
#'   }
#' @param shade_color Fill color for the shading. Default is "#4EADD0".
#' @param base_font_size Numeric; base font size in points for all text
#'   elements in the plot (default: 9).
#'
#' @return A ggplot object showing overall weighted score (or the
#'   difference from the comparator) against the weight on each selected
#'   criterion, with one line per treatment.
#'   The underlying lines, crossover points and preferred-treatment
#'   regions are attached as the attributes \code{"sensitivity_lines"},
#'   \code{"crossovers"} and \code{"preferred_regions"}.
#' @references Angelis A, Phillips LD. Advancing structured decision-making
#'   in drug regulation at the FDA and EMA. Br J Clin Pharmacol.
#'   2021;87(2):395-405. \doi{10.1111/bcp.14425}
#' @export
#' @import ggplot2
#'
#' @examples
#' # Load example MCDA data
#' data(mcda_data)
#'
#' # Define clinical scales
#' clinical_scales <- list(
#'   `Primary Efficacy` = list(min = 0, max = 1, direction = "increasing"),
#'   `Secondary Efficacy` = list(min = 0, max = 100, direction = "decreasing"),
#'   `Quality of Life` = list(min = 0, max = 100, direction = "increasing"),
#'   `Recurring AE` = list(min = 0, max = 0.5, direction = "decreasing"),
#'   `Rare SAE` = list(min = 0, max = 0.3, direction = "decreasing")
#' )
#'
#' # Define weights
#' weights <- c(
#'   `Primary Efficacy` = 0.30,
#'   `Secondary Efficacy` = 0.20,
#'   `Quality of Life` = 0.10,
#'   `Recurring AE` = 0.30,
#'   `Rare SAE` = 0.10
#' )
#'
#' # Vary the weight on a single criterion
#' mcda_weight_sensitivity(
#'   data = mcda_data |> dplyr::filter(Study == "Study 1"),
#'   weights = weights,
#'   clinical_scales = clinical_scales,
#'   criteria = "Recurring AE"
#' )
#'
#' # One panel per criterion
#' mcda_weight_sensitivity(
#'   data = mcda_data |> dplyr::filter(Study == "Study 1"),
#'   weights = weights,
#'   clinical_scales = clinical_scales
#' )
mcda_weight_sensitivity <- function(
    data,
    weights,
    clinical_scales,
    comparator_name = NULL,
    criteria = NULL,
    fig_colors = NULL,
    ref_line_color = "#ca0020",
    show_crossovers = TRUE,
    shading = c("change", "hiview", "none"),
    shade_color = "#4EADD0",
    base_font_size = 9
) {
  typography <- publication_typography(base_font_size = base_font_size)
  shading <- match.arg(shading)

  if (!is.numeric(weights) || is.null(names(weights))) {
    stop(
      "`weights` must be a named numeric vector (e.g., c(`Primary Efficacy` = 0.3, ...)). ",
      "The name `weights` conflicts with a base R function \u2014 ensure you have defined ",
      "your own weights object, or load the example via data(weights)."
    )
  }
  if (abs(sum(weights) - 1) > 1e-6) {
    stop("`weights` must sum to 1 (current sum: ", round(sum(weights), 4), ").")
  }
  if (!is.list(clinical_scales)) {
    stop(
      "`clinical_scales` must be a named list. ",
      "Ensure you have defined it, or load the example via data(clinical_scales)."
    )
  }
  if (!"Treatment" %in% colnames(data)) {
    stop("`data` must contain a Treatment column.")
  }

  all_criteria <- names(weights)
  missing_cols <- setdiff(all_criteria, colnames(data))
  if (length(missing_cols) > 0) {
    stop(
      "Criteria in `weights` not found in `data`: ",
      paste(missing_cols, collapse = ", ")
    )
  }
  missing_scales <- setdiff(all_criteria, names(clinical_scales))
  if (length(missing_scales) > 0) {
    stop(
      "Criteria in `weights` missing from `clinical_scales`: ",
      paste(missing_scales, collapse = ", ")
    )
  }

  if (is.null(criteria)) {
    criteria <- all_criteria
  }
  unknown <- setdiff(criteria, all_criteria)
  if (length(unknown) > 0) {
    stop(
      "`criteria` not found in `weights`: ", paste(unknown, collapse = ", ")
    )
  }

  normalize_value <- function(x, scale) {
    if (scale$direction == "increasing") {
      values <- 100 * (x - scale$min) / (scale$max - scale$min)
    } else if (scale$direction == "decreasing") {
      values <- 100 * (scale$max - x) / (scale$max - scale$min)
    } else {
      stop("Direction must be 'increasing' or 'decreasing'")
    }
    if (
      !is.null(scale$allow_extrapolation) &&
        !scale$allow_extrapolation
    ) {
      values <- pmax(0, pmin(100, values))
    }
    values
  }

  # Preference values: rows = data rows, columns = criteria
  pref <- vapply(
    all_criteria,
    function(cr) normalize_value(data[[cr]], clinical_scales[[cr]]),
    numeric(nrow(data))
  )
  pref <- matrix(
    pref,
    nrow = nrow(data),
    dimnames = list(NULL, all_criteria)
  )
  treatments <- as.character(data$Treatment)

  if (is.null(comparator_name)) {
    if (length(treatments) < 2) {
      stop("Need at least two treatments present in data.")
    }
  } else {
    # Score each treatment by its difference from the comparator in the
    # same study
    is_comparator <- treatments == comparator_name
    if (!any(is_comparator)) {
      stop("`comparator_name` \"", comparator_name, "\" not found in data$Treatment.")
    }
    study <- if ("Study" %in% colnames(data)) {
      as.character(data$Study)
    } else {
      rep("", nrow(data))
    }
    if (anyDuplicated(study[is_comparator])) {
      stop("Each study must have exactly one `comparator_name` row.")
    }
    comparator_row <- which(is_comparator)[
      match(study[!is_comparator], study[is_comparator])
    ]
    if (anyNA(comparator_row)) {
      stop(
        "No comparator row for study: ",
        paste(unique(study[!is_comparator][is.na(comparator_row)]), collapse = ", ")
      )
    }
    pref <- pref[!is_comparator, , drop = FALSE] -
      pref[comparator_row, , drop = FALSE]
    treatments <- treatments[!is_comparator]
    if (length(treatments) < 1) {
      stop("Need at least one treatment besides the comparator.")
    }
  }

  if (anyDuplicated(treatments)) {
    stop(
      "Treatment names must be unique. If `data` holds several studies, ",
      "filter to one study first (e.g., dplyr::filter(Study == \"Study 1\")), ",
      "drop the shared comparator rows, or set `comparator_name`."
    )
  }
  rownames(pref) <- treatments

  # For each criterion, score(w) = w * v_i + (1 - w) * score without i,
  # where the other weights are rescaled proportionally to sum to 1 - w.
  lines <- do.call(rbind, lapply(criteria, function(cr) {
    others <- setdiff(all_criteria, cr)
    w_others <- weights[others] / sum(weights[others])
    data.frame(
      Criterion = cr,
      Treatment = treatments,
      score_at_0 = as.numeric(pref[, others, drop = FALSE] %*% w_others),
      score_at_100 = pref[, cr],
      current_weight = weights[[cr]],
      stringsAsFactors = FALSE
    )
  }))
  lines$current_score <- lines$score_at_0 +
    lines$current_weight * (lines$score_at_100 - lines$score_at_0)
  rownames(lines) <- NULL

  # Weights where the top-ranked treatment changes
  crossovers <- do.call(rbind, lapply(criteria, function(cr) {
    d <- lines[lines$Criterion == cr, ]
    if (nrow(d) < 2) {
      return(NULL)
    }
    slope <- d$score_at_100 - d$score_at_0
    pairs <- which(upper.tri(diag(nrow(d))), arr.ind = TRUE)
    w <- apply(pairs, 1, function(p) {
      ds <- slope[p[1]] - slope[p[2]]
      if (abs(ds) < 1e-12) {
        return(NA_real_)
      }
      (d$score_at_0[p[2]] - d$score_at_0[p[1]]) / ds
    })
    w <- unique(round(w[!is.na(w) & w > 1e-9 & w < 1 - 1e-9], 10))
    if (length(w) == 0) {
      return(NULL)
    }
    scores <- outer(w, slope) + matrix(d$score_at_0, length(w), nrow(d), byrow = TRUE)
    top_score <- apply(scores, 1, max)
    # Keep only crossings of the upper envelope (a change in the leader)
    eps <- 1e-6
    lead_before <- apply(
      outer(w - eps, slope) +
        matrix(d$score_at_0, length(w), nrow(d), byrow = TRUE),
      1, which.max
    )
    lead_after <- apply(
      outer(w + eps, slope) +
        matrix(d$score_at_0, length(w), nrow(d), byrow = TRUE),
      1, which.max
    )
    keep <- lead_before != lead_after
    if (!any(keep)) {
      return(NULL)
    }
    data.frame(
      Criterion = cr,
      weight = w[keep],
      score = top_score[keep],
      from = d$Treatment[lead_before[keep]],
      to = d$Treatment[lead_after[keep]],
      stringsAsFactors = FALSE
    )
  }))
  if (is.null(crossovers)) {
    crossovers <- data.frame(
      Criterion = character(), weight = numeric(), score = numeric(),
      from = character(), to = character(), stringsAsFactors = FALSE
    )
  }

  # Weight ranges between crossovers, with the treatment preferred in each
  regions <- do.call(rbind, lapply(criteria, function(cr) {
    d <- lines[lines$Criterion == cr, ]
    score_at <- function(wt) d$score_at_0 + wt * (d$score_at_100 - d$score_at_0)
    breaks <- sort(c(0, crossovers$weight[crossovers$Criterion == cr], 1))
    lo <- breaks[-length(breaks)]
    hi <- breaks[-1]
    leader <- vapply((lo + hi) / 2, function(wt) which.max(score_at(wt)), 1L)
    current_leader <- which.max(score_at(weights[[cr]]))
    data.frame(
      Criterion = cr,
      weight_from = lo,
      weight_to = hi,
      preferred = d$Treatment[leader],
      score_from = vapply(seq_along(lo), function(i) score_at(lo[i])[leader[i]], 1),
      score_to = vapply(seq_along(hi), function(i) score_at(hi[i])[leader[i]], 1),
      differs_from_current = leader != current_leader,
      shaded = switch(shading,
        change = leader != current_leader,
        hiview = length(lo) > 1 & seq_along(lo) %% 2 == 1,
        none = rep(FALSE, length(lo))
      ),
      stringsAsFactors = FALSE
    )
  }))
  rownames(regions) <- NULL

  lines$Criterion <- factor(lines$Criterion, levels = criteria)
  lines$Treatment <- factor(lines$Treatment, levels = treatments)
  crossovers$Criterion <- factor(crossovers$Criterion, levels = criteria)
  regions$Criterion <- factor(regions$Criterion, levels = criteria)

  shaded <- regions[regions$shaded, ]
  df_shade <- data.frame(
    Criterion = rep(shaded$Criterion, each = 2),
    region = rep(seq_len(nrow(shaded)), each = 2),
    x = 100 * as.vector(rbind(shaded$weight_from, shaded$weight_to)),
    ymax = as.vector(rbind(shaded$score_from, shaded$score_to))
  )

  df_segments <- lines
  df_segments$x <- 0
  df_segments$xend <- 100

  df_ref <- unique(lines[, c("Criterion", "current_weight")])

  # Overall scores lie on 0-100; differences from the comparator can be
  # negative, so fit the axis to the lines and mark zero
  if (is.null(comparator_name)) {
    y_breaks <- seq(0, 100, 20)
    y_title <- "Overall weighted score"
  } else {
    y_breaks <- pretty(c(0, lines$score_at_0, lines$score_at_100))
    y_title <- paste0("Weighted score difference vs ", comparator_name)
  }
  y_limits <- range(y_breaks)

  if (is.null(fig_colors)) {
    fig_colors <- c(
      "#0571b0", "#EE8000", "#96BA39", "#5E366E", "#4EADD0", "#CF004D"
    )
  }
  trt_colors <- stats::setNames(
    rep(fig_colors, length.out = length(treatments)),
    treatments
  )

  p <- ggplot2::ggplot()

  if (nrow(df_shade) > 0) {
    p <- p +
      ggplot2::geom_ribbon(
        data = df_shade,
        ggplot2::aes(x = x, ymin = y_limits[1], ymax = ymax, group = region),
        fill = shade_color, alpha = 0.3
      )
  }

  if (!is.null(comparator_name)) {
    p <- p +
      ggplot2::geom_hline(yintercept = 0, color = "grey40", linewidth = 0.5)
  }

  p <- p +
    ggplot2::geom_vline(
      data = df_ref,
      ggplot2::aes(xintercept = 100 * current_weight),
      color = ref_line_color, linewidth = 0.8
    ) +
    ggplot2::geom_segment(
      data = df_segments,
      ggplot2::aes(
        x = x, xend = xend,
        y = score_at_0, yend = score_at_100,
        color = Treatment
      ),
      linewidth = 1
    ) +
    ggplot2::geom_point(
      data = lines,
      ggplot2::aes(x = 100 * current_weight, y = current_score, color = Treatment),
      size = 2.2
    )

  if (show_crossovers && nrow(crossovers) > 0) {
    p <- p +
      ggplot2::geom_point(
        data = crossovers,
        ggplot2::aes(x = 100 * weight, y = score),
        shape = 21, fill = "white", color = "black", size = 2.6, stroke = 0.8
      ) +
      ggrepel::geom_text_repel(
        data = crossovers,
        ggplot2::aes(
          x = 100 * weight, y = score,
          label = sprintf("%.1f%%", 100 * weight)
        ),
        nudge_y = -0.08 * diff(y_limits), direction = "x", segment.size = 0.3,
        min.segment.length = 0, box.padding = 0.15, seed = 1,
        color = "black",
        size = publication_geom_text_size(typography$data_label)
      )
  }

  p <- p +
    ggplot2::scale_color_manual(name = NULL, values = trt_colors) +
    ggplot2::scale_x_continuous(
      limits = c(0, 100), breaks = seq(0, 100, 20),
      expand = ggplot2::expansion(mult = c(0.02, 0.04))
    ) +
    ggplot2::scale_y_continuous(limits = y_limits, breaks = y_breaks) +
    ggplot2::labs(
      x = "Weight on criterion (%)",
      y = y_title
    ) +
    ggplot2::theme_minimal(base_size = base_font_size) +
    ggplot2::theme(
      legend.position = "top",
      panel.grid.minor = ggplot2::element_blank(),
      axis.line = ggplot2::element_line("black", linewidth = 0.6),
      axis.ticks = ggplot2::element_line("black", linewidth = 0.6),
      axis.text = ggplot2::element_text(color = "black", size = typography$tick),
      axis.title = ggplot2::element_text(size = typography$axis_title),
      legend.text = ggplot2::element_text(size = typography$legend_text),
      strip.text = ggplot2::element_text(
        face = "bold", size = typography$strip_text
      )
    ) +
    ggplot2::coord_cartesian(clip = "off")

  if (length(criteria) > 1) {
    p <- p + ggplot2::facet_wrap(~Criterion)
  } else {
    p <- p + ggplot2::labs(x = paste0("Weight on ", criteria, " (%)"))
  }

  attr(p, "sensitivity_lines") <- lines
  attr(p, "crossovers") <- crossovers
  attr(p, "preferred_regions") <- regions
  p
}
