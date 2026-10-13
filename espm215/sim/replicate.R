# Shared replicate machinery for stages 2-4.

# TODO: write a replicate loop: for each value of a ramp parameter, simulate
#   (sim_glmm / sim_nonlinear / sim_spatial), fit the stage's models, and
#   collect estimates, SEs, CI coverage and the variance components.

# TODO: write the diagnostics collected per replicate:
#   - sigma-hat on the boundary (stage 2)
#   - Moran's I on the 24 random intercepts and on residuals (stages 2 and 4).
#     Keep the observed I per replicate (not just the p-value), so stage 2 can
#     check that its mean under no spatial truth is -1/(n-1).
#     Needs spdep or ape; neither is installed (see README).

# TODO: save each stage's replicate table to results/ as .rds
#   (e.g. file.path(results_dir, "stage2_ramp.rds")).
