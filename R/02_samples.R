# R/02_samples.R
# ==============================================================================
# Sample Sizes & Descriptive Statistics (Step 02)
#
# Computes EVERY sample size, share, and design parameter reported in the
# manuscript from the raw data -- nothing is hardcoded. Writes:
#   tables/sample_sizes.csv  (machine-readable, for verification)
#   tables/sample_stats.rds  (for downstream scripts)
#
# NOTE: Upstream fieldwork flow counts (3,782 accessed, 85 non-consent, etc.)
# are survey-administration logs that are NOT derivable from the analysis
# file and are therefore reported here only for cross-checking row counts.
# ==============================================================================

suppressPackageStartupMessages({
  library(dplyr)
  library(haven)
  library(WeightIt)
})

source("R/01_dataproc.R")

cat("\n==================== STEP 02: SAMPLE SIZES ====================\n")

samples <- build_samples()
raw <- read_dta(resolve_data_path())
full <- samples$wide_all     # complete evaluators
pri  <- samples$wide_cc_primary
fw   <- samples$wide_cc_full

# --- 1. Upstream / row-count bookkeeping --------------------------------------
n_raw_rows <- nrow(raw)
n_finished <- sum(raw$finished == 1, na.rm = TRUE)
n_unfinished <- sum(raw$finished == 0, na.rm = TRUE)
n_finished_na <- sum(is.na(raw$finished))

# --- 2. Core analysis samples -------------------------------------------------
n_complete_evaluators <- nrow(full)        # 2,253
n_cc_full <- nrow(fw)                      # 2,252 (one missing age)
n_primary <- nrow(pri)                     # 1,981
n_primary_obs <- nrow(samples$long_cc_primary) # 3,962 repeated observations

# --- 3. Three-condition status-free subset (Section 3.1) ----------------------
sub3 <- pri %>%
  filter(cond2_factor %in% c("Baseline", "Taste Only/Like", "Taste Only/Dislike"))
n_sub3 <- nrow(sub3)
sub3_cells <- sub3 %>% count(cond2_factor)
n_sub3_control <- sum(sub3$cond2_factor == "Baseline")

# --- 4. Educational tiers and status quadrants (primary sample) --------------
tier_ns <- pri %>% count(edu4_factor)
quad_ns <- pri %>% count(objsubjclass_factor)
n_college <- sum(pri$college == 1)
college_share <- mean(pri$college == 1)

# --- 5. Full-sample appendix counts ------------------------------------------
full_quad_ns <- fw %>% count(objsubjclass_factor)
full_arm_ns <- full %>% count(cond2_factor)
raw_arm_ns <- raw %>% filter(!is.na(control)) %>% count(control)

# --- 6. Under-25 cohort degree shares (motivation for age restriction) --------
u25 <- full %>% filter(age <= 3)
u25_bach_share <- mean(u25$bach == 1)
u25_anydeg_share <- mean(u25$college == 1)
n_u25 <- nrow(u25)

# --- 7. Subjective class distribution (primary sample) ------------------------
n_lower <- sum(pri$percclass == 1, na.rm = TRUE)
n_upper <- sum(pri$percclass == 4, na.rm = TRUE)

# --- 8. Design parameters (repeated-measures precision) -----------------------
sd_t1 <- sd(pri$taste1_rev)
sd_t2 <- sd(pri$taste2_rev)
sd_diff <- sd(pri$taste2_rev - pri$taste1_rev)
r_test_retest <- cor(pri$taste1_rev, pri$taste2_rev)

# --- 9. ES vs CS equivalence tests (High-Status consolidation) ---------------
escs_one <- function(df, subset_label) {
  do.call(rbind, lapply(list(c(2, 3, "Likes"), c(5, 6, "Dislikes")), function(pr) {
    a <- df$diff[df$cond == pr[1]]
    b <- df$diff[df$cond == pr[2]]
    tt <- t.test(a, b, var.equal = TRUE)
    data.frame(
      subset = subset_label, arm = pr[3],
      n_ES = length(a), mean_ES = mean(a),
      n_CS = length(b), mean_CS = mean(b),
      F = unname(tt$statistic^2), p = tt$p.value
    )
  }))
}
escs_tests <- rbind(
  escs_one(full, "Pooled"),
  escs_one(full %>% filter(college == 1), "College graduates"),
  escs_one(pri, "Pooled (primary)"),
  escs_one(pri %>% filter(college == 1), "College graduates (primary)")
)

# --- 10. Behavioral-choice sample construction --------------------------------
assign_behavior <- function(df) {
  df %>%
    mutate(
      behavior = case_when(
        cond2_factor == "Baseline" & diff == 0 ~ "Stay",
        cond2_factor == "Baseline" & diff > 0 ~ "Shift Up",
        cond2_factor == "Baseline" & diff < 0 ~ "Shift Down",
        cond2_factor %in% c("Class & Taste/Like/-Status", "Class & Taste/Like/+Status", "Taste Only/Like") & diff == 0 ~ "Stay",
        cond2_factor %in% c("Class & Taste/Like/-Status", "Class & Taste/Like/+Status", "Taste Only/Like") & diff > 0 ~ "Conform",
        cond2_factor %in% c("Class & Taste/Like/-Status", "Class & Taste/Like/+Status", "Taste Only/Like") & diff < 0 ~ "React",
        cond2_factor %in% c("Class & Taste/Dislike/-Status", "Class & Taste/Dislike/+Status", "Taste Only/Dislike") & diff == 0 ~ "Stay",
        cond2_factor %in% c("Class & Taste/Dislike/-Status", "Class & Taste/Dislike/+Status", "Taste Only/Dislike") & diff < 0 ~ "Conform",
        cond2_factor %in% c("Class & Taste/Dislike/-Status", "Class & Taste/Dislike/+Status", "Taste Only/Dislike") & diff > 0 ~ "React",
        TRUE ~ NA_character_
      )
    )
}
pri_b <- assign_behavior(pri)
n_baseline_shifters <- sum(pri_b$behavior %in% c("Shift Up", "Shift Down"), na.rm = TRUE)
pri_b_valid <- pri_b %>% filter(behavior %in% c("Stay", "Conform", "React"))
n_beh_primary <- nrow(pri_b_valid)
pri_b_sens <- pri_b_valid %>% filter(!cond2_factor %in% c("Taste Only/Like", "Taste Only/Dislike"))
n_beh_sens <- nrow(pri_b_sens)
n_taste_only_primary <- sum(pri$cond2_factor %in% c("Taste Only/Like", "Taste Only/Dislike"))

# Raw behavioral rates by quadrant (unweighted reference rates)
beh_rates <- pri_b_valid %>%
  group_by(objsubjclass_factor) %>%
  summarise(
    n = n(),
    stay_rate = mean(behavior == "Stay"),
    conform_rate = mean(behavior == "Conform"),
    react_rate = mean(behavior == "React"),
    .groups = "drop"
  )

overall_stay_rate <- mean(full$diff == 0)

# --- 11. Raw and IPW-weighted trial means, 3-condition subset ------------------
W_pri <- WeightIt::weightit(
  objsubjclass_factor ~ age + female + factor(raceeth) + parented,
  data = pri, method = "ps", estimand = "ATE"
)
pri$.ipw_quad <- W_pri$weights
sub3w <- sub3 %>% mutate(.ipw_quad = pri$.ipw_quad[match(sub3$id, pri$id)])
trial_means <- sub3 %>%
  group_by(cond2_factor) %>%
  summarise(
    n = n(),
    m1_unwt = mean(taste1_rev), m2_unwt = mean(taste2_rev), d_unwt = mean(diff),
    .groups = "drop"
  )
trial_means_w <- sub3w %>%
  group_by(cond2_factor) %>%
  summarise(
    m1_ipw = weighted.mean(taste1_rev, .ipw_quad),
    m2_ipw = weighted.mean(taste2_rev, .ipw_quad),
    d_ipw = weighted.mean(diff, .ipw_quad),
    .groups = "drop"
  )
trial_means <- left_join(trial_means, trial_means_w, by = "cond2_factor")

# --- 12. Assemble and report ---------------------------------------------------
sample_sizes <- data.frame(
  quantity = c(
    "raw_rows_in_analysis_file", "finished_yes", "finished_no", "finished_na",
    "complete_evaluators", "full_cc", "primary_age25plus", "primary_long_obs",
    "sub3_total", "sub3_control", "sub3_genlike", "sub3_gendislike",
    "tier_hs_or_less", "tier_assoc_somecollege", "tier_bachelors", "tier_postgrad",
    "quad_working_nocollege", "quad_working_college", "quad_middle_nocollege", "quad_middle_college",
    "n_college_degree", "college_share",
    "full_quad_working_nocollege", "full_quad_working_college",
    "full_quad_middle_nocollege", "full_quad_middle_college",
    "under25_n", "under25_bach_share", "under25_anydeg_share",
    "n_lower_class", "n_upper_class",
    "baseline_shifters_excluded", "beh_primary_n", "beh_sens_n", "taste_only_primary_n",
    "overall_stay_rate", "sd_t1", "sd_t2", "sd_diff", "r_test_retest"
  ),
  value = c(
    n_raw_rows, n_finished, n_unfinished, n_finished_na,
    n_complete_evaluators, n_cc_full, n_primary, n_primary_obs,
    n_sub3, n_sub3_control,
    sum(sub3$cond2_factor == "Taste Only/Like"), sum(sub3$cond2_factor == "Taste Only/Dislike"),
    tier_ns$n[1], tier_ns$n[2], tier_ns$n[3], tier_ns$n[4],
    quad_ns$n[1], quad_ns$n[2], quad_ns$n[3], quad_ns$n[4],
    n_college, college_share,
    full_quad_ns$n[1], full_quad_ns$n[2], full_quad_ns$n[3], full_quad_ns$n[4],
    n_u25, u25_bach_share, u25_anydeg_share,
    n_lower, n_upper,
    n_baseline_shifters, n_beh_primary, n_beh_sens, n_taste_only_primary,
    overall_stay_rate, sd_t1, sd_t2, sd_diff, r_test_retest
  )
)

write.csv(sample_sizes, "tables/sample_sizes.csv", row.names = FALSE)
saveRDS(
  list(
    sample_sizes = sample_sizes, escs_tests = escs_tests,
    trial_means = trial_means, beh_rates = beh_rates,
    assign_behavior = assign_behavior,
    n = list(
      primary = n_primary, cc_full = n_cc_full, complete = n_complete_evaluators,
      sub3 = n_sub3, beh_primary = n_beh_primary, beh_sens = n_beh_sens,
      baseline_shifters = n_baseline_shifters
    )
  ),
  "tables/sample_stats.rds"
)

cat("\nCore samples: evaluators =", n_complete_evaluators,
    "| full CC =", n_cc_full, "| primary (25+) =", n_primary,
    "| primary obs =", n_primary_obs, "\n")
cat("3-cond subset: N =", n_sub3, "(control", n_sub3_control, ")\n")
cat("Tiers:", paste(tier_ns$n, collapse = "/"), " | Quadrants:", paste(quad_ns$n, collapse = "/"), "\n")
cat("Behavioral N =", n_beh_primary, "| sensitivity N =", n_beh_sens,
    "| baseline shifters excluded =", n_baseline_shifters, "\n")
cat("College share:", round(100 * college_share, 1), "% | Under-25 bach:",
    round(100 * u25_bach_share, 1), "% any-deg:", round(100 * u25_anydeg_share, 1), "%\n")
cat("Design: sd_t1 =", round(sd_t1, 4), " sd_t2 =", round(sd_t2, 4),
    " sd_diff =", round(sd_diff, 4), " r =", round(r_test_retest, 4), "\n")
cat("ES vs CS (full sample): likes F =", round(escs_tests$F[1], 3), "p =", round(escs_tests$p[1], 3),
    "| dislikes F =", round(escs_tests$F[2], 3), "p =", round(escs_tests$p[2], 3), "\n")
cat("Overall stay rate:", round(100 * overall_stay_rate, 1), "%\n")
cat("Saved tables/sample_sizes.csv and tables/sample_stats.rds\n")
