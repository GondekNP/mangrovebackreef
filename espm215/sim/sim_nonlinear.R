# Stage 3: stage-2 truth plus a nonlinear covariate effect (needs a GAM).
# Used by stages/03-q2-sim-nonlinear-gam.qmd.

# TODO: write sim_nonlinear().
#   - Start from the same pieces as sim_glmm() (beta, fresh a_j, NB1).
#   - Replace the linear term for one covariate with a nonlinear function.
#     Which covariate and what shape are your call (see the Q5 motivation in
#     stage 3: the authors used s(TreePerimeter) and a cyclic s(DistReef)).
#   - Give it a strength argument for the ramp (0 = back to the stage-2 truth).
#   - Keep the true curve so the diagnostics can plot fitted vs truth.
