# R/generate_figure_baseline_influence.R
# Publication-grade figure for Section 3.1: Baseline Exposure Drift and Generalized Influence
# Paper: "Stay, React, or Conform? Examining Social Influence Effects on Aesthetic Judgments"
# Note: Revised to display standalone DiD Treatment Effects (eliminating trajectory panel)

library(ggplot2)
library(dplyr)

source("R/dataproc.R")
source("R/did_models.R")

# 1. Prepare 3-condition weighted data
df_wide_cc$diff <- df_wide_cc$taste2_rev - df_wide_cc$taste1_rev

# Filter to 3 conditions: Baseline (Control), Taste Only/Like, Taste Only/Dislike
df_3cond_wide <- df_wide_cc %>%
  filter(cond2_factor %in% c("Baseline", "Taste Only/Like", "Taste Only/Dislike")) %>%
  mutate(
    cond3 = factor(cond2_factor, levels = c("Baseline", "Taste Only/Like", "Taste Only/Dislike"),
                   labels = c("Control Condition", "Generalized Like", "Generalized Dislike"))
  )

sig_palette <- c(
  "p < 0.05"        = "firebrick",
  "p < 0.10"        = "darkorange2",
  "Not Significant" = "grey70"
)

theme_pub <- theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold", size = 12, hjust = 0),
    plot.subtitle = element_text(size = 10, color = "grey30", margin = margin(b = 8)),
    axis.title = element_text(face = "bold", size = 11),
    axis.text = element_text(size = 10),
    panel.grid.minor = element_blank(),
    panel.border = element_rect(color = "grey80", fill = NA, linewidth = 0.5),
    legend.position = "bottom",
    legend.title = element_text(face = "bold", size = 10),
    axis.text.y = element_text(face = "bold", size = 10.5)
  )

# Difference-in-Differences Treatment Effects
mod_3cond <- lm(diff ~ cond3, data = df_3cond_wide, weights = ipw_weight)
coefs <- summary(mod_3cond)$coefficients

df_did <- data.frame(
  Condition = factor(c("Generalized Like", "Generalized Dislike"),
                     levels = c("Generalized Dislike", "Generalized Like")),
  estimate = c(coefs["cond3Generalized Like", "Estimate"],
               coefs["cond3Generalized Dislike", "Estimate"]),
  std.error = c(coefs["cond3Generalized Like", "Std. Error"],
                coefs["cond3Generalized Dislike", "Std. Error"]),
  p.value = c(coefs["cond3Generalized Like", "Pr(>|t|)"],
              coefs["cond3Generalized Dislike", "Pr(>|t|)"])
) %>%
  mutate(
    conf.low = estimate - 1.96 * std.error,
    conf.high = estimate + 1.96 * std.error,
    sig = case_when(
      p.value < 0.05 ~ "p < 0.05",
      p.value < 0.10 ~ "p < 0.10",
      TRUE ~ "Not Significant"
    ),
    sig = factor(sig, levels = c("p < 0.05", "p < 0.10", "Not Significant"))
  )

p_did <- ggplot(df_did, aes(x = estimate, y = Condition, fill = sig, color = sig)) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "grey40", linewidth = 0.6) +
  geom_col(width = 0.50, alpha = 0.85, color = NA) +
  geom_errorbar(aes(xmin = conf.low, xmax = conf.high), width = 0.22, linewidth = 0.75) +
  scale_fill_manual(name = "Significance", values = sig_palette, limits = names(sig_palette), drop = FALSE) +
  scale_color_manual(name = "Significance", values = sig_palette, limits = names(sig_palette), drop = FALSE) +
  scale_x_continuous(
    limits = c(-0.38, 0.38),
    breaks = seq(-0.3, 0.3, by = 0.1),
    labels = c("-0.3", "-0.2", "-0.1", "0.0", "+0.1", "+0.2", "+0.3")
  ) +
  labs(
    title = "Difference-in-Differences Treatment Effects: Generalized Influence",
    subtitle = "Relative to Control Condition exposure drift (95% CI, net of mere exposure)",
    x = "DiD Treatment Effect (Change Score vs. Control)",
    y = ""
  ) +
  theme_pub

ggsave("figures/Figure_DiD_Baseline_Influence.png", p_did, width = 7.5, height = 3.6, dpi = 300)
ggsave("figures/Figure_DiD_Baseline_Influence.pdf", p_did, width = 7.5, height = 3.6)
cat("Figure_DiD_Baseline_Influence saved successfully (standalone panel).\n")
