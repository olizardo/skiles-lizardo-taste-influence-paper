suppressMessages({
  library(haven)
  library(dplyr)
  library(tidyr)
  library(lme4)
  library(nnet)
  library(WeightIt)
  library(marginaleffects)
})

# Reuse process_data but override class definition
source("R/dataproc.R")
df <- read_dta("/home/omarlizardo/ACADEMIC AND COURSE MATERIALS/SSI-2012/data/clean/ssi2012_cleaned.dta")

df_clean <- df %>%
  filter(!is.na(taste1), !is.na(taste2), percclass %in% c(2, 3)) %>%
  mutate(
    taste1_rev = 8 - taste1,
    taste2_rev = 8 - taste2,
    change = as.numeric(taste1_rev != taste2_rev),
    like1 = as.numeric(taste1_rev >= 6),
    like2 = as.numeric(taste2_rev >= 6),
    control2 = if_else(control %in% c(0, 1), 1, 0),
    control_new = control + 1,
    altertaste_new = altertaste + 1,
    alterclass_new = alterclass + 1,
    cond = case_when(
      control_new == 1 & altertaste_new == 2 & alterclass_new == 2 ~ 1,
      control_new == 1 & altertaste_new == 2 & alterclass_new == 3 ~ 2,
      control_new == 1 & altertaste_new == 2 & alterclass_new == 4 ~ 3,
      control_new == 1 & altertaste_new == 3 & alterclass_new == 2 ~ 4,
      control_new == 1 & altertaste_new == 3 & alterclass_new == 3 ~ 5,
      control_new == 1 & altertaste_new == 3 & alterclass_new == 4 ~ 6,
      control_new == 2 & altertaste_new == 1 & alterclass_new == 1 ~ 7,
      control_new == 3 & altertaste_new == 2 & alterclass_new == 1 ~ 8,
      control_new == 3 & altertaste_new == 3 & alterclass_new == 1 ~ 9,
      TRUE ~ NA_real_
    ),
    cond2 = case_match(
      cond,
      1 ~ 1, c(2, 3) ~ 2, 4 ~ 3, c(5, 6) ~ 4, 7 ~ 5, 8 ~ 6, 9 ~ 7
    ),
    class = if_else(percclass == 2, 0, 1),
    college = if_else(bach == 1 | ma == 1 | docprof == 1, 1, 0),
    objsubjclass = case_when(
      class == 0 & college == 0 ~ 1,
      class == 0 & college == 1 ~ 2,
      class == 1 & college == 0 ~ 3,
      class == 1 & college == 1 ~ 4,
      TRUE ~ NA_real_
    )
  )

cond2_labels <- c(
  "Class & Taste/Like/-Status",
  "Class & Taste/Like/+Status",
  "Class & Taste/Dislike/-Status",
  "Class & Taste/Dislike/+Status",
  "Baseline",
  "Taste Only/Like",
  "Taste Only/Dislike"
)
df_clean$cond2_factor <- factor(df_clean$cond2, levels = 1:7, labels = cond2_labels)

objsubj_labels <- c("Working, No College", "Working, College", "Middle, No College", "Middle, College")
df_clean$objsubjclass_factor <- factor(df_clean$objsubjclass, levels = 1:4, labels = objsubj_labels)

# Clean for weighting
df_wide_cc <- df_clean %>%
  filter(!is.na(objsubjclass_factor), !is.na(age), !is.na(female), !is.na(raceeth), !is.na(parented))

W <- weightit(objsubjclass_factor ~ age + female + factor(raceeth) + parented, 
              data = df_wide_cc, method = "ps", estimand = "ATE")
df_wide_cc$ipw_weight <- W$weights

df_long <- df_clean %>%
  pivot_longer(cols = c(taste1_rev, taste2_rev), names_to = "trial_name", values_to = "taste") %>%
  mutate(trial = if_else(trial_name == "taste1_rev", 1, 2)) %>%
  inner_join(df_wide_cc %>% select(id, ipw_weight), by = "id")

cat("--- Linear Mixed Model (Robustness) ---\n")
mod_lmer <- lmer(taste ~ factor(trial) * cond2_factor + (1 | id), data = df_long, weights = ipw_weight, REML = FALSE)
# We can look at the overall interaction tests or just the marginal effects
# Let's compare the trial effects by condition
te_lmer <- avg_comparisons(mod_lmer, variables = "trial", by = "cond2_factor")
print(te_lmer)

cat("\n--- Multinomial Behavior Model (Robustness) ---\n")
df_multi_wt <- df_wide_cc %>%
  mutate(
    diff = taste2_rev - taste1_rev,
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
  ) %>%
  filter(behavior %in% c("Stay", "Conform", "React")) %>%
  mutate(behavior = factor(behavior, levels = c("Stay", "Conform", "React")))

multi_mod_wt <- multinom(behavior ~ objsubjclass_factor, data = df_multi_wt, weights = ipw_weight, trace = FALSE)
multi_preds_wt <- predictions(multi_mod_wt, type = "probs", by = c("objsubjclass_factor", "group"))
print(as.data.frame(multi_preds_wt)[, c("objsubjclass_factor", "group", "estimate")])
