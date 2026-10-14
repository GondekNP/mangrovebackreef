# Stage 3, part 1: the stage-2 truth with the linear TreePerimeter term made nonlinear.
# Used by stages/03-q2-sim-gam-spatial-basis.qmd.

# The true TreePerimeter effect (log scale): a blend of the stage-1 straight line
# (strength = 0) and a hump peaking at 15 m that has the same rise as the line
# over 0-30 m (strength = 1). Intermediate-sized trees are best under the hump.
tree_effect <- function(tree_perimeter, beta_tp, strength = 1) {
  line <- beta_tp * tree_perimeter
  hump <- beta_tp * 30 * (1 - ((tree_perimeter - 15) / 15)^2)
  (1 - strength) * line + strength * hump
}

# The linear predictor without the location intercepts:
#   eta = intercept + f(TreePerimeter) + Aspect + DistReef
eta_nonlinear <- function(design, truth, strength = 1) {
  beta <- with(subset(truth, type == "beta"), setNames(value, parameter))
  X    <- model.matrix(~ Aspect + DistReef, data = design)
  drop(X %*% beta[colnames(X)]) + tree_effect(design$TreePerimeter, beta[["TreePerimeter"]], strength)
}

# One simulated data set: as sim_glmm(), with f(TreePerimeter) in place of the line.
#   eta = intercept + f(TreePerimeter) + Aspect + DistReef + a[LocationID],  a_j ~ N(0, sigma^2)
#   Abundance ~ NB1(mu = exp(eta), Var = mu * (1 + phi))
# The true curve is kept as attr(, "f") (TreePerimeter, f) and the a_j as attr(, "a").
sim_nonlinear <- function(design, truth, strength = 1, sigma = NULL) {
  phi <- subset(truth, type == "phi")$value
  if (is.null(sigma)) sigma <- subset(truth, type == "sigma")$value
  beta_tp <- subset(truth, type == "beta" & parameter == "TreePerimeter")$value

  ids <- sort(unique(design$LocationID))
  a   <- rnorm(length(ids), 0, sigma)
  mu  <- exp(eta_nonlinear(design, truth, strength) + a[match(design$LocationID, ids)])

  out <- design
  out$Abundance <- rnbinom(nrow(design), size = mu / phi, mu = mu)
  attr(out, "a") <- data.frame(LocationID = ids, a = a)
  grid <- seq(min(design$TreePerimeter), max(design$TreePerimeter), length.out = 100)
  attr(out, "f") <- data.frame(TreePerimeter = grid, f = tree_effect(grid, beta_tp, strength))
  out
}
