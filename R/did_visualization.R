# R/did_visualization.R
# Publication-ready visualizations for the Difference-in-Differences (DiD) models

library(ggplot2)
library(dplyr)
library(marginaleffects)

source("R/did_models.R")

theme_paper <- theme_minimal(base_size = 13) +
  theme(
    plot.title = element_text(face = "bold", size = 14, hjust = 0.5),
    plot.subtitle = element_text(size = 11, hjust = 0.5, margin = margin(b = 10)),
    axis.title = element_text(face = "bold"),
    axis.text.y = element_text(size = 10),
    panel.grid.minor = element_blank(),
    panel.border = element_rect(color = "grey70", fill = NA, linewidth = 0.5),
    strip.text = element_text(face = "bold", size = 11),
    strip.background = element_rect(fill = "grey95", color = "grey70")
  )

# 1. Pooled DiD Forest Plot
# Extract coefficients and CIs for the DiD interaction terms from IPW model
did_coefs <- summary(mod_did_wt)$coefficients
did_terms <- grep("factor\\(trial\\)2:cond2_refctrl", rownames(did_coefs), value = TRUE)

df_plot_pooled <- data.frame(
  term = did_terms,
  estimate = did_coefs[did_terms, "Estimate"],
  std.error = did_coefs[did_terms, "Std. Error"]
) %>%
  mutate(
    conf.low = estimate - 1.96 * std.error,
    conf.high = estimate + 1.96 * std.error,
    condition = gsub("factor\\(trial\\)2:cond2_refctrl", "", term),
    condition = factor(condition, levels = rev(c(
      "Taste Only/Like",
      "Taste Only/Dislike",
      "Class & Taste/Like/+Status",
      "Class & Taste/Like/-Status",
      "Class & Taste/Dislike/+Status",
      "Class & Taste/Dislike/-Status"
    )))
  )

p_pooled <- ggplot(df_plot_pooled, aes(x = estimate, y = condition)) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "grey40", linewidth = 0.8) +
  geom_errorbarh(aes(xmin = conf.low, xmax = conf.high), height = 0.25, color = "navy", linewidth = 0.9) +
  geom_point(size = 3.5, color = "navy", fill = "white", shape = 21, stroke = 1.2) +
  labs(
    title = "Causal Difference-in-Differences Treatment Effects",
    subtitle = "Relative to Control Condition (Net of Exposure Drift)",
    x = "DiD Treatment Effect (Change in Treatment - Change in Control)",
    y = ""
  ) +
  theme_paper

ggsave("figures/Figure_DiD_Forest_Pooled.png", p_pooled, width = 8.5, height = 5.5, dpi = 300)
ggsave("figures/Figure_DiD_Forest_Pooled.pdf", p_pooled, width = 8.5, height = 5.5)
cat("Pooled DiD Forest Plot saved to figures/Figure_DiD_Forest_Pooled.png\n")

# 2. Status Consistency DiD Forest Plot
# Using res_did_status from did_models.R
df_plot_status <- res_did_status %>%
  mutate(
    condition = gsub(" - Baseline", "", contrast),
    conf.low = estimate - 1.96 * std.error,
    conf.high = estimate + 1.96 * std.error,
    condition = factor(condition, levels = rev(c(
      "Taste Only/Like",
      "Taste Only/Dislike",
      "Class & Taste/Like/+Status",
      "Class & Taste/Like/-Status",
      "Class & Taste/Dislike/+Status",
      "Class & Taste/Dislike/-Status"
    )))
  )

p_status <- ggplot(df_plot_status, aes(x = estimate, y = condition)) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "grey40", linewidth = 0.8) +
  geom_errorbarh(aes(xmin = conf.low, xmax = conf.high), height = 0.25, color = "darkred", linewidth = 0.8) +
  geom_point(size = 3, color = "darkred", fill = "white", shape = 21, stroke = 1.1) +
  facet_wrap(~objsubjclass_factor, ncol = 2) +
  labs(
    title = "Difference-in-Differences Treatment Effects by Status Consistency",
    subtitle = "Estimates Net of Exposure Drift in Unexposed Control Condition",
    x = "DiD Treatment Effect (Change in Treatment - Change in Control)",
    y = ""
  ) +
  theme_paper

ggsave("figures/Figure_DiD_Forest_Status.png", p_status, width = 11, height = 8, dpi = 300)
ggsave("figures/Figure_DiD_Forest_Status.pdf", p_status, width = 11, height = 8)
cat("Status DiD Forest Plot saved to figures/Figure_DiD_Forest_Status.png\n")
