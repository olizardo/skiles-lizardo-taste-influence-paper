# R/07_make_figures.R
# ==============================================================================
# Figure Generation (Step 07)
#
# Produces every figure referenced in manuscript_R1.tex from the saved model
# results (tables/*.rds). No models are re-fit here and no effect estimates are
# hardcoded: every plotted value comes from Step 03/04/05/06 outputs.
#
# Output files (exact names referenced in manuscript_R1.tex):
#   figures/Figure8_CovariateBalance.{png,pdf}        (Fig 2,  Section 2.5)
#   figures/Figure_DiD_Baseline_Influence.{png,pdf}   (Fig 3,  Section 3.1)
#   figures/Figure_DiD_Edu_4Tiers.{png,pdf}           (Fig 4,  Section 3.2)
#   figures/Figure7_MultinomialBehavior.{png,pdf}     (Fig 5,  Section 3.3)
#   figures/Figure_MDE_Power_Curves.{png,pdf}         (Fig A.1, Appendix A)
#   figures/Figure_DiD_Edu_Class_Separate.{png,pdf}   (Fig A.2, Appendix C)
#   figures/Figure_DiD_Pooled.{png,pdf}               (Fig A.3, Appendix D)
#   figures/Figure11_Sens_MultinomialBehavior.{png,pdf} (Fig A.4, Appendix E)
# ==============================================================================

suppressPackageStartupMessages({
  library(ggplot2)
  library(dplyr)
  library(patchwork)
  library(tidyr)
})

cat("\n================ STEP 07: FIGURES =================\n")

did <- readRDS("tables/model_results_did.rds")
beh <- readRDS("tables/model_results_behavioral.rds")
bal <- readRDS("tables/balance_results.rds")
mde <- readRDS("tables/mde_results.rds")

SAMPLE_LABEL <- "Age >= 25 Sample"

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
  "Generalized Like", "High-Status Like", "Low-Status Like",
  "Generalized Dislike", "High-Status Dislike", "Low-Status Dislike"
)
cond_order_y <- rev(cond_order_top_down)

# Re-level Condition for display (Generalized Like at top of y axis)
for_display <- function(df) {
  df %>% mutate(Condition = factor(as.character(Condition), levels = cond_order_y))
}

save_fig <- function(p, prefix, w, h) {
  ggsave(paste0(prefix, ".png"), p, width = w, height = h, dpi = 300)
  ggsave(paste0(prefix, ".pdf"), p, width = w, height = h)
}

# ------------------------------------------------------------------------------
# Figure 2: Covariate balance love plot
# ------------------------------------------------------------------------------
fig_balance <- bal$fig_balance +
  ggtitle("Covariate Balance Across Status Groups Before and After IPW Weighting (Age >= 25 Sample)") +
  theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold", size = 12, hjust = 0),
    legend.position = "bottom"
  )
save_fig(fig_balance, "figures/Figure8_CovariateBalance", 8.5, 6.0)

# ------------------------------------------------------------------------------
# Figure 3: Baseline exposure drift & generalized influence (N = 457)
# ------------------------------------------------------------------------------
df31 <- did$res_baseline$did_frame %>%
  mutate(Condition = factor(as.character(Condition),
                            levels = c("Generalized Dislike", "Generalized Like")))

p3 <- ggplot(df31, aes(x = estimate, y = Condition, fill = sig, color = sig)) +
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
    title = "Difference-in-Differences Treatment Effects (Status-Free Conditions)",
    subtitle = sprintf(
      "Relative to Control Condition exposure drift (95%% CI, IPW-Weighted, %s, N = %d)",
      SAMPLE_LABEL, did$res_baseline$n
    ),
    x = "DiD Treatment Effect (Change Score vs. Control)",
    y = ""
  ) +
  theme_pub +
  theme(
    axis.text.y = element_text(face = "bold", size = 10.5),
    legend.title = element_text(face = "bold", size = 10),
    legend.position = "bottom"
  )
save_fig(p3, "figures/Figure_DiD_Baseline_Influence", 7.5, 3.6)

# ------------------------------------------------------------------------------
# Figure 4: Four-tier education model (4 panels)
# ------------------------------------------------------------------------------
tier_levels <- c("High School or Less", "Associate/Some College",
                 "Bachelor's Degree", "Postgraduate")
tier_labels <- c(
  "A. High School or Less", "B. Two-Year Associate / Some College",
  "C. Four-Year Bachelor's Degree", "D. Postgraduate / Advanced Degree"
)
df4 <- did$res_edu4 %>%
  for_display() %>%
  mutate(
    Group = factor(as.character(Group), levels = tier_levels),
    panel = factor(tier_labels[as.integer(Group)], levels = tier_labels),
    panel_n = group_n
  )
lim4 <- max(abs(c(df4$conf.low, df4$conf.high)))
lim4 <- ceiling(lim4 * 20) / 20

p4 <- ggplot(df4, aes(x = estimate, y = Condition, fill = sig, color = sig)) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "grey40", linewidth = 0.6) +
  geom_col(width = 0.60, alpha = 0.85, color = NA) +
  geom_errorbar(aes(xmin = conf.low, xmax = conf.high), width = 0.22, linewidth = 0.75) +
  facet_wrap(~panel, ncol = 2, scales = "fixed",
             labeller = labeller(.default = label_wrap_gen(width = 30))) +
  scale_fill_manual(name = "Significance", values = sig_palette, limits = names(sig_palette), drop = FALSE) +
  scale_color_manual(name = "Significance", values = sig_palette, limits = names(sig_palette), drop = FALSE) +
  scale_x_continuous(limits = c(-lim4, lim4)) +
  labs(
    title = "Difference-in-Differences Treatment Effects Across Four Educational Tiers",
    subtitle = sprintf(
      "Relative to Control Condition within each educational tier (Multinomial IPW, 95%% CI, %s, N = 1,981)",
      SAMPLE_LABEL
    ),
    x = "DiD Treatment Effect (Change Score vs. Control)",
    y = ""
  ) +
  theme_barplot +
  theme(legend.position = "bottom")
save_fig(p4, "figures/Figure_DiD_Edu_4Tiers", 10, 9)

# ------------------------------------------------------------------------------
# Figure 5: Behavioral choices (Stay / Conform / React AMEs)
# ------------------------------------------------------------------------------
prep_ame_frame <- function(mfx) {
  comparison_levels <- rev(c(
    "Middle, College - Working, No College",
    "Middle, No College - Working, No College",
    "Working, College - Working, No College"
  ))
  as.data.frame(mfx) %>%
    mutate(
      Comparison = factor(contrast, levels = comparison_levels,
                          labels = rev(c("Middle Class, College", "Middle Class, No College",
                                         "Working Class, College"))),
      sig = case_when(
        p.value < 0.05 ~ "p < 0.05",
        p.value < 0.10 ~ "p < 0.10",
        TRUE ~ "Not Significant"
      ),
      sig = factor(sig, levels = c("p < 0.05", "p < 0.10", "Not Significant")),
      group = factor(group, levels = c("Stay", "Conform", "React"), labels = c(
        "Panel A: Stay (Inertia)", "Panel B: Conformity", "Panel C: Oppositional Reactance"
      ))
    )
}

plot_ame <- function(df, title, subtitle) {
  ggplot(df, aes(x = estimate, y = Comparison, fill = sig, color = sig)) +
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
    labs(title = title, subtitle = subtitle,
         x = "Average Marginal Effect (Difference in Probability)", y = "") +
    theme_barplot +
    theme(legend.position = "bottom")
}

df5 <- prep_ame_frame(beh$beh_primary$mfx)
p5 <- plot_ame(
  df5,
  sprintf("Average Marginal Effects on Behavioral Choices (Stay, Conform, React; %s)", SAMPLE_LABEL),
  sprintf("Relative to baseline reference group: Working Class, No College (IPW Weighted, 95%% CI, N = %d)",
          beh$beh_primary$n)
)
save_fig(p5, "figures/Figure7_MultinomialBehavior", 11, 4.8)

# ------------------------------------------------------------------------------
# Appendix Figure A.1: MDE power curves
# ------------------------------------------------------------------------------
n_seq <- seq(20, 500, by = 5)
rho_emp <- mde$mde_inputs$rho
cor_levels <- c(0.00, 0.50, 0.70, rho_emp)
df_curves <- expand.grid(n = n_seq, rho = cor_levels) %>%
  mutate(
    sd_ratio = sqrt(2 * (1 - rho)),
    se_did = sd_ratio * sqrt(2 / n),
    mde_d = (qnorm(0.975) + qnorm(0.80)) * se_did,
    rho_fac = factor(
      rho, levels = cor_levels,
      labels = c(
        "r = 0.00 (Independent Post-Test)",
        "r = 0.50 (Moderate Autocorrelation)",
        "r = 0.70 (Standard Repeated Measures)",
        sprintf("r = %.2f (Empirical Study Precision)", rho_emp)
      )
    )
  )

p_curves <- ggplot(df_curves, aes(x = n, y = mde_d, color = rho_fac, linetype = rho_fac)) +
  geom_line(linewidth = 1) +
  geom_hline(yintercept = 0.20, linetype = "dotted", color = "grey40", linewidth = 0.6) +
  geom_hline(yintercept = 0.50, linetype = "dashed", color = "grey40", linewidth = 0.6) +
  annotate("text", x = 450, y = 0.23, label = "Small effect (d = 0.20)", size = 3.2, color = "grey40", fontface = "italic") +
  annotate("text", x = 450, y = 0.53, label = "Medium effect (d = 0.50)", size = 3.2, color = "grey40", fontface = "italic") +
  scale_color_manual(values = c("grey60", "darkorange2", "steelblue", "firebrick")) +
  scale_linetype_manual(values = c("dotted", "dotdash", "dashed", "solid")) +
  coord_cartesian(ylim = c(0, 0.90), xlim = c(20, 500)) +
  scale_x_continuous(breaks = seq(0, 500, by = 100)) +
  labs(
    title = "A. Minimum Detectable Effect by Test-Retest Precision",
    subtitle = expression(paste("Power = 0.80, ", alpha, " = 0.05; comparing post-only vs. repeated-measures DiD")),
    x = "Sample Size per Cell (N)",
    y = "Minimum Detectable Effect (Cohen's d)"
  ) +
  theme_pub +
  guides(
    color = guide_legend(nrow = 2, byrow = TRUE),
    linetype = guide_legend(nrow = 2, byrow = TRUE)
  )

# Empirical points from the computed MDE table
dm <- mde$df_mde
empirical_points <- data.frame(
  Spec = c(
    "Primary Sample Drift", "Control Condition Drift",
    "Pooled DiD (High-Status)", "Pooled DiD (Single Status)", "Pooled DiD (Taste-Only)",
    sprintf("DiD: %s", dm$Comparison[6]), sprintf("DiD: %s", dm$Comparison[7]),
    sprintf("DiD: %s", dm$Comparison[8]), sprintf("DiD: %s", dm$Comparison[9])
  ),
  Category = c("Drift", "Drift", rep("Pooled DiD", 3), rep("Subgroup DiD", 4)),
  MDE_d_80 = as.numeric(dm$MDE_d_80),
  MDE_raw_80 = as.numeric(dm$MDE_raw_80)
)
empirical_points$Spec <- factor(empirical_points$Spec, levels = rev(empirical_points$Spec))
empirical_points$Category <- factor(empirical_points$Category, levels = c("Drift", "Pooled DiD", "Subgroup DiD"))

p_emp <- ggplot(empirical_points, aes(x = MDE_d_80, y = Spec, color = Category)) +
  geom_vline(xintercept = 0.20, linetype = "dotted", color = "grey40", linewidth = 0.6) +
  geom_vline(xintercept = 0.50, linetype = "dashed", color = "grey40", linewidth = 0.6) +
  geom_segment(aes(x = 0, xend = MDE_d_80, y = Spec, yend = Spec), linewidth = 0.9) +
  geom_point(size = 3.5) +
  geom_text(aes(label = sprintf("%.2f (%.2f pts)", MDE_d_80, MDE_raw_80)),
            hjust = -0.12, size = 3.2, fontface = "bold", show.legend = FALSE) +
  scale_color_manual(values = c("Drift" = "#2CA02C", "Pooled DiD" = "#1F77B4", "Subgroup DiD" = "#D62728")) +
  coord_cartesian(xlim = c(0, max(empirical_points$MDE_d_80) * 1.6)) +
  scale_x_continuous(breaks = seq(0, 0.50, by = 0.10)) +
  labs(
    title = "B. Empirical MDE Achieved in This Study (Power = 0.80)",
    subtitle = expression(paste("Standardized Cohen's ", italic(d), " (and 7-point scale raw units) at ", alpha, " = 0.05")),
    x = "Minimum Detectable Effect (Cohen's d)",
    y = ""
  ) +
  theme_pub +
  theme(legend.position = "bottom")

p_mde <- p_curves + p_emp + plot_layout(ncol = 2, widths = c(1.15, 1.2))
save_fig(p_mde, "figures/Figure_MDE_Power_Curves", 13, 6.2)

# ------------------------------------------------------------------------------
# Appendix Figure A.2: Stepwise education / class models (primary sample)
# ------------------------------------------------------------------------------
step_panels <- function(frame_edu, frame_class) {
  dfe <- frame_edu %>% for_display()
  dfc <- frame_class %>% for_display()
  lim <- max(abs(c(dfe$conf.low, dfe$conf.high, dfc$conf.low, dfc$conf.high)))
  lim <- ceiling(lim * 10) / 10

  p_e <- ggplot(dfe, aes(x = estimate, y = Condition, fill = sig, color = sig)) +
    geom_vline(xintercept = 0, linetype = "dashed", color = "grey40", linewidth = 0.6) +
    geom_col(width = 0.60, alpha = 0.85, color = NA) +
    geom_errorbar(aes(xmin = conf.low, xmax = conf.high), width = 0.22, linewidth = 0.75) +
    facet_wrap(~Group, ncol = 2) +
    scale_fill_manual(name = "Significance", values = sig_palette, limits = names(sig_palette), drop = FALSE) +
    scale_color_manual(name = "Significance", values = sig_palette, limits = names(sig_palette), drop = FALSE) +
    scale_x_continuous(limits = c(-lim, lim), breaks = seq(-0.6, 0.6, by = 0.3),
                       labels = c("-0.6", "-0.3", "0.0", "+0.3", "+0.6")) +
    labs(
      title = "Panel A: Difference-in-Differences Moderated by Educational Attainment",
      subtitle = "Relative to Control Condition (Targeted Binary IPW, 95% CI)",
      x = "DiD Treatment Effect (Change vs. Control)", y = ""
    ) +
    theme_barplot + theme(legend.position = "none")

  p_c <- ggplot(dfc, aes(x = estimate, y = Condition, fill = sig, color = sig)) +
    geom_vline(xintercept = 0, linetype = "dashed", color = "grey40", linewidth = 0.6) +
    geom_col(width = 0.60, alpha = 0.85, color = NA) +
    geom_errorbar(aes(xmin = conf.low, xmax = conf.high), width = 0.22, linewidth = 0.75) +
    facet_wrap(~Group, ncol = 2) +
    scale_fill_manual(name = "Significance", values = sig_palette, limits = names(sig_palette), drop = FALSE) +
    scale_color_manual(name = "Significance", values = sig_palette, limits = names(sig_palette), drop = FALSE) +
    scale_x_continuous(limits = c(-lim, lim), breaks = seq(-0.6, 0.6, by = 0.3),
                       labels = c("-0.6", "-0.3", "0.0", "+0.3", "+0.6")) +
    labs(
      title = "Panel B: Difference-in-Differences Moderated by Subjective Social Class",
      subtitle = "Relative to Control Condition (Targeted Binary IPW, 95% CI)",
      x = "DiD Treatment Effect (Change vs. Control)", y = ""
    ) +
    theme_barplot + theme(legend.position = "bottom")

  p_e / p_c + plot_layout(heights = c(1, 1.15))
}

p_stepwise <- step_panels(did$res_stepwise_primary$frame_edu, did$res_stepwise_primary$frame_class)
save_fig(p_stepwise, "figures/Figure_DiD_Edu_Class_Separate", 10, 9)

# ------------------------------------------------------------------------------
# Appendix Figure A.3: Pooled DiD (primary sample, unweighted; matches caption)
# ------------------------------------------------------------------------------
df_pool <- did$res_pooled$primary_unwt$frame %>% for_display()

p_pool <- ggplot(df_pool, aes(x = estimate, y = Condition, fill = sig, color = sig)) +
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
    title = sprintf("Difference-in-Differences Treatment Effects (%s)", SAMPLE_LABEL),
    subtitle = sprintf("Unweighted pooled model, relative to unexposed Control Condition (95%% CI, N = %d)",
                       did$res_pooled$n),
    x = "DiD Treatment Effect (Change Score vs. Control)",
    y = ""
  ) +
  theme_barplot +
  theme(legend.position = "bottom")
save_fig(p_pool, "figures/Figure_DiD_Pooled", 8.5, 5.5)

# ------------------------------------------------------------------------------
# Appendix Figure A.4: Sensitivity behavioral model (excl. Taste-Only, N = 1,649)
# ------------------------------------------------------------------------------
df11 <- prep_ame_frame(beh$beh_sens$mfx)
p11 <- plot_ame(
  df11,
  sprintf("Sensitivity Analysis: Behavioral Choices Excluding Taste-Only Conditions (%s, N = %d)",
          SAMPLE_LABEL, beh$beh_sens$n),
  "Relative to baseline reference group: Working Class, No College (IPW Weighted, 95% CI)"
)
save_fig(p11, "figures/Figure11_Sens_MultinomialBehavior", 11, 4.8)

cat("All 8 figures written to figures/ (png + pdf).\n")
