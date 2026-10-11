# R/05_ipw_balance.R
# ==============================================================================
# IPW Covariate Balance (Step 05)
#
# Produces the covariate balance Love plot (Figure 2 in the manuscript) for the
# multinomial IPW weighting across status-consistency quadrants (primary
# sample), plus the raw (pre-weighting) standardized mean differences and
# covariate-by-experimental-arm balance tests.
# ==============================================================================

suppressPackageStartupMessages({
  library(dplyr)
  library(cobalt)
  library(WeightIt)
})

source("R/01_dataproc.R")

cat("\n================= STEP 05: IPW BALANCE =================\n")

did_res <- readRDS("tables/model_results_did.rds")
W_quad_primary <- did_res$W_quad_primary

samples <- build_samples()
pri <- samples$wide_cc_primary

# --- Love plot (Figure 2) ------------------------------------------------------
# Note: raceeth_f is a factor (created in 01_dataproc.R), so cobalt reports one
# SMD per race/ethnicity category rather than a single misleading SMD over the
# numeric codes. var.names maps the internal cobalt term names to intuitive
# display labels for the y-axis.
balance_var_names <- c(
  "age_f_25-29"            = "Age: 25-29",
  "age_f_30-34"            = "Age: 30-34",
  "age_f_35-39"            = "Age: 35-39",
  "age_f_40-44"            = "Age: 40-44",
  "age_f_45-49"            = "Age: 45-49",
  "age_f_50-54"            = "Age: 50-54",
  "age_f_55-59"            = "Age: 55-59",
  "age_f_60-64"            = "Age: 60-64",
  "age_f_65-69"            = "Age: 65-69",
  "age_f_70-74"            = "Age: 70-74",
  "age_f_75-79"            = "Age: 75-79",
  "age_f_80+"              = "Age: 80+",
  "female"                 = "Female",
  "parented"               = "Parent has a college degree",
  "raceeth_f_Asian"        = "Race/Ethnicity: Asian",
  "raceeth_f_Black"        = "Race/Ethnicity: Black",
  "raceeth_f_Hispanic"     = "Race/Ethnicity: Hispanic",
  "raceeth_f_White"        = "Race/Ethnicity: White",
  "raceeth_f_Multiracial"  = "Race/Ethnicity: Multiracial",
  "raceeth_f_Other"        = "Race/Ethnicity: Other"
)

# Grouped display order: with the display labels in var.names, "alphabetical"
# sorts all age brackets together youngest to oldest (Age: 25-29 ... Age: 80+),
# then Female, parental education, then race/ethnicity categories.

fig_balance <- love.plot(
  W_quad_primary,
  binary = "std",
  thresholds = c(m = .1),
  var.order = "alphabetical",
  var.names = balance_var_names,
  title = "Covariate Balance Across Status Groups Before and After IPW Weighting (Age >= 25 Sample)"
) +
  ggplot2::theme_minimal(base_size = 12) +
  ggplot2::theme(
    plot.title = ggplot2::element_text(face = "bold", size = 12, hjust = 0),
    legend.position = "bottom"
  )

saveRDS(list(fig_balance = fig_balance, W_quad_primary = W_quad_primary),
        "tables/balance_results.rds")

# --- Raw and weighted SMDs -----------------------------------------------------
bal_raw <- bal.tab(W_quad_primary, binary = "std", un = TRUE, thresholds = c(m = .1), which.treat = .all)
raw_max_by_var <- apply(abs(sapply(bal_raw$Pair.Balance, function(x) x$Balance$Diff.Un)), 1, max)
adj_max_by_var <- apply(abs(sapply(bal_raw$Pair.Balance, function(x) x$Balance$Diff.Adj)), 1, max)
smd_summary <- data.frame(
  covariate = rownames(bal_raw$Pair.Balance[[1]]$Balance),
  max_smd_raw = round(as.numeric(raw_max_by_var), 3),
  max_smd_weighted = round(as.numeric(adj_max_by_var), 3)
)
max_smd_raw <- max(smd_summary$max_smd_raw)
max_smd_adj <- max(smd_summary$max_smd_weighted)

# --- Covariate-by-experimental-arm balance tests (randomization check) -------
pri$.regiongrp <- dplyr::case_when(
  pri$region %in% c(1, 2) ~ "Northeast", pri$region %in% c(3, 4) ~ "Midwest",
  pri$region %in% c(5, 6, 7) ~ "South", pri$region %in% c(8, 9) ~ "West",
  TRUE ~ NA_character_
)
arm_tests <- data.frame()
for (v in c("age", "parented", "female", "raceeth", ".regiongrp", "college", "taste1_rev")) {
  if (v %in% c("female", "raceeth", ".regiongrp", "college")) {
    p <- suppressWarnings(chisq.test(table(pri[[v]], pri$cond2_factor))$p.value)
    stat <- suppressWarnings(chisq.test(table(pri[[v]], pri$cond2_factor))$statistic)
    method <- "Chi-square"
  } else {
    fit <- aov(pri[[v]] ~ pri$cond2_factor)
    p <- summary(fit)[[1]][["Pr(>F)"]][1]
    stat <- summary(fit)[[1]][["F value"]][1]
    method <- "ANOVA F"
  }
  arm_tests <- rbind(arm_tests, data.frame(covariate = v, test = method,
                                           statistic = unname(stat), p = unname(p)))
}

saveRDS(list(max_smd_raw = max_smd_raw, max_smd_adj = max_smd_adj,
             smd_summary = smd_summary,
             arm_tests = arm_tests),
        "tables/balance_stats.rds")

cat("Max raw SMD:", round(max_smd_raw, 3), "| Max weighted SMD:", round(max_smd_adj, 3), "\n")
for (i in seq_len(nrow(arm_tests))) {
  cat(sprintf("  Arm balance -- %-11s (%s): stat %.2f, p %.4f\n",
              arm_tests$covariate[i], arm_tests$test[i],
              arm_tests$statistic[i], arm_tests$p[i]))
}
cat("Saved tables/balance_results.rds and tables/balance_stats.rds\n")
