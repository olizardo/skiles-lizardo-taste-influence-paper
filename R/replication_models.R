# R/replication_models.R
# Replicates the model comparison and Wald tests from Draft 2 & 3

library(lme4)
library(car)
library(dplyr)
library(broom.mixed)
library(modelsummary)

# Load data
source("R/dataproc.R")
data_list <- process_data()
df_long <- data_list$long
df_wide <- data_list$wide

# 1. Model Comparisons (Table 2 in Draft 2)
# Using the 9-category condition (cond_factor) and trial (1 = Before, 2 = After)
# Models fit with ML (REML=FALSE) to compare fixed effects
mod0 <- lmer(taste ~ 1 + (1 | id), data = df_long, REML = FALSE)
mod1 <- lmer(taste ~ cond_factor + (1 | id), data = df_long, REML = FALSE)
mod2 <- lmer(taste ~ factor(trial) + cond_factor + (1 | id), data = df_long, REML = FALSE)
mod3 <- lmer(taste ~ factor(trial) * cond_factor + (1 | id), data = df_long, REML = FALSE)

# Compare model fit
model_comparison <- anova(mod0, mod1, mod2, mod3)
print("Likelihood Ratio Tests (Table 2 Replication):")
print(model_comparison)

# 2. Trial effects by condition (Table 3) using marginaleffects
library(marginaleffects)
cat("\n--- Trial Effect in each Condition (Table 3) ---\n")
trial_effects_all <- avg_comparisons(mod3, variables = "trial", by = "cond_factor")
print(trial_effects_all)

# 3. Save model summaries to tables/
# Using modelsummary to export
models <- list("Null" = mod0, "Cond" = mod1, "Cond+Trial" = mod2, "Interaction" = mod3)
modelsummary(models, output = "tables/replication_table2.html", stars = TRUE, gof_map = c("nobs", "r2.marginal", "r2.conditional", "logLik", "AIC", "BIC"))
cat("\nReplication models completed and exported to tables/replication_table2.html\n")

# 4. Subgroup analyses by Education and Class (Tables 4 & 5)
cat("\n--- Trial Effects by Education (Table 4) ---\n")
# Using cond2 (7 categories) as in the paper
mod_college <- lmer(taste ~ factor(trial) * cond2_factor + (1 | id), data = filter(df_long, college == 1), REML = FALSE)
mod_nocollege <- lmer(taste ~ factor(trial) * cond2_factor + (1 | id), data = filter(df_long, college == 0), REML = FALSE)

te_college <- avg_comparisons(mod_college, variables = "trial", by = "cond2_factor")
te_nocollege <- avg_comparisons(mod_nocollege, variables = "trial", by = "cond2_factor")
print("College:")
print(te_college)
print("No College:")
print(te_nocollege)

cat("\n--- Trial Effects by Class (Table 5) ---\n")
mod_middle <- lmer(taste ~ factor(trial) * cond2_factor + (1 | id), data = filter(df_long, class == 1), REML = FALSE)
mod_working <- lmer(taste ~ factor(trial) * cond2_factor + (1 | id), data = filter(df_long, class == 0), REML = FALSE)

te_middle <- avg_comparisons(mod_middle, variables = "trial", by = "cond2_factor")
te_working <- avg_comparisons(mod_working, variables = "trial", by = "cond2_factor")
print("Middle Class:")
print(te_middle)
print("Working Class:")
print(te_working)

