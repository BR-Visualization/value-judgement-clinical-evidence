test_that("ggsave_custom saves hi-res and optional web-res plot", {

  tmp_dir <- tempdir()

  p <- ggplot(mtcars, aes(mpg, wt)) + geom_point()
  file_name <- "test_plot.png"
  file_path <- file.path(tmp_dir, file_name)
  web_path <- file.path(tmp_dir, "test_plot_web.png")

  # Save plot with web version
  expect_invisible(
    ggsave_custom(
      save_name = file_name,
      inplot = p,
      imgpath = tmp_dir,
      web_suffix = TRUE
    )
  )

  # Check if files exist
  expect_true(file.exists(file_path))
  expect_true(file.exists(web_path))

  # Cleanup
  unlink(file_path)
  unlink(web_path)
})

