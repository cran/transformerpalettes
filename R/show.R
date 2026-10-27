#' Display Transformers palettes
#'
#' Draws a swatch strip for each palette on the current graphics device,
#' labeled with the palette name and, by default, the hex code under each
#' swatch. Useful for picking a character or for reporting a color that looks
#' wrong. With no arguments every toy palette is drawn, which is a lot; filter
#' by `faction`, `team`, `role` or `use` to narrow it down, or pass a
#' character's palettes across media to compare them.
#'
#' @param names Optional character vector of palette names to show. Defaults
#'   to every palette matching the other filters.
#' @param faction Optional faction to restrict to; see [tf_factions()].
#' @param team Optional combiner team to restrict to; see [tf_teams()].
#' @param role Optional role to restrict to; see [tf_palette_names()].
#' @param use Optional use case to restrict to; see [tf_find_palettes()].
#' @param medium Which medium's palettes to show: `"toy"` (default),
#'   `"cartoon"`, `"comic"` or `"all"`. Ignored when `names` is given.
#' @param ncol Number of columns to arrange the swatch strips in.
#' @param hex Logical. Print the hex code under each swatch?
#'
#' @return Invisibly, the character vector of palette names that were drawn.
#' @examples
#' tf_show_palettes(team = "Aerialbots")
#' tf_show_palettes(team = "Aerialbots", medium = "cartoon")
#' tf_show_palettes(faction = "Decepticon", role = "combined form", ncol = 2)
#' tf_show_palettes(use = "colorblind", ncol = 4)
#' tf_show_palettes(c("megatron", "megatron_cartoon", "megatron_comic"), ncol = 1)
#' @export
tf_show_palettes <- function(names = NULL, faction = NULL, team = NULL,
                             role = NULL, use = NULL, medium = "toy",
                             ncol = 3, hex = TRUE) {
  if (is.null(names)) {
    names <- tf_palette_names(faction = faction, team = team, role = role,
                              medium = medium)
    if (!is.null(use)) {
      names <- intersect(names, tf_find_palettes(use, medium = "all"))
    }
  } else {
    names <- match.arg(names, tf_palette_names(medium = "all"), several.ok = TRUE)
  }
  n <- length(names)
  if (n == 0L) {
    stop("No palettes match the requested filters.", call. = FALSE)
  }
  ncol <- max(1L, min(as.integer(ncol), n))
  nrow <- ceiling(n / ncol)

  old <- graphics::par(mfrow = c(nrow, ncol), mar = c(0.2, 0.4, 1.4, 0.4))
  on.exit(graphics::par(old), add = TRUE)

  ylim <- if (hex) c(-0.45, 1) else c(0, 1)
  for (nm in names) {
    cols <- as.character(tf_palettes[[nm]])
    k <- length(cols)
    graphics::plot(
      0, 0, type = "n", xlim = c(0, k), ylim = ylim,
      axes = FALSE, xlab = "", ylab = "", main = nm, cex.main = 0.9,
      font.main = 1, xaxs = "i", yaxs = "i"
    )
    graphics::rect(seq_len(k) - 1, 0, seq_len(k), 1, col = cols, border = NA)
    if (hex) {
      graphics::text(
        seq_len(k) - 0.5, -0.22, labels = cols,
        cex = 0.55, family = "mono", xpd = NA
      )
    }
  }
  invisible(names)
}
