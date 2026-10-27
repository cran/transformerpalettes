test_that("media are listed and every palette belongs to one", {
  expect_equal(tf_media(), c("toy", "cartoon", "comic", "g2"))
  expect_true(all(tf_characters$medium %in% tf_media()))
  # toy palettes are the base; variants are base + suffix
  toys <- tf_characters[tf_characters$medium == "toy", ]
  expect_equal(toys$palette, toys$base)
  vars <- tf_characters[tf_characters$medium != "toy", ]
  expect_equal(vars$palette, paste0(vars$base, "_", vars$medium))
  expect_true(all(vars$base %in% toys$palette))
  # a character has at most one palette per medium
  expect_equal(anyDuplicated(paste(tf_characters$base, tf_characters$medium)), 0)
  # every character that could have appeared in a cartoon (toy year up to
  # 1988) has a cartoon palette; the 1989 Pretender Monsters never did
  sunbow <- toys$palette[toys$year <= 1988]
  expect_true(all(sunbow %in% vars$base[vars$medium == "cartoon"]))
  expect_false("monstructor" %in% vars$base[vars$medium == "cartoon"])
  # g2 palettes exist exactly for the three re-released combiner teams
  g2 <- vars$base[vars$medium == "g2"]
  expect_setequal(g2, c(tf_palette_names(team = "Constructicons"),
                        tf_palette_names(team = "Aerialbots"),
                        tf_palette_names(team = "Combaticons")))
  # variants inherit the toy's metadata and link to a section of its page
  for (i in seq_len(nrow(vars))) {
    toy <- toys[toys$palette == vars$base[i], ]
    expect_equal(vars$character[i], toy$character)
    expect_equal(vars$faction[i], toy$faction)
    expect_equal(vars$team[i], toy$team)
    expect_equal(vars$role[i], toy$role)
    expect_match(vars$source[i], "^https://tfwiki.net/wiki/.*#[A-Za-z0-9_-]+$")
  }
})

test_that("tf_palette_names filters by medium and defaults to toys", {
  toys <- tf_palette_names()
  expect_equal(toys, tf_palette_names(medium = "toy"))
  expect_false(any(grepl("_(cartoon|comic)$", toys)))
  cart <- tf_palette_names(medium = "cartoon")
  expect_true(all(endsWith(cart, "_cartoon")))
  expect_lte(length(cart), length(toys))
  expect_true(all(endsWith(tf_palette_names(medium = "g2"), "_g2")))
  expect_equal(as.character(tf_palette("devastator", medium = "g2")),
               tf_palettes[["devastator_g2"]])
  expect_equal(as.character(tf_palette("devastator_g2")), tf_palettes[["devastator_g2"]])
  expect_equal(length(tf_palette_names(medium = "all")), nrow(tf_characters))
  expect_length(tf_palette_names(team = "Aerialbots", medium = "cartoon"), 6)
  expect_equal(tf_palette_names(role = "leader", medium = "comic"),
               c("optimus_prime_comic", "megatron_comic"))
  expect_length(tf_palette_names(team = "Constructicons", medium = "comic"), 7)
  for (tm in c("Aerialbots", "Stunticons", "Protectobots", "Combaticons", "Predacons",
               "Technobots", "Terrorcons")) {
    expect_length(tf_palette_names(team = tm, medium = "comic"), 6)
  }
  expect_length(tf_palette_names(team = "Seacons", medium = "comic"), 7)
  expect_length(tf_team_palette("Combaticons", medium = "g2"), 5)
  expect_error(tf_palette_names(medium = "manga"), "Unknown or ambiguous medium")
  expect_error(tf_palette_names(medium = c("toy", "comic")), "single string")
})

test_that("tf_palette resolves a name plus medium", {
  cart <- tf_palette("optimus_prime", medium = "cartoon")
  expect_equal(as.character(cart), tf_palettes[["optimus_prime_cartoon"]])
  expect_equal(attr(cart, "name"), "optimus_prime_cartoon")
  # a full key works with the default medium, and loose matching still applies
  expect_equal(as.character(tf_palette("optimus_prime_cartoon")), as.character(cart))
  expect_equal(as.character(tf_palette("Optimus Prime", medium = "Cartoon")), as.character(cart))
  # a suffixed name is a full key and wins over the medium argument
  expect_equal(as.character(tf_palette("megatron_cartoon", medium = "comic")),
               tf_palettes[["megatron_cartoon"]])
  expect_equal(as.character(tf_palette("megatron_cartoon", medium = "toy")),
               tf_palettes[["megatron_cartoon"]])
  expect_error(tf_palette("hun_gurrr", medium = "g2"), "No g2 palette for 'hun_gurrr'")
  expect_error(tf_palette("hun_gurrr_g2"), "No g2 palette")
  expect_error(tf_palette("nobody", medium = "cartoon"), "Unknown Transformers palette")
})

test_that("team and show helpers honor medium", {
  cart <- tf_team_palette("Aerialbots", medium = "cartoon")
  expect_equal(names(cart), tf_palette_names(team = "Aerialbots", medium = "cartoon")[1:5])
  expect_equal(unname(cart[[1]]), tf_palettes[["silverbolt_cartoon"]][1])
  expect_equal(attr(cart, "name"), "aerialbots_cartoon")
  expect_error(tf_team_palette("Terrorcons", medium = "g2"), "No g2 palette yet for")
  con <- tf_team_palette("Constructicons", medium = "comic")
  expect_length(con, 6)
  expect_true(all(endsWith(names(con), "_comic")))

  tmp <- tempfile(fileext = ".png")
  grDevices::png(tmp, width = 2000, height = 4000)
  on.exit(grDevices::dev.off(), add = TRUE)
  expect_length(tf_show_palettes(team = "Aerialbots", medium = "cartoon"), 6)
  expect_length(tf_show_palettes(role = "leader", medium = "all"), 12)
  expect_equal(tf_show_palettes(c("megatron", "megatron_comic")), c("megatron", "megatron_comic"))

  found <- tf_find_palettes("categorical", medium = "cartoon")
  expect_true(all(endsWith(found, "_cartoon")))
  expect_true(all(tf_palette_names(medium = "all") %in% tf_palette_stats()$palette))
})

test_that("scales accept a medium", {
  library(ggplot2)
  p <- ggplot(mpg, aes(displ, hwy, colour = drv)) +
    geom_point() +
    scale_colour_tf("optimus_prime", medium = "cartoon")
  used <- unique(ggplot_build(p)$data[[1]]$colour)
  expect_setequal(used, tf_palettes[["optimus_prime_cartoon"]][1:3])
  p2 <- ggplot(faithfuld, aes(waiting, eruptions, fill = density)) +
    geom_tile() +
    scale_fill_tf_c("megatron", medium = "comic")
  expect_s3_class(ggplot_build(p2), "ggplot_built")
})

test_that("print method names the medium", {
  grDevices::pdf(NULL)
  on.exit(grDevices::dev.off(), add = TRUE)
  expect_output(print(tf_palette("megatron", medium = "comic")), "comic")
  expect_output(print(tf_team_palette("Seacons", medium = "cartoon")), "seacons_cartoon")
})
