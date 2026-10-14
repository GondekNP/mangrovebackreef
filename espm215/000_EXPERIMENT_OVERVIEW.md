# ESPM 215 experiment overview

Briefing for an agent picking up work in `espm215/`. It covers what the experiment is, where things live, what's done, and the working rules.

## Purpose

This workspace is prep for two ESPM 215 (Berkeley) paper discussions on **Wed Oct 14, 2026**:

1. **von Hammerstein et al. 2024, *Scientific Reports*.** Reef-fish abundance at backreef mangrove trees. The data and the authors' original R scripts are in this repo (`data/`, `R code/`).
2. **Hefley et al. 2017, *Ecology*,** "The basis function approach for modeling autocorrelation in ecological data".

The experiment ties the two papers together. It takes one of the authors' fitted models as a "truth", simulates data from it, and then adds complexity one stage at a time until the data carry strong spatial autocorrelation. At each stage it asks two things:

- Do the usual diagnostics catch the problem?
- Do the models get the answers right (bias, standard errors, CI coverage)?

The last stage fits a Hefley-style spatial basis to see whether it fixes what ignoring space breaks.

## The foundation: Q2's `mod2`

- **Data:** `data/abundance.only.natural.trees.txt` (data frame `HTrees2`). There are 48 rows: 24 natural mangrove trees, each counted on two sides, given by `Aspect` (`e` / `s`).
- **Model:**
  ```r
  mod2 <- glmmTMB(Abundance ~ TreePerimeter + Aspect + DistReef + (1 | LocationID),
                  family = nbinom1(), data = HTrees2)
  ```
  NB1 means Var = μ(1 + φ). `DistReef` is in metres.
- **Comparison model:** `mod0` is identical but without `(1 | LocationID)`. It's used instead of the authors' own alternative because that one changes several things at once.
- **`(1 | LocationID)` is not spatial.** It only says that the two rows from the same tree share an effect. It says nothing about neighbouring trees being similar. Spatial structure enters only in stage 3, part 2.

## The stages

Each stage's truth builds on the previous stage's truth.

| Stage | File | Simulated truth | Models fitted | Ramp parameter |
|---|---|---|---|---|
| 1 | `stages/01-q2-real-glmm.qmd` | none (real data) | `mod0`, `mod2` | none |
| 2 | `stages/02-q2-sim-glmm.qmd` | `mod2` with iid site effects a_j ~ N(0, σ²) | `mod0`, `mod2` | σ |
| 3 | `stages/03-q2-sim-gam-spatial-basis.qmd` | Part 1: stage 2 with the linear TreePerimeter term replaced by a hump. Part 2: part 1 plus a multi-scale spatial field (total SD 1) at the 24 locations | Part 1: linear GLMM vs `s(TreePerimeter)`. Part 2: GAM ignoring space, `s(x, y)`, full exponential covariance (`exp()`), 5-eigenvector basis of R(200 m), Gaussian kernels on 6 knots (all NB1 in glmmTMB) | Part 2 only: variance split across 600 / 200 / 60 m layers (none; 100/0/0; 70/30/0; 60/25/15 %), 200 reps each |

### Stage 1: real data (done)

This stage refits `mod0` and `mod2` and compares them side by side. It covers residuals, a residual lineup, a map, Moran's I on the location-mean Pearson residuals (permutation test via `spdep::moran.mc`, 4 nearest neighbours in UTM 60S metres), and fixed effects with 95% CIs.

It saves `results/stage1.rds`. The file is gitignored, so render stage 1 before the other stages. It holds a list of three tibbles:
- `truth`: columns `type` / `parameter` / `value`. Type `beta` has one row per `fixef(mod2)$cond` term, such as `"Aspects"`. Type `sigma` holds σ_LocationID. Type `phi` holds the NB1 φ.
- `design`: 48 rows of `LocationID, Aspect, TreePerimeter, DistReef, Lat, Long` (no response).
- `locations`: 24 rows of `LocationID, Lat, Long, x, y`, with x/y in UTM 60S metres (EPSG:32760).

### Stage 2: no-space reference

This stage simulates from `mod2` on the real design and asks how the stage-1 checks behave when we know nothing is spatial. Any Moran's I flag here is a false positive. It sweeps σ from 0 upward over many replicates and records the false-positive rate, SEs and coverage for both models.

It also checks that the mean observed Moran's I is E[I] = −1/(n−1) = −1/23. To show that this goes to 0 as n grows, it repeats the check on designs with 12, 24, 48 and 96 locations.

### Stage 3: nonlinearity, then space (GAMs and Hefley bases)

**Part 1** is the bridge: a GAM smooth is a set of basis functions with a penalty, which is the same machinery Hefley uses for space. The TreePerimeter line becomes a hump (`sim_nonlinear()`), fit with the linear GLMM and with `s(TreePerimeter)`, using one data set. The authors' Q5 shoaling GAMM (`R code/script_question5_shoaling.R`) is pointed to as motivation and isn't refit.

**Part 2** adds a spatial field at the 24 locations (`sim_spatial()`): the sum of independent exponential layers with ranges 600, 200 and 60 m and a total SD of 1 at every level. Complexity = how the variance is split: low 100/0/0 %, medium 70/30/0 %, high 60/25/15 %. No fitted model is exactly right under this truth: the full covariance assumes a single range. Five NB1 fits in glmmTMB (`fit_spatial()`):
- the GAM ignoring space
- `s(x, y)` (mean structure)
- the full exponential covariance via `exp()` (variance structure)
- the 5 leading eigenvectors of R(200 m) via `homdiag()` (reduced rank)
- Gaussian kernels on 6 grid knots via `homdiag()`

It uses the stage 1/2 checks only: map, lineup, Moran's I, estimates vs truth and coverage. Only `Aspects` and `DistReef` are scored against the truth, because the hump and the centred smooth change what the intercept means. The DistReef-aligned confounding scenario was dropped for time.

## Supporting code (`sim/`)

- `_load.R`: source it from a stage with `source("../sim/_load.R")`. It defines `espm215_root`, `data_dir` (the repo's `data/`) and `results_dir`, and sources the other files.
- `sim_glmm.R` → `sim_nonlinear.R` → `sim_spatial.R`: one simulator per stage, cumulative. Each returns the design with a simulated `Abundance` column and keeps the true effects (a_j, the true curve, the true field) for diagnostics. σ, strength, and variance/range are arguments so the ramps can override them. `sim_spatial.R` also holds the basis builders (`eigen_basis()`, `grid_knots()`, `kernel_basis()`).
- `replicate.R`: the replicate loop. For each ramp value it simulates, fits, and collects estimates, SEs, coverage, variance components, σ̂ on the boundary, and Moran's I (the observed I, not just the p-value). It saves each stage's table to `results/stageN_ramp.rds`.
- `model_compare.R` (done): `compare_models(list("flavor" = mod, ...), data)` returns tidy `$obs`, `$loc` and `$coef` tables. It works for both glmmTMB and mgcv. Each model flavor has a fixed Okabe-Ito colour across all stages: `"No location"`, `"Location RE"`, `"GAM"`, `"GAM + s(x, y)"`, `"Full covariance"`, `"Eigen basis"` and `"Knot basis"`, accessed via `scale_colour_model()` / `scale_fill_model()`.

`notes/derivations.qmd` holds pencil-and-paper work: `mod2` as an equation, a smooth as a penalized basis, Hefley Eq. 7 and the Q2 indicator matrix Z (two rows per location), the eigen basis QΛ^{1/2} and the BLUP (Eq. 15), and FWL with spatial confounding. All sections are empty templates.

## Status (Oct 13, 2026)

- **Done:** stage 1, `model_compare.R`, `_load.R`, and the rendering setup. Stages 1–3 and the notes all rendered without errors on Oct 9.
- **Filled in (Oct 13–14):** stage 2 and stage 3 (stages 3 and 4 merged), with all of `sim_*.R` and `replicate.R`. The "Interpretation" boxes are the user's to fill.
- **Today (Oct 13):** build the talk from the finished stage documents and saved figures. `slides/` holds a template deck that uses the quarto-live extension in `_extensions/`.

## Working rules

- **The statistics are the user's work.** Build scaffolding only: file structure, loaders, plotting and tidying helpers, rendering setup, and TODO outlines. Don't write the simulation, model-fitting or analysis code, and don't interpret results, unless explicitly asked to.
- **Paths:** `here` isn't installed. Quarto runs each chunk from the `.qmd`'s own folder, so stages use `../sim/_load.R` and `file.path(results_dir, ...)`. Don't use absolute paths.
- **Rendering:** the Quarto project is at the repo root (`_quarto.yml`). Its render list is `slides/*.qmd`, `espm215/stages/*.qmd` and `espm215/notes/*.qmd`. Run `quarto render` or `quarto render espm215/stages/01-q2-real-glmm.qmd` from the repo root so `renv` is active. For interactive work, also start R from the repo root.
- **Maps:** these use `ggspatial::annotation_map_tile(type = "osm")`. The first render needs network access; tiles are then cached in `results/basemap/`. Keep the "© OpenStreetMap contributors" caption.
- **gitignored:** `results/*.rds` and `*.RDS`, and the basemap cache. `archive/` holds earlier Q1-based work, kept for reference and not rendered.
- **Known stale comment:** `sim/replicate.R` says spdep isn't installed. It is installed, and stage 1 uses it.
