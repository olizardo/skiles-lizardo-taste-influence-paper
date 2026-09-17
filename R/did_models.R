# R/did_models.R
# Difference-in-Differences (DiD) Analysis comparing treatments to Control Condition
# Addresses Reviewer 1 (Point 1)

library(lme4)
library(dplyr)
library(WeightIt)
library(cobalt)
library(marginaleffects)

# 1. Load data
source("R/dataproc.R")
data_list <- process_data()
df_wide <- data_list$wide
df_long <- data_list$long

cat("Loaded dataset with N =", nrow(df_wide), "wide records and N =", nrow(df_long), "long records.\n")

# 2. Re-level condition factor so Control Condition ('Baseline') is the reference category
df_long$cond2_refctrl <- relevel(df_long$cond2_factor, ref = "Baseline")
df_wide$cond2_refctrl <- relevel(df_wide$cond2_factor, ref = "Baseline")

# Compute change score in wide data
df_wide$diff <- df_wide$taste2_rev - df_wide$taste1_rev

# 3. Model 1: Unweighted DiD (Pooled Sample)
cat("\n=======================================================\n")
cat("Model 1: Unweighted DiD Linear Mixed Model (Pooled)\n")
cat("=======================================================\n")
mod_did_unwt <- lmer(taste ~ factor(trial) * cond2_refctrl + (1 | id), data = df_long, REML = FALSE)
print(summary(mod_did_unwt)$coefficients)

# 4. Model 2: IPW-Weighted DiD (Pooled Sample)
cat("\n=======================================================\n")
cat("Model 2: IPW-Weighted DiD Linear Mixed Model (Pooled)\n")
cat("=======================================================\n")
df_wide_cc <- df_wide %>%
  filter(!is.na(objsubjclass_factor), 
         !is.na(age), !is.na(female), !is.na(raceeth), !is.na(parented))

W <- weightit(objsubjclass_factor ~ age + female + factor(raceeth) + parented, 
              data = df_wide_cc, 
              method = "ps", 
              estimand = "ATE")

df_wide_cc$ipw_weight <- W$weights

df_long_wt <- df_long %>%
  inner_join(df_wide_cc %>% select(id, ipw_weight), by = "id")

df_long_wt$cond2_refctrl <- relevel(df_long_wt$cond2_factor, ref = "Baseline")

mod_did_wt <- lmer(taste ~ factor(trial) * cond2_refctrl + (1 | id), 
                   data = df_long_wt, 
                   weights = ipw_weight, 
                   REML = FALSE)
print(summary(mod_did_wt)$coefficients)

# 5. Model 3: DiD Moderated by Education (College vs No College)
cat("\n=======================================================\n")
cat("Model 3: DiD Moderated by Education\n")
cat("=======================================================\n")
mod_did_edu <- lm(diff ~ cond2_refctrl * factor(college), data = df_wide)
print(summary(mod_did_edu)$coefficients)

# 6. Model 4: IPW-Weighted DiD Moderated by Status Consistency
cat("\n=======================================================\n")
cat("Model 4: IPW-Weighted DiD by Status Consistency Group\n")
cat("=======================================================\n")
df_wide_cc$diff <- df_wide_cc$taste2_rev - df_wide_cc$taste1_rev
df_wide_cc$cond2_refctrl <- relevel(df_wide_cc$cond2_factor, ref = "Baseline")

mod_diff_wt_status <- lm(diff ~ cond2_refctrl * objsubjclass_factor, data = df_wide_cc, weights = ipw_weight)

did_status_comps <- comparisons(
  mod_diff_wt_status,
  variables = "cond2_refctrl",
  by = "objsubjclass_factor"
)

res_did_status <- as.data.frame(did_status_comps)[, c("objsubjclass_factor", "contrast", "estimate", "std.error", "statistic", "p.value")]
res_did_status$estimate <- round(res_did_status$estimate, 3)
res_did_status$std.error <- round(res_did_status$std.error, 3)
res_did_status$p.value <- round(res_did_status$p.value, 4)

print(res_did_status)

# Save results to rds for table generation
saveRDS(list(
  mod_did_unwt = mod_did_unwt,
  mod_did_wt = mod_did_wt,
  mod_did_edu = mod_did_edu,
  res_did_status = res_did_status
), file = "tables/did_model_results.rds")
cat("\nDiD models estimated and saved to tables/did_model_results.rds\n")
