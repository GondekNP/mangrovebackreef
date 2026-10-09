# Stage 2: simulate from Q2's mod2 on the real design (iid site effects, no space).
# Used by stages/02-q2-sim-glmm.qmd.

# TODO: write sim_glmm().
#   - Inputs: the real design (24 LocationIDs x Aspect e/s, TreePerimeter,
#     DistReef from data/abundance.only.natural.trees.txt) and the truth saved
#     in stage 1 (beta, sigma_LocationID, phi). Let sigma be an argument so the
#     ramp can override it.
#   - Draw fresh a_j ~ N(0, sigma^2) for the 24 locations on every call.
#   - Build eta = X beta + a[location].
#   - Draw NB1 counts (variance mu * (1 + phi)).
#   - Return the design data frame with a simulated Abundance column, and keep
#     the true a_j (e.g. as an attribute) for the diagnostics.
