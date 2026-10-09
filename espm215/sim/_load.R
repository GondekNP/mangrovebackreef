# Load the ESPM 215 simulation code.
#
# Usage, from any .qmd in espm215/homework/ or espm215/decks/:
#   source("../sim/_load.R")
#
# `here` is not installed, so paths are relative. Quarto runs each R chunk with
# the working directory set to the .qmd's own folder. homework/ and decks/ are
# both one level below espm215/, so the espm215 root is ".." from either. The
# check below also lets this file be sourced from espm215/ itself (e.g. at the
# console with setwd("espm215")).
espm215_root <- if (file.exists("sim/_load.R")) "." else ".."
if (!file.exists(file.path(espm215_root, "sim", "_load.R"))) {
  stop("Source sim/_load.R from espm215/, espm215/homework/ or espm215/decks/.")
}

data_dir    <- file.path(espm215_root, "..", "data")  # repo's data/ (read-only)
results_dir <- file.path(espm215_root, "results")     # .rds outputs (gitignored)

source(file.path(espm215_root, "sim", "stage1.R"))
source(file.path(espm215_root, "sim", "toy1d.R"))
source(file.path(espm215_root, "sim", "stage2.R"))
source(file.path(espm215_root, "sim", "replicate.R"))
