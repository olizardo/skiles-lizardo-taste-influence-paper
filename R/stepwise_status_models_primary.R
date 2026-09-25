# R/stepwise_status_models_primary.R
# ==============================================================================
# Stepwise DiD Table: Education Alone and Subjective Social Class Alone
# PRIMARY ANALYTIC SAMPLE (Age >= 24, N = 1,981)
#
# Companion table to figures/Figure_DiD_Edu_Class_Separate.png (already generated
# on the primary Age >= 24 sample by R/generate_all_updated_assets.R::generate_figure_4).
# The original R/stepwise_status_models.R script estimated this table on the FULL,
# unrestricted sample (N = 2,253) -- that output is now correctly labeled and used
# as Appendix Table tbl:did_edu_class_full. This script produces the matching
# LaTeX table restricted to the primary analytic sample so that the main-text
# Figure 4 companion figure (Figure_DiD_Edu_Class_Separate.png) has a same-sample
# regression table to accompany it in the appendix.
#
# Paper: "Stay, React, or Conform? Examining Social Influence Effects on Aesthetic Judgments"
# Authors: Omar Lizardo & Sara Skiles (Poetics POETICS-D-26-00490)
# ==============================================================================

suppressPackageStartupMessages({
  library(dplyr)
  library(WeightIt)
  library(marginaleffects)
})

source("R/dataproc.R")
data_list <- process_data()
df_wide <- data_list$wide

df_wide$diff <- df_wide$taste2_rev - df_wide$taste1_rev
df_wide$cond2_refctrl <- relevel(df_wide$cond2_factor, ref = "Baseline")

# Complete cases on strictly exogenous pre-treatment baseline covariates
df_wide_cc_full <- df_wide %>%
  filter(!is.na(objsubjclass_factor), !is.na(age), !is.na(female), !is.na(raceeth), !is.na(parented))

# Restrict to the primary analytic sample (Age >= 24/25), identical to
# R/generate_all_updated_assets.R
df_wide_cc_primary <- df_wide_cc_full %>%
  filter(age >= 4)

cat("Primary Restricted Sample (Age >= 24/25) N:", nrow(df_wide_cc_primary), "\n")

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
# 1. Education-Moderated DiD Model (Targeted Binary IPW), Primary Sample
# ==============================================================================
W_edu <- weightit(
  college ~ age + female + factor(raceeth) + parented,
  data = df_wide_cc_primary,
  method = "ps",
  estimand = "ATE"
)
df_wide_cc_primary$ipw_edu <- W_edu$weights

mod_edu <- lm(diff ~ cond2_refctrl * college_factor, data = df_wide_cc_primary, weights = ipw_edu)

comps_edu <- comparisons(mod_edu, variables = "cond2_refctrl", by = "college_factor")

df_edu_res <- as.data.frame(comps_edu) %>%
  mutate(
    Condition = clean_cond_labels(gsub(" - Baseline", "", contrast)),
    Group = college_factor
  )

# ==============================================================================
# 2. Subjective Class-Moderated DiD Model (Targeted Binary IPW), Primary Sample
# ==============================================================================
W_class <- weightit(
  class ~ age + female + factor(raceeth) + parented,
  data = df_wide_cc_primary,
  method = "ps",
  estimand = "ATE"
)
df_wide_cc_primary$ipw_class <- W_class$weights

mod_class <- lm(diff ~ cond2_refctrl * class_factor, data = df_wide_cc_primary, weights = ipw_class)

comps_class <- comparisons(mod_class, variables = "cond2_refctrl", by = "class_factor")

df_class_res <- as.data.frame(comps_class) %>%
  mutate(
    Condition = clean_cond_labels(gsub(" - Baseline", "", contrast)),
    Group = class_factor
  )

cond_order_top_down <- c(
  "Generalized Like",
  "High-Status Like",
  "Low-Status Like",
  "Generalized Dislike",
  "High-Status Dislike",
  "Low-Status Dislike"
)

# ==============================================================================
# 3. Build LaTeX Table (Primary Sample, Age >= 24)
# ==============================================================================
saveRDS(list(
  mod_edu = mod_edu,
  mod_class = mod_class,
  df_edu_res = df_edu_res,
  df_class_res = df_class_res
), "tables/table_did_edu_class_primary.rds")

format_cell <- function(est, se, p) {
  stars <- if (p < 0.001) "$^{***}$" else if (p < 0.01) "$^{**}$" else if (p < 0.05) "$^{*}$" else if (p < 0.10) "$^{\\dagger}$" else ""
  sprintf("%+.3f%s (%.3f)", est, stars, se)
}

tbl_lines <- c(
  "\\begin{table}[ht!]",
  "\\centering",
  "\\small",
  "\\caption{Difference-in-Differences Estimates Moderated Separately by Education and Subjective Class (Primary Sample, Age $\\ge 24$, $N = 1{,}981$)}",
  "\\label{tbl:did_edu_class_primary}",
  "\\setlength{\\tabcolsep}{2.0pt}",
  "\\begin{tabular*}{\\linewidth}{@{\\extracolsep{\\fill}}lcccc@{}}",
  "\\toprule",
  "& \\multicolumn{2}{c}{\\textbf{Panel A: Education Alone}} & \\multicolumn{2}{c}{\\textbf{Panel B: Subjective Class Alone}} \\\\",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}",
  "\\textbf{Treatment Condition} & No College & College Degree & Working Class & Middle Class \\\\",
  "\\midrule"
)

for (cnd in cond_order_top_down) {
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
          format(sum(df_wide_cc_primary$college == 0), big.mark = ","),
          format(sum(df_wide_cc_primary$college == 1), big.mark = ","),
          format(sum(df_wide_cc_primary$class == 0), big.mark = ","),
          format(sum(df_wide_cc_primary$class == 1), big.mark = ",")),
  "\\bottomrule",
  "\\end{tabular*}",
  "\\begin{minipage}{\\linewidth}",
  "\\vspace{4pt}",
  "\\footnotesize",
  "\\textit{Note:} $^{\\dagger}p < 0.10, ^{*}p < 0.05, ^{**}p < 0.01, ^{***}p < 0.001$. Standard errors in parentheses. \\newline \\textit{Note:} Estimates represent Difference-in-Differences treatment contrasts relative to the unexposed Control Condition within each demographic subpopulation, estimated via targeted binary Inverse Probability Weighting (IPW) balancing baseline age, gender, race/ethnicity, and parental education, for the primary analytic sample (Age $\\ge 24$). Panel A estimates moderation by educational attainment alone (No College Degree vs.\\ Bachelor's Degree or Higher). Panel B estimates moderation by subjective social class identification alone (Working Class vs.\\ Middle Class). See Figure \\ref{fig:did_edu_class_separate} for the corresponding visualization and Appendix Table \\ref{tbl:did_edu_class_full} for the identical specification on the full unrestricted sample ($N = 2{,}253$).",
  "\\end{minipage}",
  "\\end{table}"
)

writeLines(tbl_lines, "tables/table_did_edu_class_primary.tex")
cat("Saved LaTeX table to tables/table_did_edu_class_primary.tex\n")
