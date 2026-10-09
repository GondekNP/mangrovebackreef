# Replicate stage 2 and test the authors' bubble-plot diagnostic.
# Used by homework/04-mon-replicates.qmd.

# TODO: write a loop over 200-500 replicates per scenario that calls
#   sim_stage2() and the fit helpers, and collects Treatment and DistReef
#   estimates, SEs and CI coverage for each model.

# TODO: save each scenario's table to results/ as .rds
#   (e.g. file.path(results_dir, "stage2_scenarioA.rds")).

# TODO: write the Moran's I check on the 24 iid random intercepts and record
#   the detection rate. Needs spdep or ape; neither is installed (see README).
