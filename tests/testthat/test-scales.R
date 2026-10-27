library(ggplot2)

test_that("discrete scales assign palette colors in order", {
  p <- ggplot(mpg, aes(displ, hwy, colour = drv)) +
    geom_point() +
    scale_colour_tf_d("optimus_prime")
  b <- ggplot_build(p)
  used <- unique(b$data[[1]]$colour)
  expect_setequal(used, tf_palettes[["optimus_prime"]][1:3])

  p_rev <- ggplot(mpg, aes(displ, hwy, colour = drv)) +
    geom_point() +
    scale_colour_tf_d("optimus_prime", reverse = TRUE)
  used_rev <- unique(ggplot_build(p_rev)$data[[1]]$colour)
  expect_setequal(used_rev, rev(tf_palettes[["optimus_prime"]][1:3]))
})

test_that("discrete scales interpolate when data has more levels than colors", {
  p <- ggplot(mpg, aes(displ, hwy, colour = class)) +
    geom_point() +
    scale_colour_tf_d("blades")
  used <- unique(ggplot_build(p)$data[[1]]$colour)
  expect_length(used, length(unique(mpg$class)))
})

test_that("fill scales work", {
  p <- ggplot(mpg, aes(class, fill = drv)) +
    geom_bar() +
    scale_fill_tf("megatron")
  used <- unique(ggplot_build(p)$data[[1]]$fill)
  expect_setequal(used, tf_palettes[["megatron"]][1:3])
})

test_that("continuous scales produce a gradient", {
  p <- ggplot(faithfuld, aes(waiting, eruptions, fill = density)) +
    geom_tile() +
    scale_fill_tf_c("hot_spot")
  fills <- ggplot_build(p)$data[[1]]$fill
  expect_gt(length(unique(fills)), 10)

  p2 <- ggplot(mpg, aes(displ, hwy, colour = cty)) +
    geom_point() +
    scale_colour_tf("devastator", discrete = FALSE)
  expect_s3_class(ggplot_build(p2), "ggplot_built")
})

test_that("american spellings are aliases", {
  expect_identical(scale_color_tf, scale_colour_tf)
  expect_identical(scale_color_tf_d, scale_colour_tf_d)
  expect_identical(scale_color_tf_c, scale_colour_tf_c)
})
