test_that("all palettes are valid hex colors", {
  for (nm in names(tf_palettes)) {
    cols <- tf_palettes[[nm]]
    expect_true(is.character(cols), info = nm)
    expect_true(all(grepl("^#[0-9A-Fa-f]{6}$", cols)), info = nm)
    expect_gte(length(cols), 3)
    expect_lte(length(cols), 6)
    expect_equal(anyDuplicated(cols), 0, info = nm)
  }
})

test_that("palette names are lowercase snake_case and unique", {
  nms <- tf_palette_names(medium = "all")
  expect_true(all(grepl("^[a-z][a-z0-9_]*$", nms)))
  expect_equal(anyDuplicated(nms), 0)
  expect_setequal(nms, names(tf_palettes))
})

test_that("metadata table matches the palette list", {
  expect_s3_class(tf_characters, "data.frame")
  expect_equal(tf_characters$palette, names(tf_palettes))
  expect_equal(anyDuplicated(tf_characters$palette), 0)
  expect_equal(anyDuplicated(tf_characters$character[tf_characters$medium == "toy"]), 0)
  expect_true(all(nzchar(tf_characters$description)))
  expect_true(all(nzchar(tf_characters$alt_mode)))
  expect_true(all(tf_characters$faction %in% c("Autobot", "Decepticon")))
  expect_true(all(tf_characters$role %in%
    c("leader", "standalone", "combiner torso", "combiner limb",
      "combined form", "subgroup member")))
  expect_true(all(grepl("^https://tfwiki.net/wiki/", tf_characters$source)))
  img <- tf_characters$image[!is.na(tf_characters$image)]
  expect_true(all(grepl("^https://tfwiki.net/mediawiki/images2/", img)))
  expect_equal(tf_characters$n_colours, unname(lengths(tf_palettes)))
  expect_type(tf_characters$year, "integer")
  expect_false(anyNA(tf_characters$year))
})

test_that("every combiner team has one torso, one combined form and at least four limbs", {
  for (tm in tf_teams()) {
    rows <- tf_characters[!is.na(tf_characters$team) & tf_characters$team == tm &
                            tf_characters$medium == "toy", ]
    if (all(rows$role == "subgroup member")) {
      # a subgroup: no combined form, no combiner, at least three members
      expect_true(all(is.na(rows$combiner)), info = tm)
      expect_gte(nrow(rows), 3)
      next
    }
    expect_equal(sum(rows$role == "combined form"), 1, info = tm)
    expect_gte(sum(rows$role == "combiner torso"), 1)
    expect_gte(sum(rows$role == "combiner limb"), 4)
    expect_equal(length(unique(rows$faction)), 1, info = tm)
    combiner <- unique(rows$combiner)
    expect_length(combiner, 1)
    expect_true(combiner %in% rows$palette[rows$role == "combined form"], info = tm)
    # combined form is listed last so team order reads torso, limbs, gestalt
    expect_equal(rows$role[nrow(rows)], "combined form", info = tm)
  }
  leaders <- tf_characters[tf_characters$role %in% c("leader", "standalone"), ]
  expect_true(all(is.na(leaders$team)))
  expect_true(all(is.na(leaders$combiner)))
})

test_that("factions and teams are listed in package order", {
  expect_equal(tf_factions(), c("Autobot", "Decepticon"))
  expect_equal(tf_teams()[1], "Aerialbots")
  expect_setequal(tf_teams(), unique(stats::na.omit(tf_characters$team)))
  expect_setequal(tf_teams(faction = "Autobot"),
                  c("Aerialbots", "Protectobots", "Technobots", "Dinobots",
                    "Autobot Cars", "Minibots"))
  expect_true(all(tf_teams(faction = "decept") %in% tf_teams()))
  expect_setequal(tf_teams(faction = "Decepticon"),
                  c("Constructicons", "Stunticons", "Combaticons", "Terrorcons",
                    "Predacons", "Seacons", "Pretender Monsters", "Breastforce",
                    "Seekers", "Cassettes", "Insecticons"))
})

test_that("palette names can be filtered by faction, team and role", {
  aero <- tf_palette_names(team = "Aerialbots")
  expect_length(aero, 6)
  expect_equal(aero[length(aero)], "superion")
  expect_equal(tf_palette_names(team = "aerial"), aero)

  dec <- tf_palette_names(faction = "Decepticon")
  expect_true("megatron" %in% dec)
  expect_false("optimus_prime" %in% dec)
  expect_equal(tf_palette_names(faction = "decepticon"), dec)

  gestalts <- tf_palette_names(role = "combined form")
  expect_setequal(gestalts, c("superion", "defensor", "computron", "devastator",
                              "menasor", "bruticus", "abominus", "predaking",
                              "piranacon", "monstructor", "liokaiser"))
  expect_setequal(tf_palette_names(faction = "Autobot", role = "leader"),
                  c("optimus_prime", "rodimus_prime", "ultra_magnus"))
  expect_true(all(c("shockwave", "soundwave", "hot_rod", "gnaw") %in%
                    tf_palette_names(role = "standalone")))
  seekers <- tf_palette_names(team = "Seekers")
  expect_equal(seekers[1:3], c("starscream", "thundercracker", "skywarp"))
  expect_true(all(c(seekers, tf_palette_names(team = "Dinobots")) %in%
                    tf_palette_names(role = "subgroup member")))

  expect_error(tf_palette_names(team = "nope"), "Unknown or ambiguous")
  expect_error(tf_palette_names(faction = c("a", "b")), "single string")
})

test_that("tf_palette returns the full palette by default", {
  p <- tf_palette("optimus_prime")
  expect_s3_class(p, "tf_palette")
  expect_equal(as.character(p), tf_palettes[["optimus_prime"]])
  expect_equal(attr(p, "name"), "optimus_prime")
})

test_that("tf_palette subsets and interpolates", {
  full <- tf_palettes[["megatron"]]
  expect_equal(as.character(tf_palette("megatron", 3)), full[1:3])

  cont <- tf_palette("megatron", 20, type = "continuous")
  expect_length(cont, 20)
  expect_true(all(grepl("^#[0-9A-Fa-f]{6}$", cont)))

  expect_error(tf_palette("megatron", 50), "only has")
  loose <- tf_palette("megatron", 50, strict = FALSE)
  expect_length(loose, 50)
})

test_that("tf_palette matches names loosely and errors on unknown", {
  expect_equal(
    as.character(tf_palette("Optimus Prime")),
    as.character(tf_palette("optimus_prime"))
  )
  expect_equal(
    as.character(tf_palette("Hun-Gurrr")),
    tf_palettes[["hun_gurrr"]]
  )
  expect_error(tf_palette("not_a_robot"), "Unknown Transformers palette")
})

test_that("team palettes take one color per member in team order", {
  aero <- tf_team_palette("Aerialbots")
  expect_s3_class(aero, "tf_palette")
  expect_equal(names(aero), tf_palette_names(team = "Aerialbots")[1:5])
  expect_equal(unname(aero[["silverbolt"]]), tf_palettes[["silverbolt"]][1])

  with_gestalt <- tf_team_palette("Aerialbots", combined = TRUE)
  expect_length(with_gestalt, 6)
  expect_equal(names(with_gestalt)[6], "superion")

  second <- tf_team_palette("Constructicons", which = 2)
  expect_equal(unname(second[["hook"]]), tf_palettes[["hook"]][2])
  deep <- tf_team_palette("Aerialbots", which = 99)
  expect_equal(unname(deep[["air_raid"]]), tail(tf_palettes[["air_raid"]], 1))

  # distinct = TRUE never repeats a color that a member could avoid
  plain <- tf_team_palette("Protectobots")
  expect_gt(anyDuplicated(unname(plain)), 0)
  dist <- tf_team_palette("Protectobots", distinct = TRUE)
  expect_equal(anyDuplicated(unname(dist)), 0)
  expect_equal(names(dist), names(plain))
  for (p in names(dist)) expect_true(dist[[p]] %in% tf_palettes[[p]], info = p)
  expect_equal(unname(dist[[1]]), tf_palettes[[names(dist)[1]]][1])

  expect_error(tf_team_palette("nope"), "Unknown or ambiguous")
  expect_error(tf_team_palette("Aerialbots", which = 0), "positive integer")
})

test_that("print method runs without error and names the faction", {
  grDevices::pdf(NULL)
  on.exit(grDevices::dev.off(), add = TRUE)
  expect_output(print(tf_palette("megatron")), "Decepticon")
  expect_output(print(tf_palette("silverbolt")), "Aerialbots")
  expect_output(print(tf_team_palette("Seacons")), "snaptrap = ")
})
