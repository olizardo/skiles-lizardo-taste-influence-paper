# R/visualization.R
# Recreates Figures 2-6 from Draft 2 & 3 using ggplot2 and marginaleffects

library(lme4)
library(dplyr)
library(ggplot2)
library(marginaleffects)

# Load data and processed models
source("R/dataproc.R")
data_list <- process_data()
df_long <- data_list$long
df_wide <- data_list$wide

# Set custom theme for publication-ready plots
theme_paper <- theme_minimal(base_size = 14) +
  theme(
    plot.title = element_text(hjust = 0.5, face = "bold"),
    axis.text.x = element_text(angle = 45, hjust = 1, size = 11),
    panel.grid.major.x = element_blank(),
    panel.border = element_rect(color = "black", fill = NA, linewidth = 0.5),
    legend.position = "none"
  )

cat("Generating Figure 2: Trial Effects across Conditions (All Respondents)\n")
mod_full <- lmer(taste ~ factor(trial) * cond2_factor + (1 | id), data = df_long, REML = FALSE)
te_full <- avg_comparisons(mod_full, variables = "trial", by = "cond2_factor")

fig2 <- ggplot(te_full, aes(x = cond2_factor, y = estimate)) +
  geom_bar(stat = "identity", fill = "gold", color = "black", width = 0.5) +
  geom_errorbar(aes(ymin = conf.low, ymax = conf.high), width = 0.2, color = "red", linewidth = 1) +
  geom_hline(yintercept = 0, linetype = "solid", color = "black") +
  labs(title = "Within-Subject Treatment Effect",
       x = "", y = "Effect Size") +
  theme_paper

ggsave("figures/Figure2_TrialEffects_All.png", fig2, width = 8, height = 6)
ggsave("figures/Figure2_TrialEffects_All.pdf", fig2, width = 8, height = 6)


cat("Generating Figure 3: Trial Effects by Education\n")
mod_col <- lmer(taste ~ factor(trial) * cond2_factor + (1 | id), data = filter(df_long, college == 1), REML = FALSE)
mod_ncol <- lmer(taste ~ factor(trial) * cond2_factor + (1 | id), data = filter(df_long, college == 0), REML = FALSE)
te_col <- avg_comparisons(mod_col, variables = "trial", by = "cond2_factor") %>% mutate(Group = "College")
te_ncol <- avg_comparisons(mod_ncol, variables = "trial", by = "cond2_factor") %>% mutate(Group = "No College")

te_edu <- bind_rows(te_ncol, te_col) %>%
  mutate(Group = factor(Group, levels = c("No College", "College")))

fig3 <- ggplot(te_edu, aes(x = cond2_factor, y = estimate)) +
  geom_bar(stat = "identity", fill = "gold", color = "black", width = 0.5) +
  geom_errorbar(aes(ymin = conf.low, ymax = conf.high), width = 0.2, color = "red", linewidth = 1) +
  geom_hline(yintercept = 0, linetype = "solid", color = "black") +
  facet_wrap(~Group, ncol = 2) +
  labs(title = "Within-Subject Treatment Effect by Education",
       x = "", y = "Effect Size") +
  theme_paper

ggsave("figures/Figure3_TrialEffects_Education.png", fig3, width = 12, height = 6)


cat("Generating Figure 4: Trial Effects by Class\n")
mod_mid <- lmer(taste ~ factor(trial) * cond2_factor + (1 | id), data = filter(df_long, class == 1), REML = FALSE)
mod_work <- lmer(taste ~ factor(trial) * cond2_factor + (1 | id), data = filter(df_long, class == 0), REML = FALSE)
te_mid <- avg_comparisons(mod_mid, variables = "trial", by = "cond2_factor") %>% mutate(Group = "Middle Class")
te_work <- avg_comparisons(mod_work, variables = "trial", by = "cond2_factor") %>% mutate(Group = "Working Class")

te_class <- bind_rows(te_work, te_mid) %>%
  mutate(Group = factor(Group, levels = c("Working Class", "Middle Class")))

fig4 <- ggplot(te_class, aes(x = cond2_factor, y = estimate)) +
  geom_bar(stat = "identity", fill = "gold", color = "black", width = 0.5) +
  geom_errorbar(aes(ymin = conf.low, ymax = conf.high), width = 0.2, color = "red", linewidth = 1) +
  geom_hline(yintercept = 0, linetype = "solid", color = "black") +
  facet_wrap(~Group, ncol = 2) +
  labs(title = "Within-Subject Treatment Effect by Class",
       x = "", y = "Effect Size") +
  theme_paper

ggsave("figures/Figure4_TrialEffects_Class.png", fig4, width = 12, height = 6)


cat("Generating Figure 5: Trial Effects by Objective/Subjective Status\n")
mod_objsubj <- lmer(taste ~ factor(trial) * cond2_factor * objsubjclass_factor + (1 | id), data = df_long, REML = FALSE)
te_objsubj <- avg_comparisons(mod_objsubj, variables = "trial", by = c("cond2_factor", "objsubjclass_factor"))

fig5 <- ggplot(te_objsubj, aes(x = cond2_factor, y = estimate)) +
  geom_bar(stat = "identity", fill = "gold", color = "black", width = 0.5) +
  geom_errorbar(aes(ymin = conf.low, ymax = conf.high), width = 0.2, color = "red", linewidth = 1) +
  geom_hline(yintercept = 0, linetype = "solid", color = "black") +
  facet_wrap(~objsubjclass_factor, ncol = 2) +
  labs(title = "Within-Subject Treatment Effect by Status Consistency",
       x = "", y = "Effect Size") +
  theme_paper

ggsave("figures/Figure5_TrialEffects_ObjSubj.png", fig5, width = 12, height = 10)


cat("Generating Figure 6: Probability of 'Stay' by Objective/Subjective Status\n")
# Filter out condition 7 (Taste Only Dislike) as per original stay-analysis.do
df_stay <- df_wide %>% filter(cond != 7)

# Logistic regression for 'stay'
mod_stay <- glm(stay ~ objsubjclass_factor, family = binomial(link = "logit"), data = df_stay)
stay_preds <- predictions(mod_stay, variables = "objsubjclass_factor")

avg_stay <- mean(df_stay$stay, na.rm = TRUE)

fig6 <- ggplot(stay_preds, aes(x = objsubjclass_factor, y = estimate)) +
  geom_bar(stat = "identity", fill = "gold", color = "black", width = 0.4) +
  geom_errorbar(aes(ymin = conf.low, ymax = conf.high), width = 0.1, color = "red", linewidth = 1) +
  geom_hline(yintercept = avg_stay, linetype = "dashed", color = "gray50") +
  scale_y_continuous(limits = c(0.6, 0.9), oob = scales::rescale_none) +
  labs(title = "Probability of Staying by Status Group",
       x = "", y = "Predicted Probability of 'Stay'") +
  theme_paper +
  annotate("text", x = 1.5, y = avg_stay + 0.01, label = "Average Stay Probability", color = "gray30", size = 4)

ggsave("figures/Figure6_StayProbability.png", fig6, width = 8, height = 6)

cat("Visualizations completed and saved to figures/ directory.\n")
