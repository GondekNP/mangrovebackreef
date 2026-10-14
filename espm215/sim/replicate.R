# Shared replicate machinery for stages 2-4.

# k-nearest-neighbour Moran weights from a locations table with x, y in metres.
# Rows follow the order of `locations`, so pass it sorted by LocationID.
moran_weights <- function(locations, k = 4) {
  xy <- as.matrix(locations[order(locations$LocationID), c("x", "y")])
  spdep::nb2listw(spdep::knn2nb(spdep::knearneigh(xy, k = k)), style = "W")
}

# Mean Pearson residual per LocationID, sorted by LocationID (matches moran_weights()).
location_residuals <- function(mod, data) {
  r <- tapply(resid(mod, type = "pearson"), data$LocationID, mean)
  data.frame(LocationID = as.numeric(names(r)), mean_pearson = as.numeric(r))
}

# Each tree's two Pearson residuals side by side: one row per LocationID with
# r_e (east count) and r_s (south count).
partner_residuals <- function(mod, data) {
  d <- data.frame(LocationID = data$LocationID, Aspect = as.character(data$Aspect),
                  r = as.numeric(resid(mod, type = "pearson")))
  merge(setNames(d[d$Aspect == "e", c("LocationID", "r")], c("LocationID", "r_e")),
        setNames(d[d$Aspect == "s", c("LocationID", "r")], c("LocationID", "r_s")),
        by = "LocationID")
}

# Partner correlation: cor(r_e, r_s) across trees, against nsim shuffles of which
# south residual is paired with which east residual. One-sided p (are partners
# more alike than chance?), counted the same way as spdep::moran.mc().
partner_test <- function(pairs, nsim = 999) {
  obs  <- cor(pairs$r_e, pairs$r_s)
  sims <- replicate(nsim, cor(pairs$r_e, sample(pairs$r_s)))
  list(r = obs, sims = sims, p = (sum(sims >= obs) + 1) / (nsim + 1))
}

# Tidy tables for plotting the partner check for a named list of models:
#   pairs  one row per flavor x LocationID (r_e, r_s)
#   perm   one row per flavor x shuffle, plus the real value (real = TRUE) and p
partner_check <- function(models, data, nsim = 999) {
  pairs <- do.call(rbind, Map(function(mod, flavor)
    cbind(flavor = as_flavor(flavor), partner_residuals(mod, data)), models, names(models)))
  perm <- do.call(rbind, Map(function(mod, flavor) {
    pt <- partner_test(partner_residuals(mod, data), nsim)
    data.frame(flavor = as_flavor(flavor), r = c(pt$sims, pt$r),
               real = c(rep(FALSE, nsim), TRUE), p = pt$p)
  }, models, names(models)))
  list(pairs = dplyr::as_tibble(pairs), perm = dplyr::as_tibble(perm))
}

# The stage-1 pair, refit to a (simulated) data set.
fit_stage2 <- function(data) {
  suppressWarnings(list(
    "No location" = glmmTMB::glmmTMB(Abundance ~ TreePerimeter + Aspect + DistReef,
                                     family = glmmTMB::nbinom1(), data = data),
    "Location RE" = glmmTMB::glmmTMB(Abundance ~ TreePerimeter + Aspect + DistReef + (1 | LocationID),
                                     family = glmmTMB::nbinom1(), data = data)
  ))
}

# Everything recorded from one replicate, as two tidy tables:
#   coef    one row per flavor x term: estimate, SE, 95% CI, true value, covered
#   checks  one row per flavor: Moran's I and permutation p on the location-mean
#           Pearson residuals, the partner correlation (east vs south residual at the
#           same tree) and its permutation p, sigma-hat (Location RE only), phi-hat,
#           Hessian positive-definite
summarise_replicate <- function(models, data, truth, weights, nsim = 499) {
  betas <- subset(truth, type == "beta")
  coef <- do.call(rbind, Map(coef_diag, models, names(models)))
  coef$truth   <- betas$value[match(coef$term, betas$parameter)]
  coef$covered <- coef$lwr <= coef$truth & coef$truth <= coef$upr

  checks <- do.call(rbind, Map(function(mod, flavor) {
    mc <- spdep::moran.mc(location_residuals(mod, data)$mean_pearson, weights, nsim = nsim)
    pt <- partner_test(partner_residuals(mod, data), nsim = nsim)
    data.frame(
      flavor    = as_flavor(flavor),
      moran_I   = unname(mc$statistic),
      moran_p   = mc$p.value,
      partner_r = pt$r,
      partner_p = pt$p,
      sigma_hat = if (length(glmmTMB::ranef(mod)$cond)) attr(glmmTMB::VarCorr(mod)$cond$LocationID, "stddev")[[1]] else NA_real_,
      phi_hat   = sigma(mod),                               # NB1 dispersion: Var = mu * (1 + phi)
      pd_hessian = isTRUE(mod$sdr$pdHess)
    )
  }, models, names(models)))

  list(coef = coef, checks = checks)
}

# Run `one_rep(setting)` for every row of `grid` (one row per replicate), in
# parallel, and stack each returned table with the grid columns attached.
# `one_rep` returns a named list of data frames (e.g. list(coef = , checks = )).
# Reproducible for a given seed and number of cores.
run_replicates <- function(grid, one_rep, seed = 215, cores = parallel::detectCores()) {
  RNGkind("L'Ecuyer-CMRG")
  set.seed(seed)
  res <- parallel::mclapply(seq_len(nrow(grid)), function(i) {
    out <- one_rep(grid[i, , drop = FALSE])
    lapply(out, function(tab) cbind(grid[rep(i, nrow(tab)), , drop = FALSE], tab, row.names = NULL))
  }, mc.cores = cores, mc.set.seed = TRUE)
  failed <- vapply(res, inherits, logical(1), "try-error")
  if (any(failed)) warning(sum(failed), " replicate(s) failed and were dropped")
  res <- res[!failed]
  setNames(lapply(names(res[[1]]), function(nm) dplyr::as_tibble(do.call(rbind, lapply(res, `[[`, nm)))),
           names(res[[1]]))
}

# Stage 3, part 1: the linear GLMM (mod2's formula) vs the same with a smooth
# of TreePerimeter, both NB1 in glmmTMB.
fit_nonlinear <- function(data) {
  suppressWarnings(list(
    "Location RE" = glmmTMB::glmmTMB(Abundance ~ TreePerimeter + Aspect + DistReef + (1 | LocationID),
                                     family = glmmTMB::nbinom1(), data = data),
    "GAM"         = glmmTMB::glmmTMB(Abundance ~ s(TreePerimeter) + Aspect + DistReef + (1 | LocationID),
                                     family = glmmTMB::nbinom1(), data = data)
  ))
}

# The per-location pieces the stage-3 spatial models need, built once:
#   x_km, y_km   centred coordinates in km (for s(x, y) and the exp() covariance)
#   eigen        eigen_basis() at a fixed range;  kernel  kernel_basis() on grid knots
spatial_setup <- function(locations, eigen_range = 200, m = 5, nx = 3, ny = 2) {
  knots <- grid_knots(locations, nx, ny)
  bandwidth <- diff(sort(unique(knots$x)))[1]
  locs <- locations[order(locations$LocationID), ]
  list(
    coords = data.frame(LocationID = locs$LocationID,
                        x_km = (locs$x - mean(locs$x)) / 1000,
                        y_km = (locs$y - mean(locs$y)) / 1000),
    eigen  = eigen_basis(locations, eigen_range, m),
    kernel = kernel_basis(locations, knots, bandwidth),
    knots  = knots, bandwidth = bandwidth, eigen_range = eigen_range, m = m
  )
}

# Add the coordinates and both bases to a (simulated) data set.
add_spatial <- function(data, setup, locations) {
  data <- add_basis(add_basis(data, setup$eigen, locations), setup$kernel, locations)
  j <- match(data$LocationID, setup$coords$LocationID)
  data$x_km <- setup$coords$x_km[j]
  data$y_km <- setup$coords$y_km[j]
  data$pos  <- glmmTMB::numFactor(data$x_km, data$y_km)
  data$grp  <- factor(1)
  data
}

# Stage 3, part 2: five NB1 fits, from no space to Hefley's bases.
# `data` must have been through add_spatial().
fit_spatial <- function(data) {
  base <- Abundance ~ s(TreePerimeter) + Aspect + DistReef + (1 | LocationID)
  e <- grep("^e[0-9]+$", names(data), value = TRUE)
  k <- grep("^k[0-9]+$", names(data), value = TRUE)
  forms <- list(
    "GAM"             = base,
    "GAM + s(x, y)"   = update(base, . ~ . + s(x_km, y_km, k = 10)),
    "Full covariance" = update(base, . ~ . + exp(pos + 0 | grp)),
    "Eigen basis"     = update(base, as.formula(paste(". ~ . + homdiag(0 +", paste(e, collapse = " + "), "| grp)"))),
    "Knot basis"      = update(base, as.formula(paste(". ~ . + homdiag(0 +", paste(k, collapse = " + "), "| grp)")))
  )
  suppressWarnings(lapply(forms, glmmTMB::glmmTMB, family = glmmTMB::nbinom1(), data = data))
}
