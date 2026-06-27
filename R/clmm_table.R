library(ordinal)
library(lme4)
library(dplyr)
library(modelsummary)
library(WeightIt)

suppressPackageStartupMessages({
  source("R/dataproc.R")
})
data_list <- process_data()
df_wide <- data_list$wide
df_long <- data_list$long

df_wide_cc <- df_wide %>%
  filter(!is.na(objsubjclass_factor), 
         !is.na(age), !is.na(female), !is.na(raceeth), !is.na(parented))

W <- weightit(objsubjclass_factor ~ age + female + factor(raceeth) + parented, 
              data = df_wide_cc, method = "ps", estimand = "ATE")
df_wide_cc$ipw_weight <- W$weights

df_long_wt <- df_long %>%
  inner_join(df_wide_cc %>% select(id, ipw_weight), by = "id")

df_long_wt$taste_ord <- factor(df_long_wt$taste, ordered = TRUE, levels = 1:7)

cat("Fitting LMER...\n")
mod_lmer <- lmer(taste ~ factor(trial) * cond2_factor + (1 | id), data = df_long_wt, weights = ipw_weight, REML = FALSE)

cat("Fitting CLMM...\n")
mod_clmm <- clmm(taste_ord ~ factor(trial) * cond2_factor + (1 | id), data = df_long_wt, weights = ipw_weight)

cat("Generating table...\n")
models <- list("Linear Mixed Model" = mod_lmer, "Cumulative Link Mixed Model" = mod_clmm)

cm <- c(
  "factor(trial)2" = "Trial 2 (Baseline Drift)",
  "factor(trial)2:cond2_factorClass & Taste/Like/-Status" = "Trial 2 x Like/-Status",
  "factor(trial)2:cond2_factorClass & Taste/Like/+Status" = "Trial 2 x Like/+Status",
  "factor(trial)2:cond2_factorClass & Taste/Dislike/-Status" = "Trial 2 x Dislike/-Status",
  "factor(trial)2:cond2_factorClass & Taste/Dislike/+Status" = "Trial 2 x Dislike/+Status",
  "factor(trial)2:cond2_factorTaste Only/Like" = "Trial 2 x Taste Only (Like)",
  "factor(trial)2:cond2_factorTaste Only/Dislike" = "Trial 2 x Taste Only (Dislike)"
)

# Use LaTeX format specifically tailored for the manuscript
modelsummary(models, 
             output = "tables/clmm_robustness.tex", 
             coef_map = cm,
             stars = TRUE,
             gof_omit = "AIC|BIC|Log|F|RMSE",
             title = "Comparison of Linear and Ordinal Mixed Models (IPW Weighted)")
cat("Done.\n")
