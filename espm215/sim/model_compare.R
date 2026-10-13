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
  "GAM + spatial basis" = "#D55E00"
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

