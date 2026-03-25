#' Function for colors
#'
#' @return figure colors
#' @export
#'
colfun <- function() {
  control_palettes <- data.frame(
    name = c(
      "Blue",
      "Purple",
      "Pink",
      "Orange",
      "Black",
      "Grey 4",
      "Grey 3",
      "Grey 2",
      "Grey 1",
      "Secondary Blue",
      "Secondary Green"
    ),
    hex = c(
      "#354B96",
      "#5E366E",
      "#CF004D",
      "#EE8000",
      "#1C1C1B",
      "#555555",
      "#888888",
      "#BCBCBC",
      "#ECEDED",
      "#4EADD0",
      "#96BA39"
    ),
    order = c(
      1,
      2,
      3,
      4,
      5,
      6,
      7,
      8,
      9,
      10,
      11
    )
  )
  fig2_colors <- c("#00AFBB", "#FFDB6D")
  fig3_colors <- colorBlindness::Blue2DarkOrange18Steps[12:18]
  fig4_colors <- c("#ABDDA4", "#66C2A5", "#3288BD")
  fig6_colors <- c("#d7191c", "#009292", "#ff6db6", "#490092", "#006ddb")
  fig7_colors <- c("#f8766d", "#ffc300", "#00bfc4", "#c77cff")
  fig10_colors <- c("#0571b0", "white", "#ca0020")
  fig11_colors <- c("#00AFBB", "red", "blue")
  fig12_colors <- c("chartreuse3", "yellow", "gray85", "red2", "black")
  fig13_colors <- c("#0571b0", "#ca0020")

  list(
    control_palettes = control_palettes,
    fig2_colors = fig2_colors,
    fig3_colors = fig3_colors,
    fig4_colors = fig4_colors,
    fig6_colors = fig6_colors,
    fig7_colors = fig7_colors,
    fig10_colors = fig10_colors,
    fig11_colors = fig11_colors,
    fig12_colors = fig12_colors,
    fig13_colors = fig13_colors
  )
}


#' Control Fonts
#'
#' @description `control_fonts()` calculates font-sizes depending on output size
#'
#' @param base_font_size (unit)\cr Font-size of normal paragraph
#'   text. By default is 9pt. By editing this value, all the other
#'   parameters get updated too.
#'
#' @param h1 (unit)\cr Font-size of title of the graph, dependent
#'   of `base_font_size`. By default, 12pt.
#'
#' @param h2 (unit)\cr Font-size of subtitle of the graph,
#'   dependent of `base_font_size`. By default, 10pt.
#'
#' @param label (unit)\cr Font-size of text that's called outside the ggplot
#'   theme. It should render at the same font size as base_font_size
#'
#' @details It returns a list with the font sizes of:
#'
#' * **p** - normal text elements within the ggplot theme.
#'
#' * **h1** - titles.
#'
#' * **h2** - subtitles.
#'
#' * **label** - for text elements outside the ggplot theme. If you want to add
#' an annotation or a label to your plot, use the font size `label`. By default,
#' it renders at 10pt.
#'
#' * **rel** - for legend elements.
#'
#' @export
#' @examples
#' control_fonts(base_font_size = 10)
control_fonts <- function(
  base_font_size = 9,
  h1 = 12,
  h2 = 10,
  label = base_font_size + 1
) {
  rel <- 7.253 / base_font_size

  list(
    p = base_font_size,
    h1 = h1 * rel * 1.2,
    h2 = h2 * rel * 1.25,
    label = label * rel * 0.423,
    rel = base_font_size * rel
  )
}

#' Publication Typography Profile
#'
#' @description Defines a consistent publication typography scale for common
#' plot element classes.
#'
#' @param base_font_size Base printed font size in points.
#' @param title_ratio Ratio for plot titles.
#' @param subtitle_ratio Ratio for subtitles and strip labels.
#' @param axis_title_ratio Ratio for axis and legend titles.
#' @param annotation_ratio Ratio for annotations and in-panel value labels.
#'
#' @return Named list of point sizes for publication text elements.
#' @export
publication_typography <- function(
  base_font_size = 9,
  title_ratio = 1.15,
  subtitle_ratio = 1.05,
  axis_title_ratio = 1.05,
  annotation_ratio = 0.95
) {
  list(
    base = base_font_size,
    tick = base_font_size,
    axis_title = base_font_size * axis_title_ratio,
    legend_text = base_font_size,
    legend_title = base_font_size * axis_title_ratio,
    plot_title = base_font_size * title_ratio,
    plot_subtitle = base_font_size * subtitle_ratio,
    strip_text = base_font_size * subtitle_ratio,
    annotation = base_font_size * annotation_ratio,
    data_label = base_font_size * annotation_ratio
  )
}

#' Convert points to ggplot geom text size units
#'
#' @param point_size Font size in points.
#'
#' @return Numeric size value for `geom_text(size = ...)`.
#' @export
publication_geom_text_size <- function(point_size) {
  point_size / 2.845276
}


#' Calculate Font Size Based on Figure Dimensions
#'
#' @description Scales font size proportionally to figure dimensions to maintain
#' visual consistency across plots of different sizes. Font size scales with the
#' square root of the area to ensure readability.
#'
#' For combined plots (e.g., patchwork or cowplot layouts), use \code{ncol} and
#' \code{nrow} to specify the panel grid. The function will compute the effective
#' per-panel dimensions and size the font accordingly, so text remains
#' appropriately sized after the layout engine shrinks each panel.
#'
#' @param width Figure width in inches
#' @param height Figure height in inches
#' @param ncol Number of panel columns in a combined layout (default: 1).
#'   For example, a 2-column patchwork layout should use \code{ncol = 2}.
#' @param nrow Number of panel rows in a combined layout (default: 1).
#'   For example, a 2-row cowplot layout should use \code{nrow = 2}.
#' @param reference_font_size Base font size for reference dimensions (default: 9pt)
#' @param reference_width Reference width in inches (default: 7)
#' @param reference_height Reference height in inches (default: 7)
#' @param min_font_size Minimum font size to prevent text being too small (default: 6)
#' @param max_font_size Maximum font size to prevent text being too large (default: 14)
#'
#' @return List containing font configuration from control_fonts()
#' @export
#'
#' @examples
#' # Font config for a small 5×4 plot
#' font_config(5, 4)
#'
#' # Font config for a large 16×6 plot
#' font_config(16, 6)
#'
#' # Font config for a 16×6 figure with 4 side-by-side panels
#' # (each panel is effectively 4×6)
#' font_config(16, 6, ncol = 4)
#'
#' # Font config for a 14×5 figure with 2 side-by-side panels
#' font_config(14, 5, ncol = 2)
font_config <- function(
  width,
  height,
  ncol = 1,
  nrow = 1,
  reference_font_size = 9,
  reference_width = 7,
  reference_height = 7,
  min_font_size = 6,
  max_font_size = 14
) {
  # Compute effective per-panel dimensions for combined layouts
  panel_width <- width / ncol
  panel_height <- height / nrow

  # Calculate area ratio and scale by square root for proportional sizing
  area_ratio <- sqrt((panel_width * panel_height) /
    (reference_width * reference_height))
  base_font_size <- reference_font_size * area_ratio

  # Apply bounds
  base_font_size <- max(min_font_size, min(max_font_size, base_font_size))

  # Return font configuration
  control_fonts(base_font_size = base_font_size)
}

#' BR charts theme
#'
#' @param base_family - font
#' @param base_font_size (unit)\cr Font-size of normal paragraph text.
#' @param base_stroke (unit)\cr line thickness
#' @param margin (unit)\cr margin around entire plot (unit with the sizes of the
#'  top, right, bottom, and left margins)
#' @param get_fonts fonts
#' @param get_colors colors
#' @param axis_text_x tick labels along axes
#' @param axis_line all line elements
#' @param axis_title_y labels of axes
#' @param axis_text_y_left tick labels along axes
#' @param legend_position position
#' @param panel_grid_minor grid lines
#' @param panel_grid_major grid lines
#' @param ... Additional arguments passed to other methods.
#'
#' @return theme for chart
#' @export
br_charts_theme <- function(
  base_family = "",
  base_font_size = 9,
  base_stroke = 1,
  margin = 1,
  get_fonts = control_fonts,
  get_typography = publication_typography,
  get_colors = colfun()[["control_palettes"]],
  axis_text_x = ggplot2::element_text(
    colour = black
  ),
  axis_line = ggplot2::element_line(
    colour = black,
    size = stroke_size
  ),
  axis_title_y = ggplot2::element_text(),
  axis_text_y_left = ggplot2::element_text(
    margin = ggplot2::margin(
      t = 0,
      r = spacing / 2,
      l = 0,
      b = 0,
      unit = "pt"
    )
  ),
  legend_position = "top",
  panel_grid_minor = ggplot2::element_line(
    colour = grey_2,
    size = stroke_size / 2,
    linetype = "dashed"
  ),
  panel_grid_major = ggplot2::element_line(
    colour = grey_2,
    size = stroke_size / 2,
    linetype = "dashed"
  ),
  ...
) {
  # stroke size
  stroke_size <- base_stroke * 0.47

  # fonts
  fonts <- get_fonts(base_font_size = base_font_size)
  typography <- get_typography(base_font_size = base_font_size)

  # in pt
  spacing <- fonts$rel

  # colors
  colors <- get_colors

  black <- colors[colors$name == "Black", "hex"]
  grey_4 <- colors[colors$name == "Grey 4", "hex"]
  grey_2 <- colors[colors$name == "Grey 2", "hex"]
  white <- "#ffffff"

  # Change ggplot theme ---------------------------
  ggplot2::theme(
    # Elements in the first block are not used directly,
    # but are inherited by others
    line = ggplot2::element_line(
      colour = grey_2,
      size = stroke_size,
      linetype = 1,
      lineend = "butt"
    ),
    rect = ggplot2::element_rect(
      fill = white,
      colour = black,
      size = stroke_size,
      linetype = 1
    ),
    text = ggplot2::element_text(
      size = typography$base,
      family = base_family,
      colour = black
    ),
    axis.text = ggplot2::element_text(size = typography$tick, colour = grey_4),

    # 1 Axis format ===============================
    # sets the text font, size and colour for the axis test, and margins
    # and removes lines
    # If we need those axis lines and ticks, the cookbook shows how to add them

    # 1.1 lines
    axis.line = axis_line,

    # 1.2 texts
    # axis titles are removed by default
    axis.title = ggplot2::element_text(
      colour = black,
      face = "bold",
      size = typography$axis_title
    ),
    axis.title.y = axis_title_y,
    axis.text.x = axis_text_x,
    axis.text.x.bottom = ggplot2::element_text(
      margin = ggplot2::margin(
        t = spacing / 2,
        r = 0,
        l = 0,
        b = spacing,
        unit = "pt"
      )
    ),
    axis.text.y.left = axis_text_y_left,

    # 1.3 ticks
    axis.ticks = ggplot2::element_line(colour = black),
    axis.ticks.length = ggplot2::unit(spacing / 2, "pt"),

    # 2 Panel =========================
    panel.background = ggplot2::element_blank(),
    panel.border = ggplot2::element_blank(),
    panel.grid.minor = panel_grid_minor,
    panel.grid.major = panel_grid_major,
    panel.spacing = ggplot2::unit(spacing * 2, "pt"),

    # 3 Legend Format =============================
    # 3.1 sets the position and alignment of the legend
    # removes a title and background for it and sets the requirements
    # for any text within the legend.
    # The legend is positioned on the top left side of the chart
    legend.background = ggplot2::element_blank(),
    legend.position = legend_position,
    legend.justification = "left",
    legend.direction = "horizontal",
    legend.margin = ggplot2::margin(
      t = spacing / 4,
      r = 0,
      b = spacing / 2,
      l = 0,
      unit = "pt"
    ),
    legend.key = ggplot2::element_blank(),
    legend.key.size = ggplot2::unit(spacing * 1.5, "pt"),
    legend.title = ggplot2::element_text(
      size = typography$legend_title,
      colour = grey_4,
      margin = ggplot2::margin(r = spacing / 2, unit = "pt")
    ),
    legend.text.align = 0,
    legend.text = ggplot2::element_text(
      colour = grey_4,
      size = typography$legend_text,
      hjust = 0,
      margin = ggplot2::margin(
        t = 0,
        r = spacing * 2,
        b = 0,
        l = 0,
        unit = "pt"
      )
    ),
    legend.box = NULL,
    legend.spacing.x = ggplot2::unit(spacing / 2, "pt"),

    # 4 Title & subtitle =======================
    # it changes the font, size, weight and colour
    plot.title.position = "plot",
    plot.title = ggplot2::element_text(
      size = typography$plot_title,
      face = "bold",
      colour = black,
      margin = ggplot2::margin(
        t = 0,
        r = 0,
        b = spacing / 2,
        l = 0,
        unit = "pt"
      )
    ),
    plot.subtitle = ggplot2::element_text(
      size = typography$plot_subtitle,
      colour = black,
      hjust = 0,
      margin = ggplot2::margin(
        t = spacing / 2,
        b = spacing * 1.5,
        unit = "pt"
      )
    ),

    # 5 add a general margin to the plot ==========
    plot.margin = ggplot2::margin(
      t = spacing * 2 * margin,
      b = spacing * 2 * margin,
      l = spacing * 2 * margin,
      r = spacing * 2 * margin,
      unit = "pt"
    ),

    # 6 Facets & small multiples ==================
    # background of the title facets
    strip.background = ggplot2::element_rect(fill = white, size = 0),

    # titles of the facets
    strip.text = ggplot2::element_text(
      size = typography$strip_text,
      face = "bold",
      hjust = 0,
      margin = ggplot2::margin(t = 0, r = 0, l = 0, b = spacing, unit = "pt")
    )
  ) +
    ggplot2::theme(...)
}

#' Prepare data analysis for binary and continuous outcomes with Supplied
#' interval confidence
#' identifies whether the dataframe is for Benefit or Risk analysis
#' @param df (`data.frame`) dataset
#' either `df_benefit` (selected benefit)
#' or `df_risk` (select risk).
#' @param colname (`character`) feature to fetch for the analysis
#' either `Mean`, `Prop`, `Rate`
#' @param metric_name (`character`) metric for which we must fetch the
#' confidence interval if supplied (taken from the effect table)
#' either `Diff`, `RelRisk`, `OddsRatio`, `Diff_Rates`
#' @param func (`function`) function used to calculate metrics (or BR points)
#' @return data frame for specified type of analysis
#' @details DETAILS
#' @rdname prepare_br_supplied_ci
#' @export

prepare_br_supplied_ci <- function(df, colname, metric_name, func) {
  outcome <- sub(".*_", "", deparse(substitute(df)))
  output <- data.frame(
    df$Type,
    df$Category,
    df$Trt1,
    func(df[paste0(colname, "1")], df[paste0(colname, "2")]),
    df[paste0(metric_name, "_LowerCI")],
    df[paste0(metric_name, "_UpperCI")]
  )
  names(output) <- c(
    paste0(outcome, "_Type"),
    "Category",
    "Trt1",
    outcome,
    paste0(outcome, "_lowerCI"),
    paste0(outcome, "_upperCI")
  )
  output
}

#' Prepare data analysis for binary and continuous outcomes with Calculated
#' interval confidence
#' identifies whether the dataframe is for Benefit or Risk analysis
#' @param df (`data.frame`) dataset
#' either `df_benefit` (selected benefit)
#' or `df_risk` (select risk).
#' @param colname1 (`character`) feature to fetch for the analysis
#' either `Mean`, `Prop`, `Rate`
#' @param colname2 (`character`) feature to fetch for the analysis
#' either `nPat`, `Py`
#' @param func (`function`) function used to calculate metrics (or BR points)
#' @param cl (`numeric`) confidence level
#' @return data frame for specified type of analysis
#' @details DETAILS
#' @rdname prepare_br_calculated_ci
#' @export

prepare_br_calculated_ci <- function(df, colname1, colname2, cl = 0.95, func) {
  outcome <- sub(".*_", "", deparse(substitute(df)))
  output <- data.frame(
    df$Type,
    df$Category,
    df$Trt1,
    func(
      as.vector(unlist(df[paste0(colname1, "1")])),
      as.vector(unlist(df[paste0(colname1, "2")])),
      as.vector(unlist(df[paste0(colname2, "1")])),
      as.vector(unlist(df[paste0(colname2, "2")])),
      cl
    )
  )

  names(output) <- c(
    paste0(outcome, "_Type"),
    "Category",
    "Trt1",
    outcome,
    "se",
    paste0(outcome, "_lowerCI"),
    paste0(outcome, "_upperCI")
  )
  output
}

#' Partially bold a string
#' @param ... input argument for list function
#'
#' @return Expression
#' @export
#'
#' @examples
#' add_exprs("test_bold)", "not bold")
add_exprs <- function(...) {
  x <- list(...)
  Reduce(function(a, b) bquote(bold(.(a)):.(b)), x)
}

#' Create expression
#'
#' Selectively bold label for [ggplot2::ggplot2()].
#'
#' @param cond (`numeric`) expected conditional variable bold(1), not to bold(0)
#' @param bold (`character`)  level to bold
#' @param nonbold (`character`)\cr which level to bold.
#'
#' @details The function bold text in variable (`bold`) and concatenates it
#' with string in (`nonbold`) and returns a `dataframe`.
#'
#' @import magrittr
#' @importFrom dplyr %>% mutate if_else arrange
#'
#' @seealso `?plotmath`.
#'
#' @export
#' @examples
#' library(dplyr)
#' library(ggplot2)
#'
#' xxx <- tribble(
#'   ~x, ~z, ~w, ~y,
#'   1, "BOLD_AA", " plain", 1,
#'   2, "b", "b", 0,
#'   3, "c", "c", 0
#' )
#' ggplot(xxx, aes_string(x = "x", y = "z")) +
#'   geom_point() +
#'   scale_y_discrete(
#'     label = labs_bold(cond = xxx[["y"]], xxx[["z"]], nonbold = xxx[["w"]])
#'   )
#'
labs_bold <- function(cond, bold, nonbold) {
  gout <- vector("expression", length(bold))

  for (i in seq_along(bold)) {
    if (cond[[i]] == 1) {
      gout[[i]] <- add_exprs(bold[[i]], nonbold[[i]])
    } else {
      gout[[i]] <- nonbold[[i]]
    }
  }

  # Writing a message that will be displayed in the log
  message(glue::glue(
    '[{format(Sys.time(),"%F %T")}] > Dataout object from
               the labs_bold function is created'
  ))

  # Returning the dataout object
  gout
}

#' Derive minimum boundary value for axis
#' Derive boundary value to include all values
#'
#' @param rmin (`numeric`) number to evaluate
#' @param type_scale (`character`) selected scale display type
#' @return numeric
#' @export
#'
#' @examples
#' relmin(0.5, "Free")
#' relmin(0.5, "Fixed")
#' relmin(-0.3, "Free")
#' relmin(-0.3, "Fixed")
relmin <- function(rmin, type_scale) {
  if (type_scale == "Fixed") {
    ifelse(
      rmin >= 0,
      0,
      ifelse(
        rmin >= -1,
        floor(10 * rmin) / 10,
        floor(rmin)
      )
    )
  } else {
    ifelse(
      rmin >= 1,
      floor(rmin),
      ifelse(rmin >= -1, floor(10 * rmin) / 10, floor(rmin))
    )
  }
}

#' Derive maximum boundary value for axis
#' Derive boundary value to include all values
#'
#' @param rmax (`numeric`) number to evaluate
#' @param type_scale (`character`) selected scale display type
#' @return numeric
#' @export
#'
#' @examples
#' relmax(0.5, "Free")
#' relmax(0.5, "Fixed")
#' relmax(-0.3, "Free")
#' relmax(-0.3, "Fixed")
relmax <- function(rmax, type_scale) {
  if (type_scale == "Fixed") {
    ifelse(
      rmax <= 0,
      0,
      ifelse(
        rmax <= 1,
        ceiling(10 * rmax) / 10,
        ceiling(rmax)
      )
    )
  } else {
    ifelse(
      rmax <= -1,
      ceiling(rmax),
      ifelse(rmax <= 1, ceiling(10 * rmax) / 10, ceiling(rmax))
    )
  }
}

#' Wrapper to ggsave: Save a ggplot (or other grid object) with sensible
#' defaults
#'
#' Adds customized defaults to ggsave for the BRAP Journal requirements
#'
#' @param save_name File name to create on disk.
#' @param inplot 	Plot to save, defaults to last plot displayed.
#' @param imgpath Path of the directory to save plot to: path
#' @param bgcol Background color. If NULL, uses the plot.background fill value
#' from the plot theme.
#' @param dpi Resolution in dots per inch (default: 600).
#' @param web_suffix If TRUE, also saves a low-res version with "_web" suffix
#' (default: FALSE).
#' @param scale_fonts Deprecated parameter. Font scaling is now handled
#' by passing base_font_size directly to plotting functions.
#' @param base_font_size Deprecated parameter. Font scaling is now handled
#' by passing base_font_size directly to plotting functions.
#' @param ... Other arguments passed on to the graphics device function,
#' as specified by device.
#' @param wdth width of plot
#' @param hght height of plot
#' @param unts units of plot
#'
#' @export
#'
ggsave_custom <- function(
  save_name,
  inplot = NULL,
  imgpath = ".",
  wdth = 7,
  hght = 4.1,
  unts = "in",
  bgcol = "white",
  dpi = 600,
  web_suffix = FALSE,
  scale_fonts = FALSE,
  base_font_size = NULL,
  ...
) {
  if (is.null(inplot)) {
    inplot <- ggplot2::last_plot()
  }

  file_path <- file.path(imgpath, save_name)

  # Determine file extension and use appropriate device
  ext <- tolower(tools::file_ext(save_name))

  # Check if the plot is a grob/gtable object from gridExtra::arrangeGrob
  is_grob <- inherits(inplot, c("grob", "gtable", "gTree", "arrangeGrob"))

  # Save main high-resolution version
  if (is_grob) {
    # For grid objects, open device, draw, and close properly
    # Record current device to restore later
    current_dev <- grDevices::dev.cur()

    switch(
      ext,
      png = grDevices::png(
        filename = file_path,
        width = wdth,
        height = hght,
        units = unts,
        res = dpi,
        bg = bgcol,
        ...
      ),
      pdf = grDevices::pdf(
        file = file_path,
        width = wdth,
        height = hght,
        bg = bgcol,
        ...
      ),
      tiff = grDevices::tiff(
        filename = file_path,
        width = wdth,
        height = hght,
        units = unts,
        res = dpi,
        compression = "lzw",
        bg = bgcol,
        ...
      ),
      tif = grDevices::tiff(
        filename = file_path,
        width = wdth,
        height = hght,
        units = unts,
        res = dpi,
        compression = "lzw",
        bg = bgcol,
        ...
      ),
      eps = grDevices::cairo_ps(
        filename = file_path,
        width = wdth,
        height = hght,
        bg = bgcol,
        onefile = FALSE,
        ...
      ),
      jpeg = grDevices::jpeg(
        filename = file_path,
        width = wdth,
        height = hght,
        units = unts,
        res = dpi,
        bg = bgcol,
        ...
      ),
      grDevices::png(
        filename = file_path,
        width = wdth,
        height = hght,
        units = unts,
        res = dpi,
        bg = bgcol,
        ...
      )
    )
    grid::grid.draw(inplot)
    invisible(grDevices::dev.off())

    # Restore previous device if it wasn't null device
    if (current_dev > 1) {
      grDevices::dev.set(current_dev)
    }
  } else {
    device_spec <- switch(
      ext,
      eps = grDevices::cairo_ps,
      tiff = "tiff",
      tif = "tiff",
      ext
    )

    # For ggplot objects, use ggsave
    if (identical(device_spec, grDevices::cairo_ps)) {
      ggplot2::ggsave(
        filename = file_path,
        plot = inplot,
        width = wdth,
        height = hght,
        units = unts,
        dpi = dpi,
        bg = bgcol,
        device = device_spec,
        onefile = FALSE,
        ...
      )
    } else {
      ggplot2::ggsave(
        filename = file_path,
        plot = inplot,
        width = wdth,
        height = hght,
        units = unts,
        dpi = dpi,
        bg = bgcol,
        device = device_spec,
        ...
      )
    }
  }

  # Save web-optimized version (if enabled)
  if (web_suffix) {
    web_path <- file.path(
      imgpath,
      paste0(
        tools::file_path_sans_ext(save_name),
        "_web.",
        ext
      )
    )
    if (is_grob) {
      current_dev <- grDevices::dev.cur()

      switch(
        ext,
        png = grDevices::png(
          filename = web_path,
          width = wdth,
          height = hght,
          units = unts,
          res = 120,
          bg = bgcol,
          ...
        ),
        pdf = grDevices::pdf(
          file = web_path,
          width = wdth,
          height = hght,
          bg = bgcol,
          ...
        ),
        tiff = grDevices::tiff(
          filename = web_path,
          width = wdth,
          height = hght,
          units = unts,
          res = 120,
          compression = "lzw",
          bg = bgcol,
          ...
        ),
        tif = grDevices::tiff(
          filename = web_path,
          width = wdth,
          height = hght,
          units = unts,
          res = 120,
          compression = "lzw",
          bg = bgcol,
          ...
        ),
        eps = grDevices::png(
          filename = web_path,
          width = wdth,
          height = hght,
          units = unts,
          res = 120,
          bg = bgcol,
          ...
        ),
        jpeg = grDevices::jpeg(
          filename = web_path,
          width = wdth,
          height = hght,
          units = unts,
          res = 120,
          bg = bgcol,
          ...
        ),
        grDevices::png(
          filename = web_path,
          width = wdth,
          height = hght,
          units = unts,
          res = 120,
          bg = bgcol,
          ...
        )
      )
      grid::grid.draw(inplot)
      invisible(grDevices::dev.off())

      if (current_dev > 1) {
        grDevices::dev.set(current_dev)
      }
    } else {
      web_device <- switch(
        ext,
        eps = "png",
        tiff = "tiff",
        tif = "tiff",
        ext
      )

      ggplot2::ggsave(
        filename = web_path,
        plot = inplot,
        width = wdth,
        height = hght,
        units = unts,
        dpi = 120,
        bg = bgcol,
        device = web_device,
        ...
      )
    }
    message("Web version saved to: ", normalizePath(web_path))
  }

  message("Plot saved to: ", normalizePath(file_path))
  invisible(file_path)
}
