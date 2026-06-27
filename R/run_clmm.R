suppressMessages({
  library(haven)
  library(dplyr)
  library(ordinal)
  library(WeightIt)
})

source("R/dataproc.R")
data_list <- process_data()
df_wide <- data_list$wide
df_long <- data_list$long

df_wide_cc <- df_wide %>%
  filter(!is.na(objsubjclass_factor), !is.na(age), !is.na(female), !is.na(raceeth), !is.na(parented))

W <- weightit(objsubjclass_factor ~ age + female + factor(raceeth) + parented, 
              data = df_wide_cc, method = "ps", estimand = "ATE")
df_wide_cc$ipw_weight <- W$weights

df_long_wt <- df_long %>%
  inner_join(df_wide_cc %>% select(id, ipw_weight), by = "id")

df_long_wt$taste_ord <- factor(df_long_wt$taste, ordered = TRUE, levels = 1:7)

mod_clmm <- clmm(taste_ord ~ factor(trial) * cond2_factor + (1 | id), data = df_long_wt, weights = ipw_weight)
summ <- summary(mod_clmm)

print(round(summ$coefficients, 3))
saveRDS(summ$coefficients, "clmm_coefs.rds")
