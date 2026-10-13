# Stage 4: stage-3 truth plus a spatial field (cumulative).
# Used by stages/04-q2-sim-spatial-basis.qmd.

# Location coordinates in metres (UTM 60S) are saved by stage 1:
#   stage1$locations  24 rows: LocationID, Lat, Long, x, y

# TODO: write sim_spatial().
#   - Start from the stage-3 truth (nonlinear term + iid a_j + NB1).
#   - Add a spatial field at the 24 locations with a distance-based covariance.
#     Covariance family, variance and range are your call; give the variance and
#     range arguments for the ramp.
#   - Scenario: a field partly aligned with DistReef.
#   - Keep the true field for the diagnostics.

# TODO: write the Hefley basis builder(s) for the fit, e.g. leading eigenvectors
#   of R(phi), a kernel basis on knots, or s(x, y) treated as a basis.
