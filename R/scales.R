#' Transformers color and fill scales for ggplot2
#'
#' Color and fill scales that use a character's palette. The `_d` variants
#' are for discrete data, the `_c` variants for continuous data, and
#' `scale_colour_tf()` / `scale_fill_tf()` choose between the two with the
#' `discrete` argument. `scale_color_*` spellings are aliases.
#'
#' @param palette Name of a character's palette. See [tf_palette_names()].
#' @param discrete Logical. If `TRUE` (default) build a discrete scale,
#'   otherwise a continuous gradient scale.
#' @param reverse Logical. Reverse the order of colors in the palette?
#' @param sort Logical, continuous scales only. Order the palette from darkest
#'   to lightest before building the gradient, so the scale reads as
#'   low-to-high. See [tf_find_palettes()] for palettes that suit this.
#' @param medium Which version of the character to use: `"toy"` (default),
#'   `"cartoon"` or `"comic"`. See [tf_media()].
#' @param ... Additional arguments passed on to
#'   [ggplot2::discrete_scale()] (discrete) or
#'   [ggplot2::scale_colour_gradientn()] / [ggplot2::scale_fill_gradientn()]
#'   (continuous).
#'
#' @details
#' Discrete scales draw the first `n` colors of the palette, where `n` is the
#' number of levels in the data. If the data has more levels than the palette
#' has colors, the palette is interpolated with [grDevices::colorRampPalette()]
#' so that every level still receives a distinct color; expect the result to
#' be less legible than the curated colors. For a palette with one color per
#' member of a combiner team, pass [tf_team_palette()] to
#' [ggplot2::scale_colour_manual()].
#'
#' @return A ggplot2 scale object.
#' @examples
#' library(ggplot2)
#'
#' ggplot(mpg, aes(displ, hwy, colour = drv)) +
#'   geom_point(size = 3) +
#'   scale_colour_tf("optimus_prime")
#'
#' ggplot(mpg, aes(displ, hwy, colour = drv)) +
#'   geom_point(size = 3) +
#'   scale_colour_tf("optimus_prime", medium = "cartoon")
#'
#' ggplot(diamonds, aes(cut, fill = clarity)) +
#'   geom_bar() +
#'   scale_fill_tf_d("bruticus")
#'
#' ggplot(faithfuld, aes(waiting, eruptions, fill = density)) +
#'   geom_tile() +
#'   scale_fill_tf_c("hot_spot", sort = TRUE)
#' @name scale_tf
NULL

tf_pal <- function(palette, reverse = FALSE, medium = "toy") {
  function(n) {
    cols <- tf_palette(palette, n = n, type = "discrete", strict = FALSE,
                       medium = medium)
    cols <- as.character(cols)
    if (reverse) cols <- rev(cols)
    cols
  }
}

#' @rdname scale_tf
#' @export
scale_colour_tf_d <- function(palette = "optimus_prime", reverse = FALSE,
                              medium = "toy", ...) {
  ggplot2::discrete_scale(
    aesthetics = "colour",
    palette = tf_pal(palette, reverse, medium),
    ...
  )
}

#' @rdname scale_tf
#' @export
scale_fill_tf_d <- function(palette = "optimus_prime", reverse = FALSE,
                            medium = "toy", ...) {
  ggplot2::discrete_scale(
    aesthetics = "fill",
    palette = tf_pal(palette, reverse, medium),
    ...
  )
}

#' @rdname scale_tf
#' @export
scale_colour_tf_c <- function(palette = "optimus_prime", reverse = FALSE,
                              sort = FALSE, medium = "toy", ...) {
  cols <- as.character(tf_palette(palette, sort = sort, medium = medium))
  if (reverse) cols <- rev(cols)
  ggplot2::scale_colour_gradientn(colours = cols, ...)
}

#' @rdname scale_tf
#' @export
scale_fill_tf_c <- function(palette = "optimus_prime", reverse = FALSE,
                            sort = FALSE, medium = "toy", ...) {
  cols <- as.character(tf_palette(palette, sort = sort, medium = medium))
  if (reverse) cols <- rev(cols)
  ggplot2::scale_fill_gradientn(colours = cols, ...)
}

#' @rdname scale_tf
#' @export
scale_colour_tf <- function(palette = "optimus_prime", discrete = TRUE,
                            reverse = FALSE, sort = FALSE, medium = "toy", ...) {
  if (discrete) {
    scale_colour_tf_d(palette = palette, reverse = reverse, medium = medium, ...)
  } else {
    scale_colour_tf_c(palette = palette, reverse = reverse, sort = sort,
                      medium = medium, ...)
  }
}

#' @rdname scale_tf
#' @export
scale_fill_tf <- function(palette = "optimus_prime", discrete = TRUE,
                          reverse = FALSE, sort = FALSE, medium = "toy", ...) {
  if (discrete) {
    scale_fill_tf_d(palette = palette, reverse = reverse, medium = medium, ...)
  } else {
    scale_fill_tf_c(palette = palette, reverse = reverse, sort = sort,
                    medium = medium, ...)
  }
}

#' @rdname scale_tf
#' @export
scale_color_tf_d <- scale_colour_tf_d

#' @rdname scale_tf
#' @export
scale_color_tf_c <- scale_colour_tf_c

#' @rdname scale_tf
#' @export
scale_color_tf <- scale_colour_tf
