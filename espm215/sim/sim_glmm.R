# Stage 2: simulate from Q2's mod2 on the real design (iid site effects, no space).
# Used by stages/02-q2-sim-glmm.qmd.

# TODO: write sim_glmm().
#   - Inputs: stage1 <- readRDS(file.path(results_dir, "stage1.rds")), saved by
#     stage 1:
#       stage1$design  48 rows: LocationID, Aspect, TreePerimeter, DistReef, Lat, Long
#       stage1$truth   tidy (type, parameter, value): type "beta" (one row per
#                      fixef term, names as in fixef(mod2)$cond, e.g. "Aspects"),
#                      "sigma" (LocationID) and "phi" (nbinom1)
#     Let sigma be an argument so the ramp can override it.
#   - Draw fresh a_j ~ N(0, sigma^2) for the 24 locations on every call.
#   - Build eta = X beta + a[location].
#   - Draw NB1 counts (variance mu * (1 + phi)).
#   - Return the design data frame with a simulated Abundance column, and keep
#     the true a_j (e.g. as an attribute) for the diagnostics. Keeping the design
#     columns (incl. LocationID, Lat, Long) means the result goes straight into
#     compare_models() and the stage-1 lineup / Moran's I code.
