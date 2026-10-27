# transformerpalettes 0.4.0

* New `tf_credit()` writes a figure-caption or acknowledgments sentence
  naming the characters used and where their colors come from (the Hasbro and
  Takara Tomy toys, the animated series or the Marvel comics), and follows
  picks and team palettes back to their source palettes.
  `citation("transformerpalettes")` now returns a reference for the package
  itself.
* Third pass through the wishlist, clearing the queue: Shockwave, Soundwave
  and the six cassettes, the Insecticons, the eleven 1984 Autobot cars, the
  six Mini Vehicles, the 1986 movie cast (Hot Rod, Rodimus Prime, Ultra
  Magnus, Kup, Blurr, Springer, Wreck-Gar, Galvatron, Cyclonus, Scourge,
  Gnaw), and two more combiner teams, the Pretender Monsters (Monstructor)
  and Takara's Breastforce (Liokaiser). Each has a toy palette checked
  against a TFWiki toy photo and, where the character appeared in a cartoon,
  a cartoon palette linked to an episode still.
* New `"standalone"` role for characters outside any team, and new
  subgroups Cassettes, Insecticons, Autobot Cars and Minibots.
* Comic palettes for the Technobots, Terrorcons and Seacons from the Marvel
  UK stories "Love and Steel!" and "Enemy Action!".
* New `"g2"` medium: the Generation 2 re-releases of the Constructicons
  (1992, yellow), Aerialbots (1994) and Combaticons (1994, camouflage), keyed
  `<name>_g2`. 296 palettes in total.
* Corrected the wishlist note on Rumble and Frenzy: the Hasbro toy carded as
  Rumble is red and Frenzy is blue; the cartoon swapped them. The palettes
  follow the toys for `toy` and the cartoon for `cartoon`.

# transformerpalettes 0.3.0

* First pass through the wishlist. New subgroups that do not combine, with a
  `"subgroup member"` role and `NA` combiner: the **Dinobots** (Grimlock,
  Slag, Sludge, Snarl, Swoop) and the **Seekers** (Starscream, Thundercracker,
  Skywarp, Dirge, Ramjet, Thrust), each with toy and cartoon palettes checked
  against TFWiki toy photos and episode stills. `tf_teams()` now lists
  subgroups alongside combiner teams and `tf_team_palette()` works for them.
* Comic palettes for six combiner teams, each sampled from a named Marvel US
  issue and linked to the panel: Constructicons (#10), Aerialbots (#21),
  Stunticons (#22), Protectobots (#24), Predacons (#25) and Combaticons
  (#32). Marvel's coloring often departs from the toys: Menasor is yellow
  and magenta, Vortex is cyan, Rampage and Headstrong are red. 177 palettes
  in total.

# transformerpalettes 0.2.0

* The package is now called transformerpalettes (it started life as
  transformeRs). Function names are unchanged; reinstall with
  `pak::pak("bmaitner/transformerpalettes")`. The old GitHub URL redirects.
* Palettes now record a `medium`: every character has a `toy` palette (the
  original release), every character has a `cartoon` palette (the Sunbow
  animation model, or the Masterforce model for the Seacons), and Optimus
  Prime and Megatron have a `comic` palette (Marvel). Cartoon and comic
  palettes are keyed `<name>_cartoon` and `<name>_comic`, and
  `tf_characters` gains `base` and `medium` columns. 118 palettes in total.
* New `medium` argument on `tf_palette()`, `tf_palette_names()`,
  `tf_team_palette()`, `tf_show_palettes()`, `tf_find_palettes()` and the
  ggplot2 scales, defaulting to `"toy"` so existing code is unchanged;
  `"all"` lists every medium. New `tf_media()`.
* Cartoon palettes link to an episode still on the Transformers Wiki as their
  reference image; the palette browser gains a Medium filter and badge.
* Corrected the toy palettes of Cutthroat, Drag Strip and Vortex against
  their toy photos.
* New `tf_pick()` selects the `n` most distinguishable colors from one or
  more palettes for a light, dark or grayscale plot, optionally requiring
  them to stay distinct under simulated color-vision deficiency. Colors
  that fail a WCAG contrast check against the background are dropped first;
  the subset is then chosen to maximize the smallest pairwise CIE Lab
  distance.
* Comic palettes for the combiner teams are queued in `WISHLIST.md` rather
  than guessed; Marvel coloring varies by issue, so each will cite the
  issue it was sampled from.

# transformerpalettes 0.1.0

* Initial release with 58 palettes: Optimus Prime, Megatron, and every member
  and combined form of the nine core Generation 1 combiner teams (Aerialbots,
  Protectobots, Technobots, Constructicons, Stunticons, Combaticons,
  Terrorcons, Predacons, Seacons).
* `tf_palette()`, `tf_palette_names()`, `tf_factions()`, `tf_teams()`,
  `tf_show_palettes()`, and `tf_team_palette()` for one color per member of
  a combiner team (with `distinct = TRUE` for teams cast from shared plastics).
* ggplot2 scales: `scale_colour_tf()`, `scale_fill_tf()` and their
  `_d` / `_c` variants, plus `scale_color_*` aliases.
* `tf_find_palettes()` and `tf_palette_stats()` to shortlist palettes that
  work for categorical, colorblind-safe, sequential or diverging use, judged
  from the colors themselves.
* `tf_characters` metadata table with faction, team, role, alternate mode,
  year, descriptions and Transformers Wiki links and toy photos.
* pkgdown site at <https://bmaitner.github.io/transformerpalettes/> with a filterable
  palette browser and prefilled GitHub issue forms for suggesting palette
  changes and requesting characters. `WISHLIST.md` tracks what is queued.
