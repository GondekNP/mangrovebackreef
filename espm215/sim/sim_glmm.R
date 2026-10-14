# Stage 2: simulate from Q2's mod2 on the real design (iid site effects, no space).
# Used by stages/02-q2-sim-glmm.qmd.
#
# Inputs come from results/stage1.rds (saved by stage 1):
#   stage1$design     48 rows: LocationID, Aspect, TreePerimeter, DistReef, Lat, Long
#   stage1$truth      tidy (type, parameter, value): "beta" rows named as in
#                     fixef(mod2)$cond, "sigma" (LocationID), "phi" (nbinom1)
#   stage1$locations  24 rows: LocationID, Lat, Long, x, y (UTM 60S metres)

# One simulated data set: the design plus a simulated Abundance column.
#   eta = X beta + a[LocationID],  a_j ~ N(0, sigma^2) fresh on every call
#   Abundance ~ NB1(mu = exp(eta), Var = mu * (1 + phi))
# NB1 via rnbinom(): Var = mu + mu^2 / size, so size = mu / phi gives mu * (1 + phi).
# sigma overrides the stage-1 value (for the ramp). The true a_j are kept as
# attr(, "a") (one row per LocationID).
sim_glmm <- function(design, truth, sigma = NULL) {
  beta <- with(subset(truth, type == "beta"), setNames(value, parameter))
  phi  <- subset(truth, type == "phi")$value
  if (is.null(sigma)) sigma <- subset(truth, type == "sigma")$value

  X   <- model.matrix(~ TreePerimeter + Aspect + DistReef, data = design)[, names(beta)]
  ids <- sort(unique(design$LocationID))
  a   <- rnorm(length(ids), 0, sigma)
  mu  <- exp(drop(X %*% beta) + a[match(design$LocationID, ids)])

  out <- design
  out$Abundance <- rnbinom(nrow(design), size = mu / phi, mu = mu)
  attr(out, "a") <- data.frame(LocationID = ids, a = a)
  out
}
