# R/propensity_models.R
# Implements Propensity Score Weighting to balance strictly exogenous covariates across status groups

library(WeightIt)
library(cobalt)
library(dplyr)
library(ggplot2)
library(lme4)
library(marginaleffects)
library(nnet)

source("R/dataproc.R")
data_list <- process_data()
df_wide <- data_list$wide
df_long <- data_list$long

cat("===================================================\n")
cat("1. Estimating Propensity Scores & Balancing Weights\n")
cat("===================================================\n")

# Select strictly exogenous pre-treatment baseline covariates: age, gender, race/ethnicity, and parents' education
df_wide_cc <- df_wide %>%
  filter(!is.na(objsubjclass_factor), 
         !is.na(age), !is.na(female), !is.na(raceeth), !is.na(parented))

cat("Complete cases for weighting:", nrow(df_wide_cc), "out of", nrow(df_wide), "\n")

# Multinomial propensity weighting across the 4 status consistency quadrants
# Estimand is ATE (Average Treatment Effect) to balance all groups to the full population profile
W <- weightit(objsubjclass_factor ~ age + female + factor(raceeth) + parented, 
              data = df_wide_cc, 
              method = "ps", 
              estimand = "ATE")

# Merge weights back into the wide dataset
df_wide_cc$ipw_weight <- W$weights

# Generate and save Love Plot to check balance
fig_balance <- love.plot(W, 
                         binary = "std", 
                         thresholds = c(m = .1), 
                         var.order = "unadjusted",
                         title = "Covariate Balance Across Status Groups Before and After IPW Weighting") +
  theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold", size = 12, hjust = 0),
    legend.position = "bottom"
  )
ggsave("figures/Figure8_CovariateBalance.png", fig_balance, width = 8.5, height = 6.0, dpi = 300)
ggsave("figures/Figure8_CovariateBalance.pdf", fig_balance, width = 8.5, height = 6.0)
cat("Balance plot saved to figures/Figure8_CovariateBalance.png and .pdf\n")

cat("\n===================================================\n")
cat("2. Re-estimating the Trial Effect Models with Weights\n")
cat("===================================================\n")

# Transfer weights to the long format data for mixed modeling
df_long_wt <- df_long %>%
  inner_join(df_wide_cc %>% select(id, ipw_weight), by = "id")

# Fit the weighted linear mixed model (Model 3)
mod3_wt <- lmer(taste ~ factor(trial) * cond2_factor + (1 | id), 
                data = df_long_wt, 
                weights = ipw_weight,
                REML = FALSE)

# Compare to unweighted model
mod3_unwt <- lmer(taste ~ factor(trial) * cond2_factor + (1 | id), 
                  data = df_long_wt, REML = FALSE)

models_compare <- list("Unweighted" = mod3_unwt, "IPW Weighted" = mod3_wt)
saveRDS(models_compare, "tables/propensity_weighted_models.rds")

cat("\n===================================================\n")
cat("3. Re-estimating the Multinomial Behavior Model\n")
cat("===================================================\n")

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

# Weighted multinomial model
multi_mod_wt <- multinom(behavior ~ objsubjclass_factor, 
                         data = df_multi_wt, 
                         weights = ipw_weight, 
                         trace = FALSE)

# Generate predictions using the weighted model
multi_preds_wt <- predictions(multi_mod_wt, type = "probs", by = c("objsubjclass_factor", "group"))

fig_multi_wt <- ggplot(multi_preds_wt, aes(x = objsubjclass_factor, y = estimate, fill = group)) +
  geom_bar(stat = "identity", position = "dodge", color = "black") +
  scale_fill_manual(values = c("Stay" = "gold", "Conform" = "steelblue", "React" = "firebrick")) +
  labs(title = "IPW Weighted Probability of Behavioral Response",
       x = "Status Consistency", y = "Predicted Probability", fill = "Behavior") +
  theme_minimal(base_size = 14) +
  theme(legend.position = "bottom", axis.text.x = element_text(angle = 45, hjust = 1))

ggsave("figures/Figure9_WeightedMultinomialBehavior.png", fig_multi_wt, width = 8, height = 6)
cat("Weighted multinomial predictions saved to figures/Figure9_WeightedMultinomialBehavior.png\n")

cat("\nPropensity pipeline execution complete.\n")
