#!/usr/bin/env bash
# Runs every analysis script and saves its console output and figures to output/.
# Each script runs in a fresh R process, as the scripts clear the workspace and
# load packages (plyr, dplyr, tidyverse) that mask each other.
set -euo pipefail

# Run from the repository root so .Rprofile activates the renv library.
cd "$(dirname "$0")"
mkdir -p output

for script in "R code"/script_question*.R; do
  name=$(basename "$script" .R)
  echo "Running $script -> output/$name.{txt,pdf}"
  if ! Rscript -e "set.seed(1); pdf('output/$name.pdf'); source('$script', echo = TRUE, max.deparse.length = Inf); invisible(dev.off())" \
       > "output/$name.txt" 2>&1; then
    echo "$script failed; see output/$name.txt" >&2
    exit 1
  fi
done

Rscript -e 'writeLines(capture.output(sessionInfo()), "output/sessionInfo.txt")'
echo "Done."
