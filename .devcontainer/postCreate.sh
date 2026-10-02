#!/usr/bin/env bash
set -e

# RStudio Server refuses to launch sessions for uid < 1000 by default. We run
# as root (uid 0) in this devcontainer, so without this override every login
# fails with "rsession startup failed ... lower than the minimum user id" and
# the browser just shows "JSONRPC error 1 (Unable to connect to service)".
grep -qxF "auth-minimum-user-id=0" /etc/rstudio/rserver.conf || \
  echo "auth-minimum-user-id=0" >> /etc/rstudio/rserver.conf

Rscript -e 'renv::restore(prompt = FALSE)'
