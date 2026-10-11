# R/08_make_tables.R
# ==============================================================================
# LaTeX Table Generation (Step 08)
#
# Writes every results table as a .tex file from the saved model results.
# The manuscript either \input{}s these files directly or contains numbers
# verified against them in the number-audit pass.
#
# Outputs:
#   tables/table_mde_summary.tex             (Appendix Table A.1)
#   tables/table_did_edu_4tiers.tex          (Appendix Table A.2)
#   tables/table_did_status_quadrants.tex    (Appendix Table A.3)
#   tables/table_did_edu_class_primary.tex   (Appendix Table A.4)
#   tables/table_did_pooled_compare.tex      (Appendix Table A.5)
#   tables/table_did_edu_class_separate.tex  (Appendix Table A.7, full sample)
#   tables/table_did_status_quadrants_full.tex(Appendix Table A.8, full sample)
# ==============================================================================

suppressPackageStartupMessages({
  library(dplyr)
})

cat("\n================ STEP 08: TABLES =================\n")

did <- readRDS("tables/model_results_did.rds")
mde <- readRDS("tables/mde_results.rds")

cond_order_top_down <- c(
  "Generalized Like", "High-Status Like", "Low-Status Like",
  "Generalized Dislike", "High-Status Dislike", "Low-Status Dislike"
)

format_cell <- function(est, se, p) {
  stars <- if (p < 0.001) "$^{***}$" else if (p < 0.01) "$^{**}$" else if (p < 0.05) "$^{*}$" else if (p < 0.10) "$^{\\dagger}$" else ""
  sprintf("%+.3f%s (%.3f)", est, stars, se)
}

fmt_p <- function(p) {
  if (p < 0.001) "< 0.001" else sprintf("%.3f", p)
}

# ------------------------------------------------------------------------------
# Appendix Table A.1: MDE summary
# ------------------------------------------------------------------------------
dm <- mde$df_mde
inp <- mde$mde_inputs

tex_mde <- c(
  "\\begin{table}[ht!]",
  "\\centering",
  "\\small",
  "\\caption{Ex-Post Minimum Detectable Effect (MDE) Analysis Across Experimental Specifications (Age $\\ge 25$ Sample)}",
  "\\label{tbl:mde_analysis}",
  "\\setlength{\\tabcolsep}{4.0pt}",
  "\\begin{tabular*}{\\linewidth}{@{\\extracolsep{\\fill}}lccccccc@{}}",
  "\\toprule",
  "& & & & \\multicolumn{2}{c}{\\textbf{80\\% Power}} & \\multicolumn{2}{c}{\\textbf{90\\% Power}} \\\\",
  "\\cmidrule(lr){5-6} \\cmidrule(lr){7-8}",
  "\\textbf{Model Specification / Level} & $N_T$ & $N_C$ & $SE$ & $\\text{MDE}_{\\text{raw}}$ & Cohen's $d$ & $\\text{MDE}_{\\text{raw}}$ & Cohen's $d$ \\\\",
  "\\midrule",
  "\\multicolumn{8}{l}{\\textit{Panel A: Within-Subject Exposure Drift (Paired Comparison)}} \\\\[2pt]",
  sprintf("Primary Sample Drift & %s & %s & %s & %s & %s & %s & %s \\\\",
          dm$N_T[1], dm$N_C[1], dm$SE[1], dm$MDE_raw_80[1], dm$MDE_d_80[1],
          dm$MDE_raw_90[1], dm$MDE_d_90[1]),
  sprintf("Control Condition Drift & %s & %s & %s & %s & %s & %s & %s \\\\",
          dm$N_T[2], dm$N_C[2], dm$SE[2], dm$MDE_raw_80[2], dm$MDE_d_80[2],
          dm$MDE_raw_90[2], dm$MDE_d_90[2]),
  "\\addlinespace[4pt]",
  sprintf("\\multicolumn{8}{l}{\\textit{Panel B: Pooled Difference-in-Differences Contrasts (vs.\\ Control, $N_C = %d$)}} \\\\[2pt]", inp$n_ctrl_primary),
  sprintf("Taste-Only Conditions (mean per arm) & %s & %s & %s & %s & %s & %s & %s \\\\",
          dm$N_T[3], dm$N_C[3], dm$SE[3], dm$MDE_raw_80[3], dm$MDE_d_80[3],
          dm$MDE_raw_90[3], dm$MDE_d_90[3]),
  sprintf("Single-Status Cue Conditions (mean per arm) & %s & %s & %s & %s & %s & %s & %s \\\\",
          dm$N_T[4], dm$N_C[4], dm$SE[4], dm$MDE_raw_80[4], dm$MDE_d_80[4],
          dm$MDE_raw_90[4], dm$MDE_d_90[4]),
  sprintf("Pooled High-Status Conditions (mean per arm) & %s & %s & %s & %s & %s & %s & %s \\\\",
          dm$N_T[5], dm$N_C[5], dm$SE[5], dm$MDE_raw_80[5], dm$MDE_d_80[5],
          dm$MDE_raw_90[5], dm$MDE_d_90[5]),
  "\\addlinespace[4pt]",
  "\\multicolumn{8}{l}{\\textit{Panel C: Subgroup DiD Contrasts Within Status Consistency Quadrants}} \\\\[2pt]",
  sprintf("%s & %s & %s & %s & %s & %s & %s & %s \\\\",
          dm$Comparison[6], dm$N_T[6], dm$N_C[6], dm$SE[6], dm$MDE_raw_80[6], dm$MDE_d_80[6],
          dm$MDE_raw_90[6], dm$MDE_d_90[6]),
  sprintf("%s & %s & %s & %s & %s & %s & %s & %s \\\\",
          dm$Comparison[7], dm$N_T[7], dm$N_C[7], dm$SE[7], dm$MDE_raw_80[7], dm$MDE_d_80[7],
          dm$MDE_raw_90[7], dm$MDE_d_90[7]),
  sprintf("%s & %s & %s & %s & %s & %s & %s & %s \\\\",
          dm$Comparison[8], dm$N_T[8], dm$N_C[8], dm$SE[8], dm$MDE_raw_80[8], dm$MDE_d_80[8],
          dm$MDE_raw_90[8], dm$MDE_d_90[8]),
  sprintf("%s & %s & %s & %s & %s & %s & %s & %s \\\\",
          dm$Comparison[9], dm$N_T[9], dm$N_C[9], dm$SE[9], dm$MDE_raw_80[9], dm$MDE_d_80[9],
          dm$MDE_raw_90[9], dm$MDE_d_90[9]),
  "\\bottomrule",
  "\\end{tabular*}",
  "\\begin{minipage}{\\linewidth}",
  "\\vspace{4pt}",
  "\\footnotesize",
  sprintf(paste0("\\textit{Note:} Minimum Detectable Effects (MDE) are calculated assuming a two-tailed $\\alpha = 0.05$ ",
                 "with standard statistical power thresholds of $80\\%%$ ($z = 2.802$) and $90\\%%$ ($z = 3.242$). ",
                 "Calculations incorporate the empirical test-retest correlation across repeated trials ",
                 "($r = %.4f$, yielding $\\sigma_{\\Delta} = %.3f$ relative to baseline $\\sigma_1 = %.3f$). ",
                 "$\\text{MDE}_{\\text{raw}}$ is expressed in units of the 7-point aesthetic rating scale; ",
                 "Cohen's $d = \\text{MDE}_{\\text{raw}} / \\sigma_1$. In Panels B and C, $N_T$ values for pooled rows are ",
                 "mean per-condition cell sizes; in Panel C, $N_T$ indicates the range of treatment cell sizes across ",
                 "specific cue conditions, and reported $SE$ and MDE values correspond to median cell sizes."),
          inp$rho, inp$sd_diff, inp$sd_t1),
  "\\end{minipage}",
  "\\end{table}"
)
writeLines(tex_mde, "tables/table_mde_summary.tex")

# ------------------------------------------------------------------------------
# Appendix Table A.2: Four-tier education model
# ------------------------------------------------------------------------------
tier_levels <- c("High School or Less", "Associate/Some College",
                 "Bachelor's Degree", "Postgraduate")
tier_headers <- c("HS or Less", "2-Yr / Some Col", "Bachelor's", "Postgraduate")
e4 <- did$res_edu4
e4d <- did$res_edu4_drift
tier_n <- vapply(tier_levels, function(t) {
  gn <- unique(e4$group_n[as.character(e4$Group) == t])
  if (length(gn) != 1) stop("tier N lookup failed for ", t)
  as.integer(gn)
}, integer(1))

cell4 <- function(cond, tier) {
  r <- e4 %>% filter(as.character(Condition) == cond, as.character(Group) == tier)
  if (nrow(r) != 1) stop("missing cell: ", cond, "/", tier)
  format_cell(r$estimate, r$std.error, r$p.value)
}
drift4 <- function(tier) {
  r <- e4d %>% filter(Group == tier)
  format_cell(r$drift, r$drift_se, r$drift_p)
}

tex_e4 <- c(
  "\\begin{table}[ht!]",
  "\\centering",
  "\\small",
  "\\caption{Difference-in-Differences Treatment Effects Across Four Educational Groups (Age $\\ge 25$ Sample, IPW-Weighted)}",
  "\\label{tbl:did_edu_4tiers}",
  "\\setlength{\\tabcolsep}{2.5pt}",
  "\\begin{tabular*}{\\linewidth}{@{\\extracolsep{\\fill}}lcccc@{}}",
  "\\toprule",
  sprintf("\\textbf{Treatment Condition} & \\textbf{%s} & \\textbf{%s} & \\textbf{%s} & \\textbf{%s} \\\\",
          tier_headers[1], tier_headers[2], tier_headers[3], tier_headers[4]),
  "\\midrule",
  vapply(cond_order_top_down, function(cc) {
    sprintf("%s & %s & %s & %s & %s \\\\", cc,
            cell4(cc, tier_levels[1]), cell4(cc, tier_levels[2]),
            cell4(cc, tier_levels[3]), cell4(cc, tier_levels[4]))
  }, character(1)),
  "\\midrule",
  sprintf("Control Exposure Drift & %s & %s & %s & %s \\\\",
          drift4(tier_levels[1]), drift4(tier_levels[2]),
          drift4(tier_levels[3]), drift4(tier_levels[4])),
  sprintf("Analytic Sample ($N$) & %d & %d & %d & %d \\\\",
          tier_n[1], tier_n[2], tier_n[3], tier_n[4]),
  "\\bottomrule",
  "\\end{tabular*}",
  "\\begin{minipage}{\\linewidth}",
  "\\vspace{4pt}",
  "\\footnotesize",
  "$^{\\dagger}p < 0.10, ^{*}p < 0.05, ^{**}p < 0.01, ^{***}p < 0.001$. Standard errors in parentheses. \\newline \\textit{Note:} Estimates represent Difference-in-Differences treatment contrasts relative to the unexposed Control Condition within each educational group, estimated using multinomial Inverse Probability Weighting (IPW) to balance baseline age, gender, race/ethnicity, and parental education.",
  "\\end{minipage}",
  "\\end{table}"
)
writeLines(unlist(lapply(tex_e4, function(x) if (length(x) > 1) x else x)), "tables/table_did_edu_4tiers.tex")

# ------------------------------------------------------------------------------
# Appendix Tables A.3 / A.8: Status consistency quadrants (primary / full)
# ------------------------------------------------------------------------------
quad_levels <- c("Working, No College", "Working, College",
                 "Middle, No College", "Middle, College")

make_quadrant_table <- function(frame, drifts, caption, label, note, ns) {
  cellq <- function(cond, quad) {
    r <- frame %>% filter(as.character(Condition) == cond, as.character(Group) == quad)
    if (nrow(r) != 1) stop("missing cell: ", cond, "/", quad)
    format_cell(r$estimate, r$std.error, r$p.value)
  }
  driftq <- function(quad) {
    r <- drifts %>% filter(Group == quad)
    format_cell(r$drift, r$drift_se, r$drift_p)
  }
  c(
    "\\begin{table}[ht!]",
    "\\centering",
    "\\small",
    paste0("\\caption{", caption, "}"),
    paste0("\\label{", label, "}"),
    "\\setlength{\\tabcolsep}{2.5pt}",
    "\\begin{tabular*}{\\linewidth}{@{\\extracolsep{\\fill}}lcccc@{}}",
    "\\toprule",
    "& \\multicolumn{2}{c}{\\textbf{Working Class Identification}} & \\multicolumn{2}{c}{\\textbf{Middle Class Identification}} \\\\",
    "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}",
    "\\textbf{Treatment Condition} & No College & College Degree & No College & College Degree \\\\",
    "\\midrule",
    vapply(cond_order_top_down, function(cc) {
      sprintf("%s & %s & %s & %s & %s \\\\", cc,
              cellq(cc, quad_levels[1]), cellq(cc, quad_levels[2]),
              cellq(cc, quad_levels[3]), cellq(cc, quad_levels[4]))
    }, character(1)),
    "\\midrule",
    sprintf("Control Exposure Drift & %s & %s & %s & %s \\\\",
            driftq(quad_levels[1]), driftq(quad_levels[2]),
            driftq(quad_levels[3]), driftq(quad_levels[4])),
    sprintf("Analytic Sample ($N$) & %d & %d & %d & %d \\\\", ns[1], ns[2], ns[3], ns[4]),
    "\\bottomrule",
    "\\end{tabular*}",
    "\\begin{minipage}{\\linewidth}",
    "\\vspace{4pt}",
    "\\footnotesize",
    "$^{\\dagger}p < 0.10, ^{*}p < 0.05, ^{**}p < 0.01, ^{***}p < 0.001$. Standard errors in parentheses. \\newline",
    paste0("\\textit{Note:} ", note),
    "\\end{minipage}",
    "\\end{table}"
  )
}

quad_ns_primary <- did$quad_ns_primary
quad_ns_full <- did$quad_ns_full

writeLines(
  make_quadrant_table(
    did$res_quad_primary, did$res_quad_drift_primary,
    "Difference-in-Differences Treatment Effects Across Status Consistency Quadrants (Age $\\ge 25$ Sample, IPW-Weighted)",
    "tbl:did_status_quadrants",
    paste0("Estimates represent Difference-in-Differences treatment contrasts relative to the unexposed Control Condition within each status consistency quadrant for the primary sample (Age $\\ge 25$, $N = 1{,}981$), estimated using generalized multinomial Inverse Probability Weighting (IPW) balancing baseline age, gender, race/ethnicity, and parental education."),
    quad_ns_primary
  ),
  "tables/table_did_status_quadrants.tex"
)

writeLines(
  make_quadrant_table(
    did$res_quad_full, did$res_quad_drift_full,
    "Difference-in-Differences Treatment Effects Across Status Consistency Quadrants (Full Sample, $N = 2{,}252$, IPW-Weighted)",
    "tbl:did_status_quadrants_full",
    "Estimates represent Difference-in-Differences treatment contrasts relative to the unexposed Control Condition in the unrestricted full sample ($N = 2{,}252$).",
    quad_ns_full
  ),
  "tables/table_did_status_quadrants_full.tex"
)

# ------------------------------------------------------------------------------
# Appendix Tables A.4 / A.7: Stepwise education / class (primary / full)
# ------------------------------------------------------------------------------
make_stepwise_table <- function(res, caption, label, note, n_no_col, n_col, n_work, n_mid) {
  cellrow <- function(cond) {
    re <- res$frame_edu %>% filter(as.character(Condition) == cond)
    rc <- res$frame_class %>% filter(as.character(Condition) == cond)
    e_nc <- re %>% filter(as.character(Group) == "No College Degree")
    e_c <- re %>% filter(as.character(Group) == "College Degree")
    c_w <- rc %>% filter(as.character(Group) == "Working Class")
    c_m <- rc %>% filter(as.character(Group) == "Middle Class")
    sprintf("%s & %s & %s & %s & %s \\\\", cond,
            format_cell(e_nc$estimate, e_nc$std.error, e_nc$p.value),
            format_cell(e_c$estimate, e_c$std.error, e_c$p.value),
            format_cell(c_w$estimate, c_w$std.error, c_w$p.value),
            format_cell(c_m$estimate, c_m$std.error, c_m$p.value))
  }
  driftrow <- function() {
    de <- res$drift_edu; dc <- res$drift_class
    sprintf("Control Condition Drift & %s & %s & %s & %s \\\\",
            format_cell(de$drift[1], de$drift_se[1], de$drift_p[1]),
            format_cell(de$drift[2], de$drift_se[2], de$drift_p[2]),
            format_cell(dc$drift[1], dc$drift_se[1], dc$drift_p[1]),
            format_cell(dc$drift[2], dc$drift_se[2], dc$drift_p[2]))
  }
  c(
    "\\begin{table}[ht!]",
    "\\centering",
    "\\small",
    paste0("\\caption{", caption, "}"),
    paste0("\\label{", label, "}"),
    "\\setlength{\\tabcolsep}{2.0pt}",
    "\\begin{tabular*}{\\linewidth}{@{\\extracolsep{\\fill}}lcccc@{}}",
    "\\toprule",
    "& \\multicolumn{2}{c}{\\textbf{Panel A: Education Alone}} & \\multicolumn{2}{c}{\\textbf{Panel B: Subjective Class Alone}} \\\\",
    "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}",
    "\\textbf{Treatment Condition} & No College & College Degree & Working Class & Middle Class \\\\",
    "\\midrule",
    vapply(cond_order_top_down, cellrow, character(1)),
    "\\midrule",
    driftrow(),
    sprintf("Sample Size ($N$) & %s & %s & %s & %s \\\\",
            format(n_no_col, big.mark = ","), format(n_col, big.mark = ","),
            format(n_work, big.mark = ","), format(n_mid, big.mark = ",")),
    "\\bottomrule",
    "\\end{tabular*}",
    "\\begin{minipage}{\\linewidth}",
    "\\vspace{4pt}",
    "\\footnotesize",
    "$^{\\dagger}p < 0.10, ^{*}p < 0.05, ^{**}p < 0.01, ^{***}p < 0.001$. Standard errors in parentheses. \\newline",
    paste0("\\textit{Note:} ", note),
    "\\end{minipage}",
    "\\end{table}"
  )
}

writeLines(
  make_stepwise_table(
    did$res_stepwise_primary,
    "Difference-in-Differences Estimates Moderated Separately by Education and Subjective Class (Primary Sample, Age $\\ge 25$, $N = 1{,}981$)",
    "tbl:did_edu_class_primary",
    paste0("Estimates represent Difference-in-Differences treatment contrasts relative to the unexposed Control Condition within each demographic subpopulation, estimated via targeted binary Inverse Probability Weighting (IPW) balancing baseline age, gender, race/ethnicity, and parental education, for the primary analytic sample (Age $\\ge 25$). ",
           "Panel A estimates moderation by educational attainment alone (No College Degree vs.\\ Bachelor's Degree or Higher). Panel B estimates moderation by subjective social class identification alone (Working Class vs.\\ Middle Class). ",
           "See Figure \\ref{fig:did_edu_class_separate} for the corresponding visualization and Appendix Table \\ref{tbl:did_edu_class_full} for the identical specification on the full unrestricted sample."),
    did$res_stepwise_primary$n[["no_college"]],
    did$res_stepwise_primary$n[["college"]],
    did$res_stepwise_primary$n[["working"]],
    did$res_stepwise_primary$n[["middle"]]
  ),
  "tables/table_did_edu_class_primary.tex"
)

writeLines(
  make_stepwise_table(
    did$res_stepwise_full,
    "Difference-in-Differences Estimates Moderated Separately by Education and Subjective Class (Full Sample, $N = 2{,}252$)",
    "tbl:did_edu_class_full",
    "Estimates represent Difference-in-Differences treatment contrasts relative to the unexposed Control Condition in the unrestricted full sample ($N = 2{,}252$).",
    did$res_stepwise_full$n[["no_college"]],
    did$res_stepwise_full$n[["college"]],
    did$res_stepwise_full$n[["working"]],
    did$res_stepwise_full$n[["middle"]]
  ),
  "tables/table_did_edu_class_separate.tex"
)

# ------------------------------------------------------------------------------
# Appendix Table A.5: Unweighted vs IPW pooled DiD comparison
# ------------------------------------------------------------------------------
pu <- did$res_pooled$primary_unwt
pw <- did$res_pooled$primary_ipw

tidy_full_coefs <- function(mod) {
  co <- summary(mod)$coefficients
  data.frame(
    term = rownames(co),
    estimate = co[, "Estimate"], se = co[, "Std. Error"], t = co[, "t value"]
  )
}
cu <- tidy_full_coefs(pu$mod)
cw <- tidy_full_coefs(pw$mod)

# Map the six interaction terms to table row labels in house order
interaction_labels <- c(
  "Taste Only/Like" = "Taste Only / Like",
  "Class & Taste/Like/+Status" = "Class \\& Taste / Like / $+$Status",
  "Class & Taste/Like/-Status" = "Class \\& Taste / Like / $-$Status",
  "Taste Only/Dislike" = "Taste Only / Dislike",
  "Class & Taste/Dislike/+Status" = "Class \\& Taste / Dislike / $+$Status",
  "Class & Taste/Dislike/-Status" = "Class \\& Taste / Dislike / $-$Status"
)
interaction_order <- c(
  "Taste Only/Like", "Class & Taste/Like/+Status", "Class & Taste/Like/-Status",
  "Taste Only/Dislike", "Class & Taste/Dislike/+Status", "Class & Taste/Dislike/-Status"
)
int_suffix <- "factor(trial)2:cond2_refctrl"

row_for <- function(base_term, label, digits_star = TRUE) {
  ru <- cu %>% filter(term == base_term)
  rw <- cw %>% filter(term == base_term)
  pu_v <- 2 * (1 - pnorm(abs(ru$t)))
  pw_v <- 2 * (1 - pnorm(abs(rw$t)))
  if (digits_star) {
    sprintf("\\quad %s & $%s$ (%.3f) & $%.2f%s$ & $%s$ (%.3f) & $%.2f%s$ \\\\",
            label,
            format_cell(ru$estimate, ru$se, pu_v),
            0, # placeholder replaced below
            abs(ru$t), if (pu_v < 0.05) "$^{*}$" else if (pu_v < 0.10) "$^{\\dagger}$" else "",
            format_cell(rw$estimate, rw$se, pw_v),
            0,
            abs(rw$t), if (pw_v < 0.05) "$^{*}$" else if (pw_v < 0.10) "$^{\\dagger}$" else "")
  }
}

# Simpler explicit row builders
simple_row <- function(base_term, label) {
  ru <- cu %>% filter(term == base_term)
  rw <- cw %>% filter(term == base_term)
  pu_v <- 2 * (1 - pnorm(abs(ru$t)))
  pw_v <- 2 * (1 - pnorm(abs(rw$t)))
  star <- function(p) if (p < 0.001) "$^{***}$" else if (p < 0.01) "$^{**}$" else if (p < 0.05) "$^{*}$" else if (p < 0.10) "$^{\\dagger}$" else ""
  sprintf("%s & $%+.3f%s$ (%.3f) & $%.2f$ & $%+.3f%s$ (%.3f) & $%.2f$ \\\\",
          label,
          ru$estimate, star(pu_v), ru$se, abs(ru$t),
          rw$estimate, star(pw_v), rw$se, abs(rw$t))
}

tex_a5 <- c(
  "\\begin{table}[ht!]",
  "\\centering",
  "\\small",
  "\\caption{Comparison of Unweighted and IPW-Weighted Difference-in-Differences Models (Age $\\ge 25$ Sample)}",
  "\\label{tbl:appendix_did_compare}",
  "\\setlength{\\tabcolsep}{4.5pt}",
  "\\begin{tabular*}{\\linewidth}{@{\\extracolsep{\\fill}}lcccc@{}}",
  "\\toprule",
  " & \\multicolumn{2}{c}{\\textbf{Unweighted DiD}} & \\multicolumn{2}{c}{\\textbf{IPW-Weighted DiD}} \\\\",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}",
  "\\textbf{Independent Variable} & Estimate (SE) & $t$ value & Estimate (SE) & $t$ value \\\\",
  "\\midrule",
  simple_row("(Intercept)", "Intercept ($\\beta_0$)"),
  simple_row("factor(trial)2", "Trial 2 Exposure Drift ($\\beta_{1}$)"),
  "\\addlinespace[3pt]",
  "\\multicolumn{5}{l}{\\textit{Difference-in-Differences Treatment Effects ($\\text{Trial} \\times \\text{Condition}$):}} \\\\",
  vapply(interaction_order, function(cc) {
    simple_row(paste0(int_suffix, cc), paste0("\\quad ", interaction_labels[[cc]]))
  }, character(1)),
  "\\addlinespace[3pt]",
  "Condition Main Effects Included & \\multicolumn{2}{c}{Yes} & \\multicolumn{2}{c}{Yes} \\\\",
  sprintf("Random Intercept Variance ($\\sigma^2_u$) & \\multicolumn{2}{c}{%.3f} & \\multicolumn{2}{c}{%.3f} \\\\",
          pu$between_var, pw$between_var),
  sprintf("Residual Variance ($\\sigma^2_e$) & \\multicolumn{2}{c}{%.3f} & \\multicolumn{2}{c}{%.3f} \\\\",
          pu$resid_var, pw$resid_var),
  "$N$ (Observations / Individuals) & \\multicolumn{2}{c}{3,962 / 1,981} & \\multicolumn{2}{c}{3,962 / 1,981} \\\\",
  "\\bottomrule",
  "\\end{tabular*}",
  "\\begin{minipage}{\\linewidth}",
  "\\vspace{4pt}",
  "\\footnotesize",
  paste0("$^{\\dagger}p < 0.10, ^{*}p < 0.05, ^{**}p < 0.01, ^{***}p < 0.001$. Reference condition: unexposed Control Condition. ",
         "Note that the residual variance of the IPW-weighted model is estimated on the weighted (pseudo-population) scale ",
         "and is therefore not directly comparable to the unweighted estimate."),
  "\\end{minipage}",
  "\\end{table}"
)
writeLines(tex_a5, "tables/table_did_pooled_compare.tex")

cat("Wrote 7 LaTeX tables to tables/\n")
cat("  table_mde_summary.tex, table_did_edu_4tiers.tex, table_did_status_quadrants.tex,\n")
cat("  table_did_edu_class_primary.tex, table_did_pooled_compare.tex,\n")
cat("  table_did_edu_class_separate.tex, table_did_status_quadrants_full.tex\n")
