#' Transformers palettes
#'
#' A named list of color palettes covering the Transformers cast from the
#' 1984 Generation 1 toys onward: the leaders, every member and combined
#' form of the combiner teams,
#' the Dinobots, Seekers, cassettes, Insecticons, the 1984 Autobot cars and
#' Mini Vehicles, and the 1986 movie cast. Each character has a palette for
#' the original toy, most have one for the cartoon, many have one for the
#' Marvel comic, and the three combiner teams Hasbro re-released in
#' Generation 2 have one for that; see the `medium` column of
#' [tf_characters]. Each element is a character vector of four to
#' six hex colors ordered so that the first few are the most distinct from
#' one another (body color first, then secondary color, then accents). Use
#' [tf_palette()] to pull colors from a palette, [tf_team_palette()] to take
#' one color from each member of a combiner team, and [tf_characters] for
#' background on each character.
#'
#' @details
#' Toy palettes are named after the character (`optimus_prime`); cartoon and
#' comic palettes carry a suffix (`optimus_prime_cartoon`,
#' `optimus_prime_comic`). Hex values are approximations: toy colors were
#' curated by eye from product photography on the Transformers Wiki
#' (<https://tfwiki.net/wiki/Main_Page>) and the toys' published color descriptions,
#' cartoon colors from the animation models as they appear in episode
#' stills, and comic colors from the character's early Marvel appearances.
#' Chrome and die-cast parts do not reduce to a single flat color; those
#' entries reflect how the part photographs.
#'
#' @format A named list of character vectors of hex colors.
#' @seealso [tf_palette()], [tf_palette_names()], [tf_media()], [tf_teams()],
#'   [tf_characters], [tf_show_palettes()]
#' @examples
#' length(tf_palettes)
#' tf_palettes$optimus_prime
#' tf_palettes$optimus_prime_cartoon
#' tf_palettes$devastator
#' @export
tf_palettes <- stats::setNames(
  lapply(.registry, `[[`, "colours"),
  vapply(.registry, `[[`, character(1), "palette")
)

#' Transformers character metadata
#'
#' Background information for every palette in [tf_palettes]: the character,
#' which medium the palette records (toy, cartoon, comic or Generation 2
#' re-release), its faction, the
#' combiner team and combined form it belongs to, its role in that team, its
#' alternate mode, the year of the reference, a description of the colors,
#' and links to the reference page and image on the Transformers Wiki.
#'
#' @format A data frame with one row per palette and the columns:
#' \describe{
#'   \item{palette}{Palette name, as used by [tf_palette()]. Unique.}
#'   \item{base}{The character's toy palette name, shared by all of that
#'     character's palettes across media (e.g. `"optimus_prime"` for both
#'     `optimus_prime` and `optimus_prime_cartoon`).}
#'   \item{medium}{`"toy"`, `"cartoon"`, `"comic"` or `"g2"`. See
#'     [tf_media()].}
#'   \item{character}{Character name as printed on the toy's packaging.}
#'   \item{faction}{`"Autobot"` or `"Decepticon"`. See [tf_factions()].}
#'   \item{team}{Combiner team or subgroup, e.g. `"Aerialbots"` or
#'     `"Seekers"`, or `NA` for characters that are not part of one. See
#'     [tf_teams()].}
#'   \item{combiner}{Base palette name of the team's combined form, e.g.
#'     `"superion"`, or `NA` for leaders and for subgroups that do not
#'     combine.}
#'   \item{role}{One of `"leader"`, `"standalone"` (a character outside any
#'     team), `"combiner torso"`, `"combiner limb"`, `"combined form"` or
#'     `"subgroup member"` (Dinobots, Seekers, Cassettes, Insecticons,
#'     Autobot Cars, Minibots).}
#'   \item{alt_mode}{The character's alternate mode.}
#'   \item{year}{Year of the reference: the original Hasbro release for toy
#'     palettes, the character's first appearance for cartoon and comic
#'     palettes.}
#'   \item{n_colours}{Number of colors in the palette.}
#'   \item{description}{Description of the colors in that medium.}
#'   \item{source}{URL of the character's page on the Transformers Wiki, with
#'     an anchor to the relevant section for cartoon and comic palettes.}
#'   \item{image}{Direct URL of the reference image the palette was checked
#'     against (a toy photo, an episode still, or a comic panel), hosted by
#'     the Transformers Wiki, or `NA` where none has been identified yet.}
#' }
#' @source Transformers Wiki, <https://tfwiki.net/wiki/Main_Page>.
#' @examples
#' head(tf_characters)
#' table(tf_characters$team, tf_characters$medium)
#' subset(tf_characters, base == "megatron", c(palette, medium, description))
#' @export
tf_characters <- local({
  col <- function(field, type) vapply(.registry, `[[`, type, field)
  out <- data.frame(
    palette = col("palette", character(1)),
    base = col("base", character(1)),
    medium = col("medium", character(1)),
    character = col("character", character(1)),
    faction = col("faction", character(1)),
    team = col("team", character(1)),
    combiner = col("combiner", character(1)),
    role = col("role", character(1)),
    alt_mode = col("alt_mode", character(1)),
    year = col("year", integer(1)),
    n_colours = vapply(.registry, function(x) length(x$colours), integer(1)),
    description = col("description", character(1)),
    source = col("source", character(1)),
    image = col("image", character(1)),
    stringsAsFactors = FALSE
  )
  rownames(out) <- NULL
  out
})

.media <- c("toy", "cartoon", "comic", "g2")

#' List the media, factions and combiner teams in transformerpalettes
#'
#' @param faction Optional faction to restrict `tf_teams()` to; see
#'   [tf_factions()].
#'
#' @return `tf_media()` returns the media a palette can record, in the order
#'   `"toy"` (the original Generation 1 release), `"cartoon"` (the animation
#'   model), `"comic"` (Marvel) and `"g2"` (the Generation 2 re-release of
#'   the toy in new colors, 1992-1994). `tf_factions()` returns a character
#'   vector of faction names. `tf_teams()` returns a character vector of
#'   team and subgroup names, in package order (Autobot teams first). All can be
#'   passed to the matching argument of [tf_palette_names()],
#'   [tf_show_palettes()] and [tf_find_palettes()].
#' @examples
#' tf_media()
#' tf_factions()
#' tf_teams()
#' tf_teams(faction = "Decepticon")
#' @export
tf_media <- function() {
  .media[.media %in% tf_characters$medium]
}

#' @rdname tf_media
#' @export
tf_factions <- function() {
  unique(tf_characters$faction)
}

#' @rdname tf_media
#' @export
tf_teams <- function(faction = NULL) {
  keep <- !is.na(tf_characters$team)
  if (!is.null(faction)) {
    keep <- keep & tf_characters$faction == match_label(faction, tf_characters$faction, "faction")
  }
  unique(tf_characters$team[keep])
}

#' List the available palettes
#'
#' @param faction Optional faction (see [tf_factions()]) to restrict the list
#'   to. Matched case-insensitively and by unique prefix, so `"auto"` works.
#' @param team Optional team or subgroup (see [tf_teams()]) to restrict the
#'   list to, matched the same way.
#' @param role Optional role to restrict the list to: one of `"leader"`,
#'   `"combiner torso"`, `"combiner limb"`, `"combined form"` or
#'   `"subgroup member"`, matched the same way.
#' @param medium Which medium's palettes to list: `"toy"` (default),
#'   `"cartoon"`, `"comic"`, `"g2"`, or `"all"` for every palette regardless
#'   of medium. See [tf_media()].
#'
#' @return A character vector of palette names accepted by [tf_palette()]
#'   and the `scale_*_tf()` functions.
#' @examples
#' tf_palette_names()
#' tf_palette_names(faction = "Decepticon")
#' tf_palette_names(team = "Aerialbots", medium = "cartoon")
#' tf_palette_names(role = "leader", medium = "all")
#' @export
tf_palette_names <- function(faction = NULL, team = NULL, role = NULL,
                             medium = "toy") {
  keep <- match_medium(medium)
  if (!is.null(faction)) {
    keep <- keep & tf_characters$faction == match_label(faction, tf_characters$faction, "faction")
  }
  if (!is.null(team)) {
    keep <- keep & !is.na(tf_characters$team) &
      tf_characters$team == match_label(team, tf_characters$team, "team")
  }
  if (!is.null(role)) {
    keep <- keep & tf_characters$role == match_label(role, tf_characters$role, "role")
  }
  tf_characters$palette[keep]
}

# Logical index into tf_characters for a `medium` argument.
match_medium <- function(medium) {
  if (!is.character(medium) || length(medium) != 1L) {
    stop("`medium` must be a single string.", call. = FALSE)
  }
  if (identical(tolower(medium), "all")) return(rep(TRUE, nrow(tf_characters)))
  m <- match_label(medium, .media, "medium")
  tf_characters$medium == m
}

match_label <- function(x, choices, what) {
  if (!is.character(x) || length(x) != 1L) {
    stop("`", what, "` must be a single string.", call. = FALSE)
  }
  u <- unique(choices[!is.na(choices)])
  norm <- function(s) gsub("[^a-z0-9]", "", tolower(s))
  hit <- u[norm(u) == norm(x)]
  if (length(hit) == 0L) hit <- u[startsWith(norm(u), norm(x))]
  if (length(hit) == 0L) hit <- u[grepl(norm(x), norm(u), fixed = TRUE)]
  if (length(hit) != 1L) {
    stop(
      "Unknown or ambiguous ", what, " '", x, "'. Choose one of: ",
      paste(u, collapse = ", "), ".",
      call. = FALSE
    )
  }
  hit
}

# Resolve a user-supplied name plus medium to a palette key. A name that
# carries a medium suffix (`megatron_cartoon`) is a full key and wins over
# `medium`; otherwise the suffix for `medium` is added to the base name.
palette_key <- function(name, medium = "toy") {
  if (!is.character(name) || length(name) != 1L) {
    stop("`name` must be a single string.", call. = FALSE)
  }
  key <- tolower(name)
  key <- gsub("[ -]+", "_", key)
  suffix <- regmatches(key, regexpr(paste0("_(", paste(.media[-1], collapse = "|"), ")$"), key))
  if (length(suffix)) {
    base <- sub(suffix, "", key, fixed = TRUE)
    medium <- sub("^_", "", suffix)
  } else {
    base <- key
    medium <- match_label(medium, .media, "medium")
  }
  key <- if (medium == "toy") base else paste0(base, "_", medium)
  if (!key %in% names(tf_palettes)) {
    if (base %in% names(tf_palettes)) {
      have <- tf_characters$medium[tf_characters$base == base]
      stop(
        "No ", medium, " palette for '", base, "' yet (available: ",
        paste(have, collapse = ", "), "). See WISHLIST.md to request one.",
        call. = FALSE
      )
    }
    stop(
      "Unknown Transformers palette '", name, "'. See tf_palette_names().",
      call. = FALSE
    )
  }
  key
}

#' Get colors from a character's palette
#'
#' Returns `n` colors from the named character's palette, either the first
#' `n` curated colors (`type = "discrete"`) or `n` colors interpolated
#' across the whole palette (`type = "continuous"`).
#'
#' @param name Palette name. Case-insensitive, and spaces or hyphens may
#'   stand in for underscores, so `"Optimus Prime"` and `"Hun-Gurrr"` work.
#'   See [tf_palette_names()]. A full name with a medium suffix
#'   (`"megatron_cartoon"`) also works and takes precedence over `medium`.
#' @param n Number of colors wanted. Defaults to every color in the palette.
#' @param type Either `"discrete"` (default) to return the curated colors as
#'   they are, or `"continuous"` to interpolate `n` colors across the palette
#'   with [grDevices::colorRampPalette()].
#' @param strict Logical. For discrete palettes, error when `n` exceeds the
#'   number of curated colors (default). If `FALSE`, interpolate to `n`
#'   colors instead.
#' @param sort Logical. If `TRUE`, order the colors from darkest to lightest
#'   (by CIE lightness) before selecting or interpolating. Useful when a
#'   palette is used as a sequential gradient; see [tf_find_palettes()].
#' @param medium Which version of the character to use: `"toy"` (default),
#'   `"cartoon"`, `"comic"` or `"g2"`. See [tf_media()]. Errors with a
#'   pointer to the wishlist if the character has no palette in that medium.
#'
#' @return A character vector of hex colors with class `"tf_palette"`, which
#'   has a print method that draws the swatches.
#' @examples
#' tf_palette("optimus_prime")
#' tf_palette("optimus_prime", medium = "cartoon")
#' tf_palette("Megatron", 3, medium = "comic")
#' tf_palette("devastator", medium = "g2")
#' tf_palette("devastator", 12, type = "continuous")
#' tf_palette("hot_spot", 12, type = "continuous", sort = TRUE)
#'
#' # base graphics
#' barplot(1:5, col = tf_palette("predaking"))
#' @export
tf_palette <- function(name, n = NULL, type = c("discrete", "continuous"),
                       strict = TRUE, sort = FALSE, medium = "toy") {
  type <- match.arg(type)
  key <- palette_key(name, medium)
  pal <- tf_palettes[[key]]
  subset_palette(pal, key, n, type, strict, sort)
}

subset_palette <- function(pal, key, n, type, strict, sort) {
  if (isTRUE(sort)) {
    L <- srgb_to_lab(hex_to_srgb(pal))[, "L"]
    pal <- pal[order(L)]
  }

  if (is.null(n)) n <- length(pal)
  n <- as.integer(n)
  if (length(n) != 1L || is.na(n) || n < 1L) {
    stop("`n` must be a single positive integer.", call. = FALSE)
  }

  out <- switch(
    type,
    continuous = grDevices::colorRampPalette(pal)(n),
    discrete = {
      if (n > length(pal)) {
        if (strict) {
          stop(
            "Palette '", key, "' only has ", length(pal), " colors; ",
            n, " were requested. Use type = \"continuous\" or ",
            "strict = FALSE to interpolate.",
            call. = FALSE
          )
        }
        grDevices::colorRampPalette(pal)(n)
      } else {
        pal[seq_len(n)]
      }
    }
  )
  structure(out, class = "tf_palette", name = key)
}

#' One color per member of a team
#'
#' Builds a categorical palette for a combiner team or subgroup by taking one
#' color from each member, in the team's order (torso first, then limbs, for
#' a combiner team). Each color is named after the member it came from, so
#' the palette doubles as a legend.
#'
#' @details
#' By default the body color of each member is used, which is faithful but
#' collapses for teams cast from shared plastics: every Constructicon is the
#' same green, three Protectobots are white, and so on. With
#' `distinct = TRUE` each member instead contributes the color from its
#' palette that is furthest (in CIE Lab) from the colors already chosen for
#' the members before it, so the palette stays legible while every color is
#' still one the member actually wears. The Stunticons, Combaticons and
#' Terrorcons are distinct either way; for the others `distinct = TRUE` is
#' the useful setting. Check the result with [tf_palette_stats()] on the
#' returned colors if legibility matters.
#'
#' @param team Combiner team name; see [tf_teams()]. Matched
#'   case-insensitively and by unique prefix.
#' @param which Which color to take from each member's palette when
#'   `distinct = FALSE`. `1` (the default) is the body color; `2` the
#'   secondary color, and so on. Members with fewer colors than `which`
#'   fall back to their last color.
#' @param distinct Logical. Choose each member's color to be as different as
#'   possible from those already chosen? See Details.
#' @param combined Logical. Include the team's combined form as the last
#'   color?
#' @param medium Which version of the team to use: `"toy"` (default),
#'   `"cartoon"` or `"comic"`. Errors if any member lacks a palette in that
#'   medium.
#'
#' @return A named character vector of hex colors with class `"tf_palette"`.
#' @examples
#' tf_team_palette("Stunticons")
#' tf_team_palette("Seekers")
#' tf_team_palette("Aerialbots")
#' tf_team_palette("Aerialbots", distinct = TRUE)
#' tf_team_palette("Predacons", which = 2)
#' tf_team_palette("Combaticons", medium = "cartoon")
#'
#' library(ggplot2)
#' ggplot(mpg, aes(displ, hwy, colour = drv)) +
#'   geom_point() +
#'   scale_colour_manual(values = unname(tf_team_palette("Stunticons")))
#' @export
tf_team_palette <- function(team, which = 1L, distinct = FALSE,
                            combined = FALSE, medium = "toy") {
  team <- match_label(team, tf_characters$team, "team")
  medium <- match_label(medium, .media, "medium")
  toys <- tf_characters[!is.na(tf_characters$team) & tf_characters$team == team &
                          tf_characters$medium == "toy", ]
  if (!combined) toys <- toys[toys$role != "combined form", ]
  keys <- if (medium == "toy") toys$base else paste0(toys$base, "_", medium)
  missing <- keys[!keys %in% names(tf_palettes)]
  if (length(missing)) {
    stop(
      "No ", medium, " palette yet for: ", paste(missing, collapse = ", "),
      ". See WISHLIST.md.",
      call. = FALSE
    )
  }
  which <- as.integer(which)
  if (length(which) != 1L || is.na(which) || which < 1L) {
    stop("`which` must be a single positive integer.", call. = FALSE)
  }
  if (isTRUE(distinct)) {
    chosen <- character(0)
    for (p in keys) {
      pal <- tf_palettes[[p]]
      if (length(chosen) == 0L) {
        pick <- pal[1L]
      } else {
        lab_pal <- srgb_to_lab(hex_to_srgb(pal))
        lab_chosen <- srgb_to_lab(hex_to_srgb(chosen))
        d <- apply(lab_pal, 1, function(row) {
          min(sqrt(colSums((t(lab_chosen) - row)^2)))
        })
        pick <- pal[which.max(d)]
      }
      chosen <- c(chosen, pick)
    }
    cols <- stats::setNames(chosen, keys)
  } else {
    cols <- vapply(keys, function(p) {
      pal <- tf_palettes[[p]]
      pal[min(which, length(pal))]
    }, character(1))
  }
  nm <- if (medium == "toy") tolower(team) else paste0(tolower(team), "_", medium)
  structure(cols, class = "tf_palette", name = nm)
}

#' @export
print.tf_palette <- function(x, ...) {
  cols <- as.character(x)
  n <- length(cols)
  key <- attr(x, "name")
  meta <- tf_characters[tf_characters$palette == key, ]
  if (isTRUE(attr(x, "picked"))) {
    cat("Transformers pick of ", n, " colors from ", key, "\n", sep = "")
    cat(attr(x, "style"), " background ", attr(x, "background"),
        if (isTRUE(attr(x, "colorblind"))) ", colorblind-safe" else "",
        ", min distance ", round(attr(x, "min_distance"), 1), "\n", sep = "")
  } else if (nrow(meta) == 1L) {
    cat("Transformers palette '", key, "' (", n, " colors, ", meta$medium, ")\n", sep = "")
    team <- if (is.na(meta$team)) "" else paste0(" / ", meta$team)
    cat(meta$faction, team, ": ", meta$character, "\n", sep = "")
  } else {
    cat("Transformers team palette '", key, "' (", n, " colors)\n", sep = "")
  }
  if (!is.null(names(x))) {
    cat(paste0(names(x), " = ", cols), sep = "\n")
  } else {
    cat(cols, sep = " ")
    cat("\n")
  }

  bg <- attr(x, "background")
  old <- graphics::par(mar = c(0.5, 0.5, 2, 0.5),
                       bg = if (is.null(bg)) "white" else bg)
  on.exit(graphics::par(old), add = TRUE)
  graphics::plot(
    0, 0, type = "n", xlim = c(0, n), ylim = c(0, 1),
    axes = FALSE, xlab = "", ylab = "",
    main = key, font.main = 1,
    col.main = if (!is.null(bg) && relative_luminance(bg) < 0.2) "white" else "black"
  )
  graphics::rect(seq_len(n) - 1, 0, seq_len(n), 1, col = cols, border = NA)
  invisible(x)
}
