test_that("tf_credit names character and source for one toy palette", {
  s <- tf_credit("optimus_prime")
  expect_type(s, "character")
  expect_length(s, 1)
  expect_equal(s, "Colors: Optimus Prime toy colorway by Hasbro and Takara Tomy, via the transformerpalettes R package.")
  expect_equal(tf_credit("optimus_prime", package = FALSE),
               "Colors: Optimus Prime toy colorway by Hasbro and Takara Tomy.")
})

test_that("tf_credit groups by medium and pluralises", {
  s <- tf_credit(c("optimus_prime", "megatron"))
  expect_equal(s, "Colors: Optimus Prime and Megatron toy colorways by Hasbro and Takara Tomy, via the transformerpalettes R package.")

  two <- tf_credit(c("optimus_prime", "megatron_cartoon"))
  expect_equal(two, paste0(
    "Colors: Optimus Prime toy colorway by Hasbro and Takara Tomy and ",
    "Megatron cartoon colors from the Generation 1 animated series, ",
    "via the transformerpalettes R package."
  ))

  # three or more media are separated by semicolons
  three <- tf_credit(c("optimus_prime", "megatron_cartoon", "megatron_comic"))
  expect_equal(lengths(regmatches(three, gregexpr(";", three, fixed = TRUE))), 2L)
  expect_true(grepl("Megatron comic colors from the Marvel Transformers comics", three, fixed = TRUE))

  # medium argument applies to plain names; suffixes win over it
  expect_equal(tf_credit("megatron", medium = "cartoon"), tf_credit("megatron_cartoon"))
  expect_equal(tf_credit("megatron_comic", medium = "cartoon"), tf_credit("megatron_comic"))
  # duplicates and case-insensitive names collapse
  expect_equal(tf_credit(c("Optimus Prime", "optimus_prime")), tf_credit("optimus_prime"))
})

test_that("tf_credit follows picks and team palettes back to their sources", {
  team <- tf_credit(tf_team_palette("Stunticons"))
  expect_true(grepl("Motormaster, Dead End, Breakdown, Drag Strip and Wildrider toy colorways by Hasbro and Takara Tomy", team, fixed = TRUE))
  p <- tf_pick(c("optimus_prime", "megatron_cartoon"), n = 4, min_contrast = 1)
  s <- tf_credit(p)
  expect_true(grepl("Optimus Prime toy colorway", s, fixed = TRUE))
  expect_true(grepl("Megatron cartoon colors", s, fixed = TRUE))
  expect_equal(tf_credit(tf_palette("megatron")), tf_credit("megatron"))
  expect_equal(tf_credit(tf_palette("megatron", 8, type = "continuous")), tf_credit("megatron"))
  expect_equal(tf_credit(tf_palette("drag_strip", medium = "cartoon")), tf_credit("drag_strip_cartoon"))
})

test_that("acknowledgment and markdown formats", {
  a <- tf_credit("optimus_prime", format = "acknowledgment")
  expect_true(startsWith(a, "Figure colors are derived from the Optimus Prime toy colorway designed by Hasbro and Takara Tomy. Hex values are approximations from the transformerpalettes R package (Maitner "))
  expect_true(endsWith(a, ") and imply no endorsement by Hasbro or Takara Tomy."))
  a2 <- tf_credit("optimus_prime", format = "acknowledgment", package = FALSE)
  expect_false(grepl("transformerpalettes", a2, fixed = TRUE))
  expect_true(grepl("imply no endorsement", a2, fixed = TRUE))

  m <- tf_credit(c("optimus_prime", "megatron"), format = "markdown")
  expect_true(grepl("[Optimus Prime](https://tfwiki.net/", m, fixed = TRUE))
  expect_true(grepl("[Megatron](https://tfwiki.net/", m, fixed = TRUE))
})

test_that("tf_credit validates input", {
  expect_error(tf_credit("nobody"), "Unknown Transformers palette")
  expect_error(tf_credit(character(0)), "palette object or a character vector")
  expect_error(tf_credit(1:3), "palette object or a character vector")
  expect_error(tf_credit("optimus_prime", format = "footnote"))
})

test_that("the package has a parseable CITATION", {
  cit <- utils::readCitationFile(system.file("CITATION", package = "transformerpalettes"),
                                 meta = utils::packageDescription("transformerpalettes"))
  expect_s3_class(cit, "bibentry")
  expect_true(grepl("Maitner", format(cit, style = "text"), fixed = TRUE))
})
