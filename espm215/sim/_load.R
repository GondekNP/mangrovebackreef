# Load the ESPM 215 simulation code.
#
# Usage, from any .qmd in espm215/stages/:
#   source("../sim/_load.R")
#
# `here` is not installed, so paths are relative. Quarto runs each R chunk with
# the working directory set to the .qmd's own folder. stages/ is one level below
# espm215/, so the espm215 root is "..". The check below also lets this file be
# sourced from espm215/ itself (e.g. at the console with setwd("espm215")).
espm215_root <- if (file.exists("sim/_load.R")) "." else ".."
if (!file.exists(file.path(espm215_root, "sim", "_load.R"))) {
  stop("Source sim/_load.R from espm215/ or espm215/stages/.")
}

data_dir    <- file.path(espm215_root, "..", "data")  # repo's data/ (read-only)
results_dir <- file.path(espm215_root, "results")     # .rds outputs (gitignored)

source(file.path(espm215_root, "sim", "sim_glmm.R"))
source(file.path(espm215_root, "sim", "sim_nonlinear.R"))
source(file.path(espm215_root, "sim", "sim_spatial.R"))
source(file.path(espm215_root, "sim", "replicate.R"))
source(file.path(espm215_root, "sim", "model_compare.R"))
