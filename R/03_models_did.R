# R/03_models_did.R
# ==============================================================================
# Difference-in-Differences Models (Step 03)
#
# Fits every DiD model reported in the manuscript and saves tidy result frames
# to tables/model_results_did.rds for figure (07) and table (08) generation.
# Nothing downstream re-fits models; everything reads the saved results.
#
# Models:
#   1. Section 3.1 -- status-free baseline (3-condition subset, N = 457):
#      Eq. 5 mixed model (IPW-weighted and unweighted) + valence contrast
#   2. Pooled DiD mixed model (primary sample, N = 1,981): unweighted and
#      IPW-weighted  -> Table A.5 / Appendix Figure A.3
#   3. Four-tier education DiD (multinomial IPW)  -> Figure 4 / Table A.2
#   4. Stepwise education-alone / class-alone (binary IPW), primary + full
#      -> Appendix Figure A.2 / Tables A.4 & A.7
#   5. 24-cell status-consistency quadrant DiD (multinomial IPW), primary +
#      full  -> Tables A.3 & A.8
# ==============================================================================

suppressPackageStartupMessages({
  library(dplyr)
  library(lme4)
  library(WeightIt)
  library(marginaleffects)
})

source("R/01_dataproc.R")

cat("\n==================== STEP 03: DiD MODELS ====================\n")

samples <- build_samples()
df_long <- samples$long_all
pri <- samples$wide_cc_primary
fw  <- samples$wide_cc_full
pri$cond2_refctrl <- relevel(pri$cond2_factor, ref = "Baseline")
fw$cond2_refctrl  <- relevel(fw$cond2_factor, ref = "Baseline")
pri_long <- samples$long_cc_primary %>% mutate(cond2_refctrl = relevel(cond2_factor, ref = "Baseline"))
fw_long  <- samples$long_cc_full  %>% mutate(cond2_refctrl = relevel(cond2_factor, ref = "Baseline"))

ipw_covars <- "age + female + raceeth_f + parented"

clean_cond_labels <- function(x) {
  dplyr::case_when(
    x == "Class & Taste/Dislike/+Status" ~ "High-Status Dislike",
    x == "Class & Taste/Like/-Status"    ~ "Low-Status Like",
    x == "Taste Only/Dislike"            ~ "Generalized Dislike",
    x == "Taste Only/Like"               ~ "Generalized Like",
    x == "Class & Taste/Like/+Status"    ~ "High-Status Like",
    x == "Class & Taste/Dislike/-Status" ~ "Low-Status Dislike",
    TRUE ~ x
  )
}

cond_order_top_down <- c(
  "Generalized Like", "High-Status Like", "Low-Status Like",
  "Generalized Dislike", "High-Status Dislike", "Low-Status Dislike"
)

sig_levels <- c("p < 0.05", "p < 0.10", "Not Significant")
classify_sig <- function(p) {
  factor(
    dplyr::case_when(p < 0.05 ~ "p < 0.05", p < 0.10 ~ "p < 0.10", TRUE ~ "Not Significant"),
    levels = sig_levels
  )
}

# Tidy frame from marginaleffects comparisons: one row per (Group, Condition)
tidy_comparisons <- function(comps, groupvar) {
  as.data.frame(comps) %>%
    dplyr::mutate(
      Condition = clean_cond_labels(gsub(" - Baseline", "", contrast)),
      Group = .data[[groupvar]]
    ) %>%
    dplyr::select(Group, Condition, estimate, std.error, statistic, p.value) %>%
    dplyr::mutate(
      conf.low = estimate - 1.96 * std.error,
      conf.high = estimate + 1.96 * std.error,
      sig = classify_sig(p.value),
      Condition = factor(Condition, levels = cond_order_top_down)
    )
}

# ------------------------------------------------------------------------------
# 0. IPW weights (multinomial propensity scores)
# ------------------------------------------------------------------------------
W_quad_pri <- weightit(as.formula(paste("objsubjclass_factor ~", ipw_covars)),
                       data = pri, method = "ps", estimand = "ATE")
pri$.ipw_quad <- W_quad_pri$weights
W_quad_full <- weightit(as.formula(paste("objsubjclass_factor ~", ipw_covars)),
                        data = fw, method = "ps", estimand = "ATE")
fw$.ipw_quad <- W_quad_full$weights

W_edu4 <- weightit(as.formula(paste("edu4_factor ~", ipw_covars)),
                   data = pri, method = "ps", estimand = "ATE")
pri$.ipw_edu4 <- W_edu4$weights

W_college <- weightit(as.formula(paste("college ~", ipw_covars)),
                      data = pri, method = "ps", estimand = "ATE")
pri$.ipw_college <- W_college$weights
W_class <- weightit(as.formula(paste("class ~", ipw_covars)),
                    data = pri, method = "ps", estimand = "ATE")
pri$.ipw_class <- W_class$weights

W_college_f <- weightit(as.formula(paste("college ~", ipw_covars)),
                        data = fw, method = "ps", estimand = "ATE")
fw$.ipw_college <- W_college_f$weights
W_class_f <- weightit(as.formula(paste("class ~", ipw_covars)),
                      data = fw, method = "ps", estimand = "ATE")
fw$.ipw_class <- W_class_f$weights

# Long data with quadrant IPW weights attached
pri_long_w <- df_long %>%
  dplyr::inner_join(pri %>% dplyr::select(id, .ipw_quad), by = "id") %>%
  dplyr::mutate(cond2_refctrl = relevel(cond2_factor, ref = "Baseline"))

# ------------------------------------------------------------------------------
# 1. Section 3.1: status-free baseline, 3-condition subset (N = 457)
# ------------------------------------------------------------------------------
sub3_w <- pri %>%
  filter(cond2_factor %in% c("Baseline", "Taste Only/Like", "Taste Only/Dislike")) %>%
  mutate(
    cond3 = factor(cond2_factor,
      levels = c("Baseline", "Taste Only/Like", "Taste Only/Dislike"),
      labels = c("Control Condition", "Generalized Like", "Generalized Dislike")
    )
  )
sub3_l <- df_long %>%
  filter(id %in% sub3_w$id) %>%
  dplyr::inner_join(sub3_w %>% dplyr::select(id, .ipw_quad), by = "id") %>%
  mutate(
    cond3 = factor(cond2_factor,
      levels = c("Baseline", "Taste Only/Like", "Taste Only/Dislike"),
      labels = c("Control Condition", "Generalized Like", "Generalized Dislike")
    )
  )

# Eq. 5 mixed model, IPW-weighted (canonical model for Section 3.1)
mod31_ipw <- lmer(taste ~ factor(trial) * cond3 + (1 | id),
                  data = sub3_l, weights = .ipw_quad, REML = FALSE)
co31 <- summary(mod31_ipw)$coefficients
beta1_ipw <- co31["factor(trial)2", "Estimate"]
delta_like_ipw <- co31["factor(trial)2:cond3Generalized Like", "Estimate"]
delta_dislike_ipw <- co31["factor(trial)2:cond3Generalized Dislike", "Estimate"]

# Eq. 5 mixed model, unweighted (reference)
mod31_unwt <- lmer(taste ~ factor(trial) * cond3 + (1 | id),
                   data = sub3_l, REML = FALSE)
co31u <- summary(mod31_unwt)$coefficients

# Valence contrast (delta_Like - delta_Dislike) via delta method on the IPW model
V31 <- vcov(mod31_ipw)
v_like <- V31["factor(trial)2:cond3Generalized Like", "factor(trial)2:cond3Generalized Like"]
v_dis <- V31["factor(trial)2:cond3Generalized Dislike", "factor(trial)2:cond3Generalized Dislike"]
cv <- V31["factor(trial)2:cond3Generalized Like", "factor(trial)2:cond3Generalized Dislike"]
valence_contrast <- delta_like_ipw - delta_dislike_ipw
valence_se <- sqrt(v_like + v_dis - 2 * cv)
valence_z <- valence_contrast / valence_se
valence_p <- 2 * (1 - pnorm(abs(valence_z)))
valence_chisq <- valence_z^2

res_baseline <- list(
  mod_ipw = mod31_ipw, mod_unwt = mod31_unwt,
  beta1_ipw = beta1_ipw,
  beta1_ipw_se = co31["factor(trial)2", "Std. Error"],
  beta1_ipw_t = co31["factor(trial)2", "t value"],
  beta1_ipw_p = 2 * (1 - pnorm(abs(co31["factor(trial)2", "t value"]))),
  beta1_unwt = co31u["factor(trial)2", "Estimate"],
  delta_like = delta_like_ipw,
  delta_like_se = co31["factor(trial)2:cond3Generalized Like", "Std. Error"],
  delta_like_p = 2 * (1 - pnorm(abs(co31["factor(trial)2:cond3Generalized Like", "t value"]))),
  delta_dislike = delta_dislike_ipw,
  delta_dislike_se = co31["factor(trial)2:cond3Generalized Dislike", "Std. Error"],
  delta_dislike_p = 2 * (1 - pnorm(abs(co31["factor(trial)2:cond3Generalized Dislike", "t value"]))),
  valence_contrast = valence_contrast, valence_se = valence_se,
  valence_chisq = valence_chisq, valence_p = valence_p,
  n = nrow(sub3_w),
  did_frame = data.frame(
    Condition = factor(c("Generalized Like", "Generalized Dislike"),
                       levels = c("Generalized Dislike", "Generalized Like")),
    estimate = c(delta_like_ipw, delta_dislike_ipw),
    std.error = c(co31["factor(trial)2:cond3Generalized Like", "Std. Error"],
                  co31["factor(trial)2:cond3Generalized Dislike", "Std. Error"]),
    p.value = c(2 * (1 - pnorm(abs(co31["factor(trial)2:cond3Generalized Like", "t value"]))),
                2 * (1 - pnorm(abs(co31["factor(trial)2:cond3Generalized Dislike", "t value"]))))
  ) %>%
    dplyr::mutate(
      conf.low = estimate - 1.96 * std.error,
      conf.high = estimate + 1.96 * std.error,
      sig = classify_sig(p.value)
    )
)

cat(sprintf("3.1 (N=%d): beta1=%.3f (SE %.3f, t %.2f, p %.4f); dLike=%+.3f (p %.3f); dDislike=%+.3f (p %.4f); contrast=%.3f (chi2 %.2f, p %.4f)\n",
            res_baseline$n, res_baseline$beta1_ipw, res_baseline$beta1_ipw_se,
            res_baseline$beta1_ipw_t, res_baseline$beta1_ipw_p,
            res_baseline$delta_like, res_baseline$delta_like_p,
            res_baseline$delta_dislike, res_baseline$delta_dislike_p,
            res_baseline$valence_contrast, res_baseline$valence_chisq,
            res_baseline$valence_p))

# ------------------------------------------------------------------------------
# 2. Pooled DiD mixed model (primary sample): unweighted vs IPW -> Table A.5
# ------------------------------------------------------------------------------
mod_pooled_unwt <- lmer(taste ~ factor(trial) * cond2_refctrl + (1 | id),
                        data = pri_long, REML = FALSE)
mod_pooled_ipw <- lmer(taste ~ factor(trial) * cond2_refctrl + (1 | id),
                       data = pri_long_w, weights = .ipw_quad, REML = FALSE)

tidy_pooled <- function(mod) {
  co <- summary(mod)$coefficients
  terms <- grep("factor\\(trial\\)2:cond2_refctrl", rownames(co), value = TRUE)
  dplyr::tibble(
    Condition = clean_cond_labels(gsub("factor\\(trial\\)2:cond2_refctrl", "", terms)),
    estimate = co[terms, "Estimate"],
    std.error = co[terms, "Std. Error"],
    t.value = co[terms, "t value"],
    p.value = 2 * (1 - pnorm(abs(co[terms, "t value"])))
  ) %>%
    dplyr::mutate(
      Condition = factor(Condition, levels = cond_order_top_down),
      conf.low = estimate - 1.96 * std.error,
      conf.high = estimate + 1.96 * std.error,
      sig = classify_sig(p.value)
    ) %>%
    dplyr::arrange(Condition)
}

res_pooled <- list(
  primary_unwt = list(
    mod = mod_pooled_unwt,
    beta1 = summary(mod_pooled_unwt)$coefficients["factor(trial)2", "Estimate"],
    beta1_se = summary(mod_pooled_unwt)$coefficients["factor(trial)2", "Std. Error"],
    beta1_t = summary(mod_pooled_unwt)$coefficients["factor(trial)2", "t value"],
    resid_var = sigma(mod_pooled_unwt)^2,
    between_var = as.data.frame(VarCorr(mod_pooled_unwt))$vcov[1],
    frame = tidy_pooled(mod_pooled_unwt)
  ),
  primary_ipw = list(
    mod = mod_pooled_ipw,
    beta1 = summary(mod_pooled_ipw)$coefficients["factor(trial)2", "Estimate"],
    beta1_se = summary(mod_pooled_ipw)$coefficients["factor(trial)2", "Std. Error"],
    beta1_t = summary(mod_pooled_ipw)$coefficients["factor(trial)2", "t value"],
    resid_var = sigma(mod_pooled_ipw)^2,
    between_var = as.data.frame(VarCorr(mod_pooled_ipw))$vcov[1],
    frame = tidy_pooled(mod_pooled_ipw)
  ),
  n = nrow(pri)
)

# ------------------------------------------------------------------------------
# 3. Four-tier education DiD (multinomial IPW) -> Figure 4 / Table A.2
# ------------------------------------------------------------------------------
mod_edu4 <- lm(diff ~ cond2_refctrl * edu4_factor, data = pri, weights = .ipw_edu4)
comps_edu4 <- comparisons(mod_edu4, variables = "cond2_refctrl", by = "edu4_factor")
tier_levels <- c("High School or Less", "Associate/Some College", "Bachelor's Degree", "Postgraduate")
tier_ns <- vapply(tier_levels, function(t) sum(pri$edu4_factor == t), integer(1))
res_edu4 <- tidy_comparisons(comps_edu4, "edu4_factor") %>%
  dplyr::mutate(
    Group = factor(as.character(Group), levels = tier_levels),
    group_n = tier_ns[as.character(Group)]
  ) %>%
  dplyr::arrange(Group, Condition)
# Drift (control change score) per tier with delta-method SE
V4 <- vcov(mod_edu4)
drift_rows <- lapply(seq_along(tier_levels)[-1], function(k) {
  lab <- paste0("edu4_factor", tier_levels[k])
  est <- coef(mod_edu4)["(Intercept)"] + coef(mod_edu4)[lab]
  se <- sqrt(V4["(Intercept)", "(Intercept)"] + V4[lab, lab] + 2 * V4["(Intercept)", lab])
  data.frame(Group = tier_levels[k], drift = est, drift_se = se,
             drift_p = 2 * (1 - pnorm(abs(est / se))))
})
res_edu4_drift <- do.call(rbind, c(
  list(data.frame(Group = tier_levels[1],
                  drift = coef(mod_edu4)["(Intercept)"],
                  drift_se = sqrt(V4["(Intercept)", "(Intercept)"]),
                  drift_p = summary(mod_edu4)$coefficients["(Intercept)", "Pr(>|t|)"])),
  drift_rows
))

# ------------------------------------------------------------------------------
# 4. Stepwise education-alone / class-alone (binary IPW), primary + full
# ------------------------------------------------------------------------------
fit_stepwise <- function(df, w_college, w_class) {
  mod_e <- lm(diff ~ cond2_refctrl * college_factor, data = df, weights = .ipw_college)
  df_e <- tidy_comparisons(comparisons(mod_e, variables = "cond2_refctrl", by = "college_factor"), "college_factor")
  mod_c <- lm(diff ~ cond2_refctrl * class_factor, data = df, weights = .ipw_class)
  df_c <- tidy_comparisons(comparisons(mod_c, variables = "cond2_refctrl", by = "class_factor"), "class_factor")
  # Per-group control-condition drift (intercept + group main effect, delta-method SE)
  group_drift <- function(mod, group_label) {
    co <- coef(mod); V <- vcov(mod)
    ref <- co["(Intercept)"]; ref_se <- sqrt(V["(Intercept)", "(Intercept)"])
    rows <- list(data.frame(Group = "REF", drift = ref, drift_se = ref_se,
                            drift_p = 2 * (1 - pnorm(abs(ref / ref_se)))))
    rows[[2]] <- local({
      est <- ref + co[[group_label]]
      se <- sqrt(V["(Intercept)", "(Intercept)"] + V[group_label, group_label] +
                   2 * V["(Intercept)", group_label])
      data.frame(Group = "NONREF", drift = est, drift_se = se,
                 drift_p = 2 * (1 - pnorm(abs(est / se))))
    })
    do.call(rbind, rows)
  }
  list(mod_edu = mod_e, mod_class = mod_c, frame_edu = df_e, frame_class = df_c,
       drift_edu = group_drift(mod_e, "college_factorCollege Degree"),
       drift_class = group_drift(mod_c, "class_factorMiddle Class"))
}
res_stepwise_primary <- fit_stepwise(pri, W_college, W_class)
res_stepwise_full <- fit_stepwise(fw, W_college_f, W_class_f)
res_stepwise_primary$n <- c(
  no_college = sum(pri$college == 0), college = sum(pri$college == 1),
  working = sum(pri$class == 0), middle = sum(pri$class == 1)
)
res_stepwise_full$n <- c(
  no_college = sum(fw$college == 0), college = sum(fw$college == 1),
  working = sum(fw$class == 0), middle = sum(fw$class == 1)
)

# ------------------------------------------------------------------------------
# 5. 24-cell status-consistency quadrant DiD (multinomial IPW), primary + full
# ------------------------------------------------------------------------------
mod_quad_pri <- lm(diff ~ cond2_refctrl * objsubjclass_factor, data = pri, weights = .ipw_quad)
res_quad_primary <- tidy_comparisons(
  comparisons(mod_quad_pri, variables = "cond2_refctrl", by = "objsubjclass_factor"),
  "objsubjclass_factor"
) %>% dplyr::arrange(Group, Condition)

quad_levels <- c("Working, No College", "Working, College",
                 "Middle, No College", "Middle, College")
quad_group_drift <- function(mod) {
  co <- coef(mod); V <- vcov(mod)
  ref <- co["(Intercept)"]; ref_se <- sqrt(V["(Intercept)", "(Intercept)"])
  rows <- list(data.frame(Group = quad_levels[1], drift = ref, drift_se = ref_se,
                          drift_p = 2 * (1 - pnorm(abs(ref / ref_se)))))
  for (k in 2:4) {
    lab <- paste0("objsubjclass_factor", quad_levels[k])
    est <- ref + co[[lab]]
    se <- sqrt(V["(Intercept)", "(Intercept)"] + V[lab, lab] + 2 * V["(Intercept)", lab])
    rows[[k]] <- data.frame(Group = quad_levels[k], drift = est, drift_se = se,
                            drift_p = 2 * (1 - pnorm(abs(est / se))))
  }
  do.call(rbind, rows)
}
res_quad_drift_primary <- quad_group_drift(mod_quad_pri)
quad_ns_pri <- vapply(quad_levels, function(q) sum(as.character(pri$objsubjclass_factor) == q), integer(1))

mod_quad_full <- lm(diff ~ cond2_refctrl * objsubjclass_factor, data = fw, weights = .ipw_quad)
res_quad_full <- tidy_comparisons(
  comparisons(mod_quad_full, variables = "cond2_refctrl", by = "objsubjclass_factor"),
  "objsubjclass_factor"
) %>% dplyr::arrange(Group, Condition)
res_quad_drift_full <- quad_group_drift(mod_quad_full)
quad_ns_fw <- vapply(quad_levels, function(q) sum(as.character(fw$objsubjclass_factor) == q), integer(1))

# ------------------------------------------------------------------------------
# Save
# ------------------------------------------------------------------------------
saveRDS(
  list(
    res_baseline = res_baseline,
    res_pooled = res_pooled,
    res_edu4 = res_edu4,
    res_edu4_drift = res_edu4_drift,
    res_stepwise_primary = res_stepwise_primary,
    res_stepwise_full = res_stepwise_full,
    res_quad_primary = res_quad_primary,
    res_quad_drift_primary = res_quad_drift_primary,
    quad_ns_primary = quad_ns_pri,
    res_quad_full = res_quad_full,
    res_quad_drift_full = res_quad_drift_full,
    quad_ns_full = quad_ns_fw,
    W_quad_primary = W_quad_pri,
    W_quad_full = W_quad_full
  ),
  "tables/model_results_did.rds"
)

cat("Primary pooled DiD: unwt beta1 =", round(res_pooled$primary_unwt$beta1, 4),
    "| IPW beta1 =", round(res_pooled$primary_ipw$beta1, 4),
    "| resid var unwt =", round(res_pooled$primary_unwt$resid_var, 3),
    "| IPW =", round(res_pooled$primary_ipw$resid_var, 3), "\n")
cat("4-tier model: 24 cells computed; tier Ns =", paste(tier_ns, collapse = "/"), "\n")
cat("Saved tables/model_results_did.rds\n")
