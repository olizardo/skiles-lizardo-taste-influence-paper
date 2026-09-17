# R/generate_figure_baseline_influence.R
# Publication-grade figure for Section 3.1: Baseline Exposure Drift and Generalized Influence
# Paper: "Stay, React, or Conform? Examining Social Influence Effects on Aesthetic Judgments"

library(ggplot2)
library(dplyr)
library(patchwork)

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

df_3cond_long <- df_long %>%
  inner_join(df_3cond_wide %>% select(id, cond3, ipw_weight), by = "id")

# Compute weighted mean and SE by condition and trial
df_traj <- df_3cond_long %>%
  group_by(cond3, trial) %>%
  summarise(
    mean_val = sum(taste * ipw_weight) / sum(ipw_weight),
    var_w = sum(ipw_weight * (taste - (sum(taste * ipw_weight) / sum(ipw_weight)))^2) / sum(ipw_weight),
    se_val = sqrt(sum(ipw_weight * (taste - (sum(taste * ipw_weight) / sum(ipw_weight)))^2) / sum(ipw_weight) / n()),
    n_obs = n(),
    .groups = "drop"
  ) %>%
  mutate(
    ci_low = mean_val - 1.96 * se_val,
    ci_high = mean_val + 1.96 * se_val,
    trial_label = factor(trial, levels = c(1, 2), labels = c("Trial 1\n(Initial)", "Trial 2\n(Final)")),
    cond_ordered = factor(cond3, levels = c("Generalized Like", "Control Condition", "Generalized Dislike"))
  )

# Color palettes matching publication style
cond_colors <- c(
  "Generalized Like"    = "#2B6CB0",
  "Control Condition"   = "#4A5568",
  "Generalized Dislike" = "#C53030"
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
    legend.position = "bottom"
  )

# Panel A: Evaluative Trajectories with position dodge
dodge_w <- position_dodge(width = 0.14)

p_traj <- ggplot(df_traj, aes(x = trial_label, y = mean_val, group = cond_ordered, color = cond_ordered)) +
  geom_line(position = dodge_w, linewidth = 1.1, alpha = 0.9) +
  geom_point(position = dodge_w, size = 3.5) +
  geom_errorbar(aes(ymin = ci_low, ymax = ci_high), position = dodge_w, width = 0.10, linewidth = 0.75) +
  scale_color_manual(name = "Condition", values = cond_colors) +
  scale_y_continuous(
    limits = c(4.35, 5.15),
    breaks = seq(4.4, 5.1, by = 0.2),
    labels = sprintf("%.1f", seq(4.4, 5.1, by = 0.2))
  ) +
  labs(
    title = "A. Evaluative Trajectories Across Repeated Trials",
    subtitle = "Mean aesthetic rating by trial with 95% CIs (IPW-Weighted, N = 521)",
    x = "",
    y = "Aesthetic Rating (1-7 Scale)"
  ) +
  theme_pub +
  theme(legend.title = element_text(face = "bold", size = 10))

# Panel B: Difference-in-Differences Treatment Effects
# Estimate weighted model
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
  geom_col(width = 0.45, alpha = 0.85, color = NA) +
  geom_errorbar(aes(xmin = conf.low, xmax = conf.high), width = 0.20, linewidth = 0.75) +
  scale_fill_manual(name = "Significance", values = sig_palette, limits = names(sig_palette), drop = FALSE) +
  scale_color_manual(name = "Significance", values = sig_palette, limits = names(sig_palette), drop = FALSE) +
  scale_x_continuous(
    limits = c(-0.38, 0.38),
    breaks = seq(-0.3, 0.3, by = 0.1),
    labels = c("-0.3", "-0.2", "-0.1", "0.0", "+0.1", "+0.2", "+0.3")
  ) +
  labs(
    title = "B. Net DiD Treatment Effects vs. Control Drift",
    subtitle = "Relative to Control exposure drift (95% CI, net of mere exposure)",
    x = "DiD Treatment Effect (Change Score vs. Control)",
    y = ""
  ) +
  theme_pub +
  theme(
    axis.text.y = element_text(face = "bold", size = 10),
    legend.title = element_text(face = "bold", size = 10)
  )

# Combine panels with patchwork
p_combined <- p_traj + p_did + 
  plot_layout(widths = c(1.05, 1))

ggsave("figures/Figure_DiD_Baseline_Influence.png", p_combined, width = 11, height = 4.8, dpi = 300)
ggsave("figures/Figure_DiD_Baseline_Influence.pdf", p_combined, width = 11, height = 4.8)
cat("Figure_DiD_Baseline_Influence saved successfully.\n")
