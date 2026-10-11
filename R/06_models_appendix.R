# R/06_models_appendix.R
# ==============================================================================
# Appendix Models & Analyses (Step 06)
#
# 1. Ex-post Minimum Detectable Effect (MDE) analysis -- ALL inputs computed
#    from the data (cell sizes, SDs, test-retest correlation). No hardcoded Ns.
# 2. Descriptive distributions for Table 1 (primary sample) and Appendix
#    Table A.6 (full unrestricted sample), by experimental arm.
# 3. Class-definition robustness check (Appendix F): restricting subjective
#    class to strict working/middle identifiers.
#
# Saves: tables/mde_results.rds, tables/descriptives.rds, tables/class_robustness.rds
# ==============================================================================

suppressPackageStartupMessages({
  library(dplyr)
  library(haven)
})

source("R/01_dataproc.R")

cat("\n================ STEP 06: APPENDIX MODELS =================\n")

samples <- build_samples()
pri <- samples$wide_cc_primary
fw  <- samples$wide_cc_full
raw <- read_dta(resolve_data_path())
stats02 <- readRDS("tables/sample_stats.rds")

# ==============================================================================
# 1. Ex-Post MDE Analysis (primary sample, Age >= 25, N = 1,981)
# ==============================================================================
sd_t1 <- stats02$sample_sizes$value[stats02$sample_sizes$quantity == "sd_t1"]
sd_t2 <- stats02$sample_sizes$value[stats02$sample_sizes$quantity == "sd_t2"]
sd_diff <- stats02$sample_sizes$value[stats02$sample_sizes$quantity == "sd_diff"]
rho <- stats02$sample_sizes$value[stats02$sample_sizes$quantity == "r_test_retest"]
n_primary <- nrow(pri)

# Observed exposure drift in the Control Condition
ctrl <- pri %>% filter(cond2_factor == "Baseline")
drift_ctrl_primary <- mean(ctrl$diff)
drift_ctrl_primary_se <- sd(ctrl$diff) / sqrt(nrow(ctrl))
drift_ctrl_primary_t <- drift_ctrl_primary / drift_ctrl_primary_se
drift_ctrl_primary_p <- 2 * (1 - pnorm(abs(drift_ctrl_primary_t)))
n_ctrl_primary <- nrow(ctrl)

# Full-sample control drift (for reference)
ctrl_full <- samples$wide_all %>% filter(cond2_factor == "Baseline")
drift_ctrl_full <- mean(ctrl_full$diff)
drift_ctrl_full_t <- drift_ctrl_full / (sd(ctrl_full$diff) / sqrt(nrow(ctrl_full)))

calc_mde <- function(n_t, n_c = NULL, s_diff, s_base, alpha = 0.05, power = 0.80) {
  z_crit <- qnorm(1 - alpha / 2)
  z_pwr <- qnorm(power)
  multiplier <- z_crit + z_pwr
  if (is.null(n_c)) {
    se <- s_diff / sqrt(n_t)
  } else {
    se <- s_diff * sqrt(1 / n_t + 1 / n_c)
  }
  list(se = se, mde_raw = multiplier * se, mde_d = multiplier * se / s_base)
}

# Treated-cell sizes, all computed from the primary sample
arm_sizes <- pri %>% count(cond2_factor)
n_tasteonly <- arm_sizes$n[arm_sizes$cond2_factor == "Taste Only/Like"] +
  arm_sizes$n[arm_sizes$cond2_factor == "Taste Only/Dislike"]
n_tasteonly_percond <- n_tasteonly / 2                                   # 150
six_status_arms <- pri %>% filter(cond %in% 1:6) %>% count(cond)
n_singlestatus_percond <- mean(six_status_arms$n)                        # ~254
n_hs_like <- arm_sizes$n[arm_sizes$cond2_factor == "Class & Taste/Like/+Status"]
n_hs_dislike <- arm_sizes$n[arm_sizes$cond2_factor == "Class & Taste/Dislike/+Status"]
n_hs_pooled_percond <- (n_hs_like + n_hs_dislike) / 2                    # ~505

# Quadrant cells (control N; treated cell min / median / max across 6 arms)
quad_cells <- pri %>% count(objsubjclass_factor, cond2_factor)
quad_control <- quad_cells %>% filter(cond2_factor == "Baseline")
quad_spec <- lapply(quad_control$objsubjclass_factor, function(q) {
  treated <- quad_cells %>% filter(objsubjclass_factor == q, cond2_factor != "Baseline")
  list(
    group = q,
    n_c = quad_control$n[quad_control$objsubjclass_factor == q],
    n_min = min(treated$n), n_max = max(treated$n), n_med = median(treated$n)
  )
})

mde_row <- function(comparison, tier, n_t, n_c = NULL, power = c(0.80, 0.90)) {
  r80 <- calc_mde(n_t, n_c, sd_diff, sd_t1, power = 0.80)
  r90 <- calc_mde(n_t, n_c, sd_diff, sd_t1, power = 0.90)
  data.frame(
    Tier = tier, Comparison = comparison,
    N_T = as.character(n_t), N_C = if (is.null(n_c)) "---" else as.character(n_c),
    SE = sprintf("%.3f", r80$se),
    MDE_raw_80 = sprintf("%.3f", r80$mde_raw), MDE_d_80 = sprintf("%.3f", r80$mde_d),
    MDE_raw_90 = sprintf("%.3f", r90$mde_raw), MDE_d_90 = sprintf("%.3f", r90$mde_d)
  )
}

df_mde <- rbind(
  mde_row("Primary Sample Drift", "Within-Subject Drift", n_primary),
  mde_row("Control Condition Drift", "Within-Subject Drift", n_ctrl_primary),
  mde_row("Taste-Only Conditions (mean per arm)", "Pooled DiD vs Control",
          n_tasteonly_percond, n_ctrl_primary),
  mde_row("Single-Status Cue Conditions (mean per arm)", "Pooled DiD vs Control",
          n_singlestatus_percond, n_ctrl_primary),
  mde_row("Pooled High-Status Conditions (mean per arm)", "Pooled DiD vs Control",
          n_hs_pooled_percond, n_ctrl_primary),
  do.call(rbind, lapply(quad_spec, function(sg) {
    r80 <- calc_mde(sg$n_med, sg$n_c, sd_diff, sd_t1, power = 0.80)
    r90 <- calc_mde(sg$n_med, sg$n_c, sd_diff, sd_t1, power = 0.90)
    rmin <- calc_mde(sg$n_max, sg$n_c, sd_diff, sd_t1, power = 0.80)
    rmax <- calc_mde(sg$n_min, sg$n_c, sd_diff, sd_t1, power = 0.80)
    data.frame(
      Tier = "Subgroup Status DiD", Comparison = sg$group,
      N_T = sprintf("%d--%d", sg$n_min, sg$n_max), N_C = as.character(sg$n_c),
      SE = sprintf("%.3f", r80$se),
      MDE_raw_80 = sprintf("%.3f", r80$mde_raw), MDE_d_80 = sprintf("%.3f", r80$mde_d),
      MDE_raw_90 = sprintf("%.3f", r90$mde_raw), MDE_d_90 = sprintf("%.3f", r90$mde_d)
    )
  }))
)

mde_inputs <- list(
  n_primary = n_primary, n_ctrl_primary = n_ctrl_primary,
  sd_t1 = sd_t1, sd_t2 = sd_t2, sd_diff = sd_diff, rho = rho,
  n_tasteonly_percond = n_tasteonly_percond,
  n_singlestatus_percond = n_singlestatus_percond,
  n_hs_pooled_percond = n_hs_pooled_percond,
  drift_ctrl_primary = drift_ctrl_primary, drift_ctrl_primary_t = drift_ctrl_primary_t,
  drift_ctrl_primary_p = drift_ctrl_primary_p,
  drift_ctrl_full = drift_ctrl_full, drift_ctrl_full_t = drift_ctrl_full_t
)
saveRDS(list(df_mde = df_mde, mde_inputs = mde_inputs), "tables/mde_results.rds")

cat("MDE table rows:", nrow(df_mde),
    "| primary N:", n_primary, "| control N:", n_ctrl_primary, "\n")
cat("Drift (control, primary):", round(drift_ctrl_primary, 3),
    "(t =", round(drift_ctrl_primary_t, 2), ", p =", round(drift_ctrl_primary_p, 3), ")\n")
cat("Treated arm means: taste-only", n_tasteonly_percond,
    "| single-status", round(n_singlestatus_percond, 1),
    "| pooled HS", n_hs_pooled_percond, "\n")

# ==============================================================================
# 2. Descriptives (Table 1 and Appendix Table A.6)
# ==============================================================================
arm_of <- function(df) {
  dplyr::case_when(
    df$control == 0 ~ "Treatment",
    df$control == 1 ~ "Control",
    df$control == 2 ~ "Taste Only",
    TRUE ~ NA_character_
  )
}

build_descriptives <- function(df, drop_na_arm = FALSE) {
  if (drop_na_arm) df <- df %>% filter(!is.na(control))
  d <- df %>%
    mutate(
      arm = arm_of(df),
      gender = if_else(female == 1, "Women", "Men"),
      race = case_when(
        raceeth == 4 ~ "White", raceeth == 3 ~ "Hispanic / Latino",
        raceeth == 2 ~ "Black / African American", raceeth == 1 ~ "Asian / Pacific Islander",
        raceeth %in% c(5, 6) ~ "Other / Multiracial", TRUE ~ NA_character_
      ),
      agegrp = case_when(
        age >= 4 & age <= 5 ~ "25--34", age >= 6 & age <= 7 ~ "35--44",
        age >= 8 & age <= 9 ~ "45--54", age >= 10 & age <= 11 ~ "55--64",
        age >= 12 ~ "65+", age <= 3 ~ "18--24", TRUE ~ NA_character_
      ),
      regiongrp = case_when(
        region %in% c(1, 2) ~ "Northeast", region %in% c(3, 4) ~ "Midwest",
        region %in% c(5, 6, 7) ~ "South", region %in% c(8, 9) ~ "West",
        TRUE ~ NA_character_
      ),
      educat = case_when(
        ma == 1 | docprof == 1 ~ "Graduate / Professional",
        bach == 1 ~ "Bachelor's Degree",
        aadeg == 1 | somcol == 1 ~ "Some College / AA",
        nodipdeg == 1 & (is.na(hsged) | hsged == 0) ~ "Less than High School",
        TRUE ~ "High School Diploma"
      )
    )
  total_n <- nrow(d)
  # per-arm percentages: share of each arm belonging to the category
  arm_pct <- function(var, category) {
    sapply(c("Treatment", "Control", "Taste Only"), function(a) {
      arm_sub <- d[!is.na(d$arm) & d$arm == a & !is.na(d[[var]]), ]
      round(100 * mean(arm_sub[[var]] == category), 1)
    })
  }
  blocks <- list(
    list("gender", "Gender"), list("race", "Race / Ethnicity"),
    list("agegrp", "Age Group"), list("regiongrp", "Geographic Region"),
    list("educat", "Education (Oversampled)")
  )
  out <- do.call(rbind, lapply(blocks, function(b) {
    v <- b[[1]]; lab <- b[[2]]
    tab <- d %>% filter(!is.na(.data[[v]])) %>% count(.data[[v]])
    res <- lapply(seq_len(nrow(tab)), function(i) {
      ap <- arm_pct(v, tab[[1]][i])
      dplyr::tibble(
        block = lab, category = tab[[1]][i], n = tab$n[i],
        pct = round(100 * tab$n[i] / total_n, 1),
        pct_treatment = ap[1], pct_control = ap[2], pct_tasteonly = ap[3]
      )
    })
    do.call(rbind, res)
  }))
  arm_totals <- d %>% filter(!is.na(arm)) %>% count(arm)
  list(table = out, total_n = total_n,
       arm_totals = setNames(arm_totals$n, arm_totals$arm))
}

desc_primary <- build_descriptives(pri)
desc_full_raw <- build_descriptives(raw, drop_na_arm = TRUE)  # full unrestricted sample (N = 2,275)
saveRDS(list(desc_primary = desc_primary, desc_full_raw = desc_full_raw),
       "tables/descriptives.rds")
cat("Descriptives: primary N =", desc_primary$total_n,
    "| full raw N =", desc_full_raw$total_n,
    "| arms (raw):", paste(names(desc_full_raw$arm_totals),
                           desc_full_raw$arm_totals, sep = "=", collapse = ", "), "\n")

# ==============================================================================
# 3. Class-definition robustness (Appendix F)
# ==============================================================================
# Restrict subjective class to strict "working class" (percclass = 2) and
# "middle class" (percclass = 3) identifiers; recompute Stay/Conform/React rates
class_rob <- pri %>%
  filter(percclass %in% c(2, 3)) %>%
  mutate(class_strict = if_else(percclass == 2, 0, 1)) %>%
  mutate(quad = case_when(
    class_strict == 0 & college == 0 ~ "Working, No College",
    class_strict == 0 & college == 1 ~ "Working, College",
    class_strict == 1 & college == 0 ~ "Middle, No College",
    class_strict == 1 & college == 1 ~ "Middle, College",
    TRUE ~ NA_character_
  )) %>%
  mutate(behavior = case_when(
    cond2_factor == "Baseline" & diff == 0 ~ "Stay",
    cond2_factor == "Baseline" & diff != 0 ~ NA_character_,
    cond2_factor %in% c("Class & Taste/Like/-Status", "Class & Taste/Like/+Status", "Taste Only/Like") & diff == 0 ~ "Stay",
    cond2_factor %in% c("Class & Taste/Like/-Status", "Class & Taste/Like/+Status", "Taste Only/Like") & diff > 0 ~ "Conform",
    cond2_factor %in% c("Class & Taste/Like/-Status", "Class & Taste/Like/+Status", "Taste Only/Like") & diff < 0 ~ "React",
    cond2_factor %in% c("Class & Taste/Dislike/-Status", "Class & Taste/Dislike/+Status", "Taste Only/Dislike") & diff == 0 ~ "Stay",
    cond2_factor %in% c("Class & Taste/Dislike/-Status", "Class & Taste/Dislike/+Status", "Taste Only/Dislike") & diff < 0 ~ "Conform",
    cond2_factor %in% c("Class & Taste/Dislike/-Status", "Class & Taste/Dislike/+Status", "Taste Only/Dislike") & diff > 0 ~ "React",
    TRUE ~ NA_character_
  )) %>%
  filter(!is.na(behavior))

class_rob_rates <- class_rob %>%
  group_by(quad) %>%
  summarise(
    n = n(),
    stay = round(100 * mean(behavior == "Stay"), 1),
    conform = round(100 * mean(behavior == "Conform"), 1),
    react = round(100 * mean(behavior == "React"), 1),
    .groups = "drop"
  )
saveRDS(list(rates = class_rob_rates, n = nrow(class_rob)), "tables/class_robustness.rds")
cat("Class-robustness (percclass 2/3 only, N =", nrow(class_rob), ") rates:\n")
print(class_rob_rates)
cat("Saved tables/mde_results.rds, tables/descriptives.rds, tables/class_robustness.rds\n")
