# R/generate_did_barplots.R
# Generates publication-grade DiD bar plots with error bars
# Highlights statistical significance (p < 0.05, p < 0.10, and Not Significant)

library(ggplot2)
library(dplyr)
library(lme4)
library(marginaleffects)
library(patchwork)
library(nnet)
library(WeightIt)

source("R/dataproc.R")
source("R/did_models.R")

theme_barplot <- theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold", size = 12, hjust = 0),
    plot.subtitle = element_text(size = 10, color = "grey30", margin = margin(b = 8)),
    axis.title = element_text(face = "bold", size = 11),
    axis.text.y = element_text(size = 9.5, face = "bold"),
    axis.text.x = element_text(size = 9.5),
    panel.grid.minor = element_blank(),
    panel.border = element_rect(color = "grey80", fill = NA, linewidth = 0.5),
    strip.text = element_text(face = "bold", size = 11, hjust = 0.5),
    strip.background = element_rect(fill = "grey95", color = "grey80"),
    legend.position = "bottom",
    legend.title = element_blank()
  )

sig_palette <- c(
  "p < 0.05" = "firebrick",
  "p < 0.10" = "darkorange2",
  "Not Significant" = "grey70"
)

# Standard condition order from top to bottom on the vertical axis:
# All Likes grouped together, all Dislikes grouped together: Generalized, High-Status, Low-Status
cond_order_top_down <- c(
  "Generalized Like",
  "High-Status Like",
  "Low-Status Like",
  "Generalized Dislike",
  "High-Status Dislike",
  "Low-Status Dislike"
)

cond_order_y <- rev(cond_order_top_down)

# ==============================================================================
# 1. Appendix Figure A.2: Pooled DiD Bar Plot
# ==============================================================================
did_coefs_unwt <- summary(mod_did_unwt)$coefficients
did_terms_unwt <- grep("factor\\(trial\\)2:cond2_refctrl", rownames(did_coefs_unwt), value = TRUE)

df_pooled_plot <- data.frame(
  term = did_terms_unwt,
  estimate = did_coefs_unwt[did_terms_unwt, "Estimate"],
  std.error = did_coefs_unwt[did_terms_unwt, "Std. Error"],
  t.value = did_coefs_unwt[did_terms_unwt, "t value"]
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
    cond_clean = case_match(
      cond_raw,
      "Class & Taste/Like/+Status" ~ "High-Status Like",
      "Class & Taste/Like/-Status" ~ "Low-Status Like",
      "Class & Taste/Dislike/+Status" ~ "High-Status Dislike",
      "Class & Taste/Dislike/-Status" ~ "Low-Status Dislike",
      "Taste Only/Like" ~ "Generalized Like",
      "Taste Only/Dislike" ~ "Generalized Dislike",
      .default = cond_raw
    ),
    cond_clean = factor(cond_clean, levels = cond_order_y),
    conf.low = estimate - 1.96 * std.error,
    conf.high = estimate + 1.96 * std.error
  )

p_pooled_bar <- ggplot(df_pooled_plot, aes(x = estimate, y = cond_clean, fill = sig, color = sig)) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "grey40", linewidth = 0.6) +
  geom_col(width = 0.6, alpha = 0.85, color = NA) +
  geom_errorbar(aes(xmin = conf.low, xmax = conf.high), width = 0.25, linewidth = 0.75) +
  scale_fill_manual(name = "Significance", values = sig_palette, limits = names(sig_palette), drop = FALSE) +
  scale_color_manual(name = "Significance", values = sig_palette, limits = names(sig_palette), drop = FALSE) +
  scale_x_continuous(
    limits = c(-0.35, 0.35),
    breaks = seq(-0.3, 0.3, by = 0.1),
    labels = c("-0.3", "-0.2", "-0.1", "0.0", "+0.1", "+0.2", "+0.3")
  ) +
  labs(
    title = "Difference-in-Differences Treatment Effects (Pooled Sample)",
    subtitle = "Relative to unexposed Control Condition (95% CI, net of exposure drift)",
    x = "DiD Treatment Effect (Change Score vs. Control)",
    y = ""
  ) +
  theme_barplot +
  theme(legend.position = "bottom")

ggsave("figures/Figure_DiD_Pooled.png", p_pooled_bar, width = 8.5, height = 5.5, dpi = 300)
ggsave("figures/Figure_DiD_Pooled.pdf", p_pooled_bar, width = 8.5, height = 5.5)
cat("Figure_DiD_Pooled saved successfully.\n")

# ==============================================================================
# 2. Figure 4: Complete 24-Cell Status Consistency DiD Bar Plot (Main Text)
# ==============================================================================
df_status_all <- res_did_status %>%
  mutate(
    cond_raw = gsub(" - Baseline", "", contrast),
    cond_clean = case_match(
      cond_raw,
      "Class & Taste/Like/+Status" ~ "High-Status Like",
      "Class & Taste/Like/-Status" ~ "Low-Status Like",
      "Class & Taste/Dislike/+Status" ~ "High-Status Dislike",
      "Class & Taste/Dislike/-Status" ~ "Low-Status Dislike",
      "Taste Only/Like" ~ "Generalized Like",
      "Taste Only/Dislike" ~ "Generalized Dislike",
      .default = cond_raw
    ),
    cond_clean = factor(cond_clean, levels = cond_order_y),
    sig = case_when(
      p.value < 0.05 ~ "p < 0.05",
      p.value < 0.10 ~ "p < 0.10",
      TRUE ~ "Not Significant"
    ),
    sig = factor(sig, levels = c("p < 0.05", "p < 0.10", "Not Significant")),
    conf.low = estimate - 1.96 * std.error,
    conf.high = estimate + 1.96 * std.error
  )

p_status_bar <- ggplot(df_status_all, aes(x = estimate, y = cond_clean, fill = sig, color = sig)) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "grey40", linewidth = 0.6) +
  geom_col(width = 0.65, alpha = 0.85, color = NA) +
  geom_errorbar(aes(xmin = conf.low, xmax = conf.high), width = 0.25, linewidth = 0.75) +
  facet_wrap(~objsubjclass_factor, ncol = 2) +
  scale_fill_manual(name = "Significance", values = sig_palette, limits = names(sig_palette), drop = FALSE) +
  scale_color_manual(name = "Significance", values = sig_palette, limits = names(sig_palette), drop = FALSE) +
  scale_x_continuous(
    limits = c(-0.80, 0.80),
    breaks = seq(-0.8, 0.8, by = 0.4),
    labels = c("-0.8", "-0.4", "0.0", "+0.4", "+0.8")
  ) +
  labs(
    title = "Estimated Difference-in-Differences Treatment Effects Across Status-Consistency Quadrants (IPW-Weighted)",
    subtitle = "Relative to unexposed Control Condition within each status quadrant (95% CI)",
    x = "DiD Treatment Effect (Change Score vs. Control)",
    y = ""
  ) +
  theme_barplot +
  theme(legend.position = "bottom")

ggsave("figures/Figure_DiD_Status_All.png", p_status_bar, width = 10.5, height = 8.5, dpi = 300)
ggsave("figures/Figure_DiD_Status_All.pdf", p_status_bar, width = 10.5, height = 8.5)
cat("Figure_DiD_Status_All saved successfully.\n")

# ==============================================================================
# 3. Figure 5: Multinomial Behavioral Choices (AME Bar Plot)
# ==============================================================================
df_wide_cc <- df_wide %>%
  filter(!is.na(objsubjclass_factor), !is.na(age), !is.na(female), !is.na(raceeth), !is.na(parented))

W <- weightit(objsubjclass_factor ~ age + female + factor(raceeth) + parented, 
              data = df_wide_cc, method = "ps", estimand = "ATE")
df_wide_cc$ipw_weight <- W$weights

df_multi <- df_wide_cc %>%
  mutate(
    diff = taste2_rev - taste1_rev,
    behavior = case_when(
      diff == 0 ~ "Stay",
      cond2_factor %in% c("Class & Taste/Like/-Status", "Class & Taste/Like/+Status", "Taste Only/Like") & diff > 0 ~ "Conform",
      cond2_factor %in% c("Class & Taste/Like/-Status", "Class & Taste/Like/+Status", "Taste Only/Like") & diff < 0 ~ "React",
      cond2_factor %in% c("Class & Taste/Dislike/-Status", "Class & Taste/Dislike/+Status", "Taste Only/Dislike") & diff < 0 ~ "Conform",
      cond2_factor %in% c("Class & Taste/Dislike/-Status", "Class & Taste/Dislike/+Status", "Taste Only/Dislike") & diff > 0 ~ "React",
      TRUE ~ NA_character_
    )
  ) %>%
  filter(!is.na(behavior)) %>%
  mutate(
    behavior = factor(behavior, levels = c("Stay", "Conform", "React")),
    objsubjclass_factor = relevel(objsubjclass_factor, ref = "Working, No College")
  )

multi_mod <- multinom(behavior ~ objsubjclass_factor, data = df_multi, weights = ipw_weight, trace = FALSE)

multi_mfx <- avg_comparisons(
  multi_mod,
  variables = "objsubjclass_factor",
  type = "probs"
)

df_mfx_plot <- as.data.frame(multi_mfx) %>%
  mutate(
    Comparison = factor(contrast, levels = rev(c(
      "Middle, College - Working, No College",
      "Middle, No College - Working, No College",
      "Working, College - Working, No College"
    )), labels = rev(c(
      "Middle Class, College",
      "Middle Class, No College",
      "Working Class, College"
    ))),
    sig = case_when(
      p.value < 0.05 ~ "p < 0.05",
      p.value < 0.10 ~ "p < 0.10",
      TRUE ~ "Not Significant"
    ),
    sig = factor(sig, levels = c("p < 0.05", "p < 0.10", "Not Significant")),
    group = factor(group, levels = c("Stay", "Conform", "React"), labels = c(
      "Panel A: Stay (Inertia)",
      "Panel B: Conformity",
      "Panel C: Oppositional Reactance"
    ))
  )

p_multi_bars <- ggplot(df_mfx_plot, aes(x = estimate, y = Comparison, fill = sig, color = sig)) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "grey40", linewidth = 0.6) +
  geom_col(width = 0.55, alpha = 0.85, color = NA) +
  geom_errorbar(aes(xmin = conf.low, xmax = conf.high), width = 0.22, linewidth = 0.75) +
  facet_wrap(~group, ncol = 3) +
  scale_fill_manual(name = "Significance", values = sig_palette, limits = names(sig_palette), drop = FALSE) +
  scale_color_manual(name = "Significance", values = sig_palette, limits = names(sig_palette), drop = FALSE) +
  scale_x_continuous(
    limits = c(-0.12, 0.12),
    breaks = seq(-0.10, 0.10, by = 0.05),
    labels = c("-0.10", "-0.05", "0.00", "+0.05", "+0.10")
  ) +
  labs(
    title = "Average Marginal Effects on Behavioral Choices (Stay, Conform, React)",
    subtitle = "Relative to baseline reference group: Working Class, No College (IPW Weighted, 95% CI)",
    x = "Average Marginal Effect (Difference in Probability)",
    y = ""
  ) +
  theme_barplot +
  theme(legend.position = "bottom")

ggsave("figures/Figure7_MultinomialBehavior.png", p_multi_bars, width = 11, height = 4.8, dpi = 300)
ggsave("figures/Figure7_MultinomialBehavior.pdf", p_multi_bars, width = 11, height = 4.8)
cat("Figure 5 (Figure7_MultinomialBehavior) saved successfully.\n")

# ==============================================================================
# 4. Appendix Figure A.3: Sensitivity Behavioral Choices (Excluding Taste-Only)
# ==============================================================================
df_multi_sens <- df_multi %>%
  filter(!cond2_factor %in% c("Taste Only/Like", "Taste Only/Dislike"))

multi_mod_sens <- multinom(behavior ~ objsubjclass_factor, data = df_multi_sens, weights = ipw_weight, trace = FALSE)

multi_mfx_sens <- avg_comparisons(
  multi_mod_sens,
  variables = "objsubjclass_factor",
  type = "probs"
)

df_sens_plot <- as.data.frame(multi_mfx_sens) %>%
  mutate(
    Comparison = factor(contrast, levels = rev(c(
      "Middle, College - Working, No College",
      "Middle, No College - Working, No College",
      "Working, College - Working, No College"
    )), labels = rev(c(
      "Middle Class, College",
      "Middle Class, No College",
      "Working Class, College"
    ))),
    sig = case_when(
      p.value < 0.05 ~ "p < 0.05",
      p.value < 0.10 ~ "p < 0.10",
      TRUE ~ "Not Significant"
    ),
    sig = factor(sig, levels = c("p < 0.05", "p < 0.10", "Not Significant")),
    group = factor(group, levels = c("Stay", "Conform", "React"), labels = c(
      "Panel A: Stay (Inertia)",
      "Panel B: Conformity",
      "Panel C: Oppositional Reactance"
    ))
  )

p_sens_bars <- ggplot(df_sens_plot, aes(x = estimate, y = Comparison, fill = sig, color = sig)) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "grey40", linewidth = 0.6) +
  geom_col(width = 0.55, alpha = 0.85, color = NA) +
  geom_errorbar(aes(xmin = conf.low, xmax = conf.high), width = 0.22, linewidth = 0.75) +
  facet_wrap(~group, ncol = 3) +
  scale_fill_manual(name = "Significance", values = sig_palette, limits = names(sig_palette), drop = FALSE) +
  scale_color_manual(name = "Significance", values = sig_palette, limits = names(sig_palette), drop = FALSE) +
  scale_x_continuous(
    limits = c(-0.12, 0.12),
    breaks = seq(-0.10, 0.10, by = 0.05),
    labels = c("-0.10", "-0.05", "0.00", "+0.05", "+0.10")
  ) +
  labs(
    title = "Sensitivity Analysis: Behavioral Choices Excluding Taste-Only Conditions (N = 1,870)",
    subtitle = "Relative to baseline reference group: Working Class, No College (IPW Weighted, 95% CI)",
    x = "Average Marginal Effect (Difference in Probability)",
    y = ""
  ) +
  theme_barplot +
  theme(legend.position = "bottom")

ggsave("figures/Figure11_Sens_MultinomialBehavior.png", p_sens_bars, width = 11, height = 4.8, dpi = 300)
ggsave("figures/Figure11_Sens_MultinomialBehavior.pdf", p_sens_bars, width = 11, height = 4.8)
cat("Appendix Figure A.3 (Figure11_Sens_MultinomialBehavior) saved successfully.\n")
