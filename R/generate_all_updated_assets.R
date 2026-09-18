# R/generate_all_updated_assets.R
# ==============================================================================
# Comprehensive Pipeline to Generate All Primary Assets (Age >= 24 Sample, N = 1,981)
# and Full Sample Assets for Appendix Robustness Check
# Paper: "Stay, React, or Conform? Examining Social Influence Effects on Aesthetic Judgments"
# Authors: Omar Lizardo & Sara Skiles (Poetics POETICS-D-26-00490)
# ==============================================================================

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(ggplot2)
  library(lme4)
  library(marginaleffects)
  library(patchwork)
  library(WeightIt)
  library(cobalt)
  library(nnet)
})

source("R/dataproc.R")
data_list <- process_data()
df_wide <- data_list$wide
df_long <- data_list$long

# Define change score and factor reference
df_wide$diff <- df_wide$taste2_rev - df_wide$taste1_rev
df_wide$cond2_refctrl <- relevel(df_wide$cond2_factor, ref = "Baseline")
df_long$cond2_refctrl <- relevel(df_long$cond2_factor, ref = "Baseline")

# ==============================================================================
# Setup Restricted Sample (Age >= 25, dropping 18-24, N = 1,981)
# ==============================================================================
df_wide_cc_full <- df_wide %>%
  filter(!is.na(objsubjclass_factor), !is.na(age), !is.na(female), !is.na(raceeth), !is.na(parented))

df_wide_cc_primary <- df_wide_cc_full %>%
  filter(age >= 4)

cat("Sample Sizes:\n")
cat("Full Sample CC N:", nrow(df_wide_cc_full), "\n")
cat("Primary Restricted Sample (Age >= 24/25) N:", nrow(df_wide_cc_primary), "\n")

# IPW Weighting on Primary Restricted Sample
W_primary <- weightit(
  objsubjclass_factor ~ age + female + factor(raceeth) + parented,
  data = df_wide_cc_primary,
  method = "ps",
  estimand = "ATE"
)
df_wide_cc_primary$ipw_weight <- W_primary$weights

# IPW Weighting on Full Sample
W_full <- weightit(
  objsubjclass_factor ~ age + female + factor(raceeth) + parented,
  data = df_wide_cc_full,
  method = "ps",
  estimand = "ATE"
)
df_wide_cc_full$ipw_weight <- W_full$weights

# Merged Long Data
df_long_primary <- df_long %>%
  inner_join(df_wide_cc_primary %>% select(id, ipw_weight), by = "id")
df_long_primary$cond2_refctrl <- relevel(df_long_primary$cond2_factor, ref = "Baseline")

df_long_full <- df_long %>%
  inner_join(df_wide_cc_full %>% select(id, ipw_weight), by = "id")
df_long_full$cond2_refctrl <- relevel(df_long_full$cond2_factor, ref = "Baseline")

# Palettes & Styling
sig_palette <- c(
  "p < 0.05"        = "firebrick",
  "p < 0.10"        = "darkorange2",
  "Not Significant" = "grey70"
)

cond_colors <- c(
  "Generalized Like"    = "#2B6CB0",
  "Control Condition"   = "#4A5568",
  "Generalized Dislike" = "#C53030"
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

cond_order_top_down <- c(
  "Generalized Like",
  "High-Status Like",
  "Low-Status Like",
  "Generalized Dislike",
  "High-Status Dislike",
  "Low-Status Dislike"
)
cond_order_y <- rev(cond_order_top_down)

clean_cond_labels <- function(x) {
  case_match(
    x,
    "Class & Taste/Dislike/+Status" ~ "High-Status Dislike",
    "Class & Taste/Like/-Status"    ~ "Low-Status Like",
    "Taste Only/Dislike"            ~ "Generalized Dislike",
    "Taste Only/Like"               ~ "Generalized Like",
    "Class & Taste/Like/+Status"    ~ "High-Status Like",
    "Class & Taste/Dislike/-Status" ~ "Low-Status Dislike",
    .default = x
  )
}

# ==============================================================================
# ASSET 1: Figure 2 (Covariate Balance Love Plot for Primary Sample)
# ==============================================================================
cat("\nGenerating Figure 2: Covariate Balance Love Plot...\n")
fig_balance <- love.plot(W_primary, 
                         binary = "std", 
                         thresholds = c(m = .1), 
                         var.order = "unadjusted",
                         title = "Covariate Balance Across Status Groups Before and After IPW Weighting (Age >= 24 Sample)") +
  theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold", size = 12, hjust = 0),
    legend.position = "bottom"
  )
ggsave("figures/Figure8_CovariateBalance.png", fig_balance, width = 8.5, height = 6.0, dpi = 300)
ggsave("figures/Figure8_CovariateBalance.pdf", fig_balance, width = 8.5, height = 6.0)

# ==============================================================================
# ASSET 2: Figure 3 (Baseline Exposure Drift & Generalized Influence)
# ==============================================================================
cat("\nGenerating Figure 3: Baseline Exposure Drift and Generalized Influence...\n")
generate_figure_3 <- function(df_w, df_l, out_prefix, sample_label) {
  df_3_w <- df_w %>%
    filter(cond2_factor %in% c("Baseline", "Taste Only/Like", "Taste Only/Dislike")) %>%
    mutate(
      cond3 = factor(cond2_factor, levels = c("Baseline", "Taste Only/Like", "Taste Only/Dislike"),
                     labels = c("Control Condition", "Generalized Like", "Generalized Dislike")),
      diff = taste2_rev - taste1_rev
    )
  
  df_3_l <- df_l %>%
    filter(id %in% df_3_w$id) %>%
    mutate(
      cond3 = factor(cond2_factor, levels = c("Baseline", "Taste Only/Like", "Taste Only/Dislike"),
                     labels = c("Control Condition", "Generalized Like", "Generalized Dislike"))
    )
  
  df_traj <- df_3_l %>%
    group_by(cond3, trial) %>%
    summarise(
      mean_val = sum(taste * ipw_weight) / sum(ipw_weight),
      se_val = sqrt(sum(ipw_weight * (taste - (sum(taste * ipw_weight) / sum(ipw_weight)))^2) / sum(ipw_weight) / n()),
      .groups = "drop"
    ) %>%
    mutate(
      ci_low = mean_val - 1.96 * se_val,
      ci_high = mean_val + 1.96 * se_val,
      trial_label = factor(trial, levels = c(1, 2), labels = c("Trial 1\n(Initial)", "Trial 2\n(Final)")),
      cond_ordered = factor(cond3, levels = c("Generalized Like", "Control Condition", "Generalized Dislike"))
    )
  
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
      subtitle = sprintf("Mean aesthetic rating by trial with 95%% CIs (IPW-Weighted, %s, N = %d)", sample_label, nrow(df_3_w)),
      x = "",
      y = "Aesthetic Rating (1-7 Scale)"
    ) +
    theme_pub +
    theme(legend.title = element_text(face = "bold", size = 10))
  
  mod_3 <- lm(diff ~ cond3, data = df_3_w, weights = ipw_weight)
  coefs <- summary(mod_3)$coefficients
  
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
  
  p_comb <- p_traj + p_did + plot_layout(widths = c(1.05, 1))
  ggsave(paste0(out_prefix, ".png"), p_comb, width = 11, height = 4.8, dpi = 300)
  ggsave(paste0(out_prefix, ".pdf"), p_comb, width = 11, height = 4.8)
  p_comb
}

generate_figure_3(df_wide_cc_primary, df_long_primary, "figures/Figure_DiD_Baseline_Influence", "Age >= 24 Sample")
generate_figure_3(df_wide_cc_full, df_long_full, "figures/Figure_DiD_Baseline_Influence_FullSample", "Full Sample")

# ==============================================================================
# ASSET 3: Figure 4 (Stepwise DiD Models: Education & Class)
# ==============================================================================
cat("\nGenerating Figure 4: Stepwise Education & Class DiD Models...\n")
generate_figure_4 <- function(df_w, out_prefix, sample_label) {
  # Targeted binary IPW for Education
  W_e <- weightit(college ~ age + female + factor(raceeth) + parented, data = df_w, method = "ps", estimand = "ATE")
  df_w$ipw_e <- W_e$weights
  mod_e <- lm(diff ~ cond2_refctrl * college_factor, data = df_w, weights = ipw_e)
  comps_e <- comparisons(mod_e, variables = "cond2_refctrl", by = "college_factor")
  
  df_e_res <- as.data.frame(comps_e) %>%
    mutate(
      cond_clean = clean_cond_labels(gsub(" - Baseline", "", contrast)),
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
  
  # Targeted binary IPW for Class
  W_c <- weightit(class ~ age + female + factor(raceeth) + parented, data = df_w, method = "ps", estimand = "ATE")
  df_w$ipw_c <- W_c$weights
  mod_c <- lm(diff ~ cond2_refctrl * class_factor, data = df_w, weights = ipw_c)
  comps_c <- comparisons(mod_c, variables = "cond2_refctrl", by = "class_factor")
  
  df_c_res <- as.data.frame(comps_c) %>%
    mutate(
      cond_clean = clean_cond_labels(gsub(" - Baseline", "", contrast)),
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
  
  p_e <- ggplot(df_e_res, aes(x = estimate, y = cond_clean, fill = sig, color = sig)) +
    geom_vline(xintercept = 0, linetype = "dashed", color = "grey40", linewidth = 0.6) +
    geom_col(width = 0.60, alpha = 0.85, color = NA) +
    geom_errorbar(aes(xmin = conf.low, xmax = conf.high), width = 0.22, linewidth = 0.75) +
    facet_wrap(~college_factor, ncol = 2) +
    scale_fill_manual(name = "Significance", values = sig_palette, limits = names(sig_palette), drop = FALSE) +
    scale_color_manual(name = "Significance", values = sig_palette, limits = names(sig_palette), drop = FALSE) +
    scale_x_continuous(limits = c(-0.65, 0.65), breaks = seq(-0.6, 0.6, by = 0.3), labels = c("-0.6", "-0.3", "0.0", "+0.3", "+0.6")) +
    labs(
      title = "Panel A: Difference-in-Differences Moderated by Educational Attainment",
      subtitle = "Relative to Control Condition (Targeted Binary IPW, 95% CI)",
      x = "DiD Treatment Effect (Change vs. Control)", y = ""
    ) +
    theme_barplot + theme(legend.position = "none")
  
  p_c <- ggplot(df_c_res, aes(x = estimate, y = cond_clean, fill = sig, color = sig)) +
    geom_vline(xintercept = 0, linetype = "dashed", color = "grey40", linewidth = 0.6) +
    geom_col(width = 0.60, alpha = 0.85, color = NA) +
    geom_errorbar(aes(xmin = conf.low, xmax = conf.high), width = 0.22, linewidth = 0.75) +
    facet_wrap(~class_factor, ncol = 2) +
    scale_fill_manual(name = "Significance", values = sig_palette, limits = names(sig_palette), drop = FALSE) +
    scale_color_manual(name = "Significance", values = sig_palette, limits = names(sig_palette), drop = FALSE) +
    scale_x_continuous(limits = c(-0.65, 0.65), breaks = seq(-0.6, 0.6, by = 0.3), labels = c("-0.6", "-0.3", "0.0", "+0.3", "+0.6")) +
    labs(
      title = "Panel B: Difference-in-Differences Moderated by Subjective Social Class",
      subtitle = "Relative to Control Condition (Targeted Binary IPW, 95% CI)",
      x = "DiD Treatment Effect (Change vs. Control)", y = ""
    ) +
    theme_barplot + theme(legend.position = "bottom")
  
  p_comb <- p_e / p_c + plot_layout(heights = c(1, 1.15))
  ggsave(paste0(out_prefix, ".png"), p_comb, width = 10, height = 9, dpi = 300)
  ggsave(paste0(out_prefix, ".pdf"), p_comb, width = 10, height = 9)
  
  list(edu = df_e_res, class = df_c_res)
}

res_stepwise_primary <- generate_figure_4(df_wide_cc_primary, "figures/Figure_DiD_Edu_Class_Separate", "Age >= 24 Sample")
res_stepwise_full <- generate_figure_4(df_wide_cc_full, "figures/Figure_DiD_Edu_Class_Separate_FullSample", "Full Sample")

# ==============================================================================
# ASSET 4: Figure 5 (Complete 24-Cell Status Consistency Matrix)
# ==============================================================================
cat("\nGenerating Figure 5: Complete 24-Cell Status Consistency Matrix...\n")
generate_figure_5 <- function(df_w, out_prefix, sample_label) {
  mod <- lm(diff ~ cond2_refctrl * objsubjclass_factor, data = df_w, weights = ipw_weight)
  comps <- comparisons(mod, variables = "cond2_refctrl", by = "objsubjclass_factor")
  
  df_res <- as.data.frame(comps) %>%
    mutate(
      cond_clean = clean_cond_labels(gsub(" - Baseline", "", contrast)),
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
  
  p_bar <- ggplot(df_res, aes(x = estimate, y = cond_clean, fill = sig, color = sig)) +
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
      title = sprintf("Estimated Difference-in-Differences Treatment Effects Across Status-Consistency Quadrants (%s)", sample_label),
      subtitle = "Relative to unexposed Control Condition within each status quadrant (IPW-Weighted, 95% CI)",
      x = "DiD Treatment Effect (Change Score vs. Control)",
      y = ""
    ) +
    theme_barplot +
    theme(legend.position = "bottom")
  
  ggsave(paste0(out_prefix, ".png"), p_bar, width = 10.5, height = 8.5, dpi = 300)
  ggsave(paste0(out_prefix, ".pdf"), p_bar, width = 10.5, height = 8.5)
  df_res
}

res_status_primary <- generate_figure_5(df_wide_cc_primary, "figures/Figure_DiD_Status_All", "Age >= 24 Sample")
res_status_full <- generate_figure_5(df_wide_cc_full, "figures/Figure_DiD_Status_All_FullSample", "Full Sample")

# ==============================================================================
# ASSET 5: Figure 6 & Appendix Figure A.3 (Discrete Behavioral Choices)
# ==============================================================================
cat("\nGenerating Figure 6 & Appendix Figure A.3: Discrete Behavioral Choices...\n")
generate_figure_6_and_a3 <- function(df_w, out_fig6_prefix, out_figa3_prefix, sample_label) {
  df_multi <- df_w %>%
    select(id, cond2_factor, taste1_rev, taste2_rev, objsubjclass_factor, ipw_weight) %>%
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
    mutate(
      behavior = factor(behavior, levels = c("Stay", "Conform", "React")),
      objsubjclass_factor = relevel(objsubjclass_factor, ref = "Working, No College")
    )
  
  # Fig 6: Full Treatments Model
  mod <- multinom(behavior ~ objsubjclass_factor, data = df_multi, weights = ipw_weight, trace = FALSE)
  mfx <- avg_comparisons(mod, variables = "objsubjclass_factor", type = "probs")
  preds <- predictions(mod, by = c("objsubjclass_factor", "group"), type = "probs")
  
  df_mfx_plot <- as.data.frame(mfx) %>%
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
      title = sprintf("Average Marginal Effects on Behavioral Choices (Stay, Conform, React; %s)", sample_label),
      subtitle = "Relative to baseline reference group: Working Class, No College (IPW Weighted, 95% CI)",
      x = "Average Marginal Effect (Difference in Probability)",
      y = ""
    ) +
    theme_barplot +
    theme(legend.position = "bottom")
  
  ggsave(paste0(out_fig6_prefix, ".png"), p_multi_bars, width = 11, height = 4.8, dpi = 300)
  ggsave(paste0(out_fig6_prefix, ".pdf"), p_multi_bars, width = 11, height = 4.8)
  
  # Fig A.3: Sensitivity Analysis (Excluding Taste-Only)
  df_multi_sens <- df_multi %>%
    filter(!cond2_factor %in% c("Taste Only/Like", "Taste Only/Dislike"))
  
  mod_sens <- multinom(behavior ~ objsubjclass_factor, data = df_multi_sens, weights = ipw_weight, trace = FALSE)
  mfx_sens <- avg_comparisons(mod_sens, variables = "objsubjclass_factor", type = "probs")
  
  df_sens_plot <- as.data.frame(mfx_sens) %>%
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
      title = sprintf("Sensitivity Analysis: Behavioral Choices Excluding Taste-Only Conditions (%s, N = %d)", sample_label, nrow(df_multi_sens)),
      subtitle = "Relative to baseline reference group: Working Class, No College (IPW Weighted, 95% CI)",
      x = "Average Marginal Effect (Difference in Probability)",
      y = ""
    ) +
    theme_barplot +
    theme(legend.position = "bottom")
  
  ggsave(paste0(out_figa3_prefix, ".png"), p_sens_bars, width = 11, height = 4.8, dpi = 300)
  ggsave(paste0(out_figa3_prefix, ".pdf"), p_sens_bars, width = 11, height = 4.8)
  
  list(preds = preds, mfx = mfx, mfx_sens = mfx_sens, n = nrow(df_multi), n_sens = nrow(df_multi_sens))
}

beh_primary <- generate_figure_6_and_a3(df_wide_cc_primary, "figures/Figure7_MultinomialBehavior", "figures/Figure11_Sens_MultinomialBehavior", "Age >= 24 Sample")
beh_full <- generate_figure_6_and_a3(df_wide_cc_full, "figures/Figure7_MultinomialBehavior_FullSample", "figures/Figure11_Sens_MultinomialBehavior_FullSample", "Full Sample")

# ==============================================================================
# ASSET 6: Appendix Figure A.2 (Pooled DiD Model)
# ==============================================================================
cat("\nGenerating Appendix Figure A.2: Pooled DiD Bar Plot...\n")
generate_figure_a2 <- function(df_l, out_prefix, sample_label) {
  mod_pooled <- lmer(taste ~ factor(trial) * cond2_refctrl + (1 | id), data = df_l, REML = FALSE)
  coefs <- summary(mod_pooled)$coefficients
  terms <- grep("factor\\(trial\\)2:cond2_refctrl", rownames(coefs), value = TRUE)
  
  df_p <- data.frame(
    term = terms,
    estimate = coefs[terms, "Estimate"],
    std.error = coefs[terms, "Std. Error"],
    t.value = coefs[terms, "t value"]
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
      cond_clean = clean_cond_labels(cond_raw),
      cond_clean = factor(cond_clean, levels = cond_order_y),
      conf.low = estimate - 1.96 * std.error,
      conf.high = estimate + 1.96 * std.error
    )
  
  p_bar <- ggplot(df_p, aes(x = estimate, y = cond_clean, fill = sig, color = sig)) +
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
      title = sprintf("Difference-in-Differences Treatment Effects (%s)", sample_label),
      subtitle = "Relative to unexposed Control Condition (95% CI, net of exposure drift)",
      x = "DiD Treatment Effect (Change Score vs. Control)",
      y = ""
    ) +
    theme_barplot +
    theme(legend.position = "bottom")
  
  ggsave(paste0(out_prefix, ".png"), p_bar, width = 8.5, height = 5.5, dpi = 300)
  ggsave(paste0(out_prefix, ".pdf"), p_bar, width = 8.5, height = 5.5)
  df_p
}

generate_figure_a2(df_long_primary, "figures/Figure_DiD_Pooled", "Age >= 24 Sample")
generate_figure_a2(df_long_full, "figures/Figure_DiD_Pooled_FullSample", "Full Sample")

# Save all results object for table generation
saveRDS(list(
  stepwise_primary = res_stepwise_primary,
  stepwise_full = res_stepwise_full,
  status_primary = res_status_primary,
  status_full = res_status_full,
  beh_primary = beh_primary,
  beh_full = beh_full
), file = "tables/all_model_results_updated.rds")

cat("\nAll updated figures and model results generated and saved successfully!\n")
