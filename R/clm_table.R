suppressMessages({
  library(haven)
  library(dplyr)
  library(ordinal)
  library(WeightIt)
})
source("R/dataproc.R")
df_wide <- process_data()$wide
df_long <- process_data()$long
df_wide_cc <- df_wide %>% filter(!is.na(objsubjclass_factor), !is.na(age), !is.na(female), !is.na(raceeth), !is.na(parented))
W <- weightit(objsubjclass_factor ~ age + female + factor(raceeth) + parented, data = df_wide_cc, method = "ps", estimand = "ATE")
df_wide_cc$ipw_weight <- W$weights
df_long_wt <- df_long %>% inner_join(df_wide_cc %>% select(id, ipw_weight), by = "id")
df_long_wt$taste_ord <- factor(df_long_wt$taste, ordered = TRUE, levels = 1:7)

mod_clm <- clm(taste_ord ~ factor(trial) * cond2_factor, data = df_long_wt, weights = ipw_weight)
summ <- summary(mod_clm)
cf <- summ$coefficients

cm <- c(
  "factor(trial)2" = "Trial 2 (Baseline Drift)",
  "factor(trial)2:cond2_factorClass & Taste/Like/+Status" = "Trial 2 x Like/+Status",
  "factor(trial)2:cond2_factorClass & Taste/Dislike/-Status" = "Trial 2 x Dislike/-Status",
  "factor(trial)2:cond2_factorClass & Taste/Dislike/+Status" = "Trial 2 x Dislike/+Status",
  "factor(trial)2:cond2_factorTaste Only/Like" = "Trial 2 x Taste Only (Like)",
  "factor(trial)2:cond2_factorTaste Only/Dislike" = "Trial 2 x Taste Only (Dislike)"
)

cat("\\begin{table}[ht!]\n\\centering\n\\caption{Cumulative Link Model for Change in Taste Evaluations (IPW Weighted)}\n\\label{tab:clm}\n\\begin{tabular}{lcc}\n\\hline\n\\hline\n", file="tables/clm_table.tex")
cat("Term & Estimate & Std. Error \\\\\n\\hline\n", file="tables/clm_table.tex", append=TRUE)

for (k in names(cm)) {
  est <- sprintf("%.3f", cf[k, "Estimate"])
  se <- sprintf("%.3f", cf[k, "Std. Error"])
  pval <- cf[k, "Pr(>|z|)"]
  stars <- ifelse(pval < 0.001, "***", ifelse(pval < 0.01, "**", ifelse(pval < 0.05, "*", "")))
  cat(sprintf("%s & %s%s & (%s) \\\\\n", cm[k], est, stars, se), file="tables/clm_table.tex", append=TRUE)
}

cat("\\hline\n\\end{tabular}\n\\end{table}\n", file="tables/clm_table.tex", append=TRUE)
