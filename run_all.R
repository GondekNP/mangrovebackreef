# Runs every analysis script and saves its console output and figures to output/.
# Run from the repository root so .Rprofile activates the renv library:
#   Rscript run_all.R
# Each script runs in a fresh R process, as the scripts clear the workspace and
# load packages (plyr, dplyr, tidyverse) that mask each other.

scripts <- list.files("R code", pattern = "^script_question.*\\.R$", full.names = TRUE)
dir.create("output", showWarnings = FALSE)

for (script in scripts) {
  name <- tools::file_path_sans_ext(basename(script))
  log  <- file.path("output", paste0(name, ".txt"))
  pdf  <- file.path("output", paste0(name, ".pdf"))
  message("Running ", script, " -> ", log, ", ", pdf)
  expr <- sprintf(
    "set.seed(1); pdf(%s); source(%s, echo = TRUE, max.deparse.length = Inf); invisible(dev.off())",
    deparse(pdf), deparse(script)
  )
  status <- system2(file.path(R.home("bin"), "Rscript"), c("-e", shQuote(expr)),
                    stdout = log, stderr = log)
  if (status != 0) stop(script, " failed (exit ", status, "); see ", log)
}

writeLines(capture.output(sessionInfo()), file.path("output", "sessionInfo.txt"))
message("Done.")
