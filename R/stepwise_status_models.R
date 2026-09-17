# R/stepwise_status_models.R
# ==============================================================================
# Stepwise DiD Models: Education Alone and Subjective Social Class Alone
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
})

# Load clean data
source("R/dataproc.R")
data_list <- process_data()
df_wide <- data_list$wide
df_long <- data_list$long

# Ensure difference and factors are properly defined
df_wide$diff <- df_wide$taste2_rev - df_wide$taste1_rev
df_wide$cond2_refctrl <- relevel(df_wide$cond2_factor, ref = "Baseline")
df_long$cond2_refctrl <- relevel(df_long$cond2_factor, ref = "Baseline")

# Filter complete cases on strictly exogenous pre-treatment baseline covariates
df_wide_cc <- df_wide %>%
  filter(!is.na(college), !is.na(class), !is.na(age), !is.na(female), !is.na(raceeth), !is.na(parented))

# Map condition names to clean publication labels
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
# 1. Education-Moderated DiD Model (Targeted Binary IPW)
# ==============================================================================
cat("=== Estimating Targeted Binary IPW for Education ===\n")
W_edu <- weightit(
  college ~ age + female + factor(raceeth) + parented,
  data = df_wide_cc,
  method = "ps",
  estimand = "ATE"
)
df_wide_cc$ipw_edu <- W_edu$weights

cat("=== Estimating Education-Moderated DiD Model ===\n")
mod_edu <- lm(diff ~ cond2_refctrl * college_factor, data = df_wide_cc, weights = ipw_edu)

# Extract DiD contrasts against Baseline within each education level
comps_edu <- comparisons(
  mod_edu,
  variables = "cond2_refctrl",
  by = "college_factor"
)

df_edu_res <- as.data.frame(comps_edu) %>%
  mutate(
    Condition = clean_cond_labels(contrast),
    Condition = gsub(" - Baseline", "", Condition),
    Condition = clean_cond_labels(Condition),
    Group = college_factor,
    p_cat = case_when(
      p.value < 0.05 ~ "p < 0.05",
      p.value < 0.10 ~ "p < 0.10",
      TRUE ~ "Not Significant"
    ),
    p_cat = factor(p_cat, levels = c("p < 0.05", "p < 0.10", "Not Significant"))
  )

# ==============================================================================
# 2. Subjective Class-Moderated DiD Model (Targeted Binary IPW)
# ==============================================================================
cat("=== Estimating Targeted Binary IPW for Subjective Class ===\n")
W_class <- weightit(
  class ~ age + female + factor(raceeth) + parented,
  data = df_wide_cc,
  method = "ps",
  estimand = "ATE"
)
df_wide_cc$ipw_class <- W_class$weights

cat("=== Estimating Subjective Class-Moderated DiD Model ===\n")
mod_class <- lm(diff ~ cond2_refctrl * class_factor, data = df_wide_cc, weights = ipw_class)

comps_class <- comparisons(
  mod_class,
  variables = "cond2_refctrl",
  by = "class_factor"
)

df_class_res <- as.data.frame(comps_class) %>%
  mutate(
    Condition = clean_cond_labels(contrast),
    Condition = gsub(" - Baseline", "", Condition),
    Condition = clean_cond_labels(Condition),
    Group = class_factor,
    p_cat = case_when(
      p.value < 0.05 ~ "p < 0.05",
      p.value < 0.10 ~ "p < 0.10",
      TRUE ~ "Not Significant"
    ),
    p_cat = factor(p_cat, levels = c("p < 0.05", "p < 0.10", "Not Significant"))
  )

# Order conditions logically (top to bottom on y-axis):
# All Likes grouped together, all Dislikes grouped together: Generalized, High-Status, Low-Status
cond_order_top_down <- c(
  "Generalized Like",
  "High-Status Like",
  "Low-Status Like",
  "Generalized Dislike",
  "High-Status Dislike",
  "Low-Status Dislike"
)

# In ggplot, the last factor level appears at the top of the y-axis
cond_order_y <- rev(cond_order_top_down)

df_edu_res$Condition <- factor(df_edu_res$Condition, levels = cond_order_y)
df_class_res$Condition <- factor(df_class_res$Condition, levels = cond_order_y)

# ==============================================================================
# 3. Generate Publication-Quality Two-Panel Bar Plot
# ==============================================================================
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
    legend.title = element_blank(),
    legend.box = "horizontal",
    legend.margin = margin(t = 5, b = 5)
  )

sig_palette <- c(
  "p < 0.05" = "firebrick",
  "p < 0.10" = "darkorange2",
  "Not Significant" = "grey70"
)

# Panel A: Education (includes all 3 significance levels)
p_edu <- ggplot(df_edu_res, aes(x = estimate, y = Condition, fill = p_cat, color = p_cat)) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "grey40", linewidth = 0.6) +
  geom_col(width = 0.65, alpha = 0.85, color = NA) +
  geom_errorbar(aes(xmin = conf.low, xmax = conf.high), width = 0.25, linewidth = 0.75) +
  facet_wrap(~ Group, ncol = 2) +
  scale_fill_manual(name = "Significance", values = sig_palette, limits = names(sig_palette), drop = FALSE) +
  scale_color_manual(name = "Significance", values = sig_palette, limits = names(sig_palette), drop = FALSE) +
  scale_x_continuous(
    limits = c(-0.60, 0.50),
    breaks = c(-0.6, -0.4, -0.2, 0.0, 0.2, 0.4),
    labels = c("-0.6", "-0.4", "-0.2", "0.0", "+0.2", "+0.4")
  ) +
  labs(
    title = "A. Treatment Effects Moderated by Educational Attainment Alone",
    subtitle = "Difference-in-Differences estimates relative to unexposed Control Condition (95% CI)",
    x = "DiD Treatment Effect (Change Score vs. Control)",
    y = ""
  ) +
  theme_barplot +
  guides(
    fill = guide_legend(override.aes = list(color = sig_palette, fill = sig_palette)),
    color = "none"
  )

# Panel B: Subjective Class (hide redundant legend)
p_class <- ggplot(df_class_res, aes(x = estimate, y = Condition, fill = p_cat, color = p_cat)) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "grey40", linewidth = 0.6) +
  geom_col(width = 0.65, alpha = 0.85, color = NA) +
  geom_errorbar(aes(xmin = conf.low, xmax = conf.high), width = 0.25, linewidth = 0.75) +
  facet_wrap(~ Group, ncol = 2) +
  scale_fill_manual(name = "Significance", values = sig_palette, limits = names(sig_palette), drop = FALSE) +
  scale_color_manual(name = "Significance", values = sig_palette, limits = names(sig_palette), drop = FALSE) +
  scale_x_continuous(
    limits = c(-0.60, 0.50),
    breaks = c(-0.6, -0.4, -0.2, 0.0, 0.2, 0.4),
    labels = c("-0.6", "-0.4", "-0.2", "0.0", "+0.2", "+0.4")
  ) +
  labs(
    title = "B. Treatment Effects Moderated by Subjective Social Class Alone",
    subtitle = "Difference-in-Differences estimates relative to unexposed Control Condition (95% CI)",
    x = "DiD Treatment Effect (Change Score vs. Control)",
    y = ""
  ) +
  theme_barplot +
  theme(legend.position = "none")

# Extract clean single 3-level legend from Panel A
legend_shared <- cowplot::get_legend(p_edu)
p_edu_noleg <- p_edu + theme(legend.position = "none")

# Stack panels with a single clean shared legend at the bottom
p_combined <- (p_edu_noleg / plot_spacer() / p_class / plot_spacer() / legend_shared) +
  plot_layout(heights = c(1, 0.04, 1, 0.02, 0.1))

ggsave("figures/Figure_DiD_Edu_Class_Separate.png", p_combined, width = 10.5, height = 9.2, dpi = 300)
ggsave("figures/Figure_DiD_Edu_Class_Separate.pdf", p_combined, width = 10.5, height = 9.2)
cat("Saved plot to figures/Figure_DiD_Edu_Class_Separate.png and .pdf\n")

# ==============================================================================
# 4. Generate Formal LaTeX Table
# ==============================================================================
saveRDS(list(
  mod_edu = mod_edu,
  mod_class = mod_class,
  df_edu_res = df_edu_res,
  df_class_res = df_class_res
), "tables/table_did_edu_class_separate.rds")

format_cell <- function(est, se, p) {
  stars <- if (p < 0.001) "^{***}" else if (p < 0.01) "^{**}" else if (p < 0.05) "^{*}" else if (p < 0.10) "^{\\dagger}" else ""
  sprintf("%+.3f%s (%.3f)", est, stars, se)
}

# Construct side-by-side table rows following identical top-down order
conditions_display <- cond_order_top_down

tbl_lines <- c(
  "\\begin{table}[ht!]",
  "\\centering",
  "\\small",
  "\\caption{Difference-in-Differences Estimates Moderated Separately by Education and Subjective Class}",
  "\\label{tbl:did_edu_class}",
  "\\setlength{\\tabcolsep}{4.5pt}",
  "\\begin{tabular*}{\\linewidth}{@{\\extracolsep{\\fill}}lcccc@{}}",
  "\\toprule",
  "& \\multicolumn{2}{c}{\\textbf{Panel A: Education Alone}} & \\multicolumn{2}{c}{\\textbf{Panel B: Subjective Class Alone}} \\\\",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}",
  "\\textbf{Treatment Condition} & No College & College Degree & Working Class & Middle Class \\\\",
  "\\midrule"
)

for (cnd in conditions_display) {
  row_edu_nocol <- df_edu_res %>% filter(Group == "No College Degree", Condition == cnd)
  row_edu_col   <- df_edu_res %>% filter(Group == "College Degree", Condition == cnd)
  row_cls_wrk   <- df_class_res %>% filter(Group == "Working Class", Condition == cnd)
  row_cls_mid   <- df_class_res %>% filter(Group == "Middle Class", Condition == cnd)
  
  cell1 <- format_cell(row_edu_nocol$estimate, row_edu_nocol$std.error, row_edu_nocol$p.value)
  cell2 <- format_cell(row_edu_col$estimate, row_edu_col$std.error, row_edu_col$p.value)
  cell3 <- format_cell(row_cls_wrk$estimate, row_cls_wrk$std.error, row_cls_wrk$p.value)
  cell4 <- format_cell(row_cls_mid$estimate, row_cls_mid$std.error, row_cls_mid$p.value)
  
  tbl_lines <- c(tbl_lines, sprintf("%s & %s & %s & %s & %s \\\\", cnd, cell1, cell2, cell3, cell4))
}

# Add exposure drift baseline rows
nocol_drift <- coef(mod_edu)["(Intercept)"]
nocol_drift_se <- summary(mod_edu)$coefficients["(Intercept)", "Std. Error"]
nocol_drift_p <- summary(mod_edu)$coefficients["(Intercept)", "Pr(>|t|)"]

col_drift <- coef(mod_edu)["(Intercept)"] + coef(mod_edu)["college_factorCollege Degree"]
vcov_edu <- vcov(mod_edu)
col_drift_se <- sqrt(vcov_edu["(Intercept)", "(Intercept)"] + vcov_edu["college_factorCollege Degree", "college_factorCollege Degree"] + 2 * vcov_edu["(Intercept)", "college_factorCollege Degree"])
col_drift_p <- 2 * (1 - pnorm(abs(col_drift / col_drift_se)))

wrk_drift <- coef(mod_class)["(Intercept)"]
wrk_drift_se <- summary(mod_class)$coefficients["(Intercept)", "Std. Error"]
wrk_drift_p <- summary(mod_class)$coefficients["(Intercept)", "Pr(>|t|)"]

mid_drift <- coef(mod_class)["(Intercept)"] + coef(mod_class)["class_factorMiddle Class"]
vcov_cls <- vcov(mod_class)
mid_drift_se <- sqrt(vcov_cls["(Intercept)", "(Intercept)"] + vcov_cls["class_factorMiddle Class", "class_factorMiddle Class"] + 2 * vcov_cls["(Intercept)", "class_factorMiddle Class"])
mid_drift_p <- 2 * (1 - pnorm(abs(mid_drift / mid_drift_se)))

cell_drift1 <- format_cell(nocol_drift, nocol_drift_se, nocol_drift_p)
cell_drift2 <- format_cell(col_drift, col_drift_se, col_drift_p)
cell_drift3 <- format_cell(wrk_drift, wrk_drift_se, wrk_drift_p)
cell_drift4 <- format_cell(mid_drift, mid_drift_se, mid_drift_p)

tbl_lines <- c(
  tbl_lines,
  "\\midrule",
  sprintf("Control Condition Drift & %s & %s & %s & %s \\\\", cell_drift1, cell_drift2, cell_drift3, cell_drift4),
  sprintf("Sample Size ($N$) & %s & %s & %s & %s \\\\",
          format(sum(df_wide$college == 0), big.mark = ","),
          format(sum(df_wide$college == 1), big.mark = ","),
          format(sum(df_wide$class == 0), big.mark = ","),
          format(sum(df_wide$class == 1), big.mark = ",")),
  "\\bottomrule",
  "\\end{tabular*}",
  "\\begin{minipage}{\\linewidth}",
  "\\vspace{4pt}",
  "\\footnotesize",
  "\\textit{Note:} $^{\\dagger}p < 0.10, ^{*}p < 0.05, ^{**}p < 0.01, ^{***}p < 0.001$. Estimates represent Difference-in-Differences treatment contrasts relative to the unexposed Control Condition within each demographic subpopulation, estimated via targeted binary Inverse Probability Weighting (IPW) balancing baseline age, gender, race/ethnicity, and parental education. Panel A estimates moderation by educational attainment alone (No College Degree vs. Bachelor's Degree or Higher). Panel B estimates moderation by subjective social class identification alone (Working Class vs. Middle Class).",
  "\\end{minipage}",
  "\\end{table}"
)

writeLines(tbl_lines, "tables/table_did_edu_class_separate.tex")
cat("Saved LaTeX table to tables/table_did_edu_class_separate.tex\n")
