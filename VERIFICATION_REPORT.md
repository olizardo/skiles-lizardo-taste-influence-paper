# Replication Verification Report (Pre-Resubmission Audit)

**Date:** October 11, 2026
**Scope:** Full audit of the R pipeline, all manuscript figures/tables, and every
inline statistic in `manuscript_R1.tex` and `response_to_reviewers.tex`, followed
by remediation. Everything below was regenerated from the raw data
(`ssi2012_cleaned.dta`, md5 `bc22190150b20a4418e07a375b143542`) via the new
pipeline (`R/run_all.R`).

---

## 1. What was broken and how it was fixed

| # | Problem found | Fix |
|---|---------------|-----|
| 1 | **Figure 4 (`Figure_DiD_Edu_4Tiers.png`) and Appendix Tables A.2, A.3, A.5, A.6, A.8 had no producing script** — the 4-tier education model (centerpiece of Section 3.2) existed as hand-entered numbers only | 4-tier model reconstructed and verified (multinomial IPW on 4 education tiers + change-score DiD); reproduces **every** published estimate exactly. All five tables now generated as `.tex` by `R/08_make_tables.R` and `\input` into the manuscript |
| 2 | **Two manuscript figures contained the wrong sample**: `Figure_DiD_Edu_Class_Separate.png` (App. Fig A.2) had been overwritten with the full-sample version on 9/30; `Figure_DiD_Baseline_Influence.png` (Fig 3) had been overwritten with a full-sample version | Regenerated from the primary (25+) sample; full-sample variants no longer share filenames |
| 3 | **Filename collisions**: 4–5 scripts wrote the same output paths; last-run-wins silently | New pipeline assigns each asset exactly one producer; superseded scripts quarantined in `R/legacy/` with a warning README |
| 4 | `appendix_robustness.R` and `test_labels.R` hardcoded a nonexistent data path (would not run) | Replaced by `R/06_models_appendix.R` (class robustness) and robust path resolution in `R/01_dataproc.R` |
| 5 | Age filter ambiguity: `age >= 4` selects bracket 25–29+, i.e. **25+**, but the manuscript mostly said "Age ≥ 24" | Manuscript standardized to "aged 25 or older" everywhere (user decision) |
| 6 | `case_match()` deprecation warnings; NA-handling edge in `percclass` recode | Fixed in `R/01_dataproc.R` |

## 2. Numbers that were wrong in the manuscript (now corrected)

| Location | Old value | Verified value | Source |
|----------|-----------|---------------|--------|
| §1.4/Abstract, all captions/notes | "Age ≥ 24" / "aged 24 or older" | **25+** (bracket code 4 = 25–29) | `01_dataproc.R` |
| §1.3 (p.~) buffer length | "between 10 and 20 minutes" | "between 15 and 20 minutes" | protocol (consistent with §2.3, §4.2, App. B) |
| §2.2 trial sequence | vignette described as after the survey battery | vignette precedes the battery (pages 5–6 vs 7–15) | Qualtrics protocol (App. B) |
| §2.4 ES/CS consolidation F-tests | F=0.29/p=.59; F=0.92/p=.34; F=0.06/p=.80; F=0.04/p=.85 (unreproducible) | pooled: F=0.35, p=.55 (likes); F=0.07, p=.80 (dislikes); college grads: F=1.11, p=.29; F=0.06, p=.80 | `02_samples.R` (t² on change scores) |
| §2.4 36-cell design | "N ≈ 20–35… d > 0.45" | smallest cell N=15, control as small as N=21; d ≈ 0.43 in smallest cells | `06_models_appendix.R` |
| §2.5 raw SMD range | "0.35 to 0.50" | "0.06 to 0.59" (after categorical age + raceeth fix: max weighted SMD 0.116, "Other" race N=11 reweighting artifact; parented 0.111; all other contrasts < 0.08; every age bracket < 0.06) | `05_ipw_balance.R` |
| Age IPW specification (Oct 2026 re-audit) | linear bracket code | categorical `age_f` factor in all propensity models (linear spec left 8/12 brackets > 0.10 SMD after weighting, worst 0.26); all weighted estimates re-verified, max movement 0.048 across 24 tier×condition DiDs; §3.1/§3.2 numbers updated throughout | `01_dataproc.R`, `02`–`04`, `05_ipw_balance.R` |
| §3.1 GenDislike raw change | p = 0.68 | **p = 0.59** (delta method on IPW mixed model) | `03_models_did.R` |
| §3.2 postgraduate exposure drift | +0.375 (p < 0.01) | **+0.355 (p < 0.001)** (model-implied drift, consistent with A.3 method) | `03_models_did.R` |
| §3.3 & App. E sensitivity sample | **N = 1,643** | **N = 1,649** (1,981 − 300 Taste-Only − 32 baseline shifters) | `02_samples.R` |
| §3.3 & App. E sensitivity AMEs | +7.6/+4.9/+4.1/−3.1/−4.1 | **+6.6 / +5.5 / +5.0 / −3.0 (p=.004) / −2.6 (p=.014)** | `04_models_behavioral.R` |
| Appendix A prose | Full-sample numbers (N=2,253, control 177, d≥0.028/0.099, arms 575/290/172, quadrants 70/51/33/23, example −0.394) mixed into a primary-sample table | Rewritten to primary-sample values matching Table A.1: N=1,981, control 157, d≥0.029/0.102, arms 505/254/150, quadrants 55/50/31/21, example −0.320* | `06_models_appendix.R` |
| Appendix D "consistent estimates" claim | claimed both specs consistent | softened: Low-Status Like attenuates from marginal (p<.10) to null under IPW; note added that weighted σ²ε is on the pseudo-population scale (0.982 is lmer output, not comparable to 0.233) | `03_models_did.R` |
| Appendix F class robustness | 80.5/74.1/18.2/17.6 | **80.1 / 75.3 / 18.2 / 16.7** | `06_models_appendix.R` |
| Appendix G full-sample N | "2,253 complete cases; 4,506 obs" | 2,253 evaluators, **2,252** complete on covariates (models), **4,504** obs | `01_dataproc.R` |
| Table A.6 micro-errors | Men 1,091; Other/Multiracial 65; four rounding cells | Men **1,090** (one unreported gender, noted); Other **64**; rounding cells fixed | `06_models_appendix.R` |
| Response memo p.~ | "t = 2.86, p = 0.0044" | t = 2.87, p = 0.0041 | `03_models_did.R` |
| Response memo | "only 20.3% held a bachelor's degree" (18–24) | 18.1% bachelor's; 20.3% any college degree | `02_samples.R` |
| Response memo | "all p > 0.40" (arm balance) | accurate: all p > 0.20 for gender/race/age/parental education/education + baseline taste (p=.46); region marginal at p=0.04 (quota-filling) | `05_ipw_balance.R` |
| Response memo | "Tables G.1, G.2, G.3" | Tables A.6, A.7, A.8 | — |

## 3. Numbers verified as correct (no change needed)

- Sample flow (3,782 → 2,275 → 2,253) and all primary Ns: 1,981 / 3,962 / 457 (157/152/148) / tier Ns 468/655/577/281 / quadrant Ns 680/243/443/615 / college share 43.3% / lower 220 (11.1%) / upper 47 (2.4%).
- §3.1: β₁ = +0.156 (SE 0.055, t 2.87, p 0.0041); IPW-weighted trial means 4.65→4.85 (+0.203); δLike = +0.047 (p = 0.55); δDislike = −0.186 (p = 0.016); valence contrast +0.233 (χ² = 8.57, p = 0.003).
- All 24 four-tier DiD estimates (+0.284†, −0.491***, −0.442**, −0.345**, −0.308*, −0.271*, tier-2 p ≥ 0.25, etc.) — reproduced to the third decimal.
- §3.3 primary AMEs (+0.073/−0.026/−0.012 stay; +0.042/+0.043/−0.033 conform; −0.030/−0.040 react) and base rates (73.8/14.2/12.0; 81.1/71.2/72.5; 18.4/18.5/10.9).
- Appendix C prose (stepwise: −0.325**, −0.263**, −0.248*, −0.204*) and both stepwise tables; the 24-cell quadrant table (A.3) reproduced **exactly**, including the drift row.
- Table A.5 coefficients (both models), random-intercept variances (2.100/2.060).
- Table 1 descriptives: **every** count and percentage verified.
- Design parameters: r = 0.8993, σ₁ = 1.504, σ₂ = 1.554, σΔ = 0.688; overall stay 73.9%; MDE Table A.1 (all cells).
- Tier-2 ancillary split (196 terminal AA / 459 non-degreed attenders).

## 4. Judgment calls requiring author attention

1. **Regional imbalance across arms (p = 0.04)** — surfaced by the new balance tests
   (`05_ipw_balance.R`). Likely quota-filling in the SSI panel. Response memo now
   reports it honestly; manuscript §2.1 softened from "balanced across all observed
   baseline characteristics" to "closely balanced across baseline demographic
   characteristics." Consider whether to mention in the limitations.
2. **Appendix A prose** was rewritten to primary-sample values. If you prefer the
   full-sample framing there instead, Table A.1 would need to be regenerated for
   the full sample.
3. **Postgraduate drift row** in Table A.2 changed (+0.375** → +0.355***) because the
   original hand-entered drift row could not be reproduced under any natural method;
   the regenerated row uses the same model-implied (delta-method) approach as the
   quadrant tables, where it reproduces the published values exactly.
4. **Under-25 degree share**: the true figures are 18.1% (bachelor's) / 20.3% (any
   college). Both documents updated; the age-restriction rationale is unaffected.
5. **Upstream flow counts** (3,782 accessed, 85 non-consent, 1,394 quota-screened,
   16 early dropouts) are fieldwork logs not derivable from the analysis file; the
   file contains 2,276 rows, of which 2,275 have a valid experimental arm.

## 5. Pipeline map (strict replication)

Run `Rscript R/run_all.R` from the project root. Steps: `01_dataproc` (cleaning,
samples, 4-tier education variable) → `02_samples` (all Ns/shares/F-tests/design
parameters → `tables/sample_sizes.csv`) → `03_models_did` (§3.1 baseline model,
pooled unweighted/IPW, 4-tier, stepwise, 24-cell; primary + full) →
`04_models_behavioral` (multinomial AMEs, primary/sensitivity/full) →
`05_ipw_balance` (love plot, SMDs, arm-balance tests) → `06_models_appendix` (MDE,
descriptives, class robustness) → `07_make_figures` (8 figures, png+pdf) →
`08_make_tables` (7 LaTeX tables). No script hardcodes effect estimates or sample
sizes; every figure/table has exactly one producer. Legacy scripts are quarantined
in `R/legacy/` (do not run — they overwrite primary-sample figures with full-sample
versions).

## 6. Appendix reproducibility audit (October 11, 2026)

Full pipeline (`Rscript R/run_all.R`, 2.5 min) rerun from the raw data. All outputs
reproduce: PNG figures bit-identical; PDF figure diffs are embedded creation
timestamps only; regenerated `model_results_did.rds` / `balance_results.rds` agree
with the committed versions to floating-point noise (max coefficient drift ~1e-13).

Every numeric claim in the Appendix prose (A-G) was checked against the `tables/*.rds`
model outputs. All values verified, including: Appendix A variance inputs
(r = 0.8993, sigma1 = 1.504, sigma2 = 1.554, sigma_Delta = 0.688), control drift
(+0.140, t = 3.43, p = 0.00061), all Panel A-C MDE thresholds and cell sizes,
the ES/CS consolidation F-tests (4/4 match), smallest-cell MDE d ~ 0.43, and the
N = 505 / 575 pooled High-Status per-arm sizes; Appendix C stepwise DiD prose
(6 estimates + p-values) and the tier-2 homogeneity check (459/196, 73.0/70.4,
chi2 = 0.335, p = 0.563); Appendix D unweighted/weighted Low-Status Like contrast;
Appendix E sensitivity AMEs (6/6) and the N = 1,949 - 300 = 1,649 sample arithmetic;
Appendix F class-robustness rates; Appendix G Ns verified directly from the raw
data (2,253 evaluations / 2,252 covariate-complete / 4,504 observations) and all
22 rows x 5 columns of typed Table A.6 against `descriptives.rds`.

One correction: Appendix B stated that N = 6 respondents selected "I can't see the
image" and were excluded. The raw data contain zero selections of code 98 at either
trial, no variable in the file carries the label, and the documented exclusion
ledger (85 + 12 + 1,394 + 16 = 1,507) has no can't-see bucket, so the count is not
derivable from any available source. The "(N = 6)" was deleted; the sentence now
states the exclusion rule without an unverifiable count.

## 7. Appendix A expansion: education-tier MDE panel (October 12, 2026)

Consistency check of Appendix A against the restructured manuscript found: (a) an
Overleaf-side trim had left the two larger quadrants sharing a single MDE threshold
(0.223) although Middle/College's is 0.230 -- restored; (b) the MDE analysis covered
pooled and status-quadrant contrasts but not the four education tiers that now carry
the principal heterogeneity results. Added Panel C ("Subgroup DiD Contrasts Within
Educational Tiers") to Table A.1 and the corresponding rows to Figure A.1 Panel B,
computed in R/06 from actual tier x condition cell sizes (tier contrasts compare each
tier cell against that tier's own control cell, matching the saturated
tier x condition model). Median-cell 80% MDEs: High School or Less 0.410 (d = 0.272,
N_C = 38), Associate/Some College 0.346 (d = 0.230, N_C = 48), Bachelor's 0.360
(d = 0.239, N_C = 47), Postgraduate 0.491 (d = 0.326, N_C = 24). Quadrant panel
relabeled Panel D; takeaway renumbered to four; R/07 and R/08 MDE code made
group-driven (no hardcoded row indices). Recompiled: 42 pp., 0 errors, 0 overfull.
