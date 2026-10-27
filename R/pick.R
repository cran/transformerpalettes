# Selecting a subset of colors from one or more palettes ---------------------
#
# The palettes are curated to look like the characters, not to plot well.
# tf_pick() pools the colors of one or more palettes, removes the ones that
# will not read against the intended background, and then chooses the n
# colors that are hardest to confuse with one another: the subset whose
# closest pair is as far apart as possible in CIE Lab (a max-min dispersion
# problem), optionally judged under simulated color-vision deficiency, or by
# lightness alone for output that will be printed in grayscale.

# WCAG 2 relative luminance of sRGB colors.
relative_luminance <- function(hex) {
  lin <- srgb_to_linear(hex_to_srgb(hex))
  as.numeric(lin %*% c(0.2126, 0.7152, 0.0722))
}

# WCAG 2 contrast ratio between each color and a single background color.
contrast_ratio <- function(hex, background) {
  l1 <- relative_luminance(hex)
  l2 <- relative_luminance(background)
  (pmax(l1, l2) + 0.05) / (pmin(l1, l2) + 0.05)
}

# Pairwise distance matrix used to judge how confusable two colors are.
pick_distances <- function(hex, colorblind = FALSE, grayscale = FALSE) {
  srgb <- hex_to_srgb(hex)
  lab <- srgb_to_lab(srgb)
  if (grayscale) {
    return(as.matrix(stats::dist(lab[, "L", drop = FALSE])))
  }
  d <- as.matrix(stats::dist(lab))
  if (colorblind) {
    for (t in names(cvd_matrices)) {
      d_t <- as.matrix(stats::dist(srgb_to_lab(simulate_cvd(srgb, t))))
      d <- pmin(d, d_t)
    }
  }
  d
}

# Score of a subset: the smallest pairwise distance, with the mean pairwise
# distance as a tie-breaker so that among equally safe subsets the more
# spread-out one wins.
subset_score <- function(d, idx) {
  sub <- d[idx, idx]
  vals <- sub[upper.tri(sub)]
  min(vals) + 0.01 * mean(vals)
}

# Choose n of the m colors maximizing subset_score(). Exhaustive when the
# number of subsets is small; otherwise greedy farthest-point seeding
# followed by single-swap local search, which is deterministic and close to
# optimal for the pool sizes the package produces.
choose_subset <- function(d, n, max_exhaustive = 50000) {
  m <- nrow(d)
  if (n >= m) return(seq_len(m))
  if (n == 1L) return(which.max(rowSums(d)))
  if (choose(m, n) <= max_exhaustive) {
    combos <- utils::combn(m, n)
    scores <- apply(combos, 2, function(idx) subset_score(d, idx))
    return(combos[, which.max(scores)])
  }
  # greedy: start from the most distant pair, then add the color whose
  # nearest chosen neighbor is farthest away
  start <- which(d == max(d), arr.ind = TRUE)[1, ]
  chosen <- as.integer(start)
  while (length(chosen) < n) {
    rest <- setdiff(seq_len(m), chosen)
    nearest <- apply(d[rest, chosen, drop = FALSE], 1, min)
    chosen <- c(chosen, rest[which.max(nearest)])
  }
  # local search: swap one chosen color for one unchosen while it helps
  best <- subset_score(d, chosen)
  repeat {
    improved <- FALSE
    for (i in seq_along(chosen)) {
      for (j in setdiff(seq_len(m), chosen)) {
        cand <- chosen
        cand[i] <- j
        s <- subset_score(d, cand)
        if (s > best + 1e-9) {
          chosen <- cand
          best <- s
          improved <- TRUE
        }
      }
    }
    if (!improved) break
  }
  sort(chosen)
}

# Order a chosen set so that each color is as different as possible from
# the ones before it, so taking the first k of the result is still a good
# choice.
order_by_dispersion <- function(d, idx) {
  if (length(idx) <= 2L) return(idx)
  sub <- d[idx, idx]
  first <- which.max(rowSums(sub))
  out <- first
  while (length(out) < length(idx)) {
    rest <- setdiff(seq_along(idx), out)
    nearest <- apply(sub[rest, out, drop = FALSE], 1, min)
    out <- c(out, rest[which.max(nearest)])
  }
  idx[out]
}

#' Pick the most distinguishable colors from one or more palettes
#'
#' Pools the colors of the named palettes and selects the `n` that are
#' hardest to confuse with one another on a given kind of plot: light
#' background, dark background, or output that will be read in grayscale.
#' Optionally judges distinctness under simulated color-vision deficiency.
#' Use it when a single character's palette does not have enough usable
#' colors, or when you want a team's or a faction's colors but only the
#' ones that hold up on a chart.
#'
#' @details
#' The selection runs in three steps.
#'
#' 1. **Pool.** The colors of every palette in `palettes` are combined,
#'    with duplicates removed. Names may be plain (`"optimus_prime"`) or
#'    carry a medium suffix (`"optimus_prime_cartoon"`); plain names use
#'    `medium`.
#' 2. **Filter for the background.** Colors whose WCAG 2 contrast ratio
#'    against the background is below `min_contrast` are dropped, so a
#'    light-mode selection never contains a near-white and a dark-mode
#'    selection never contains a near-black. The background is white for
#'    `"light"` and `"grayscale"` and near-black (`"#121212"`) for `"dark"`
#'    unless `background` is given. The default of 3 is the WCAG minimum for
#'    graphical objects; lower it to keep more colors, raise it for text.
#' 3. **Choose.** Every pair of remaining colors is scored by its distance
#'    in CIE Lab (CIE76). With `colorblind = TRUE` the distance is the
#'    smallest of the normal-vision distance and the distances after
#'    simulating deuteranopia, protanopia and tritanopia (Machado, Oliveira
#'    and Fernandes 2009), so two colors only count as distinct if every
#'    viewer can tell them apart. With `style = "grayscale"` only the
#'    lightness difference counts, so the colors survive conversion to
#'    gray. The `n` colors whose closest pair is farthest apart are chosen
#'    (a maximum-dispersion subset, found exhaustively when the pool is
#'    small and by greedy seeding plus swap search otherwise), then ordered
#'    so that each color is as different as possible from those before it.
#'
#' The result is a categorical palette: it does not try to build a gradient.
#' The smallest pairwise distance in the selection is returned as the
#' `min_distance` attribute; values above about 20 are comfortably distinct,
#' and below about 12 two colors will be hard to tell apart. If the pool
#' cannot supply `n` colors after filtering, the function errors and says
#' how many it had, so add palettes or lower `min_contrast`.
#'
#' @param palettes Character vector of one or more palette names; see
#'   [tf_palette_names()]. Team names are not accepted; use
#'   `tf_palette_names(team = ...)` to expand a team.
#' @param n Number of colors wanted.
#' @param style One of `"light"` (white background), `"dark"` (near-black
#'   background) or `"grayscale"` (white background, judged by lightness
#'   alone).
#' @param colorblind Logical. Require the colors to stay distinct under
#'   simulated deuteranopia, protanopia and tritanopia?
#' @param medium Medium for plain palette names; see [tf_media()].
#' @param background Optional background color overriding the one implied
#'   by `style`, as a hex string.
#' @param min_contrast Minimum WCAG 2 contrast ratio a color must have
#'   against the background to be considered. Set to 1 to disable the
#'   filter.
#'
#' @return A character vector of `n` hex colors with class `"tf_palette"`,
#'   named by the palette each color came from, and with attributes
#'   `min_distance` (smallest pairwise distance under the chosen criterion),
#'   `style`, `colorblind` and `background`.
#' @seealso [tf_find_palettes()] to shortlist whole palettes instead;
#'   [tf_palette_stats()] for the underlying measures.
#' @examples
#' # five colors for a white-background plot, from the two leaders
#' tf_pick(c("optimus_prime", "megatron"), n = 5)
#'
#' # the same for a dark theme, and color-blind safe
#' tf_pick(c("optimus_prime", "megatron"), n = 4, style = "dark", colorblind = TRUE)
#'
#' # a whole team, cartoon colors, printable in grayscale
#' tf_pick(tf_palette_names(team = "Combaticons"), n = 4,
#'         style = "grayscale", medium = "cartoon")
#'
#' library(ggplot2)
#' cols <- tf_pick(tf_palette_names(team = "Predacons"), n = 3, colorblind = TRUE)
#' ggplot(mpg, aes(displ, hwy, colour = drv)) +
#'   geom_point(size = 2.5) +
#'   scale_colour_manual(values = unname(cols)) +
#'   theme_minimal()
#' @export
tf_pick <- function(palettes, n = 5, style = c("light", "dark", "grayscale"),
                    colorblind = FALSE, medium = "toy", background = NULL,
                    min_contrast = 3) {
  style <- match.arg(style)
  if (!is.character(palettes) || length(palettes) == 0L) {
    stop("`palettes` must be a character vector of palette names.", call. = FALSE)
  }
  n <- as.integer(n)
  if (length(n) != 1L || is.na(n) || n < 1L) {
    stop("`n` must be a single positive integer.", call. = FALSE)
  }
  if (is.null(background)) {
    background <- if (style == "dark") "#121212" else "#FFFFFF"
  }
  if (!is.character(background) || length(background) != 1L ||
      !grepl("^#[0-9A-Fa-f]{6}$", background)) {
    stop("`background` must be a single hex color such as \"#FFFFFF\".", call. = FALSE)
  }

  keys <- vapply(palettes, palette_key, character(1), medium = medium)
  pool <- do.call(rbind, lapply(keys, function(k) {
    data.frame(hex = tf_palettes[[k]], source = k, stringsAsFactors = FALSE)
  }))
  pool <- pool[!duplicated(toupper(pool$hex)), , drop = FALSE]

  contrast <- contrast_ratio(pool$hex, background)
  keep <- contrast >= min_contrast
  if (sum(keep) < n) {
    stop(
      "Only ", sum(keep), " of the ", nrow(pool), " pooled colors have a ",
      "contrast ratio of at least ", min_contrast, " against ", background,
      ", but ", n, " were requested. Add palettes or lower `min_contrast`.",
      call. = FALSE
    )
  }
  pool <- pool[keep, , drop = FALSE]

  d <- pick_distances(pool$hex, colorblind = colorblind,
                      grayscale = style == "grayscale")
  idx <- choose_subset(d, n)
  idx <- order_by_dispersion(d, idx)
  sub <- d[idx, idx, drop = FALSE]
  min_d <- if (length(idx) > 1L) min(sub[upper.tri(sub)]) else Inf

  structure(
    stats::setNames(pool$hex[idx], pool$source[idx]),
    class = "tf_palette",
    name = paste(unique(keys), collapse = " + "),
    picked = TRUE,
    min_distance = min_d,
    style = style,
    colorblind = colorblind,
    background = background
  )
}
