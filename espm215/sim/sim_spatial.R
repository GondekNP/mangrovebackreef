# Stage 4: stage-3 truth plus a spatial field (cumulative).
# Used by stages/04-q2-sim-spatial-basis.qmd.

# TODO: write a helper that returns the 24 location coordinates in metres
#   (one tree per LocationID; the e and s rows share Lat/Long). Stage 1 saves
#   these to results/; this helper can just read them back.

# TODO: write sim_spatial().
#   - Start from the stage-3 truth (nonlinear term + iid a_j + NB1).
#   - Add a spatial field at the 24 locations with a distance-based covariance.
#     Covariance family, variance and range are your call; give the variance and
#     range arguments for the ramp.
#   - Scenario: a field partly aligned with DistReef.
#   - Keep the true field for the diagnostics.

# TODO: write the Hefley basis builder(s) for the fit, e.g. leading eigenvectors
#   of R(phi), a kernel basis on knots, or s(x, y) treated as a basis.
