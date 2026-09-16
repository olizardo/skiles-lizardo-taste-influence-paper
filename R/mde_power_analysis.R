# R/mde_power_analysis.R
# ==============================================================================
# Ex-Post Minimum Detectable Effect (MDE) Power Analysis
# Paper: "Stay, React, or Conform? Examining Social Influence Effects on Aesthetic Judgments"
# Authors: Omar Lizardo & Sara Skiles (Poetics POETICS-D-26-00490)
# ==============================================================================
# This script computes formal ex-post Minimum Detectable Effect (MDE) benchmarks
# following Gelman (2000), Bloom (1995), and McKenzie (2012).
#
# Unlike flawed retrospective "observed power" calculations (which are merely a
# monotonic transformation of the observed p-value), ex-post MDE analysis answers
# the principled methodological question:
# "Given the actual achieved cell sample sizes and design variance parameters,
#  what is the minimum effect size that this study was adequately powered (80% or 90%)
#  to detect at alpha = 0.05?"
# ==============================================================================

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(ggplot2)
  library(patchwork)
  library(scales)
})

# Load clean data
source("R/dataproc.R")
data_list <- process_data()
df_wide <- data_list$wide

# ------------------------------------------------------------------------------
# 1. Empirical Parameters of the Repeated-Measures Design
# ------------------------------------------------------------------------------
df_clean <- df_wide %>% filter(!is.na(taste1_rev), !is.na(taste2_rev))
N_total <- nrow(df_clean)

# Baseline and post-treatment standard deviations
sd_t1 <- sd(df_clean$taste1_rev, na.rm = TRUE)      # 1.5001
sd_t2 <- sd(df_clean$taste2_rev, na.rm = TRUE)      # 1.5478
diff_taste <- df_clean$taste2_rev - df_clean$taste1_rev
sd_diff <- sd(diff_taste, na.rm = TRUE)             # 0.7017
r_test_retest <- cor(df_clean$taste1_rev, df_clean$taste2_rev, use = "complete.obs") # 0.8945

cat(sprintf("=== Design Parameters ===\n"))
cat(sprintf("Total Complete N: %d\n", N_total))
cat(sprintf("Trial 1 SD (sigma_1): %.4f\n", sd_t1))
cat(sprintf("Trial 2 SD (sigma_2): %.4f\n", sd_t2))
cat(sprintf("Change Score SD (sigma_delta): %.4f\n", sd_diff))
cat(sprintf("Pre-Post Correlation (rho): %.4f\n", r_test_retest))
cat(sprintf("Theoretical sigma_delta = sqrt(s1^2 + s2^2 - 2*rho*s1*s2): %.4f\n",
            sqrt(sd_t1^2 + sd_t2^2 - 2 * r_test_retest * sd_t1 * sd_t2)))

# ------------------------------------------------------------------------------
# 2. MDE Calculation Function
# ------------------------------------------------------------------------------
calc_mde <- function(n_t, n_c = NULL, s_diff = sd_diff, s_base = sd_t1, alpha = 0.05, power = 0.80) {
  z_crit <- qnorm(1 - alpha / 2) # 1.95996 for alpha = 0.05
  z_pwr  <- qnorm(power)         # 0.84162 for 80%, 1.28155 for 90%
  multiplier <- z_crit + z_pwr
  
  if (is.null(n_c)) {
    # Within-subject pre-post drift (one-sample paired contrast)
    se <- s_diff / sqrt(n_t)
  } else {
    # Two-sample Difference-in-Differences contrast vs. control
    se <- s_diff * sqrt(1 / n_t + 1 / n_c)
  }
  
  mde_raw <- multiplier * se
  mde_d   <- mde_raw / s_base
  
  return(list(se = se, mde_raw = mde_raw, mde_d = mde_d))
}

# ------------------------------------------------------------------------------
# 3. Systematically Calculate MDE Across All Analytical Levels
# ------------------------------------------------------------------------------
# A. Within-Subject Exposure Drift
mde_drift_full_80 <- calc_mde(n_t = 2253, power = 0.80)
mde_drift_full_90 <- calc_mde(n_t = 2253, power = 0.90)

mde_drift_ctrl_80 <- calc_mde(n_t = 177, power = 0.80)
mde_drift_ctrl_90 <- calc_mde(n_t = 177, power = 0.90)

# B. Pooled Difference-in-Differences Contrasts (Reference = Control N = 177)
# 1. Taste Only conditions (N = 172 vs. 177)
mde_did_to_80 <- calc_mde(n_t = 172, n_c = 177, power = 0.80)
mde_did_to_90 <- calc_mde(n_t = 172, n_c = 177, power = 0.90)

# 2. Single Status conditions (Like/-Status N=288, Dislike/-Status N=293, approx 290 vs. 177)
mde_did_single_80 <- calc_mde(n_t = 290, n_c = 177, power = 0.80)
mde_did_single_90 <- calc_mde(n_t = 290, n_c = 177, power = 0.90)

# 3. Pooled Status conditions (Like/+Status N=574, Dislike/+Status N=577, approx 575 vs. 177)
mde_did_pooled_80 <- calc_mde(n_t = 575, n_c = 177, power = 0.80)
mde_did_pooled_90 <- calc_mde(n_t = 575, n_c = 177, power = 0.90)

# C. Status Quadrant Subgroup DiD Contrasts
# Cell counts by quadrant:
# Working, No College: Control N=70, Taste Only N~66, Single N~104, Pooled N~212
# Middle, College:     Control N=51, Taste Only N~55, Single N~87,  Pooled N~157
# Middle, No College:  Control N=33, Taste Only N~33, Single N~64,  Pooled N~141
# Working, College:    Control N=23, Taste Only N~19, Single N~37,  Pooled N~67

subgroup_specs <- list(
  list(group = "Working Class, No College", n_c = 70, n_min = 60, n_max = 214, n_med = 104),
  list(group = "Middle Class, College",     n_c = 51, n_min = 51, n_max = 164, n_med = 87),
  list(group = "Middle Class, No College",  n_c = 33, n_min = 32, n_max = 146, n_med = 64),
  list(group = "Working Class, College",    n_c = 23, n_min = 16, n_max = 72,  n_med = 37)
)

subgroup_rows <- lapply(subgroup_specs, function(sg) {
  res_80 <- calc_mde(n_t = sg$n_med, n_c = sg$n_c, power = 0.80)
  res_90 <- calc_mde(n_t = sg$n_med, n_c = sg$n_c, power = 0.90)
  res_min80 <- calc_mde(n_t = sg$n_max, n_c = sg$n_c, power = 0.80)
  res_max80 <- calc_mde(n_t = sg$n_min, n_c = sg$n_c, power = 0.80)
  
  data.frame(
    Tier = "Subgroup Status DiD",
    Comparison = sg$group,
    N_T = sprintf("%d--%d", sg$n_min, sg$n_max),
    N_C = as.character(sg$n_c),
    SE = sprintf("%.3f", res_80$se),
    MDE_raw_80 = sprintf("%.3f", res_80$mde_raw),
    MDE_d_80 = sprintf("%.3f", res_80$mde_d),
    MDE_raw_90 = sprintf("%.3f", res_90$mde_raw),
    MDE_d_90 = sprintf("%.3f", res_90$mde_d),
    Range_d_80 = sprintf("%.2f--%.2f", res_min80$mde_d, res_max80$mde_d),
    stringsAsFactors = FALSE
  )
})

df_subgroups <- do.call(rbind, subgroup_rows)

# Build Comprehensive Summary Table
df_mde_summary <- rbind(
  data.frame(
    Tier = "Within-Subject Drift",
    Comparison = "Full Sample Repeated Measures Drift",
    N_T = "2,253", N_C = "---",
    SE = sprintf("%.3f", mde_drift_full_80$se),
    MDE_raw_80 = sprintf("%.3f", mde_drift_full_80$mde_raw),
    MDE_d_80 = sprintf("%.3f", mde_drift_full_80$mde_d),
    MDE_raw_90 = sprintf("%.3f", mde_drift_full_90$mde_raw),
    MDE_d_90 = sprintf("%.3f", mde_drift_full_90$mde_d),
    Range_d_80 = "---",
    stringsAsFactors = FALSE
  ),
  data.frame(
    Tier = "Within-Subject Drift",
    Comparison = "Control Condition Exposure Drift",
    N_T = "177", N_C = "---",
    SE = sprintf("%.3f", mde_drift_ctrl_80$se),
    MDE_raw_80 = sprintf("%.3f", mde_drift_ctrl_80$mde_raw),
    MDE_d_80 = sprintf("%.3f", mde_drift_ctrl_80$mde_d),
    MDE_raw_90 = sprintf("%.3f", mde_drift_ctrl_90$mde_raw),
    MDE_d_90 = sprintf("%.3f", mde_drift_ctrl_90$mde_d),
    Range_d_80 = "---",
    stringsAsFactors = FALSE
  ),
  data.frame(
    Tier = "Pooled DiD vs. Control",
    Comparison = "Taste-Only Conditions vs. Control",
    N_T = "172", N_C = "177",
    SE = sprintf("%.3f", mde_did_to_80$se),
    MDE_raw_80 = sprintf("%.3f", mde_did_to_80$mde_raw),
    MDE_d_80 = sprintf("%.3f", mde_did_to_80$mde_d),
    MDE_raw_90 = sprintf("%.3f", mde_did_to_90$mde_raw),
    MDE_d_90 = sprintf("%.3f", mde_did_to_90$mde_d),
    Range_d_80 = "---",
    stringsAsFactors = FALSE
  ),
  data.frame(
    Tier = "Pooled DiD vs. Control",
    Comparison = "Single Status Conditions vs. Control",
    N_T = "290", N_C = "177",
    SE = sprintf("%.3f", mde_did_single_80$se),
    MDE_raw_80 = sprintf("%.3f", mde_did_single_80$mde_raw),
    MDE_d_80 = sprintf("%.3f", mde_did_single_80$mde_d),
    MDE_raw_90 = sprintf("%.3f", mde_did_single_90$mde_raw),
    MDE_d_90 = sprintf("%.3f", mde_did_single_90$mde_d),
    Range_d_80 = "---",
    stringsAsFactors = FALSE
  ),
  data.frame(
    Tier = "Pooled DiD vs. Control",
    Comparison = "Pooled High-Status Conditions vs. Control",
    N_T = "575", N_C = "177",
    SE = sprintf("%.3f", mde_did_pooled_80$se),
    MDE_raw_80 = sprintf("%.3f", mde_did_pooled_80$mde_raw),
    MDE_d_80 = sprintf("%.3f", mde_did_pooled_80$mde_d),
    MDE_raw_90 = sprintf("%.3f", mde_did_pooled_90$mde_raw),
    MDE_d_90 = sprintf("%.3f", mde_did_pooled_90$mde_d),
    Range_d_80 = "---",
    stringsAsFactors = FALSE
  ),
  df_subgroups
)

saveRDS(df_mde_summary, "tables/table_mde_summary.rds")
cat("\nSaved MDE summary to tables/table_mde_summary.rds\n")

# ------------------------------------------------------------------------------
# 4. Export Publication-Grade LaTeX Table
# ------------------------------------------------------------------------------
latex_table <- c(
  "\\begin{table}[ht!]",
  "\\centering",
  "\\small",
  "\\caption{Ex-Post Minimum Detectable Effect (MDE) Analysis Across Experimental Specifications}",
  "\\label{tbl:mde_analysis}",
  "\\setlength{\\tabcolsep}{5.5pt}",
  "\\begin{tabular*}{\\linewidth}{@{\\extracolsep{\\fill}}lccccccc@{}}",
  "\\toprule",
  "& & & & \\multicolumn{2}{c}{\\textbf{80\\% Power}} & \\multicolumn{2}{c}{\\textbf{90\\% Power}} \\\\",
  "\\cmidrule(lr){5-6} \\cmidrule(lr){7-8}",
  "\\textbf{Model Specification / Level} & $N_T$ & $N_C$ & $SE$ & $\\text{MDE}_{\\text{raw}}$ & Cohen's $d$ & $\\text{MDE}_{\\text{raw}}$ & Cohen's $d$ \\\\",
  "\\midrule",
  "\\multicolumn{8}{l}{\\textit{Panel A: Within-Subject Exposure Drift (Paired Comparison)}} \\\\[2pt]",
  sprintf("Full Sample Drift & %s & %s & %s & %s & %s & %s & %s \\\\",
          df_mde_summary$N_T[1], df_mde_summary$N_C[1], df_mde_summary$SE[1],
          df_mde_summary$MDE_raw_80[1], df_mde_summary$MDE_d_80[1],
          df_mde_summary$MDE_raw_90[1], df_mde_summary$MDE_d_90[1]),
  sprintf("Control Condition Drift & %s & %s & %s & %s & %s & %s & %s \\\\",
          df_mde_summary$N_T[2], df_mde_summary$N_C[2], df_mde_summary$SE[2],
          df_mde_summary$MDE_raw_80[2], df_mde_summary$MDE_d_80[2],
          df_mde_summary$MDE_raw_90[2], df_mde_summary$MDE_d_90[2]),
  "\\addlinespace[4pt]",
  "\\multicolumn{8}{l}{\\textit{Panel B: Pooled Difference-in-Differences Contrasts (vs. Control $N_C=177$)}} \\\\[2pt]",
  sprintf("Taste-Only Conditions & %s & %s & %s & %s & %s & %s & %s \\\\",
          df_mde_summary$N_T[3], df_mde_summary$N_C[3], df_mde_summary$SE[3],
          df_mde_summary$MDE_raw_80[3], df_mde_summary$MDE_d_80[3],
          df_mde_summary$MDE_raw_90[3], df_mde_summary$MDE_d_90[3]),
  sprintf("Single Status Conditions & %s & %s & %s & %s & %s & %s & %s \\\\",
          df_mde_summary$N_T[4], df_mde_summary$N_C[4], df_mde_summary$SE[4],
          df_mde_summary$MDE_raw_80[4], df_mde_summary$MDE_d_80[4],
          df_mde_summary$MDE_raw_90[4], df_mde_summary$MDE_d_90[4]),
  sprintf("Pooled High-Status Conditions & %s & %s & %s & %s & %s & %s & %s \\\\",
          df_mde_summary$N_T[5], df_mde_summary$N_C[5], df_mde_summary$SE[5],
          df_mde_summary$MDE_raw_80[5], df_mde_summary$MDE_d_80[5],
          df_mde_summary$MDE_raw_90[5], df_mde_summary$MDE_d_90[5]),
  "\\addlinespace[4pt]",
  "\\multicolumn{8}{l}{\\textit{Panel C: Subgroup DiD Contrasts Within Status Consistency Quadrants}} \\\\[2pt]",
  sprintf("Working Class, No College & %s & %s & %s & %s & %s & %s & %s \\\\",
          df_mde_summary$N_T[6], df_mde_summary$N_C[6], df_mde_summary$SE[6],
          df_mde_summary$MDE_raw_80[6], df_mde_summary$MDE_d_80[6],
          df_mde_summary$MDE_raw_90[6], df_mde_summary$MDE_d_90[6]),
  sprintf("Middle Class, College & %s & %s & %s & %s & %s & %s & %s \\\\",
          df_mde_summary$N_T[7], df_mde_summary$N_C[7], df_mde_summary$SE[7],
          df_mde_summary$MDE_raw_80[7], df_mde_summary$MDE_d_80[7],
          df_mde_summary$MDE_raw_90[7], df_mde_summary$MDE_d_90[7]),
  sprintf("Middle Class, No College & %s & %s & %s & %s & %s & %s & %s \\\\",
          df_mde_summary$N_T[8], df_mde_summary$N_C[8], df_mde_summary$SE[8],
          df_mde_summary$MDE_raw_80[8], df_mde_summary$MDE_d_80[8],
          df_mde_summary$MDE_raw_90[8], df_mde_summary$MDE_d_90[8]),
  sprintf("Working Class, College & %s & %s & %s & %s & %s & %s & %s \\\\",
          df_mde_summary$N_T[9], df_mde_summary$N_C[9], df_mde_summary$SE[9],
          df_mde_summary$MDE_raw_80[9], df_mde_summary$MDE_d_80[9],
          df_mde_summary$MDE_raw_90[9], df_mde_summary$MDE_d_90[9]),
  "\\bottomrule",
  "\\end{tabular*}",
  "\\begin{minipage}{\\linewidth}",
  "\\vspace{4pt}",
  "\\footnotesize",
  "\\textit{Note:} Minimum Detectable Effects (MDE) are calculated assuming a two-tailed $\\alpha = 0.05$ with standard statistical power thresholds of $80\\%$ ($z = 2.802$) and $90\\%$ ($z = 3.242$). Calculations incorporate the empirical test-retest correlation across repeated trials ($r = 0.8945$, yielding $\\sigma_{\\Delta} = 0.702$ relative to baseline $\\sigma_1 = 1.500$). $\\text{MDE}_{\\text{raw}}$ is expressed in units of the 7-point aesthetic rating scale; Cohen's $d = \\text{MDE}_{\\text{raw}} / \\sigma_1$. In Panel C, $N_T$ indicates the range of treatment cell sizes across specific cue conditions, and reported $SE$ and MDE values correspond to median cell sizes.",
  "\\end{minipage}",
  "\\end{table}"
)

writeLines(latex_table, "tables/table_mde_summary.tex")
cat("Saved LaTeX table to tables/table_mde_summary.tex\n")

# ------------------------------------------------------------------------------
# 5. Generate Publication-Quality Figure: Power Curves and Design Benchmarks
# ------------------------------------------------------------------------------
n_seq <- seq(20, 500, by = 5)
cor_levels <- c(0.00, 0.50, 0.70, 0.8945)

df_curves <- expand.grid(n = n_seq, rho = cor_levels) %>%
  mutate(
    sd_ratio = sqrt(2 * (1 - rho)),
    se_did = sd_ratio * sqrt(2 / n),
    mde_d = (qnorm(0.975) + qnorm(0.80)) * se_did,
    rho_fac = factor(
      rho,
      levels = cor_levels,
      labels = c(
        "r = 0.00 (Independent Post-Test)",
        "r = 0.50 (Moderate Autocorrelation)",
        "r = 0.70 (Standard Repeated Measures)",
        "r = 0.89 (Empirical Study Precision)"
      )
    )
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
    legend.title = element_blank(),
    legend.text = element_text(size = 9.5)
  )

p_curves_clean <- ggplot(df_curves, aes(x = n, y = mde_d, color = rho_fac, linetype = rho_fac)) +
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

# Empirical points
empirical_points <- data.frame(
  Spec = factor(
    c(
      "Full Sample Drift",
      "Control Condition Drift",
      "Pooled DiD (High-Status)",
      "Pooled DiD (Single Status)",
      "Pooled DiD (Taste-Only)",
      "DiD: Working/No College",
      "DiD: Middle/College",
      "DiD: Middle/No College",
      "DiD: Working/College"
    ),
    levels = rev(c(
      "Full Sample Drift",
      "Control Condition Drift",
      "Pooled DiD (High-Status)",
      "Pooled DiD (Single Status)",
      "Pooled DiD (Taste-Only)",
      "DiD: Working/No College",
      "DiD: Middle/College",
      "DiD: Middle/No College",
      "DiD: Working/College"
    ))
  ),
  Category = factor(
    c("Drift", "Drift", "Pooled DiD", "Pooled DiD", "Pooled DiD",
      "Subgroup DiD", "Subgroup DiD", "Subgroup DiD", "Subgroup DiD"),
    levels = c("Drift", "Pooled DiD", "Subgroup DiD")
  ),
  MDE_d_80 = c(
    as.numeric(df_mde_summary$MDE_d_80[1]),
    as.numeric(df_mde_summary$MDE_d_80[2]),
    as.numeric(df_mde_summary$MDE_d_80[5]),
    as.numeric(df_mde_summary$MDE_d_80[4]),
    as.numeric(df_mde_summary$MDE_d_80[3]),
    as.numeric(df_mde_summary$MDE_d_80[6]),
    as.numeric(df_mde_summary$MDE_d_80[7]),
    as.numeric(df_mde_summary$MDE_d_80[8]),
    as.numeric(df_mde_summary$MDE_d_80[9])
  ),
  MDE_raw_80 = c(
    as.numeric(df_mde_summary$MDE_raw_80[1]),
    as.numeric(df_mde_summary$MDE_raw_80[2]),
    as.numeric(df_mde_summary$MDE_raw_80[5]),
    as.numeric(df_mde_summary$MDE_raw_80[4]),
    as.numeric(df_mde_summary$MDE_raw_80[3]),
    as.numeric(df_mde_summary$MDE_raw_80[6]),
    as.numeric(df_mde_summary$MDE_raw_80[7]),
    as.numeric(df_mde_summary$MDE_raw_80[8]),
    as.numeric(df_mde_summary$MDE_raw_80[9])
  )
)

p_emp_clean <- ggplot(empirical_points, aes(x = MDE_d_80, y = Spec, color = Category)) +
  geom_vline(xintercept = 0.20, linetype = "dotted", color = "grey40", linewidth = 0.6) +
  geom_vline(xintercept = 0.50, linetype = "dashed", color = "grey40", linewidth = 0.6) +
  geom_segment(aes(x = 0, xend = MDE_d_80, y = Spec, yend = Spec), linewidth = 0.9) +
  geom_point(size = 3.5) +
  geom_text(aes(label = sprintf("%.2f (%.2f pts)", MDE_d_80, MDE_raw_80)),
            hjust = -0.12, size = 3.2, fontface = "bold", show.legend = FALSE) +
  scale_color_manual(
    values = c("Drift" = "#2CA02C", "Pooled DiD" = "#1F77B4", "Subgroup DiD" = "#D62728")
  ) +
  coord_cartesian(xlim = c(0, 0.56)) +
  scale_x_continuous(breaks = seq(0, 0.50, by = 0.10)) +
  labs(
    title = "B. Empirical MDE Achieved in This Study (Power = 0.80)",
    subtitle = expression(paste("Standardized Cohen's ", italic(d), " (and 7-point scale raw units) at ", alpha, " = 0.05")),
    x = "Minimum Detectable Effect (Cohen's d)",
    y = ""
  ) +
  theme_pub +
  theme(legend.position = "bottom")

p_combined <- p_curves_clean + p_emp_clean +
  plot_layout(ncol = 2, widths = c(1.15, 1.2))

ggsave("figures/Figure_MDE_Power_Curves.png", p_combined, width = 13, height = 6.2, dpi = 300)
ggsave("figures/Figure_MDE_Power_Curves.pdf", p_combined, width = 13, height = 6.2)

cat("Successfully generated and saved figures/Figure_MDE_Power_Curves.png and .pdf\n")
