# R/04_models_behavioral.R
# ==============================================================================
# Discrete Behavioral Choice Models (Step 04)
#
# Multinomial logistic models of Stay / Conform / React by status-consistency
# quadrant, IPW-weighted, with average marginal effects (AMEs) and predicted
# probabilities. Produces the results behind:
#   - Figure 5 (main text, primary sample)
#   - Appendix Figure A.4 (sensitivity, excluding Taste-Only arms, N = 1,649)
# Saves tidy frames to tables/model_results_behavioral.rds.
# ==============================================================================

suppressPackageStartupMessages({
  library(dplyr)
  library(nnet)
  library(WeightIt)
  library(marginaleffects)
})

source("R/01_dataproc.R")

cat("\n================ STEP 04: BEHAVIORAL MODELS ================\n")

# assign_behavior is defined in Step 02 and stored in tables/sample_stats.rds
if (!file.exists("tables/sample_stats.rds")) {
  stop("Run R/02_samples.R first (tables/sample_stats.rds not found).")
}
stats02 <- readRDS("tables/sample_stats.rds")
assign_behavior <- stats02$assign_behavior

samples <- build_samples()
pri <- samples$wide_cc_primary
fw  <- samples$wide_cc_full

ipw_covars <- "age + female + factor(raceeth) + parented"

quad_levels <- c("Working, No College", "Working, College",
                 "Middle, No College", "Middle, College")

prep_behavior_data <- function(df, weights) {
  df$.ipw_quad <- weights
  assign_behavior(df) %>%
    filter(behavior %in% c("Stay", "Conform", "React")) %>%
    mutate(
      behavior = factor(behavior, levels = c("Stay", "Conform", "React")),
      objsubjclass_factor = relevel(factor(objsubjclass_factor), ref = "Working, No College")
    )
}

fit_behavioral <- function(df) {
  mod <- multinom(behavior ~ objsubjclass_factor, data = df,
                  weights = .ipw_quad, trace = FALSE)
  mfx <- as.data.frame(avg_comparisons(mod, variables = "objsubjclass_factor", type = "probs"))
  preds <- as.data.frame(predictions(mod, by = c("objsubjclass_factor", "group"), type = "probs"))
  list(mod = mod, mfx = mfx, preds = preds, n = nrow(df))
}

# Primary sample (N = 1,949 after excluding 32 baseline shifters)
W_pri <- WeightIt::weightit(as.formula(paste("objsubjclass_factor ~", ipw_covars)),
                            data = pri, method = "ps", estimand = "ATE")
beh_primary <- fit_behavioral(prep_behavior_data(pri, W_pri$weights))

# Sensitivity: excluding Taste-Only arms (N = 1,649)
beh_sens_data <- prep_behavior_data(pri, W_pri$weights) %>%
  filter(!cond2_factor %in% c("Taste Only/Like", "Taste Only/Dislike"))
beh_sens <- fit_behavioral(beh_sens_data)

# Full sample (Appendix G robustness)
W_fw <- WeightIt::weightit(as.formula(paste("objsubjclass_factor ~", ipw_covars)),
                          data = fw, method = "ps", estimand = "ATE")
beh_full <- fit_behavioral(prep_behavior_data(fw, W_fw$weights))

saveRDS(
  list(beh_primary = beh_primary, beh_sens = beh_sens, beh_full = beh_full),
  "tables/model_results_behavioral.rds"
)

# Report key AMEs for verification against the manuscript
show_ames <- function(m, tag) {
  cat("\n--", tag, "(N =", m$n, ") AMEs --\n")
  for (i in seq_len(nrow(m$mfx))) {
    cat(sprintf("  %-32s %-6s AME %+.4f  p %.4f\n",
                m$mfx$contrast[i], m$mfx$group[i],
                m$mfx$estimate[i], m$mfx$p.value[i]))
  }
  cat("-- predicted probabilities --\n")
  for (i in seq_len(nrow(m$preds))) {
    cat(sprintf("  %-22s %-7s %.4f\n",
                m$preds$objsubjclass_factor[i], m$preds$group[i], m$preds$estimate[i]))
  }
}
show_ames(beh_primary, "Primary")
show_ames(beh_sens, "Sensitivity (excl. Taste-Only)")
cat("\nSaved tables/model_results_behavioral.rds\n")
