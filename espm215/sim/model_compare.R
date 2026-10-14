# A/B(/C/D) model comparison helpers, shared by all stages.
# Plotting and tidying only: no fitting, no interpretation.
#
# Each model "flavor" gets one fixed colour for the whole project, so the same
# model looks the same in every stage's figures (Okabe-Ito, colour-blind safe).
# Usage:
#   cmp <- compare_models(list("No location" = mod0, "Location RE" = mod2), HTrees2)
#   ggplot(cmp$obs, aes(fitted, pearson, colour = flavor)) +
#     geom_point() + facet_wrap(~ flavor) + scale_colour_model()

model_palette <- c(
  "No location"         = "#E69F00",
  "Location RE"         = "#0072B2",
  "GAM"                 = "#009E73",
  "GAM + s(x, y)"       = "#D55E00",
  "Full covariance"     = "#CC79A7",
  "Eigen basis"         = "#56B4E9",
  "Knot basis"          = "#000000"
)
model_levels <- names(model_palette)

scale_colour_model <- function(...) {
  ggplot2::scale_colour_manual(values = model_palette, ...)
}
scale_fill_model <- function(...) {
  ggplot2::scale_fill_manual(values = model_palette, ...)
}

as_flavor <- function(x) factor(x, levels = model_levels)

# One row per observation. Uses only generics, so glmmTMB and mgcv::gam both work.
obs_diag <- function(mod, data, flavor) {
  data |>
    dplyr::mutate(
      fitted  = as.numeric(fitted(mod)),
      eta     = as.numeric(predict(mod, type = "link")),
      pearson = as.numeric(resid(mod, type = "pearson")),
      flavor  = as_flavor(flavor)
    )
}

# One row per LocationID: location, mean Pearson residual, and the random
# intercept if the model has a (1 | LocationID) term (NA otherwise).
loc_diag <- function(mod, data, flavor) {
  out <- obs_diag(mod, data, flavor) |>
    dplyr::group_by(LocationID) |>
    dplyr::summarise(Lat = mean(Lat), Long = mean(Long),
                     mean_pearson = mean(pearson), .groups = "drop")
  out$ranef <- NA_real_
  if (inherits(mod, "glmmTMB") && "LocationID" %in% names(glmmTMB::ranef(mod)$cond)) {
    re <- glmmTMB::ranef(mod)$cond$LocationID
    out$ranef <- re[as.character(out$LocationID), "(Intercept)"]
  }
  out$flavor <- as_flavor(flavor)
  out
}

# Fixed (parametric) effects only: estimate, SE, Wald 95% CI.
coef_diag <- function(mod, flavor) {
  if (inherits(mod, "glmmTMB")) {
    est <- glmmTMB::fixef(mod)$cond
    se  <- sqrt(diag(vcov(mod)$cond))
  } else if (inherits(mod, "gam")) {
    pt  <- summary(mod)$p.table
    est <- pt[, 1]
    se  <- pt[, 2]
  } else {
    est <- coef(mod)
    se  <- sqrt(diag(vcov(mod)))
  }
  data.frame(term = names(est), estimate = unname(est), se = unname(se),
             lwr = unname(est - 1.96 * se), upr = unname(est + 1.96 * se),
             flavor = as_flavor(flavor), row.names = NULL)
}

# Stack the three tables for a named list of models.
compare_models <- function(models, data) {
  stopifnot(!is.null(names(models)), all(names(models) %in% model_levels))
  list(
    obs  = dplyr::bind_rows(Map(obs_diag,  models, list(data), names(models))),
    loc  = dplyr::bind_rows(Map(loc_diag,  models, list(data), names(models))),
    coef = dplyr::bind_rows(Map(coef_diag, models, names(models)))
  )
}


# From the linear part to the counts, one row per observation:
#   eta_fixed  the fixed-effect part X beta (link scale)
#   eta        the full linear predictor (adds the random-effect terms: site
#              intercepts, penalised smooth wiggles, spatial terms)
#   mu         exp(eta), the predicted mean count
#   lo90/hi90, lo50/hi50  NB1 predictive intervals for a count with mean mu
#              (Var = mu * (1 + phi), phi = sigma(mod))
# glmmTMB only (uses re.form = NA for the fixed-effect part).
link_to_response <- function(mod, data, flavor) {
  eta       <- as.numeric(predict(mod, type = "link"))
  eta_fixed <- as.numeric(predict(mod, type = "link", re.form = NA))
  phi <- sigma(mod)
  mu  <- exp(eta)
  q   <- function(p) qnbinom(p, size = mu / phi, mu = mu)
  dplyr::mutate(data, eta_fixed = eta_fixed, eta = eta, mu = mu, phi = phi,
                lo90 = q(0.05), hi90 = q(0.95), lo50 = q(0.25), hi50 = q(0.75),
                inside90 = Abundance >= lo90 & Abundance <= hi90,
                flavor = as_flavor(flavor))
}

# Three panels per model (one row each): the linear part (eta per observation,
# with an arrow from X beta to eta where random-effect terms move it), the link
# (mu = exp(eta)), and the response (observed counts against mu with the NB1
# 50% and 90% predictive bands).
plot_link_to_response <- function(models, data) {
  lr <- dplyr::bind_rows(Map(link_to_response, models, list(data), names(models))) |>
    dplyr::group_by(flavor) |>
    dplyr::mutate(row = rank(eta, ties.method = "first")) |>
    dplyr::ungroup()
  shifted <- dplyr::filter(lr, abs(eta - eta_fixed) > 1e-8)

  band <- lr |>
    dplyr::group_by(flavor) |>
    dplyr::reframe(mu = exp(seq(log(min(mu)), log(max(mu)), length.out = 100)), phi = phi[1]) |>
    dplyr::mutate(lo90 = qnbinom(0.05, size = mu / phi, mu = mu), hi90 = qnbinom(0.95, size = mu / phi, mu = mu),
                  lo50 = qnbinom(0.25, size = mu / phi, mu = mu), hi50 = qnbinom(0.75, size = mu / phi, mu = mu))
  cover <- lr |>
    dplyr::group_by(flavor) |>
    dplyr::summarise(label = sprintf("φ = %.1f\n%d of %d counts inside the 90%% band",
                                     phi[1], sum(inside90), dplyr::n()),
                     x = min(mu), .groups = "drop")

  facet <- ggplot2::facet_wrap(~ flavor, ncol = 1)
  p_lin <- ggplot2::ggplot(lr, ggplot2::aes(x = row, colour = flavor)) +
    ggplot2::geom_segment(data = shifted, ggplot2::aes(xend = row, y = eta_fixed, yend = eta),
                          arrow = ggplot2::arrow(length = ggplot2::unit(0.08, "cm")), alpha = 0.6) +
    ggplot2::geom_point(ggplot2::aes(y = eta_fixed), shape = 1, alpha = 0.6) +
    ggplot2::geom_point(ggplot2::aes(y = eta), size = 1.8) +
    facet + scale_colour_model(guide = "none") +
    ggplot2::labs(title = "1. Linear part (link scale)",
                  subtitle = "open = fixed effects Xβ; filled = η after\nrandom-effect terms (arrows)",
                  x = "Observations, ordered by η", y = "η = log(predicted mean)")
  p_link <- ggplot2::ggplot(lr, ggplot2::aes(x = eta, y = mu, colour = flavor)) +
    ggplot2::stat_function(fun = exp, colour = "grey40", linetype = 2,
                           xlim = range(lr$eta)) +
    ggplot2::geom_point(size = 1.8) +
    facet + scale_colour_model(guide = "none") +
    ggplot2::labs(title = "2. Link: μ = exp(η)", subtitle = "dashed: the exp curve\n ",
                  x = "η (link scale)", y = "μ = predicted mean count")
  p_resp <- ggplot2::ggplot(lr, ggplot2::aes(x = mu)) +
    ggplot2::geom_ribbon(data = band, ggplot2::aes(ymin = lo90, ymax = hi90, fill = flavor), alpha = 0.15) +
    ggplot2::geom_ribbon(data = band, ggplot2::aes(ymin = lo50, ymax = hi50, fill = flavor), alpha = 0.3) +
    ggplot2::geom_line(data = band, ggplot2::aes(y = mu), linetype = 2, colour = "grey40") +
    ggplot2::geom_point(ggplot2::aes(y = Abundance, colour = flavor, shape = inside90), size = 1.8) +
    ggplot2::geom_label(data = cover, ggplot2::aes(x = x, y = Inf, label = label), hjust = 0, vjust = 1.1,
                        size = 2.8, inherit.aes = FALSE) +
    facet + scale_colour_model(guide = "none") + scale_fill_model(guide = "none") +
    ggplot2::scale_shape_manual(values = c(`TRUE` = 16, `FALSE` = 4), guide = "none") +
    ggplot2::scale_x_log10() +
    ggplot2::scale_y_continuous(trans = scales::pseudo_log_trans(sigma = 1), breaks = c(0, 3, 10, 30, 100, 300)) +
    ggplot2::labs(title = "3. Response: counts ~ NB1(μ, φ)",
                  subtitle = "bands: 50% and 90% of NB1 counts with mean μ;\ndashed: count = μ; points: observed (× = outside 90%)",
                  x = "μ = predicted mean count (log scale)", y = "Observed count (log-ish scale)")
  patchwork::wrap_plots(p_lin, p_link, p_resp, nrow = 1)
}
