test_that("palette stats cover every palette with sane values", {
  s <- tf_palette_stats()
  expect_equal(s$palette, tf_palette_names(medium = "all"))
  expect_true(all(s$min_de >= 0))
  expect_true(all(s$lum_range >= 0 & s$lum_range <= 100))
  expect_true(all(s$hue_spread >= 0 & s$hue_spread <= 360))
  expect_type(s$categorical, "logical")
  expect_type(s$colorblind, "logical")
  expect_type(s$sequential, "logical")
  expect_type(s$diverging, "logical")
  # colorblind-safe implies categorical
  expect_true(all(!s$colorblind | s$categorical))
})

test_that("cvd simulation leaves grays alone and shifts reds and greens together", {
  greys <- hex_to_srgb(c("#000000", "#808080", "#FFFFFF"))
  for (t in names(cvd_matrices)) {
    sim <- simulate_cvd(greys, t)
    expect_equal(unname(sim), unname(greys), tolerance = 0.02)
  }
  rg <- srgb_to_lab(simulate_cvd(hex_to_srgb(c("#FF0000", "#00AA00")), "deutan"))
  normal <- srgb_to_lab(hex_to_srgb(c("#FF0000", "#00AA00")))
  expect_lt(stats::dist(rg), stats::dist(normal))
})

test_that("tf_find_palettes returns matching, ordered palette names", {
  for (u in c("categorical", "colorblind", "sequential", "diverging")) {
    found <- tf_find_palettes(u)
    expect_type(found, "character")
    expect_true(all(found %in% tf_palette_names()), info = u)
    expect_false(any(grepl("_(cartoon|comic)$", found)), info = u)
    if (length(found)) {
      s <- tf_palette_stats(found)
      expect_true(all(s[[u]]), info = u)
    }
  }
  # obvious cases
  expect_true("optimus_prime" %in% tf_find_palettes("categorical"))
  expect_true("abominus" %in% tf_find_palettes("categorical"))
  # shared plastics keep the Constructicons off the diverging list's opposite:
  # they are green plus purple, so they do qualify as diverging
  expect_true("devastator" %in% tf_find_palettes("diverging"))

  dec <- tf_find_palettes("categorical", faction = "Decepticon")
  expect_true(all(tf_characters$faction[match(dec, tf_characters$palette)] == "Decepticon"))
  aero <- tf_find_palettes("categorical", team = "Aerialbots", min_colours = 3)
  expect_true(all(aero %in% tf_palette_names(team = "Aerialbots")))
  expect_error(tf_find_palettes("nope"))
})

test_that("sort orders a palette from dark to light", {
  p <- tf_palette("hot_spot", sort = TRUE)
  L <- srgb_to_lab(hex_to_srgb(as.character(p)))[, "L"]
  expect_true(all(diff(L) >= 0))
  expect_setequal(as.character(p), tf_palettes[["hot_spot"]])
})
