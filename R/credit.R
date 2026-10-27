# Attribution text for the rights holders behind the palettes ----------------

# Join a character vector in prose: "a", "a and b", "a, b and c".
credit_join <- function(x) {
  n <- length(x)
  if (n <= 1L) return(x)
  if (n == 2L) return(paste(x, collapse = " and "))
  paste0(paste(x[-n], collapse = ", "), " and ", x[n])
}

# Year used in the package reference: the CRAN publication date when there is
# one, otherwise the current year.
credit_year <- function() {
  d <- tryCatch(utils::packageDescription("transformerpalettes")$`Date/Publication`,
                error = function(e) NULL)
  if (is.null(d) || is.na(d)) d <- Sys.Date()
  format(as.Date(substr(as.character(d), 1, 10)), "%Y")
}

# How each medium is credited: the noun that follows the character names, and
# the phrase naming where the colors come from, in caption and acknowledgment
# registers.
.credit_media <- list(
  toy = list(noun = "toy colorway", noun_pl = "toy colorways",
             by = "by Hasbro and Takara Tomy",
             ack = "designed by Hasbro and Takara Tomy"),
  g2 = list(noun = "Generation 2 toy colorway", noun_pl = "Generation 2 toy colorways",
            by = "by Hasbro and Takara Tomy",
            ack = "designed by Hasbro and Takara Tomy"),
  cartoon = list(noun = "cartoon colors", noun_pl = "cartoon colors",
                 by = "from the Generation 1 animated series",
                 ack = "from the Generation 1 animated series"),
  comic = list(noun = "comic colors", noun_pl = "comic colors",
               by = "from the Marvel Transformers comics",
               ack = "from the Marvel Transformers comics")
)

# Palette keys behind a credit request: a palette object (plain, team or
# picked) or a vector of names.
credit_keys <- function(x, medium = "toy") {
  if (inherits(x, "tf_palette")) {
    keys <- if (!is.null(names(x))) names(x) else attr(x, "name")
    keys <- keys[keys %in% names(tf_palettes)]
    if (length(keys) == 0L) {
      stop("Could not identify the source palettes of this object.", call. = FALSE)
    }
    return(unique(keys))
  }
  if (!is.character(x) || length(x) == 0L) {
    stop("`x` must be a palette object or a character vector of palette names.",
         call. = FALSE)
  }
  unique(vapply(x, palette_key, character(1), medium = medium, USE.NAMES = FALSE))
}

#' Credit the rights holders behind a plot's colors
#'
#' Builds a short attribution sentence naming the characters whose palettes
#' were used and where their colors come from (the Hasbro and Takara Tomy
#' toys, the Generation 1 animated series, or the Marvel comics), suitable for
#' a figure caption or an acknowledgments section. Naming the source of a
#' color scheme is ordinary factual attribution; the longer form also states
#' that the colors are approximations and imply no endorsement, which is the
#' wording journals tend to want.
#'
#' @param x What to credit: a palette name, a character vector of names, or a
#'   `tf_palette` object. Objects from [tf_pick()] and [tf_team_palette()]
#'   carry their source palettes, so the credit covers every character that
#'   contributed a color. Names may carry a medium suffix
#'   (`"megatron_cartoon"`) or rely on `medium`.
#' @param format One of:
#'   \describe{
#'     \item{`"caption"`}{One sentence for a figure caption, e.g. `Colors:
#'       Optimus Prime toy colorway by Hasbro and Takara Tomy, via the
#'       transformerpalettes R package.`}
#'     \item{`"acknowledgment"`}{Two sentences in the register of an
#'       acknowledgments section, naming the sources and stating that the hex
#'       values are approximations that imply no endorsement.}
#'     \item{`"markdown"`}{The caption with each character linked to its
#'       Transformers Wiki reference page, for R Markdown, Quarto or pkgdown
#'       captions.}
#'   }
#' @param package Logical. Mention the transformerpalettes package? Set to
#'   `FALSE` when the package is cited elsewhere in the text.
#' @param medium Medium for plain palette names; see [tf_media()].
#'
#' @return A single character string.
#' @seealso [tf_characters] for the underlying metadata;
#'   `citation("transformerpalettes")` for the package reference.
#' @examples
#' tf_credit("optimus_prime")
#' tf_credit(c("optimus_prime", "megatron_cartoon", "megatron_comic"))
#' tf_credit(tf_team_palette("Stunticons"))
#' tf_credit(tf_pick(c("optimus_prime", "megatron"), n = 4))
#' tf_credit("optimus_prime", format = "acknowledgment")
#' cat(tf_credit(c("optimus_prime", "megatron"), format = "markdown"))
#'
#' library(ggplot2)
#' ggplot(mpg, aes(displ, hwy, color = drv)) +
#'   geom_point(size = 2.5) +
#'   scale_color_tf("optimus_prime") +
#'   labs(caption = tf_credit("optimus_prime"))
#' @export
tf_credit <- function(x, format = c("caption", "acknowledgment", "markdown"),
                      package = TRUE, medium = "toy") {
  format <- match.arg(format)
  keys <- credit_keys(x, medium = medium)
  meta <- tf_characters[match(keys, tf_characters$palette), ]

  label <- if (format == "markdown") {
    paste0("[", meta$character, "](", meta$source, ")")
  } else {
    meta$character
  }

  groups <- character(0)
  for (md in unique(meta$medium)) {
    rows <- meta$medium == md
    names_md <- unique(label[rows])
    spec <- .credit_media[[md]]
    if (is.null(spec)) {
      spec <- list(noun = paste(md, "colors"), noun_pl = paste(md, "colors"),
                   by = "by Hasbro and Takara Tomy",
                   ack = "designed by Hasbro and Takara Tomy")
    }
    noun <- if (length(names_md) > 1L) spec$noun_pl else spec$noun
    link <- if (format == "acknowledgment") spec$ack else spec$by
    groups <- c(groups, paste(credit_join(names_md), noun, link))
  }
  body <- if (length(groups) > 2L) paste(groups, collapse = "; ") else credit_join(groups)

  pkg <- "the transformerpalettes R package"
  if (format == "acknowledgment") {
    out <- paste0("Figure colors are derived from the ", body, ".")
    if (isTRUE(package)) {
      out <- paste0(
        out, " Hex values are approximations from ", pkg, " (Maitner ",
        credit_year(), ") and imply no endorsement by Hasbro or Takara Tomy."
      )
    } else {
      out <- paste0(out, " Hex values are approximations and imply no ",
                    "endorsement by Hasbro or Takara Tomy.")
    }
    return(out)
  }

  out <- paste0("Colors: ", body)
  if (isTRUE(package)) out <- paste0(out, ", via ", pkg)
  paste0(out, ".")
}
