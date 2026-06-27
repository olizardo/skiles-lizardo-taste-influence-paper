# R/advanced_models.R
# Explores advanced analytical strategies: 
# 1. Multinomial Logit for Conformity vs Reactance

library(nnet)
library(dplyr)
library(ggplot2)
library(marginaleffects)

source("R/dataproc.R")
data_list <- process_data()
df_long <- data_list$long
df_wide <- data_list$wide

cat("\n=============================================\n")
cat("1. Multinomial Logit Model for Conformity vs Reactance\n")
cat("=============================================\n")

# Define Conform, React, and Stay behaviors
# Cond 1, 2, 6: Alter Likes (Conform = diff > 0, React = diff < 0)
# Cond 3, 4, 7: Alter Dislikes (Conform = diff < 0, React = diff > 0)
# diff = taste2_rev - taste1_rev 
df_wide <- df_wide %>%
  mutate(
    diff = taste2_rev - taste1_rev,
    behavior = case_when(
      # Baseline (no alter evaluation)
      cond2_factor == "Baseline" & diff == 0 ~ "Stay",
      cond2_factor == "Baseline" & diff > 0 ~ "Shift Up",
      cond2_factor == "Baseline" & diff < 0 ~ "Shift Down",
      
      # Alter Likes conditions
      cond2_factor %in% c("Class & Taste/Like/-Status", "Class & Taste/Like/+Status", "Taste Only/Like") & diff == 0 ~ "Stay",
      cond2_factor %in% c("Class & Taste/Like/-Status", "Class & Taste/Like/+Status", "Taste Only/Like") & diff > 0 ~ "Conform",
      cond2_factor %in% c("Class & Taste/Like/-Status", "Class & Taste/Like/+Status", "Taste Only/Like") & diff < 0 ~ "React",
      
      # Alter Dislikes conditions
      cond2_factor %in% c("Class & Taste/Dislike/-Status", "Class & Taste/Dislike/+Status", "Taste Only/Dislike") & diff == 0 ~ "Stay",
      cond2_factor %in% c("Class & Taste/Dislike/-Status", "Class & Taste/Dislike/+Status", "Taste Only/Dislike") & diff < 0 ~ "Conform",
      cond2_factor %in% c("Class & Taste/Dislike/-Status", "Class & Taste/Dislike/+Status", "Taste Only/Dislike") & diff > 0 ~ "React",
      
      TRUE ~ NA_character_
    )
  )

# Keep only the experimental groups where we can define Conform vs React
df_multi <- df_wide %>%
  filter(behavior %in% c("Stay", "Conform", "React")) %>%
  mutate(behavior = factor(behavior, levels = c("Stay", "Conform", "React")))

# Multinomial logit for status consistency predicting behavior
cat("Fitting Multinomial Logit Model...\n")
multi_mod <- multinom(behavior ~ objsubjclass_factor, data = df_multi, trace = FALSE)
print(summary(multi_mod))

cat("\nPredicted Probabilities of Behaviors by Status Group:\n")
multi_preds <- predictions(multi_mod, type = "probs", by = c("objsubjclass_factor", "group"))
print(multi_preds)

# Save the predictions plot
fig_multi <- ggplot(multi_preds, aes(x = objsubjclass_factor, y = estimate, fill = group)) +
  geom_bar(stat = "identity", position = "dodge", color = "black") +
  scale_fill_manual(values = c("Stay" = "gold", "Conform" = "steelblue", "React" = "firebrick")) +
  labs(title = "Probability of Behavioral Response by Status Group",
       x = "Status Consistency", y = "Predicted Probability", fill = "Behavior") +
  theme_minimal() +
  theme(legend.position = "bottom", axis.text.x = element_text(angle = 45, hjust = 1))

ggsave("figures/Figure7_MultinomialBehavior.png", fig_multi, width = 8, height = 6)
cat("\nAdvanced models run successfully. Figure 7 saved to figures/\n")
