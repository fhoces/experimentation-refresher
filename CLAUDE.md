# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

A self-study refresher on experimental design for tech-interview prep. Eight modules, each containing:

- `slides.Rmd` — xaringan slide deck (`countIncrementalSlides: false`, 16:9)
- `slides.html` — committed render output (GitHub Pages serves these directly)
- `exercise.R` — runnable R script with simulations and fill-in-the-blank questions
- `concepts.md` — written refresher
- `slides_files/` — generated PNGs and CSS, also committed (Pages needs them)

Live decks: `https://fhoces.github.io/experimentation-refresher/module-NN/slides.html`. Pushing to `main` rebuilds Pages.

## Rendering slides

Two non-obvious gotchas — both have bitten this repo:

```bash
cd module-NN                    # rmarkdown uses CWD; must cd in
Rscript -e 'Sys.setenv(RSTUDIO_PANDOC = "/Applications/RStudio.app/Contents/Resources/app/quarto/bin/tools/aarch64"); rmarkdown::render("slides.Rmd", quiet = TRUE)'
```

Without `RSTUDIO_PANDOC`, render fails with "pandoc version 1.12.3 or higher is required." Without `cd`, render fails to find `slides.Rmd`.

After rendering, refresh Safari rather than re-opening:

```bash
osascript -e 'tell application "Safari" to set URL of document 1 to (URL of document 1)'
```

To navigate to a specific slide: append `#N` (1-indexed, sub-slides from `--` don't bump the count).

## Visual spot-checks (no screenshot ping-pong)

To preview slides without screenshots from the user, render to PDF and read the PNG:

```bash
"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" \
  --headless --disable-gpu --no-sandbox --virtual-time-budget=10000 \
  --print-to-pdf=/tmp/m7.pdf --print-to-pdf-no-header \
  "file:///abs/path/module-NN/slides.html?print-pdf"
Rscript -e 'png::writePNG(pdftools::pdf_render_page("/tmp/m7.pdf", page = N, dpi = 90), "/tmp/sN.png")'
# then Read /tmp/sN.png
```

`?print-pdf` is xaringan's print mode — one slide per PDF page. Use this proactively when debugging overflow/clipping.

## The running example: zone-notification

Modules 1, 2, 3, 5, and 7 share one DGP. Don't drift the parameters between modules — anything you change here propagates downstream.

```r
n_cities <- 40; drivers_per_city <- 5000      # 200,000 drivers total
direct_effect <- 0.05                          # per-driver direct boost
interference  <- 0.07                          # symmetric crowd-out per share treated
policy_effect <- direct_effect - interference  # -0.02 (full rollout)
city_effect   <- rnorm(n_cities, 0, 0.10)      # demand density
# y0 = 0.4 + 0.2*experience + city_effect - interference*frac_t  (LPM scale)
# y1 = y0 + direct_effect
```

The canonical setup chunk lives at `module-03/slides.Rmd` lines 96–117. M5 uses a continuous-outcome variant (weekly earnings via `rlnorm`); M7 adds a city-level `hte_slope = 0.40` so `local_effect = direct_effect + hte_slope * city_effect` — that heterogeneity is what makes the external-validity story land.

## Slide-deck conventions

The CSS block at the top of every `slides.Rmd` defines a small set of utility classes. Use them; don't invent new ones.

- `.small[ ... ]` / `.tiny[ ... ]` — shrink overflowing content (default first response to "this slide overflows")
- `.highlight-box[ ... ]` (orange) and `.blue-box[ ... ]` (blue) — emphasis blocks. Both have padding/border; if the slide is tight, downgrade to `.small[]` to save vertical space.
- `.pull-left[ ... ] .pull-right[ ... ]` — two-column layout. Standard fix for overflow with chart + text.
- `.nav-btn` (bottom-left), `.nav-btn-br` (bottom-right, leaves room for page counter), `.inline-btn` (inline link styled as a button) — used for jumping between main slides and named-anchor backup slides.

Backup-slide pattern:

```
---
name: my-backup

# Backup: ...

[content]

<a href="#my-main-slide" class="nav-btn">← back</a>
```

And on the main slide: `<a href="#my-backup" class="nav-btn">DGP code</a>` or similar.

## Cross-module navigation

Each deck has a Course Map slide near the top (`# Course Map`) with hyperlinks to siblings (`../module-NN/slides.html`). When you finish a module, also update:

- `index.html` row for that module (mark done, add link)
- `README.md` table row (bold + hyperlink)
- The Course Map TOC in every other module's deck (status from "upcoming"/"done" to ✓ done with link)

This is mechanical but easy to forget — search for `Designing Around Interference` (or whichever module title) to find them all.

## Module status (as of this commit)

- M1, M2, M3, M5, M7: rebuilt around the zone-notification thread, reviewed.
- M4, M6, M8: drafted by agents in an earlier pass; still need a review pass to align with M3's setup and verify the simulations.

## Git workflow

- `main` is published to Pages on push. There's no CI gate.
- Commits run no hooks. Push directly when slides render correctly.
- Rendered `slides.html` and `slides_files/` PNGs are tracked — don't `.gitignore` them or Pages breaks.
- Avoid amending pushed commits; create new ones.

## What is *not* in this repo

No tests, no Makefile, no CI. The only "build" is `rmarkdown::render`. There is no shared package or library — each module's R code is self-contained inside its `slides.Rmd` chunks (and `exercise.R` if applicable).
