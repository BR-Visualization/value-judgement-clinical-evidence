#' Create MCDA Tornado Plot
#'
#' @param data A data frame in wide format with Treatment column and
#'   criteria columns. Required parameter - must be provided. Each row
#'   should contain raw values for a treatment on their original
#'   measurement scales. See \code{\link{mcda_data}} for example format.
#' @param comparator_name Character string specifying the name of the
#'   reference treatment (e.g., placebo or active control) in the data.
#'   Default is "Placebo".
#' @param comparison_drug Character string specifying which drug to
#'   compare with the reference treatment in the visualization.
#'   Default is "Drug A".
#' @param weights Named numeric vector of criterion weights. Must sum to 1.
#'   If NULL, uses equal weights.
#' @param clinical_scales List defining clinical reference levels for
#'   each criterion. Each element should be a list with: min (lower
#'   threshold), max (upper threshold), direction ("increasing" for
#'   higher is better, "decreasing" for lower is better).
#' @param fig_colors A vector of length 2 specifying colors for benefits
#'   and risks. Default is c("#0571b0", "#ca0020") to match
#'   correlogram colors.
#' @param weight_change A numerical input specifying the percentage change in
#'   weight that will be observed across the criterion. Default is 20.
#' @param base_font_size Numeric; base font size in points for all text
#'   elements in the plot (default: 9).
#'
#' @return A ggplot object displaying criterion-specific weights toggled by
#' a specified percentage (default is 20), and the corresponding difference in
#' BRScore between the comparison and comparator treatments.
#' @export
#' @import ggplot2
#'
#' @examples
#' # Load example MCDA data
#' data(mcda_data)
#'
#' # View the data structure - each row has raw values for a treatment
#' head(mcda_data)
#' #   Treatment Benefit 1 Benefit 2 Benefit 3 Risk 1 Risk 2
#' # 1   Placebo      0.05        65         9   0.30  0.087
#' # 2    Drug A      0.46        20        60   0.46  0.100
#' # 3    Drug B      ...
#'
#' # Define clinical scales
#' clinical_scales <- list(
#'   `Benefit 1` = list(min = 0, max = 1, direction = "increasing"),
#'   `Benefit 2` = list(min = 0, max = 100, direction = "decreasing"),
#'   `Benefit 3` = list(min = 0, max = 100, direction = "increasing"),
#'   `Risk 1` = list(min = 0, max = 0.5, direction = "decreasing"),
#'   `Risk 2` = list(min = 0, max = 0.3, direction = "decreasing")
#' )
#'
#' # Define weights
#' weights <- c(
#'   `Benefit 1` = 0.30,
#'   `Benefit 2` = 0.20,
#'   `Benefit 3` = 0.10,
#'   `Risk 1` = 0.30,
#'   `Risk 2` = 0.10
#' )
#'
#' # Create sensitivity plot toggling criterion weight by 20 percent
#' sensitivity_plot <- mcda_tornado(
#'   data = mcda_data |>
#'            dplyr::filter(Study == "Study 1") |>
#'              dplyr::select(-Study),
#'   comparison_drug = "Drug A",
#'   clinical_scales = clinical_scales,
#'   weights = weights
#' )
mcda_tornado <- function(
    data,
    comparator_name = "Placebo",
    comparison_drug,
    weights,
    clinical_scales,
    fig_colors = c("#0571b0", "#ca0020"),
    weight_change = 20,
    base_font_size = 9
) {

  df_brscore <- tidyr::pivot_longer(
    data,
    cols = -Treatment,
    names_to = "Endpoint",
    values_to = "AVAL"
  )

  df_brscore <- df_brscore |> dplyr::mutate(
    WEIGHT = sapply(Endpoint, function(x) weights[[x]]),
    BEST = sapply(Endpoint, function(x) clinical_scales[[x]]$max),
    WORST = sapply(Endpoint, function(x) clinical_scales[[x]]$min),
    direction = sapply(
      Endpoint, function(x) clinical_scales[[x]]$direction
    )
  )

  treatments <- unique(df_brscore$Treatment)
  if (length(treatments) < 2) {
    stop("Need at least two treatments present in eff_data.")
  }

  df_brscore <- df_brscore |> dplyr::mutate(w_label = "original")

  weight <- weight_change / 100
  pos_we <- 1 + weight
  neg_we <- 1 - weight

  endpoints <- unique(df_brscore$Endpoint)

  df_res <- df_brscore |> dplyr::mutate(scenario_id = 0L)

  make_scenario <- function(df_base, endpoint_i, boost_factor, label_prefix) {
    orig_w_i <- df_base |>
      dplyr::filter(Endpoint == endpoint_i) |>
      dplyr::distinct(Endpoint, .keep_all = TRUE) |>
      dplyr::pull(WEIGHT) |>
      sum(na.rm = TRUE)

    boosted_total <- orig_w_i * boost_factor

    remaining_total_orig <- df_base |>
      dplyr::filter(Endpoint != endpoint_i) |>
      dplyr::distinct(Endpoint, .keep_all = TRUE) |>
      dplyr::summarise(s = sum(WEIGHT, na.rm = TRUE)) |>
      dplyr::pull(s)

    if (is.na(remaining_total_orig) || remaining_total_orig <= 0) {
      stop("No remaining endpoints to redistribute for endpoint: ", endpoint_i)
    }

    scale_remaining <- (1 - boosted_total) / remaining_total_orig
    if (!is.finite(scale_remaining)) {
      stop(
        "Non-finite scaling for endpoint: ", endpoint_i,
        " (boosted_total=", boosted_total,
        ", remaining_total_orig=", remaining_total_orig, ")"
      )
    }

    boosted_group <- df_base |>
      dplyr::filter(Endpoint == endpoint_i) |>
      dplyr::mutate(
        WEIGHT = WEIGHT * boost_factor,
        w_label = paste0(label_prefix, endpoint_i)
      )

    remaining_group <- df_base |>
      dplyr::filter(Endpoint != endpoint_i) |>
      dplyr::mutate(
        WEIGHT = WEIGHT * scale_remaining,
        w_label = paste0(label_prefix, endpoint_i)
      )

    dplyr::bind_rows(boosted_group, remaining_group)
  }

  scenario_counter <- 1L
  for (ep in endpoints) {
    scen <- make_scenario(df_brscore, ep, pos_we, "plus_")
    scen <- scen |> dplyr::mutate(scenario_id = scenario_counter)
    df_res <- dplyr::bind_rows(df_res, scen)
    scenario_counter <- scenario_counter + 1L
  }
  for (ep in endpoints) {
    scen <- make_scenario(df_brscore, ep, neg_we, "minus_")
    scen <- scen |> dplyr::mutate(scenario_id = scenario_counter)
    df_res <- dplyr::bind_rows(df_res, scen)
    scenario_counter <- scenario_counter + 1L
  }

  df_res <- df_res |>
    dplyr::mutate(
      trans_trt = ifelse(
        direction == "increasing",
        100 * (AVAL - WORST) / (BEST - WORST),
        100 * (BEST - AVAL) / (BEST - WORST)
      )
    )

  treatment1 <- comparison_drug
  treatment2 <- comparator_name

  endpoint_diff <- df_res |>
    dplyr::group_by(w_label, scenario_id, Endpoint) |>
    dplyr::summarise(
      # grab one trans_trt per treatment (first occurrence)
      trans_t1 = trans_trt[Treatment == treatment1][1],
      trans_t2 = trans_trt[Treatment == treatment2][1],
      WEIGHT_endpoint = WEIGHT[1],
      .groups = "drop"
    ) |>
    dplyr::mutate(
      diff_trt = trans_t1 - trans_t2,
      BRScore_endpoint = diff_trt * WEIGHT_endpoint
    )

  df_res <- df_res |>
    dplyr::left_join(
      endpoint_diff |>
        dplyr::select(
          w_label, scenario_id, Endpoint,
          diff_trt, BRScore_endpoint, WEIGHT_endpoint
        ),
      by = c("w_label", "scenario_id", "Endpoint")
    )

  df_res <- df_res |>
    dplyr::rename(
      BRScore = BRScore_endpoint,
      weight_endpoint = WEIGHT_endpoint
    )

  df_res <- df_res |>
    dplyr::mutate(Endpoint = factor(Endpoint, levels = endpoints)) |>
    dplyr::arrange(w_label, scenario_id, Treatment, Endpoint) |>
    dplyr::mutate(group = paste0(w_label, "_", scenario_id)) |>
    dplyr::group_by(group) |>
    dplyr::arrange(Endpoint, .by_group = TRUE) |>
    dplyr::ungroup()

  scenario_totals <- endpoint_diff |>
    dplyr::group_by(w_label, scenario_id) |>
    dplyr::summarise(diff_tot = sum(BRScore_endpoint), .groups = "drop")

  df_res <- df_res |>
    dplyr::left_join(scenario_totals, by = c("w_label", "scenario_id"))

  df_res_orig <- df_res |> dplyr::filter(w_label == "original")
  df_res_fil <- df_res |>
    dplyr::filter(w_label != "original") |>
    dplyr::mutate(Crit = sub("^(minus_|plus_)", "", w_label)) |>
    dplyr::filter(as.character(Endpoint) == Crit)

  df_final <- dplyr::bind_rows(df_res_orig, df_res_fil)

  df_final <- df_final |>
    dplyr::mutate(w_label = dplyr::case_when(
      grepl("^plus_", w_label)  ~ "plus",
      grepl("^minus_", w_label) ~ "minus",
      TRUE ~ as.character(w_label)
    ))

  central <- df_final |>
    dplyr::filter(w_label == "original") |>
    dplyr::select(diff_tot) |>
    dplyr::distinct() |>
    dplyr::pull()

  if (length(central) == 0) central <- 0
  central_val <- central[[1]]

  df_bars <- df_final |>
    dplyr::mutate(ind = dplyr::case_when(
      w_label == "minus" ~ "low",
      w_label == "plus"  ~ "high",
      TRUE ~ NA_character_
    ))

  unique_lab <- df_bars |>
    dplyr::filter(!is.na(ind)) |>
    dplyr::pull(ind) |>
    unique()

  vec_color <- fig_colors
  if (length(vec_color) < length(unique_lab)) {
    vec_color <- rep(vec_color, length.out = length(unique_lab))
  }

  colors2 <- stats::setNames(vec_color, unique_lab)

  df_bars <- df_bars |>
    dplyr::mutate(color = as.character(colors2[ind])) |>
    dplyr::mutate(
      delta = diff_tot - central_val,
      pos = dplyr::case_when(
        delta > 0 ~ "right",
        delta < 0 ~ "left",
        TRUE ~ "center"  # exactly equal to central
      )
    ) |>
    dplyr::filter(w_label != "original") |>
    dplyr::group_by(Endpoint) |>
    dplyr::mutate(
      xmin = ifelse(pos == "left", diff_tot, central_val),
      xmax = ifelse(pos == "right", diff_tot, central_val),
      ymin = as.numeric(Endpoint) - 0.25,
      ymax = as.numeric(Endpoint) + 0.25
    ) |>
    dplyr::ungroup() |>
    dplyr::mutate(
      label_offset = 0.1 * (
        max(diff_tot, na.rm = TRUE) - min(diff_tot, na.rm = TRUE)
      ),

      label_x = dplyr::case_when(
        direction == "increasing" &
          pos == "left" & ind == "low" ~
          xmin - label_offset,
        direction == "increasing" &
          pos == "right" & ind == "high" ~
          xmax + label_offset,
        direction == "decreasing" &
          pos == "left" & ind == "high" ~
          xmin - label_offset,
        direction == "decreasing" &
          pos == "right" & ind == "low" ~
          xmax + label_offset,
        TRUE ~ central_val
      ),

      label_y = (ymin + ymax) / 2
    )

  order_endpoints <- df_bars |>
    dplyr::group_by(Endpoint) |>
    dplyr::summarise(
      max_len = max(abs(diff_tot - central_val), na.rm = TRUE)
    ) |>
    dplyr::arrange((max_len))
  endpoint_levels <- order_endpoints$Endpoint

  df_bar <- df_final |>
    dplyr::filter(w_label == "original") |>
    dplyr::select(Endpoint, weight_endpoint) |>
    dplyr::distinct() |>
    dplyr::mutate(x_lab = central_val, y_lab = as.numeric(Endpoint) - 0.5)

  df_bar <- df_bar |>
    dplyr::mutate(Endpoint = factor(Endpoint, levels = endpoint_levels))
  df_bars <- df_bars |>
    dplyr::mutate(Endpoint = factor(Endpoint, levels = endpoint_levels))
  df_final <- df_final |>
    dplyr::mutate(Endpoint = factor(Endpoint, levels = endpoint_levels))

  df_bars <- df_bars |>
    dplyr::mutate(
      ymin = as.numeric(Endpoint) - 0.25,
      ymax = as.numeric(Endpoint) + 0.25,
      label_y = (ymin + ymax) / 2
    )

  df_bar <- df_bar |>
    dplyr::mutate(
      y_lab = as.numeric(Endpoint) - 0.5
    )

  df_bars <- df_bars |>
    dplyr::mutate(
      scenario = dplyr::case_when(
        ind == "low"  ~ "20% less",
        ind == "high" ~ "20% more",
        TRUE ~ NA_character_
      )
    )

  weight_table <- df_bars |>
    dplyr::select(Endpoint, scenario, weight_endpoint, label_y) |>
    dplyr::filter(!is.na(scenario)) |>
    dplyr::bind_rows(
      df_final |>
        dplyr::filter(w_label == "original") |>
        dplyr::mutate(
          scenario = "original",
          label_y = as.numeric(Endpoint)
        ) |>
        dplyr::select(Endpoint, scenario, weight_endpoint, label_y)
    ) |>
    dplyr::mutate(
      scenario = factor(
        scenario,
        levels = c("20% less", "original", "20% more")
      )
    ) |>
    dplyr::group_by(Endpoint, scenario, label_y) |>
    dplyr::summarise(
      weight_endpoint = mean(weight_endpoint, na.rm = TRUE),
      .groups = "drop"
    ) |>
    dplyr::mutate(weight_pct = round(weight_endpoint * 100, 1))

  p_tornado <- ggplot2::ggplot() +
    ggplot2::geom_rect(
      data = df_bars,
      ggplot2::aes(
        xmin = xmin, xmax = xmax,
        ymin = ymin, ymax = ymax, fill = color
      )
    ) +
    ggplot2::scale_y_continuous(
      breaks = unique(as.numeric(df_final$Endpoint)),
      labels = unique(df_final$Endpoint)
    ) +
    ggplot2::scale_fill_manual(
      name = "Weight Change",
      labels = unique_lab,
      values = vec_color
    ) +
    ggplot2::theme_minimal(base_size = base_font_size) +
    ggplot2::labs(
      x = paste0(
        "BRScore (", comparison_drug, "-", comparator_name, ")"
      ),
      y = NULL
    ) +
    ggplot2::theme(
      legend.position = "top",   # move legend to top
      panel.grid.major.y = ggplot2::element_blank(),
      panel.grid.minor.y = ggplot2::element_blank(),
      axis.line.x = ggplot2::element_line("black", size = 1),
      axis.ticks.x = ggplot2::element_line("black", size = 1),
      axis.ticks.length = grid::unit(0.2, "cm"),
      axis.text.x = ggplot2::element_text(color = "black", size = base_font_size * 1.11),
      axis.text.y = ggplot2::element_text(color = "black", size = base_font_size * 1.11)
    ) +
    ggplot2::scale_x_continuous(
      sec.axis = ggplot2::dup_axis(name = NULL)
    ) +
    ggplot2::coord_cartesian(clip = "off")

  p_table <- ggplot2::ggplot(
    weight_table,
    ggplot2::aes(x = scenario, y = label_y)
  ) +
    ggplot2::geom_hline(
      ggplot2::aes(yintercept = label_y + 0.40),
      color = "grey80", linewidth = 0.5
    ) +
    ggplot2::geom_hline(
      yintercept = max(weight_table$label_y) + 0.40,
      color = "black", linewidth = 0.5
    ) +
    ggplot2::geom_vline(
      xintercept = c(1.5, 2.5),
      color = "grey80", linewidth = 0.5
    ) +
    ggplot2::geom_text(
      ggplot2::aes(label = paste0(weight_pct, "%")),
      hjust = 0.5,
      size = base_font_size * 0.35
    ) +
    ggplot2::scale_x_discrete(
      name = "Weight Change", position = "top",
      expand = c(0.1, 0.1)
    ) +
    ggplot2::scale_y_continuous(
      breaks = unique(df_bars$label_y),
      labels = NULL,
      expand = c(0, 0),
      limits = c(
        min(weight_table$label_y) - 0.40,
        max(weight_table$label_y) + 0.40
      )
    ) +
    ggplot2::theme_void(base_size = base_font_size) +
    ggplot2::theme(
      axis.title.x.top = ggplot2::element_text(
        color = "black", face = "bold", size = base_font_size * 1.11,
        margin = ggplot2::margin(b = 5, t = 0)
      ),
      axis.text.x.top = ggplot2::element_text(
        color = "black", face = "bold", size = base_font_size * 1.11,
        margin = ggplot2::margin(b = 5, t = 5),
        vjust = 0.5
      ),
      axis.text.y = ggplot2::element_blank(),
      plot.margin = grid::unit(c(0.3, 0, 0, 0), "cm")
    ) +
    ggplot2::geom_hline(
      yintercept = min(weight_table$label_y) - 0.40,
      color = "black", linewidth = 0.5
    )

  p_combined <- p_tornado + p_table +
    patchwork::plot_layout(ncol = 2, widths = c(2.5, 1.5))

  p_combined

}
