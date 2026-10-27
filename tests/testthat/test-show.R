test_that("tf_show_palettes draws without error", {
  tmp <- tempfile(fileext = ".png")
  grDevices::png(tmp, width = 2000, height = 4000)
  on.exit(grDevices::dev.off(), add = TRUE)
  expect_invisible(tf_show_palettes(faction = "Autobot"))
  expect_equal(tf_show_palettes(c("optimus_prime", "megatron")),
               c("optimus_prime", "megatron"))
  aero <- tf_show_palettes(team = "Aerialbots", ncol = 2)
  expect_equal(aero, tf_palette_names(team = "Aerialbots"))
  gestalts <- tf_show_palettes(role = "combined form")
  expect_length(gestalts, 11)
  expect_error(tf_show_palettes("nope"))
  expect_error(tf_show_palettes(team = "nope"))
})
