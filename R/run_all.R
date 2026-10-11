# R/run_all.R
# ==============================================================================
# Master Replication Script
#
# Regenerates EVERY figure and table in the manuscript from the raw Stata data
# in one command. Run from the project root:
#
#   Rscript R/run_all.R        (or source("R/run_all.R") in an R session)
#
# Pipeline:
#   01_dataproc.R           data cleaning + sample construction (no outputs)
#   02_samples.R            all sample sizes / shares / design parameters
#   03_models_did.R         DiD models (3.1 baseline, pooled, 4-tier,
#                           stepwise, 24-cell quadrants; primary + full)
#   04_models_behavioral.R  multinomial Stay/Conform/React models + AMEs
#   05_ipw_balance.R        covariate balance (love plot data, SMDs, arm tests)
#   06_models_appendix.R    MDE analysis, descriptives, class robustness
#   07_make_figures.R       all 8 manuscript figures (png + pdf)
#   08_make_tables.R        all 7 LaTeX results tables
#
# Each numbered script may also be run individually, in order.
# ==============================================================================

t0 <- Sys.time()

steps <- c(
  "R/02_samples.R",
  "R/03_models_did.R",
  "R/04_models_behavioral.R",
  "R/05_ipw_balance.R",
  "R/06_models_appendix.R",
  "R/07_make_figures.R",
  "R/08_make_tables.R"
)

for (s in steps) {
  cat("\n>>> source(", s, ")\n", sep = "")
  source(s, echo = FALSE)
}

cat(sprintf("\nFull pipeline completed in %.1f minutes.\n",
            as.numeric(difftime(Sys.time(), t0, units = "mins"))))
