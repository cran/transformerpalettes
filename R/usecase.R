# Palette suitability for common plotting use cases ---------------------------
#
# Most palettes were designed to look good on a toy, not on a chart. These
# helpers compute a few perceptual properties from the colors themselves so
# users can find the palettes that actually work for a given job.

# Machado, Oliveira & Fernandes (2009) simulation matrices, severity 1.0,
# applied to linear RGB. Rows are output R, G, B.
cvd_matrices <- list(
  deutan = matrix(c(
    0.367322, 0.860646, -0.227968,
    0.280085, 0.672501, 0.047413,
    -0.011820, 0.042940, 0.968881
  ), 3, byrow = TRUE),
  protan = matrix(c(
    0.152286, 1.052583, -0.204868,
    0.114503, 0.786281, 0.099216,
    -0.003882, -0.048116, 1.051998
  ), 3, byrow = TRUE),
  tritan = matrix(c(
    1.255528, -0.076749, -0.178779,
    -0.078411, 0.930809, 0.147602,
    0.004733, 0.691367, 0.303900
  ), 3, byrow = TRUE)
)

hex_to_srgb <- function(hex) t(grDevices::col2rgb(hex)) / 255

srgb_to_linear <- function(x) {
  ifelse(x <= 0.04045, x / 12.92, ((x + 0.055) / 1.055)^2.4)
}
linear_to_srgb <- function(x) {
  x <- pmin(pmax(x, 0), 1)
  ifelse(x <= 0.0031308, 12.92 * x, 1.055 * x^(1 / 2.4) - 0.055)
}

simulate_cvd <- function(srgb, type) {
  lin <- srgb_to_linear(srgb)
  out <- lin %*% t(cvd_matrices[[type]])
  linear_to_srgb(out)
}

srgb_to_lab <- function(srgb) {
  grDevices::convertColor(srgb, from = "sRGB", to = "Lab")
}

# Smallest pairwise CIE76 distance between colors, in Lab.
min_pairwise_de <- function(lab) {
  if (nrow(lab) < 2L) return(Inf)
  d <- stats::dist(lab)
  min(d)
}

hue_deg <- function(lab) {
  h <- atan2(lab[, "b"], lab[, "a"]) * 180 / pi
  (h + 360) %% 360
}
chroma <- function(lab) sqrt(lab[, "a"]^2 + lab[, "b"]^2)

# Largest angular gap-free spread of a set of hues, in degrees (0 = all the
# same hue, 180 = opposite hues).
hue_spread <- function(h) {
  if (length(h) < 2L) return(0)
  h <- sort(h)
  gaps <- diff(c(h, h[1] + 360))
  360 - max(gaps)
}

palette_stats_one <- function(cols) {
  srgb <- hex_to_srgb(cols)
  lab <- srgb_to_lab(srgb)
  L <- lab[, "L"]
  C <- chroma(lab)
  chromatic <- C >= 20
  h <- hue_deg(lab)[chromatic]

  de_normal <- min_pairwise_de(lab)
  de_cvd <- vapply(names(cvd_matrices), function(t) {
    min_pairwise_de(srgb_to_lab(simulate_cvd(srgb, t)))
  }, numeric(1))

  # Diverging: two chromatic hue families at least 100 degrees apart plus a
  # light or neutral color to sit between them.
  hue_clusters <- 0L
  if (length(h) >= 2L) {
    hs <- sort(h)
    gaps <- diff(c(hs, hs[1] + 360))
    hue_clusters <- sum(gaps > 60)
    if (hue_clusters == 0L) hue_clusters <- 1L
  }
  has_light <- any(L >= 75 | (!chromatic & L >= 55))

  c(
    min_de = de_normal,
    min_de_deutan = unname(de_cvd["deutan"]),
    min_de_protan = unname(de_cvd["protan"]),
    min_de_tritan = unname(de_cvd["tritan"]),
    lum_range = max(L) - min(L),
    hue_spread = hue_spread(h),
    hue_clusters = hue_clusters,
    has_light = as.numeric(has_light)
  )
}

#' Perceptual statistics for every Transformers palette
#'
#' Computes, from the hex colors alone, how suitable each palette is for the
#' common plotting jobs. Used by [tf_find_palettes()]; exposed so you can
#' apply your own thresholds.
#'
#' @details
#' Distances are CIE76 (Euclidean in CIE Lab). Color-vision deficiency is
#' simulated with the Machado, Oliveira and Fernandes (2009) matrices at full
#' severity for deuteranopia, protanopia and tritanopia. Hue statistics only
#' consider colors with chroma of at least 20, so grays and blacks do not
#' count as a hue.
#'
#' @param names Palette names to compute for. Defaults to every palette in
#'   every medium.
#'
#' @return A data frame with one row per palette and the columns:
#' \describe{
#'   \item{palette}{Palette name.}
#'   \item{n_colours}{Number of colors.}
#'   \item{min_de}{Smallest pairwise Lab distance between any two colors.
#'     Larger is easier to tell apart; 20 is a comfortable floor for
#'     categorical use.}
#'   \item{min_de_deutan, min_de_protan, min_de_tritan}{The same after
#'     simulating each color-vision deficiency.}
#'   \item{lum_range}{Range of CIE lightness (0 to 100) across the palette.}
#'   \item{hue_spread}{Angular spread of the chromatic colors' hues, in
#'     degrees. Near 0 means one hue family.}
#'   \item{hue_clusters}{Number of distinct hue families (hues separated by
#'     more than 60 degrees).}
#'   \item{has_light}{Whether the palette contains a light or neutral color
#'     that can serve as a midpoint.}
#'   \item{categorical, colorblind, sequential, diverging}{Logical flags as
#'     used by [tf_find_palettes()].}
#' }
#' @examples
#' s <- tf_palette_stats()
#' head(s[order(-s$min_de_deutan), c("palette", "min_de", "min_de_deutan")])
#' @export
tf_palette_stats <- function(names = tf_palette_names(medium = "all")) {
  names <- match.arg(names, tf_palette_names(medium = "all"), several.ok = TRUE)
  m <- t(vapply(tf_palettes[names], palette_stats_one, numeric(8)))
  out <- data.frame(
    palette = names,
    n_colours = unname(lengths(tf_palettes[names])),
    m,
    stringsAsFactors = FALSE
  )
  out$has_light <- out$has_light > 0
  out$categorical <- out$min_de >= 20
  out$colorblind <- out$min_de >= 20 &
    pmin(out$min_de_deutan, out$min_de_protan, out$min_de_tritan) >= 15
  out$sequential <- out$lum_range >= 50 & out$hue_spread <= 45
  out$diverging <- out$hue_clusters == 2 & out$has_light & out$lum_range >= 40
  rownames(out) <- NULL
  out
}

#' Find Transformers palettes that suit a plotting use case
#'
#' Filters the palettes to those whose colors work for a given job, judged
#' from the perceptual statistics in [tf_palette_stats()]. Many toys
#' look great on a figure but poor on a chart; this surfaces the ones that
#' hold up.
#'
#' @param use One of:
#'   \describe{
#'     \item{`"categorical"`}{Every pair of colors is clearly distinguishable
#'       (minimum Lab distance of 20 or more). Good for unordered groups.}
#'     \item{`"colorblind"`}{Categorical, and still distinguishable under
#'       simulated deuteranopia, protanopia and tritanopia (minimum distance
#'       15 or more in each).}
#'     \item{`"sequential"`}{One hue family (hue spread of 45 degrees or
#'       less among the chromatic colors) spanning at least 50 units of
#'       lightness, so a continuous gradient reads as low-to-high. Pair with
#'       `sort = TRUE` in [tf_palette()] or the `_c` scales.}
#'     \item{`"diverging"`}{Exactly two distinct hue families plus a light or
#'       neutral color to sit between them. The curated order is not
#'       necessarily dark-A, light, dark-B; check [tf_palette_stats()] and
#'       reorder the colors yourself for a continuous diverging scale.}
#'   }
#'
#' The thresholds are deliberately simple heuristics computed by
#' [tf_palette_stats()]; treat the result as a shortlist to look at with
#' [tf_show_palettes()], not a guarantee.
#' @param faction,team,role,medium Optional filters passed to
#'   [tf_palette_names()]. `medium` defaults to `"toy"`; use `"all"` to
#'   search cartoon and comic palettes too.
#' @param min_colours Minimum number of colors the palette must have.
#'
#' @return A character vector of palette names, ordered so that the strongest
#'   candidates for the use case come first.
#' @examples
#' tf_find_palettes("colorblind")
#' tf_find_palettes("diverging", faction = "Decepticon")
#' tf_find_palettes("sequential")
#' tf_find_palettes("colorblind", medium = "cartoon")
#' @export
tf_find_palettes <- function(use = c("categorical", "colorblind", "sequential", "diverging"),
                                faction = NULL, team = NULL, role = NULL,
                             medium = "toy", min_colours = 4) {
  use <- match.arg(use)
  names <- tf_palette_names(faction = faction, team = team, role = role,
                            medium = medium)
  s <- tf_palette_stats(names)
  s <- s[s$n_colours >= min_colours & s[[use]], ]
  score <- switch(
    use,
    categorical = s$min_de,
    colorblind = pmin(s$min_de_deutan, s$min_de_protan, s$min_de_tritan),
    sequential = s$lum_range - s$hue_spread / 4,
    diverging = s$lum_range + pmin(s$hue_spread, 180) / 4
  )
  s$palette[order(-score)]
}
