min_pair <- function(hex, ...) {
  d <- pick_distances(hex, ...)
  min(d[upper.tri(d)])
}

test_that("tf_pick returns n distinct colors drawn from the pool", {
  p <- tf_pick(c("optimus_prime", "megatron"), n = 5)
  expect_s3_class(p, "tf_palette")
  expect_length(p, 5)
  expect_equal(anyDuplicated(unname(p)), 0)
  pool <- c(tf_palettes$optimus_prime, tf_palettes$megatron)
  expect_true(all(unname(p) %in% pool))
  expect_true(all(names(p) %in% c("optimus_prime", "megatron")))
  for (i in seq_along(p)) expect_true(p[[i]] %in% tf_palettes[[names(p)[i]]])
  expect_equal(attr(p, "min_distance"), min_pair(unname(p)))
  expect_equal(attr(p, "style"), "light")
  expect_equal(attr(p, "background"), "#FFFFFF")
})

test_that("light and dark styles drop colors that vanish into the background", {
  light <- tf_pick("silverbolt", n = 3)
  expect_false("#F0F0EC" %in% unname(light))
  expect_true(all(contrast_ratio(unname(light), "#FFFFFF") >= 3))

  dark <- tf_pick("motormaster", n = 3, style = "dark")
  expect_false("#1E1E1E" %in% unname(dark))
  expect_true(all(contrast_ratio(unname(dark), "#121212") >= 3))
  expect_equal(attr(dark, "background"), "#121212")

  # disabling the filter lets everything back in
  all_in <- tf_pick("silverbolt", n = 5, min_contrast = 1)
  expect_setequal(unname(all_in), tf_palettes$silverbolt)

  # a custom background overrides the style
  custom <- tf_pick("silverbolt", n = 3, style = "light", background = "#000000")
  expect_true(all(contrast_ratio(unname(custom), "#000000") >= 3))
})

test_that("the chosen subset is the most dispersed one when the search is exhaustive", {
  pals <- c("optimus_prime", "megatron")
  p <- tf_pick(pals, n = 3, min_contrast = 1)
  pool <- unique(toupper(c(tf_palettes$optimus_prime, tf_palettes$megatron)))
  d <- pick_distances(pool)
  best <- max(apply(utils::combn(length(pool), 3), 2, function(i) min(d[i, i][upper.tri(d[i, i])])))
  expect_equal(attr(p, "min_distance"), best)
})

test_that("greedy search matches exhaustive on a moderate pool", {
  pool <- unique(unlist(tf_palettes[tf_palette_names(team = "Combaticons")]))
  d <- pick_distances(pool)
  ex <- choose_subset(d, 4, max_exhaustive = 1e6)
  gr <- choose_subset(d, 4, max_exhaustive = 0)
  expect_equal(subset_score(d, gr), subset_score(d, ex), tolerance = 1e-6)
})

test_that("colorblind and grayscale change the criterion", {
  pals <- tf_palette_names(team = "Predacons")
  normal <- tf_pick(pals, n = 4, min_contrast = 1)
  cb <- tf_pick(pals, n = 4, colorblind = TRUE, min_contrast = 1)
  expect_true(attr(cb, "colorblind"))
  expect_gte(min_pair(unname(cb), colorblind = TRUE), min_pair(unname(normal), colorblind = TRUE) - 1e-9)
  expect_equal(attr(cb, "min_distance"), min_pair(unname(cb), colorblind = TRUE))

  grey <- tf_pick(pals, n = 4, style = "grayscale", min_contrast = 1)
  L <- srgb_to_lab(hex_to_srgb(unname(grey)))[, "L"]
  expect_equal(attr(grey, "min_distance"), min(diff(sort(L))))
  # grayscale picks are at least as separated in lightness as the default pick
  L0 <- srgb_to_lab(hex_to_srgb(unname(normal)))[, "L"]
  expect_gte(min(diff(sort(L))), min(diff(sort(L0))) - 1e-9)
})

test_that("results are ordered so leading subsets stay dispersed", {
  p <- tf_pick(tf_palette_names(team = "Stunticons"), n = 5, min_contrast = 1)
  d <- pick_distances(unname(p))
  # the second color is the one farthest from the first
  expect_equal(unname(which.max(d[1, ])), 2L)
})

test_that("media and suffixed names are honored", {
  cart <- tf_pick("drag_strip", n = 3, medium = "cartoon", min_contrast = 1)
  expect_true(all(unname(cart) %in% tf_palettes$drag_strip_cartoon))
  expect_equal(unique(names(cart)), "drag_strip_cartoon")
  mixed <- tf_pick(c("megatron", "megatron_comic"), n = 4, min_contrast = 1)
  expect_setequal(unique(names(mixed)) %in% c("megatron", "megatron_comic"), TRUE)
})

test_that("tf_pick validates its inputs and reports an empty pool", {
  # white and yellow both fail the 3:1 contrast check against white
  expect_error(tf_pick("silverbolt", n = 5), "Only 3 of the 5 pooled colors")
  expect_error(tf_pick(character(0)), "character vector")
  expect_error(tf_pick("silverbolt", n = 0), "positive integer")
  expect_error(tf_pick("silverbolt", n = 2, background = "white"), "hex color")
  expect_error(tf_pick("nobody", n = 2), "Unknown Transformers palette")
  expect_error(tf_pick("silverbolt", n = 2, style = "sepia"))
  one <- tf_pick("optimus_prime", n = 1)
  expect_length(one, 1)
  expect_equal(attr(one, "min_distance"), Inf)
})

test_that("print method describes a pick", {
  grDevices::pdf(NULL)
  on.exit(grDevices::dev.off(), add = TRUE)
  expect_output(print(tf_pick(c("optimus_prime", "megatron"), n = 3, style = "dark",
                              colorblind = TRUE)),
                "pick of 3 colors from optimus_prime \\+ megatron")
  expect_output(print(tf_pick("megatron", n = 3)), "min distance")
})
