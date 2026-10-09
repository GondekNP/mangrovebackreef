# Stage 2: replace the iid location intercepts with a spatial field.
# Used by homework/03-sun-stage2.qmd.

# TODO: write a helper that builds location coordinates in metres
#   (mean of the tree and control plot per LocationID).

# TODO: write sim_stage2().
#   - Spatial field with exponential covariance (phi = 250 m, small nugget)
#     in place of the iid a_j.
#   - Scenario A: field independent of DistReef.
#   - Scenario B: field partly aligned with DistReef.

# TODO: write fit helpers for the three models:
#   - the authors' iid model (glmmTMB, 1 | LocationID)
#   - glmmTMB with exp(pos + 0 | group)
#   - mgcv: s(x, y, k = 10) + s(LocationID, bs = "re"), family nb() (NB2!)
#   - stretch: DIY basis from the leading eigenvectors of R(phi)
