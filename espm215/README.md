# ESPM 215 prep: Q2 GLMM → GAM → Hefley spatial basis

Prep workspace for two ESPM 215 paper discussions on **Wed Oct 14, 2026**:

1. von Hammerstein et al. 2024 (Sci Rep), reef-fish abundance at backreef mangrove trees (this repo).
2. Hefley et al. 2017 (Ecology), "The basis function approach for modeling autocorrelation in ecological data".

**Roadmap.** Use Q2's `mod2` (abundance at natural trees ~ TreePerimeter + Aspect + DistReef + (1 | LocationID), NB1) as the foundation. Simulate from it, add complexity one stage at a time, and watch what the models and diagnostics do as the autocorrelation ramps up. It starts as site-to-site variance with nothing spatial about it and ends as a strongly spatial gradient. Each stage builds on the one before.

| Stage | File | Truth | Model | Ramp | Suggested day |
|-------|------|-------|-------|------|---------------|
| 1 | [stages/01-q2-real-glmm.qmd](stages/01-q2-real-glmm.qmd) | real data | GLMM (`mod2`) | — | Fri Oct 9 |
| 2 | [stages/02-q2-sim-glmm.qmd](stages/02-q2-sim-glmm.qmd) | `mod2` + iid site effects | GLMM | iid σ | Sat Oct 10 |
| 3 | [stages/03-q2-sim-nonlinear-gam.qmd](stages/03-q2-sim-nonlinear-gam.qmd) | stage 2 + a nonlinear term | GAM | nonlinearity strength | Sun Oct 11 |
| 4 | [stages/04-q2-sim-spatial-basis.qmd](stages/04-q2-sim-spatial-basis.qmd) | stage 3 + a spatial field | GAM + Hefley spatial basis | spatial variance and range | Mon Oct 12 |

Tue Oct 13: build the talk from the finished stage documents and the figures saved in `results/`. Q5's shoaling GAMM is used only as motivation for stage 3; it isn't refit.

Pencil-and-paper work goes in [notes/derivations.qmd](notes/derivations.qmd). Everything here is scaffolding: each `# TODO:` marks work still to do.

## Layout

```
espm215/
  stages/     one .qmd per stage (renders to HTML)
  sim/        simulation code; _load.R sources the rest
                sim_glmm.R -> sim_nonlinear.R -> sim_spatial.R (cumulative), replicate.R
  results/    .rds outputs and saved figures (*.rds / *.RDS gitignored; folder kept)
  notes/      derivations
  archive/    earlier Q1-based work, kept for reference (not rendered)
```

**Paths.** `here` isn't installed, so paths are relative. Quarto runs each chunk with the working directory set to the `.qmd`'s folder. From `stages/`, use `source("../sim/_load.R")`. It defines `espm215_root`, `data_dir` (the repo's `data/`) and `results_dir`. Prefer `file.path(results_dir, ...)` to absolute paths, so the files work in any checkout.

## Rendering

The Quarto project is at the repo root ([`_quarto.yml`](../_quarto.yml)), so every document can find `_extensions/`. Its `render:` list covers `slides/*.qmd` (the existing template deck), `espm215/stages/*.qmd` and `espm215/notes/*.qmd`. Nothing else in the repo is rendered. Quarto starts R from the repo root, so `renv` is active during renders. If you run chunks interactively, start R from the repo root too.

```sh
quarto render                                     # everything in the render list
quarto render espm215/stages/01-q2-real-glmm.qmd
```

Last check (Oct 9): all four stage files and `notes/derivations.qmd` rendered without errors or warnings.

## Known gaps

- **Moran's I: neither `spdep` nor `ape` is installed** in the renv library or the site library. Install one (and record it in `renv.lock`) before the stage 2 and stage 4 diagnostics.
- `here` is not installed, which is why the relative paths above are used.
- `_extensions/` (quarto-live) sits at the repo root but is not committed on this branch. The stage files are plain HTML and don't need it; `slides/` does.
