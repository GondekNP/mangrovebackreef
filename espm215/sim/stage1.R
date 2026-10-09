# Stage 1: simulate from the authors' model on the real design (no space).
# Used by homework/01-fri-stage1.qmd.

# TODO: write sim_stage1().
#   - Inputs: the real design (24 LocationIDs, Treatment, DistReef from
#     data/abundance.tree.and.controls.txt) and the parameters saved from mod1
#     in results/ (beta, sigma_LocationID, phi).
#   - Draw a_j ~ N(0, sigma^2) for each of the 24 locations.
#   - Build eta = X beta + a[location].
#   - Draw NB1 counts (variance mu * (1 + phi)).
#   - Return the design data frame with a simulated Abundance column.

# TODO: (optional) a helper that refits mod1's formula to one simulated data set
#   and returns the estimates you want to track.
