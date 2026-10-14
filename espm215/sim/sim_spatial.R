# Stage 3, part 2: the part-1 truth plus a spatial field at the 24 locations,
# and the Hefley basis builders used to fit it.
# Used by stages/03-q2-sim-gam-spatial-basis.qmd.
#
# Location coordinates in metres (UTM 60S) are saved by stage 1:
#   stage1$locations  24 rows: LocationID, Lat, Long, x, y

# Exponential correlation between the locations: R_ij = exp(-d_ij / range), d in metres.
exp_correlation <- function(locations, range) {
  xy <- as.matrix(locations[order(locations$LocationID), c("x", "y")])
  exp(-as.matrix(dist(xy)) / range)
}

# Independent unit-variance fields at the locations, one column per range:
#   column r ~ N(0, R(range_r)). Rows sorted by LocationID.
field_layers <- function(locations, ranges = c(600, 200, 60)) {
  L <- sapply(ranges, function(r)
    drop(t(chol(exp_correlation(locations, r))) %*% rnorm(nrow(locations))))
  colnames(L) <- paste0("w_", ranges)
  L
}

# The same layers drawn jointly on a regular grid over the study area and at the
# locations, for drawing the field as a continuous surface. Returns
#   grid    data.frame of x, y (metres) and one column per layer
#   layers  matrix of the layers at the locations (rows sorted by LocationID),
#           which can be passed to sim_spatial(layers = ) so the simulated counts
#           use exactly the values shown on the surface
field_surface <- function(locations, ranges = c(600, 200, 60), margin = 100, spacing = 15) {
  loc  <- locations[order(locations$LocationID), c("x", "y")]
  grid <- expand.grid(x = seq(min(loc$x) - margin, max(loc$x) + margin, by = spacing),
                      y = seq(min(loc$y) - margin, max(loc$y) + margin, by = spacing))
  pts  <- rbind(as.matrix(loc), as.matrix(grid))
  D    <- as.matrix(dist(pts))
  z    <- sapply(ranges, function(r) {
    R <- exp(-D / r)
    diag(R) <- diag(R) + 1e-8                 # numerical jitter for the Cholesky
    drop(t(chol(R)) %*% rnorm(nrow(pts)))
  })
  colnames(z) <- paste0("w_", ranges)
  n <- nrow(loc)
  list(grid = cbind(grid, z[-(1:n), , drop = FALSE]), layers = z[1:n, , drop = FALSE])
}

# One simulated data set: the part-1 truth plus a multi-scale spatial field w.
#   eta = intercept + f(TreePerimeter) + Aspect + DistReef + a[LocationID] + w[LocationID]
#   a_j ~ N(0, sigma^2) (iid, as in stage 2)
#   w   = sd_field * sum_r sqrt(share_r) * layer_r,   layer_r ~ N(0, R(range_r)) independent
# so Var(w) = sd_field^2 at every location whatever the split, and
#   Cov(w) = sd_field^2 * sum_r share_r * R(range_r).
# `shares` are variance shares, one per range, summing to 1 (all 0 = no field).
# Pass `layers` (from field_layers()) to reuse the same layer draws across splits.
# The true w and each layer's contribution are kept as attr(, "field").
sim_spatial <- function(design, truth, locations, shares, ranges = c(600, 200, 60),
                        sd_field = 1, layers = NULL, sigma = NULL, strength = 1) {
  phi <- subset(truth, type == "phi")$value
  if (is.null(sigma)) sigma <- subset(truth, type == "sigma")$value
  if (is.null(layers)) layers <- field_layers(locations, ranges)

  ids <- sort(unique(design$LocationID))
  a   <- rnorm(length(ids), 0, sigma)
  parts <- sd_field * sweep(layers, 2, sqrt(shares), "*")
  w   <- rowSums(parts)
  j   <- match(design$LocationID, ids)
  mu  <- exp(eta_nonlinear(design, truth, strength) + a[j] + w[j])

  out <- design
  out$Abundance <- rnbinom(nrow(design), size = mu / phi, mu = mu)
  attr(out, "a")     <- data.frame(LocationID = ids, a = a)
  attr(out, "field") <- data.frame(LocationID = ids, w = w, parts)
  out
}

# Hefley's reduced-rank basis: the m leading eigenvectors of R(range), scaled by
# the square roots of their eigenvalues (Z = Q_m Lambda_m^(1/2)), so that with
# alpha ~ N(0, s^2 I), Z alpha has covariance s^2 Z Z' ~ s^2 R. One row per LocationID.
eigen_basis <- function(locations, range, m) {
  e <- eigen(exp_correlation(locations, range), symmetric = TRUE)
  Z <- e$vectors[, 1:m, drop = FALSE] %*% diag(sqrt(e$values[1:m]), m)
  colnames(Z) <- paste0("e", 1:m)
  Z
}

# Knots on a regular nx x ny grid over the locations' bounding box (x, y in metres).
grid_knots <- function(locations, nx = 3, ny = 2) {
  gx <- seq(min(locations$x), max(locations$x), length.out = nx + 2)[-c(1, nx + 2)]
  gy <- seq(min(locations$y), max(locations$y), length.out = ny + 2)[-c(1, ny + 2)]
  expand.grid(x = gx, y = gy)
}

# Kernel basis: a Gaussian bump centred on each knot, Z_jk = exp(-d_jk^2 / (2 h^2)).
# Each column is ~0 a few bandwidths away from its knot (local support).
# One row per LocationID.
kernel_basis <- function(locations, knots, bandwidth) {
  loc <- locations[order(locations$LocationID), c("x", "y")]
  d2  <- outer(loc$x, knots$x, "-")^2 + outer(loc$y, knots$y, "-")^2
  Z   <- exp(-d2 / (2 * bandwidth^2))
  colnames(Z) <- paste0("k", seq_len(nrow(knots)))
  Z
}

# Attach a per-location basis (rows sorted by LocationID) to the observation rows.
add_basis <- function(data, Z, locations) {
  ids <- sort(locations$LocationID)
  cbind(data, Z[match(data$LocationID, ids), , drop = FALSE])
}
