# R/did_visualization.R
# Generates publication-grade DiD Forest Plots matching the visual style of Figure 5
# Highlights statistical significance: p < 0.05, p < 0.10, and Not Significant

library(ggplot2)
library(dplyr)
library(lme4)
library(marginaleffects)

source("R/did_models.R")

# Custom theme matching Figure 5 in original manuscript
theme_forest <- theme_minimal(base_size = 13) +
  theme(
    plot.title = element_text(face = "bold", size = 13, hjust = 0.5),
    plot.subtitle = element_text(size = 11, hjust = 0.5, margin = margin(b = 8)),
    axis.title = element_text(face = "bold", size = 11),
    axis.text.y = element_text(size = 10),
    panel.grid.minor = element_blank(),
    panel.border = element_rect(color = "grey80", fill = NA, linewidth = 0.5),
    strip.text = element_text(face = "bold", size = 11),
    strip.background = element_rect(fill = "grey95", color = "grey80"),
    legend.position = "bottom",
    legend.title = element_blank()
  )

# Color palette for significance levels
sig_colors <- c(
  "p < 0.05" = "firebrick",
  "p < 0.10" = "darkorange2",
  "Not Significant" = "grey50"
)

# ==============================================================================
# 1. Pooled DiD Forest Plot (Unweighted Model 1)
# ==============================================================================
did_coefs <- summary(mod_did_unwt)$coefficients
did_terms <- grep("factor\\(trial\\)2:cond2_refctrl", rownames(did_coefs), value = TRUE)

df_pooled_plot <- data.frame(
  term = did_terms,
  estimate = did_coefs[did_terms, "Estimate"],
  std.error = did_coefs[did_terms, "Std. Error"],
  t.value = did_coefs[did_terms, "t value"]
) %>%
  mutate(
    p.value = 2 * (1 - pnorm(abs(t.value))),
    sig = case_when(
      p.value < 0.05 ~ "p < 0.05",
      p.value < 0.10 ~ "p < 0.10",
      TRUE ~ "Not Significant"
    ),
    sig = factor(sig, levels = c("p < 0.05", "p < 0.10", "Not Significant")),
    cond_raw = gsub("factor\\(trial\\)2:cond2_refctrl", "", term),
    cond_clean = factor(cond_raw, levels = c(
      "Class & Taste/Dislike/-Status",
      "Class & Taste/Dislike/+Status",
      "Taste Only/Dislike",
      "Taste Only/Like",
      "Class & Taste/Like/-Status",
      "Class & Taste/Like/+Status"
    ), labels = c(
      "Dislike / Low Status",
      "Dislike / High Status",
      "Dislike (No Status)",
      "Like (No Status)",
      "Like / Low Status",
      "Like / High Status"
    )),
    conf.low = estimate - 1.96 * std.error,
    conf.high = estimate + 1.96 * std.error
  )

p_pooled <- ggplot(df_pooled_plot, aes(x = estimate, y = cond_clean, color = sig)) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "darkgray", linewidth = 0.8) +
  geom_errorbar(aes(xmin = conf.low, xmax = conf.high), width = 0.25, linewidth = 0.9, orientation = "y") +
  geom_point(size = 3.5) +
  scale_color_manual(values = sig_colors) +
  labs(
    title = "Difference-in-Differences Treatment Effects (Pooled Sample)",
    subtitle = "Relative to Control Condition (Net of Exposure Drift)",
    x = "DiD Treatment Effect (Change in Treatment - Change in Control)",
    y = ""
  ) +
  theme_forest

ggsave("figures/Figure_DiD_Forest_Pooled.png", p_pooled, width = 8.5, height = 5.5, dpi = 300)
ggsave("figures/Figure_DiD_Forest_Pooled.pdf", p_pooled, width = 8.5, height = 5.5)
cat("Pooled DiD Forest Plot saved to figures/Figure_DiD_Forest_Pooled.png\n")

# ==============================================================================
# 2. Status Consistency DiD Forest Plot (IPW-Weighted Model 4)
# ==============================================================================
df_status_plot <- res_did_status %>%
  mutate(
    cond_clean = factor(gsub(" - Baseline", "", contrast), levels = c(
      "Class & Taste/Dislike/-Status",
      "Class & Taste/Dislike/+Status",
      "Taste Only/Dislike",
      "Taste Only/Like",
      "Class & Taste/Like/-Status",
      "Class & Taste/Like/+Status"
    ), labels = c(
      "Dislike / Low Status",
      "Dislike / High Status",
      "Dislike (No Status)",
      "Like (No Status)",
      "Like / Low Status",
      "Like / High Status"
    )),
    sig = case_when(
      p.value < 0.05 ~ "p < 0.05",
      p.value < 0.10 ~ "p < 0.10",
      TRUE ~ "Not Significant"
    ),
    sig = factor(sig, levels = c("p < 0.05", "p < 0.10", "Not Significant")),
    conf.low = estimate - 1.96 * std.error,
    conf.high = estimate + 1.96 * std.error
  )

p_status <- ggplot(df_status_plot, aes(x = estimate, y = cond_clean, color = sig)) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "darkgray", linewidth = 0.8) +
  geom_errorbar(aes(xmin = conf.low, xmax = conf.high), width = 0.25, linewidth = 0.9, orientation = "y") +
  geom_point(size = 3) +
  facet_wrap(~objsubjclass_factor, ncol = 2) +
  scale_color_manual(values = sig_colors) +
  labs(
    title = "Estimated DiD Treatment Effects by Status Consistency (IPW Weighted)",
    subtitle = "Relative to Control Condition (Net of Exposure Drift)",
    x = "DiD Treatment Effect (Change in Treatment - Change in Control)",
    y = ""
  ) +
  theme_forest

ggsave("figures/Figure_DiD_Forest_Status.png", p_status, width = 10, height = 8, dpi = 300)
ggsave("figures/Figure_DiD_Forest_Status.pdf", p_status, width = 10, height = 8)
cat("Status DiD Forest Plot saved to figures/Figure_DiD_Forest_Status.png\n")
