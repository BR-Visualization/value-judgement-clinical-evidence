test_that("ggsave_custom saves hi-res and optional web-res plot", {
  tmp_dir <- tempdir()

  p <- ggplot2::ggplot(mtcars, ggplot2::aes(mpg, wt)) +
    ggplot2::geom_point()
  file_name <- "test_plot.png"
  file_path <- file.path(tmp_dir, file_name)
  web_path <- file.path(tmp_dir, "test_plot_web.png")

  expect_invisible(
    ggsave_custom(
      save_name = file_name,
      inplot = p,
      imgpath = tmp_dir,
      web_suffix = TRUE
    )
  )

  expect_true(file.exists(file_path))
  expect_true(file.exists(web_path))

  unlink(file_path)
  unlink(web_path)
})

test_that("ggsave_custom saves tiff output", {
  tmp_dir <- tempdir()

  p <- ggplot2::ggplot(mtcars, ggplot2::aes(mpg, wt)) +
    ggplot2::geom_point()
  file_name <- "test_plot.tiff"
  file_path <- file.path(tmp_dir, file_name)

  expect_invisible(
    ggsave_custom(
      save_name = file_name,
      inplot = p,
      imgpath = tmp_dir
    )
  )

  expect_true(file.exists(file_path))

  unlink(file_path)
})
