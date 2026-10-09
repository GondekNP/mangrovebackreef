# ESPM 215 prep: mangrove GLMM → Hefley basis functions

Prep workspace for two ESPM 215 paper discussions on **Wed Oct 14, 2026**:

1. von Hammerstein et al. 2024 (Sci Rep), reef-fish abundance with NB GLMMs and location random intercepts (this repo).
2. Hefley et al. 2017 (Ecology), "The basis function approach for modeling autocorrelation in ecological data".

**Roadmap.** Simulate from the authors' `mod1` on the real design (stage 1). Learn Hefley's machinery on a 1-D toy. Replace the iid location intercepts with a spatial field (stage 2) and refit with basis-function and spatial models. Replicate, test the authors' spatial diagnostic, then build both decks.

Everything here is scaffolding. Each `# TODO:` marks work still to do.

## Schedule

| Day | File | Focus | Main outputs |
|-----|------|-------|--------------|
| Fri Oct 9  | [homework/01-fri-stage1.qmd](homework/01-fri-stage1.qmd)     | Orient; stage 1 (iid intercepts) | `sim/stage1.R`, stage-1 results in `results/` |
| Sat Oct 10 | [homework/02-sat-toy1d.qmd](homework/02-sat-toy1d.qmd)       | Hefley's 1-D toy (Fig. 2) | `sim/toy1d.R` |
| Sun Oct 11 | [homework/03-sun-stage2.qmd](homework/03-sun-stage2.qmd)     | Stage 2: add a spatial field | `sim/stage2.R` |
| Mon Oct 12 | [homework/04-mon-replicates.qmd](homework/04-mon-replicates.qmd) | Replicates; Moran's I check | `sim/replicate.R`, stage-2 .rds in `results/` |
| Tue Oct 13 | [homework/05-tue-decks.qmd](homework/05-tue-decks.qmd)       | Build decks; rehearse | `decks/*.qmd` |
| Wed Oct 14 | [decks/mangrove.qmd](decks/mangrove.qmd), [decks/hefley.qmd](decks/hefley.qmd) | Present | — |

Pencil-and-paper work goes in [notes/derivations.qmd](notes/derivations.qmd).

## Layout

```
espm215/
  homework/   one .qmd per day (renders to HTML)
  sim/        simulation code; _load.R sources the rest
  decks/      live-revealjs decks (quarto-live / webR)
  results/    .rds outputs (gitignored; folder kept with .gitkeep)
  notes/      derivations
```

**Paths.** `here` isn't installed, so paths are relative. Quarto runs each chunk with the working directory set to the `.qmd`'s folder. From `homework/` or `decks/`, use `source("../sim/_load.R")`. It defines `espm215_root`, `data_dir` (the repo's `data/`) and `results_dir`.

## Rendering

The Quarto project is at the repo root ([`_quarto.yml`](../_quarto.yml)), so every document can find `_extensions/r-wasm/live`. Its `render:` list covers `slides/*.qmd` (the existing template deck) and the `.qmd` files in `espm215/homework`, `decks` and `notes`. Nothing else in the repo is rendered. Quarto starts R from the repo root, so `renv` is active during renders.

```sh
quarto render                                # everything in the render list
quarto render espm215/homework/01-fri-stage1.qmd
quarto preview espm215/decks/mangrove.qmd    # served on port 4200
```

Last check (Oct 9): all five homework files, `notes/derivations.qmd` and both decks rendered without errors or warnings.

## Known gaps

- **Moran's I: neither `spdep` nor `ape` is installed** in the renv library or the site library. Install one (and record it in `renv.lock`) before Monday's diagnostic.
- `here` is not installed, which is why the relative paths above are used.
- `_extensions/` (quarto-live) is used from the repo root but is not committed on this branch. A fresh clone needs it before the decks will render.
