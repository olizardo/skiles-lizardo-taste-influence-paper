# R/sensitivity_analysis.R
# Sensitivity analysis: Dropping "Taste Only" conditions to isolate the effect of class feedback

library(lme4)
library(dplyr)
library(marginaleffects)
library(ggplot2)
library(nnet)

source("R/dataproc.R")
data_list <- process_data()
df_long <- data_list$long
df_wide <- data_list$wide

cat("===============================================================\n")
cat("Sensitivity Analysis: Dropping 'Taste Only' Conditions\n")
cat("===============================================================\n")

# Filter data to exclude 'Taste Only' conditions (cond2 levels 6 and 7)
# Baseline is level 5.
df_long_sens <- df_long %>%
  filter(!cond2_factor %in% c("Taste Only/Like", "Taste Only/Dislike")) %>%
  mutate(cond2_factor = droplevels(cond2_factor))

df_wide_sens <- df_wide %>%
  filter(!cond2_factor %in% c("Taste Only/Like", "Taste Only/Dislike")) %>%
  mutate(cond2_factor = droplevels(cond2_factor))

cat("Rows in long dataset after dropping 'Taste Only':", nrow(df_long_sens), "\n")

# 1. Linear Mixed Model
mod_sens <- lmer(taste ~ factor(trial) * cond2_factor + (1 | id), data = df_long_sens, REML = FALSE)

cat("\nTrial Effects by Condition (Sensitivity Subset):\n")
te_sens <- avg_comparisons(mod_sens, variables = "trial", by = "cond2_factor")
print(te_sens)

fig_sens_te <- ggplot(te_sens, aes(x = cond2_factor, y = estimate)) +
  geom_bar(stat = "identity", fill = "gold", color = "black", width = 0.5) +
  geom_errorbar(aes(ymin = conf.low, ymax = conf.high), width = 0.2, color = "red", linewidth = 1) +
  geom_hline(yintercept = 0, linetype = "solid", color = "black") +
  labs(title = "Treatment Effect (No 'Taste Only' Conditions)",
       x = "", y = "Effect Size") +
  theme_minimal(base_size = 14) +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

ggsave("figures/Figure10_Sens_TrialEffects.png", fig_sens_te, width = 8, height = 6)

# 2. Multinomial Behavior Model
df_multi_sens <- df_wide_sens %>%
  mutate(
    diff = taste2_rev - taste1_rev,
    behavior = case_when(
      cond2_factor == "Baseline" & diff == 0 ~ "Stay",
      cond2_factor == "Baseline" & diff > 0 ~ "Shift Up",
      cond2_factor == "Baseline" & diff < 0 ~ "Shift Down",
      cond2_factor %in% c("Class & Taste/Like/-Status", "Class & Taste/Like/+Status") & diff == 0 ~ "Stay",
      cond2_factor %in% c("Class & Taste/Like/-Status", "Class & Taste/Like/+Status") & diff > 0 ~ "Conform",
      cond2_factor %in% c("Class & Taste/Like/-Status", "Class & Taste/Like/+Status") & diff < 0 ~ "React",
      cond2_factor %in% c("Class & Taste/Dislike/-Status", "Class & Taste/Dislike/+Status") & diff == 0 ~ "Stay",
      cond2_factor %in% c("Class & Taste/Dislike/-Status", "Class & Taste/Dislike/+Status") & diff < 0 ~ "Conform",
      cond2_factor %in% c("Class & Taste/Dislike/-Status", "Class & Taste/Dislike/+Status") & diff > 0 ~ "React",
      TRUE ~ NA_character_
    )
  ) %>%
  filter(behavior %in% c("Stay", "Conform", "React")) %>%
  mutate(behavior = factor(behavior, levels = c("Stay", "Conform", "React")))

multi_mod_sens <- multinom(behavior ~ objsubjclass_factor, data = df_multi_sens, trace = FALSE)

multi_preds_sens <- predictions(multi_mod_sens, type = "probs", by = c("objsubjclass_factor", "group"))

fig_sens_multi <- ggplot(multi_preds_sens, aes(x = objsubjclass_factor, y = estimate, fill = group)) +
  geom_bar(stat = "identity", position = "dodge", color = "black") +
  scale_fill_manual(values = c("Stay" = "gold", "Conform" = "steelblue", "React" = "firebrick")) +
  labs(title = "Behavioral Response (No 'Taste Only' Conditions)",
       x = "Status Consistency", y = "Predicted Probability", fill = "Behavior") +
  theme_minimal(base_size = 14) +
  theme(legend.position = "bottom", axis.text.x = element_text(angle = 45, hjust = 1))

ggsave("figures/Figure11_Sens_MultinomialBehavior.png", fig_sens_multi, width = 8, height = 6)

cat("\nSensitivity analysis completed. Figures 10 and 11 generated in figures/ directory.\n")
