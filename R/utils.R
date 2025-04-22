#' Custom Wrapper for ggsave with Sensible Defaults
#'
#' @description
#' Save a ggplot or patchwork object with cleaner defaults (BRAP Journal style).
#'
#' @param save_name File name (e.g. 'plot.png', 'plot.pdf') to save.
#' @param inplot Plot object. If NULL, saves the last displayed plot.
#' @param imgpath Directory path where the plot is saved (default: current directory).
#' @param wdth Width of the plot in units (default: 7).
#' @param hght Height of the plot in units (default: 4.1).
#' @param unts Units for width/height (default: "in").
#' @param bgcol Background color (default: "white").
#' @param dpi Resolution in dots per inch (default: 600).
#' @param web_suffix If TRUE, also saves a low-res version with "_web" suffix (default: FALSE).
#' @param ... Additional arguments passed to `ggsave()`.
#'
#' @return Invisibly returns full file path to saved image.
#'
#' @examples
#' # Example usage:
#' dotforest <- create_forest_dot_plot(
#'   prepare_forest_dot_data(effects_table)
#' )
#' ggsave_custom("dotforest.png", imgpath = tempdir(), inplot = dotforest)
#'
#' @export
ggsave_custom <- function(save_name,
                          inplot = NULL,
                          imgpath = ".",
                          wdth = 7,
                          hght = 4.1,
                          unts = "in",
                          bgcol = "white",
                          dpi = 600,
                          web_suffix = FALSE,
                          ...) {
  if (is.null(inplot)) {
    inplot <- ggplot2::last_plot()
  }

  file_path <- file.path(imgpath, save_name)

  # Determine file extension and use appropriate device
  ext <- tools::file_ext(save_name)

  # Save main high-resolution version
  ggplot2::ggsave(
    filename = file_path,
    plot = inplot,
    width = wdth,
    height = hght,
    units = unts,
    dpi = dpi,
    bg = bgcol,
    device = ext,
    ...
  )

  # Save web-optimized version (if enabled)
  if (web_suffix) {
    web_path <- file.path(imgpath, paste0(tools::file_path_sans_ext(save_name), "_web.", ext))
    ggplot2::ggsave(
      filename = web_path,
      plot = inplot,
      width = wdth,
      height = hght,
      units = unts,
      dpi = 120,
      bg = bgcol,
      device = ext,
      ...
    )
    message("Web version saved to: ", normalizePath(web_path))
  }

  message("Plot saved to: ", normalizePath(file_path))
  invisible(file_path)
}
