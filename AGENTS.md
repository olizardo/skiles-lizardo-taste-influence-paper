# Taste Influence Paper Project

## Overview
This project modernizes, revises, and revives the analysis for the paper *"Stay, React, or Conform? Examining Social Influence Effects on Aesthetic Judgments"* (Omar Lizardo & Sara Skiles), currently undergoing Major Revision at *Poetics* (POETICS-D-26-00490). The original Stata pipeline and early drafts have been upgraded to a fully reproducible R workflow and connected to Overleaf.

- **Journal:** *Poetics* (Editor-in-Chief: Hannah Wohl)
- **Overleaf Project URL:** https://www.overleaf.com/project/6a3fe1ed665ddc04ec45136a
- **Overleaf Git Endpoint:** `https://git.overleaf.com/6a3fe1ed665ddc04ec45136a`
- **Revision Tracking & Response Documents:**
  - `REVISION_PLAN_POETICS.md`: Comprehensive strategy and execution plan for the major revision.
  - `response_to_reviewers.md`: Active Markdown memo detailing point-by-point responses to Editor Hannah Wohl and both reviewers.
  - `response_to_reviewers.tex`: Publication-grade LaTeX document containing the complete response memo styled with `tcolorbox` reviewer callouts, mathematical formulas, and formal `booktabs` tables. Written in full academic prose paragraphs (avoiding bullet points), using italics for emphasis, and stripped of bug-tracker status tags.
  - `response_to_reviewers.pdf`: Compiled 18-page PDF response memo ready for journal resubmission (0 errors).
- **Manuscript Files & Critical Preservation Policy:**
  - `manuscript.tex`: **DO NOT OVERWRITE OR EDIT.** Preserves the frozen, historical original version of the manuscript as initially submitted to *Poetics* (14 pages).
  - `manuscript_R1.tex`: **The ONLY active working manuscript file.** All current revisions, Overleaf edits, DiD models, IPW specifications, and text updates belong exclusively in `manuscript_R1.tex`.

## Replication Pipeline (Single Source of Truth)
- **Run `Rscript R/run_all.R` from the project root to regenerate every figure and table from the raw data.** Steps (each numbered script is also runnable individually, in order):
  1. `R/01_dataproc.R` — data cleaning, sample construction, 4-tier education variable (`edu4_factor`: ma/docprof→4, bach→3, aadeg/somcol→2, else 1)
  2. `R/02_samples.R` — computes ALL sample sizes/shares/F-tests/design parameters → `tables/sample_sizes.csv` (never hardcode an N)
  3. `R/03_models_did.R` — §3.1 baseline mixed model, pooled unweighted/IPW, 4-tier, stepwise, 24-cell quadrants (primary + full)
  4. `R/04_models_behavioral.R` — multinomial Stay/Conform/React AMEs (primary, sensitivity N=1,649, full)
  5. `R/05_ipw_balance.R` — love plot data, SMDs, covariate-by-arm balance tests
  6. `R/06_models_appendix.R` — MDE analysis (all inputs data-computed), Table 1/A.6 descriptives, Appendix F class robustness, tier-2 homogeneity check (`tables/tier2_homogeneity.rds`)
  7. `R/07_make_figures.R` — all 8 manuscript figures (png + pdf), no hardcoded estimates
  8. `R/08_make_tables.R` — all 7 LaTeX results tables, `\input` into the manuscript
- **`R/legacy/` contains superseded scripts. DO NOT RUN THEM** — several silently overwrite primary-sample figures with full-sample versions; two hardcode a dead data path. Kept for provenance only.
- `VERIFICATION_REPORT.md` documents the full pre-resubmission audit: every number checked, every correction made.
- Model results are saved to `tables/*.rds`; figures/tables read those rds files, so nothing downstream re-fits models.

---

## Manuscript Architecture & Word Count Balance (`manuscript_R1.tex`)

The revised manuscript contains approximately **8,404 words** in the main body (Sections 1–4, including text, in-text citations, and footnotes; excluding floating tables, figures, display equations, and references; recomputed after the October 2026 structural revision, the Overleaf Section 1 prose revisions (which renamed §1.3 to "The Present Research" and rewrote the study-outcome sentence to describe the net-of-drift DiD change and the discrete stay/conform/react outcomes), and the blinding-related relocation of the funding acknowledgement from §2.1 to a \thanks footnote on the non-blinded title page), hitting the optimal target for a *Poetics* full article (8,000–10,000 words).

| Section | Subsection Titles | Word Count | Share of Main Text |
| :--- | :--- | :---: | :---: |
| **Front Matter** | Title, Authors, Abstract (201 words) | 240 words | — |
| **Section 1: Introduction** | 1.1 Personal Tastes vs. Others' Tastes (389w)<br>1.2 How Do Others' Tastes Influence Our Own? (756w)<br>1.3 The Present Research (278w)<br>1.4 Hypotheses H1–H6 (744w) | 2,167 words | 25.8% |
| **Section 2: Data & Methods** | 2.1 Sample Recruitment & Administration (469w)<br>2.2 Experimental Design & Stimulus (279w)<br>2.3 Demand Characteristics & Reactivity (380w)<br>2.4 Variables & Measurement (492w)<br>2.5 Inverse Probability Weighting (444w)<br>2.6 DiD Analytic Strategy (643w) | 2,711 words | 32.3% |
| **Section 3: Results** | 3.1 Baseline Exposure Drift & Generalized Influence (451w)<br>3.2 Status-Differentiated Social Influence (840w)<br>3.3 Status Inconsistency & Behavioral Choices (654w) | 1,947 words | 23.2% |
| **Section 4: Discussion** | 4.1 Summary of Key Results / Table 2 (439w)<br>4.2 Limitations & Suggestions for Future Work (568w)<br>4.3 Implications: Distinction, Defense, Negativity, Crystallization, & Concluding Paragraph (570w) | 1,579 words | 18.8% |
| **Main Body Total** | **Sections 1–4 Combined** | **8,404 words** | **100.0%** |
| *Appendices (Prose)* | *Appendices A–G (Power, Vignettes, Tables, Sensitivity, Full Sample; including Appendix B verbatim transcription)* | *~2,370 words* | — |

---

## Data & Experimental Protocol
- **Primary Raw Data Path**: `/home/omarlizardo/projects/CULTURE/cultural-consensus-musical-genres/SSI-2012/data/clean/ssi2012_cleaned.dta` (fallback: `/home/omarlizardo/ACADEMIC AND COURSE MATERIALS/SSI-2012/data/clean/ssi2012_cleaned.dta`).
- **Format**: Stata `.dta` file containing survey data with embedded value labels, loaded via `haven::read_dta()`.
- **Sample Flow & Primary Population Restriction:**
  - $3,782$ accessed survey $\to 85$ non-consent $\to 12$ under-age $\to 1,394$ quota-screened $\to 16$ early dropouts $\to N = 2,275$ completed responses ($N = 2,253$ complete pre- and post-treatment evaluations).
  - **Primary Analytic Sample ($\text{Age} \ge 25$):** To ensure all respondents have had the opportunity to complete higher education and eliminate right-censoring in educational attainment among the college-age cohort (18–24, where only 18.1% held a bachelor's degree and 20.3% held a college degree of any kind), the primary analytic sample is restricted to respondents aged 25 or older ($N = 1,981$ complete cases; $3,962$ repeated observations across trials). College degree holders represent $43.3\%$ of this primary sample. (The `age` variable is a bracket code; the filter `age >= 4` selects the 25–29 bracket and up.)
  - **Full Sample Preservation:** The full unrestricted sample ($N = 2,253$) is preserved as a complete sensitivity robustness check in Appendix \ref{sec:appendix_full_sample} (Tables \ref{tbl:full_sample_descriptives}, \ref{tbl:did_edu_class_full}, \ref{tbl:did_status_quadrants_full}), confirming that all empirical findings and hypothesis verdicts are identical across the entire age spectrum.
- **Experimental Procedures (`Skiles dissertation2.docx` & Appendix \ref{sec:appendix_vignettes})**:
  - *Trial 1 (Survey Page 4):* High-resolution image of James McNeill Whistler's *Nocturne: Battersea Bridge* (1872); verbatim prompt (*"Please look at this painting for a few seconds. Give us your first impression of this painting -- how much do you like it?"*) on a reversed 1–7 scale ($7 = \text{like very much}$, $1 = \text{dislike very much}$).
  - *Feedback Vignette & Attribution (Pages 5–6):* Treatment respondents receive naturalistic aggregate feedback from prior survey respondents (*"Our survey so far indicates that the group of people most likely to say that they [LIKE / DISLIKE] the painting you saw have completed..."*) followed by subjective similarity (5-point) and alter attribution probes.
  - *Cognitive Buffer (Pages 7–15):* Extensive 15-to-20 minute intervening survey battery (detailed educational history, degree major, parental education, occupation/SOC, income, subjective social class, and a comprehensive 20-genre musical taste battery).
  - *Trial 2 (Page 16):* Respondents view the identical painting again with verbatim prompt (*"Please look at this painting for a few seconds again. Give us your final impression of this painting -- how much do you like it?"*) on the same scale, without being reminded of their Trial 1 score and without any instructional prompt suggesting conformity.
  - *Consolidation of High-Status Alters:* Economic Specialists (ES: business degree, financial firm) and Cultural Specialists (CS: advanced degrees/PhD, higher education) are collapsed into a single High-Status (`+Status`) condition. Formal $F$-tests confirm responses to ES and CS are statistically indistinguishable (pooled sample: $F = 0.35, p = 0.55$ for likes; $F = 0.07, p = 0.80$ for dislikes; among college graduates: $F = 1.11, p = 0.29$ and $F = 0.06, p = 0.80$), and collapsing prevents severe statistical power loss across a 36-cell design.

---

## Streamlined Results Architecture & Core Findings

### 1. Difference-in-Differences Causal Architecture (Section 2.6)
- **Base DiD Linear Mixed Model (Equation \ref{eq:did_model}):**
  $$\text{Taste}_{it} = \beta_0 + \beta_1 \text{Trial}_{it} + \sum_{k=2}^{K} \beta_k \text{Cond}_{ik} + \sum_{k=2}^{K} \delta_k (\text{Trial}_{it} \times \text{Cond}_{ik}) + u_i + \epsilon_{it}$$
- **Fully Moderated DiD Model (Equation \ref{eq:did_moderation_model}):**
  $$\begin{aligned}
  \text{Taste}_{it} = {} & \beta_0 + \beta_1 \text{Trial}_{it} + \sum_{k=2}^K \beta_k \text{Cond}_{ik} + \sum_{m=2}^M \gamma_m \text{Status}_{im} \\
  & + \sum_{k=2}^K \delta_k (\text{Trial}_{it} \times \text{Cond}_{ik}) + \sum_{m=2}^M \theta_m (\text{Trial}_{it} \times \text{Status}_{im}) \\
  & + \sum_{k=2}^K \sum_{m=2}^M \lambda_{km} (\text{Cond}_{ik} \times \text{Status}_{im}) \\
  & + \sum_{k=2}^K \sum_{m=2}^M \psi_{km} (\text{Trial}_{it} \times \text{Cond}_{ik} \times \text{Status}_{im}) + u_i + \epsilon_{it}
  \end{aligned}$$
  where $\theta_m$ captures group-specific differences in counterfactual baseline exposure drift in the Control Condition ($\text{Trial}_{it} \times \text{Status}_{im}$), $\delta_k$ is the baseline DiD effect for the reference group, $\psi_{km}$ is the three-way interaction coefficient testing status divergence, and $\delta_{km} = \delta_k + \psi_{km}$ represents the status-specific causal DiD effect.

### 2. Status-Free Baseline: Exposure Drift & Generalized Influence (Section 3.1)
Estimated on the 3-condition status-free subset of the primary sample (Control $N = 157$, Generalized Like $N = 152$, Generalized Dislike $N = 148$, total $N = 457$, $914$ observations) via Equation \ref{eq:generalized_did_model}:
$$\text{Taste}_{it} = \beta_0 + \beta_1 \text{Trial}_{it} + \beta_2 \text{Like}_i + \beta_3 \text{Dislike}_i + \delta_{\text{Like}} (\text{Trial}_{it} \times \text{Like}_i) + \delta_{\text{Dislike}} (\text{Trial}_{it} \times \text{Dislike}_i) + u_i + \epsilon_{it}$$
- **Mere Exposure Drift in Control (H1):** Seeing the artwork a second time in the absence of external cues produces an intrinsic appreciation boost ($\beta_1 = +0.156^{**}, SE = 0.055, t = 2.87, p = 0.0041$; IPW-weighted mixed model on the 3-condition subset).
- **Valence Asymmetry & Negativity Bias in Generalized Cues:**
  - *Generalized Like (H2a):* Raw increase ($+0.203^{**}$), but net DiD boost relative to control drift is positive and modest ($\delta_{\text{Like}} = +0.047, p = 0.555$).
  - *Generalized Dislike (H2b):* Negative feedback completely halts exposure appreciation (raw change $-0.030$), resulting in statistically significant negative DiD suppression ($\delta_{\text{Dislike}} = -0.186^{*}, SE = 0.078, t = -2.40, p = 0.0169$).
  - *Valence Contrast:* Direct contrast yields a significant directional swing ($\Delta = +0.233^{**}, SE = 0.080, \chi^2 = 8.57, p = 0.0034$), demonstrating that negative social consensus exerts an asymmetric veto power.
  - *Negativity Bias Mechanism:* Grounded in psychological and cognitive research on negativity dominance (Baumeister et al. 2001; Rozin & Royzman 2001; Kahneman 2011; Cerulo 2010), negative consensus functions as a diagnostic alarm alerting individuals to social risk and taste stigma, overriding automatic perceptual fluency.

### 3. Status-Differentiated Social Influence Across Four Educational Tiers (Section 3.2 & Figure 4)
Because the treatment vignettes explicitly differentiated alter status via educational credentials and occupations, educational attainment is the primary structural axis of cultural capital matching ego to alter (titled `\subsection{Status-Differentiated Social Influence}` in `manuscript_R1.tex`). With $N = 1,981$ and high repeated-measures test-retest precision ($r = 0.899, \sigma_{\Delta} = 0.688$), the design has ample statistical power to test four granular educational tiers via multinomial IPW (Figure \ref{fig:did_edu_4tiers} and Appendix Table \ref{tbl:did_edu_4tiers}):
- **Tier 1: High School or Less ($N = 468$):** Exclusively positive or inert shifts. Positive facilitation under Generalized Likes ($\text{DiD} = +0.284^{\dagger}, p = 0.0608$) and Low-Status Dislikes ($\text{DiD} = +0.240^{\dagger}, p = 0.0737$). Unresponsive to elite cues ($+0.032, p = 0.777$ for like; $-0.140, p = 0.215$ for dislike).
  - *Hypothesis 4 (Cultural Goodwill) is decisively rejected:* Lower-status individuals exhibit no deference or upward alignment with elite consensus.
- **Tier 2: Two-Year Associate / Some College ($N = 655$):** Complete evaluative stability and inertia across all six conditions ($p \ge 0.25$, estimates tightly bounded between $-0.113$ and $+0.145$). Functions as an evaluative buffer.
- **Tier 3: Four-Year Bachelor's Degree ($N = 577$):** Onset of downward evaluative suppression under High-Status Dislikes ($\text{DiD} = -0.271^{*}, p = 0.0296$) and Generalized Dislikes ($\text{DiD} = -0.308^{*}, p = 0.0455$), with complete unresponsiveness to positive cues ($p \ge 0.75$).
  - *Hypothesis 3 (Same-Status Alignment) is rejected across strata:* BA holders do not follow high-status likes ($-0.030, p = 0.809$).
- **Tier 4: Postgraduate / Advanced Degree ($N = 281$):** Severe, pervasive Bourdieusian boundary-drawing and status distancing:
  - *Hypothesis 5 (Status-Based Distancing) is strongly supported:* Learning that working-class peers liked the painting triggers an immediate evaluative collapse of nearly half a point ($\text{DiD} = -0.491^{***}, SE = 0.135, t = -3.64, p = 0.0003$, Cohen's $d = 0.33$)—the single largest negative treatment effect in the study. Postgraduates' counterfactual exposure drift is $+0.355$ ($p < 0.001$, model-implied).
  - Reinforced by severe downward vetoes across all dislike conditions (Generalized Dislike: $-0.442^{**}$; Low-Status Dislike: $-0.345^{**}$; High-Status Dislike: $-0.266^{*}$).

### 4. Status Inconsistency and Discrete Behavioral Choices (Section 3.3 & Figure 5)
Subjective social class identification (Middle Class vs. Working Class) cross-cuts education to form the four status consistency quadrants (Working/No College, Working/College, Middle/No College, Middle/College) to test **Hypothesis 6 (Status Consistency)** via multinomial logistic regression (Figure \ref{fig:multinom}):
- **Baseline Reference Group (Working Class, No College):** $73.8\%$ Stay, $14.2\%$ Conform, $12.0\%$ React.
- **Inertia (Stay):** Status consistency anchors stability. Middle Class/College is $+7.3\%$ more likely to stay ($\text{AME} = +0.073^{***}, SE = 0.013, z = 5.47, p < 0.001$, overall stay rate $81.1\%$). Inconsistent non-college actors are less stable ($\text{AME} = -0.026^{\dagger}, p = 0.070$, stay rate $71.2\%$).
- **Conformity:** Status-inconsistent individuals are significantly more susceptible to external influence: Working Class/College is $+4.2\%$ more likely to conform ($\text{AME} = +0.042^{***}, p = 0.0003$), and Middle Class/No College is $+4.3\%$ more likely to conform ($\text{AME} = +0.043^{***}, p = 0.0002$). High-status consistent respondents are significantly less likely to conform ($\text{AME} = -0.033^{**}, p = 0.0021$).
- **Reactance:** College-educated individuals shun oppositional reactance ($-3.0\%$ and $-4.0\%, p < 0.003$). Oppositional defiance is concentrated among non-college workers.
- **Sensitivity Check (Appendix Figure A.4):** Re-estimating the model excluding Taste-Only conditions ($N = 1,649$) yields identical substantive results (Middle Class with College stay $+6.6\%, p < 0.001$; conformity heightened among status-inconsistent groups at $+5.5\%$ and $+5.0\%$, both $p < 0.001$).
- **Streamlining Benefit:** Eliminating the old 24-cell continuous grid from the main text removed narrative redundancy and statistical dilution; the full 24-cell regression table is retained in Appendix Table \ref{tbl:did_status_quadrants} for reference.

### 5. Inverse Probability Weighting (IPW) Causal Architecture (Section 2.5)
- Propensity score weighting via `WeightIt` and `cobalt` balances strictly exogenous pre-treatment baseline covariates (`age`, `female`, `raceeth`, and `parented`), excluding post-treatment adult personal income and geographic region to avoid conditioning on post-treatment socioeconomic outcomes of education.
- Multinomial IPW across the four educational tiers is applied to the DiD models in Section 3.2 (Figure 4).
- Multinomial IPW across the four status consistency quadrants is applied to the discrete behavioral models in Section 3.3 (Figure 5).
- Standardized mean differences across all status groups are compressed below $0.10$ (Figure 2 in Section 2.5).

---

## Active Manuscript Assets Inventory (`manuscript_R1.tex`)

All figures use **horizontal bar plots with color-matched error bars** and standardized top-down y-axis ordering (grouping all Likes together and all Dislikes together, ordered by Generalized, High-Status, Low-Status):
1. Generalized Like
2. High-Status Like
3. Low-Status Like
4. Generalized Dislike
5. High-Status Dislike
6. Low-Status Dislike

| Manuscript Asset | File Path | Label | Description |
| :--- | :--- | :--- | :--- |
| **Figure 1** | `figures/experimental_stimulus.jpeg` | `\ref{fig:stimulus}` | Whistler's *Nocturne: Blue and Gold -- Old Battersea Bridge* (1872) |
| **Figure 2** | `figures/Figure8_CovariateBalance.png` | `\ref{fig:balance}` | IPW Love Plot of covariate balance across status quadrants (Section 2.5) |
| **Figure 3** | `figures/Figure_DiD_Baseline_Influence.png` | `\ref{fig:did_baseline}` | Horizontal bar plot of net DiD treatment effects for Section 3.1 generalized influence ($N = 457$) |
| **Figure 4** | `figures/Figure_DiD_Edu_4Tiers.png` | `\ref{fig:did_edu_4tiers}` | 4-panel horizontal bar plot of DiD effects across four educational tiers ($N = 1,981$, Section 3.2) |
| **Figure 5** | `figures/Figure7_MultinomialBehavior.png` | `\ref{fig:multinom}` | 3-panel horizontal bar plot of AMEs for Stay, Conform, and React across status quadrants (Section 3.3) |
| **Table 1** | `manuscript_R1.tex` | `\ref{tbl:descriptives}` | Primary sample demographics (Age $\ge 25$, $N = 1,981$) vs. 2012 Census benchmarks across experimental arms (typed; all counts verified programmatically via `R/06_models_appendix.R`) |
| **Table 2** | `manuscript_R1.tex` | `\ref{tbl:hypotheses_summary}` | Summary of Hypotheses (H1–H6), Theoretical Expectations, and Empirical Verdicts (Section 4.1) |
| **Appendix Fig A.1** | `figures/Figure_MDE_Power_Curves.png` | `\ref{fig:mde_curves}` | Dual-panel MDE power curves (theoretical & empirical benchmarks for Age $\ge 25$ sample, Appendix A) |
| **Appendix Fig A.2** | `figures/Figure_DiD_Edu_Class_Separate.png` | `\ref{fig:did_edu_class_separate}` | Two-panel DiD bar plot moderated separately by Education Alone and Subjective Class Alone (Primary Sample, $N = 1,981$, Appendix C) |
| **Appendix Fig A.3** | `figures/Figure_DiD_Pooled.png` | `\ref{fig:did_pooled}` | Difference-in-Differences Treatment Effects in the Pooled Primary Sample ($N = 1,981$, Appendix D) |
| **Appendix Fig A.4** | `figures/Figure11_Sens_MultinomialBehavior.png` | `\ref{fig:sens_multinom}` | Sensitivity behavioral bar plot (excluding Taste-Only conditions, $N = 1,649$, Appendix E) |
| **Appendix Tab A.1** | `tables/table_mde_summary.tex` | `\ref{tbl:mde_analysis}` | Ex-post Minimum Detectable Effect (MDE) analysis table (Appendix A), generated by `R/08_make_tables.R` (all inputs data-computed by `R/06_models_appendix.R`) and `\input` into `manuscript_R1.tex` |
| **Appendix Tab A.2** | `tables/table_did_edu_4tiers.tex` | `\ref{tbl:did_edu_4tiers}` | DiD estimates across Four Educational Tiers ($N = 1,981$, Appendix C), generated by `R/08_make_tables.R` |
| **Appendix Tab A.3** | `tables/table_did_status_quadrants.tex` | `\ref{tbl:did_status_quadrants}` | Complete 24-cell DiD matrix across Status Consistency Quadrants (Appendix C), generated by `R/08_make_tables.R` |
| **Appendix Tab A.4** | `tables/table_did_edu_class_primary.tex` | `\ref{tbl:did_edu_class_primary}` | DiD estimates moderated separately by Education Alone and Subjective Class Alone (Primary Sample, $N = 1,981$, Appendix C; generated by `R/08_make_tables.R`) |
| **Appendix Tab A.5** | `tables/table_did_pooled_compare.tex` | `\ref{tbl:appendix_did_compare}` | Comparison of Unweighted and IPW-Weighted pooled DiD models ($N = 1,981$, Appendix D), generated by `R/08_make_tables.R` |
| **Appendix Tab A.6** | `manuscript_R1.tex` | `\ref{tbl:full_sample_descriptives}` | Full unrestricted sample demographics ($N = 2,275$, Appendix G; typed, verified via `R/06_models_appendix.R`) |
| **Appendix Tab A.7** | `tables/table_did_edu_class_separate.tex` | `\ref{tbl:did_edu_class_full}` | Full unrestricted sample stepwise DiD estimates ($N = 2,252$, Appendix G), generated by `R/08_make_tables.R` |
| **Appendix Tab A.8** | `tables/table_did_status_quadrants_full.tex` | `\ref{tbl:did_status_quadrants_full}` | Full unrestricted sample 24-cell status consistency matrix ($N = 2,252$, Appendix G), generated by `R/08_make_tables.R` |
| **Response Memo (TeX)** | `response_to_reviewers.tex` | --- | Publication-grade LaTeX response memo styled with `tcolorbox`, full prose paragraphs, and verified citations |
| **Response Memo (PDF)** | `response_to_reviewers.pdf` | --- | Compiled 18-page PDF response memo ready for submission to *Poetics* |

---

## Revision Status Tracker (All Points Fully Addressed)

- [x] **Primary Sample Restriction ($\text{Age} \ge 25$):** Restricts main analysis to respondents aged 25+ ($N = 1,981$) to ensure completed college attainment, preserving full unrestricted sample ($N = 2,253$ evaluators; $N = 2,252$ model complete cases) in Appendix G.
- [x] **Four-Tier Educational Disaggregation (Section 3.2 & Figure 4):** Promoted the 4-tier education model to Section 3.2 as Figure 4, testing H3, H4, and H5 directly.
- [x] **Streamlined Status Consistency (Section 3.3 & Figure 5):** Eliminated the unwieldy 24-cell continuous grid from the main text; dedicated Section 3.3 exclusively to the discrete multinomial model of Stay, Conform, and React (Figure 5) testing Hypothesis 6.
- [x] **Negativity Bias Grounding (Section 3.1 & Section 4.3):** Integrated cognitive and social psychological literature on negativity bias and negativity dominance (Baumeister et al. 2001; Rozin & Royzman 2001; Kahneman 2011; Cerulo 2010), explaining why negative peer consensus acts as an authoritative veto against natural aesthetic familiarization.
- [x] **Discussion Streamlining (Section 4):** Structured into 3 punchy, academic sections (4.1 Summary of Key Results with Table 2; 4.2 Limitations & Suggestions for Future Work; 4.3 Implications synthesizing distinction, reactive defense, negativity bias, and status crystallization).
- [x] **Word Count Balance Optimization:** Main body balanced at approximately 8,404 words (Intro ~25.8%, Methods ~32.3%, Results ~23.2%, Discussion ~18.8%), adhering to *Poetics* standards. (Recounted after the October 2026 Overleaf Section 1 prose revisions, which renamed §1.3 "The Present Research" and revised the study-outcome sentence to describe the net-of-drift DiD change plus the discrete stay/conform/react outcomes, and after moving the funding acknowledgement from §2.1 to the title-page \thanks footnote for blinding.)
- [x] **Blinding: Funding Acknowledgement Relocated (October 2026):** Removed the NSF/Notre Dame funding sentence from §2.1 (now ends "Participants received monetary compensation (\$3.92) via SSI.") and added it as a "Funding:" \thanks footnote attached to the author block on the non-blinded title page, so the blinded body text reveals no institutional or grant identity. Note: if the journal later requires a fully blinded submission, the author block and this footnote should move to a separate title-page file.
- [x] **Structural Revision (October 2026):** Editorial pass for structure, simplicity, and flow: corrected the Whistler–Ruskin libel trial date (1877→1878), fixed the §3.1 "raw evaluations" mislabel (4.65→4.85 are IPW-weighted trial means), replaced colloquial §3.2 phrasing ("one shining spot"/"had a rough time"), softened the overstated §3.3 reactance opener (MC/No College contrast is marginal), moved the ES/CS consolidation F-tests and 36-cell power arithmetic from §2.4 to a closing design note in Appendix A, replaced the §2.2 verbatim prompt quotes with a paraphrase pointing to Appendix B, compressed §1.3 Study Description, and gave the §3.2 tier-2 ancillary split real appendix backing (Appendix C note; stay rates 70.4% vs. 73.0%, χ² = 0.34, p = 0.56, now computed by `R/06_models_appendix.R` → `tables/tier2_homogeneity.rds`). Section/subsection numbering, equation numbering, and all memo cross-references unchanged; manuscript recompiled at 41 pp., 0 errors. Added a short concluding paragraph to Section 4.3, giving the article an explicit closing synthesis of the valence-asymmetry, status-distancing, and status-crystallization findings.
- [x] **Response Memo Prose Overhaul:** Rewrote all responses in `response_to_reviewers.tex` into continuous academic paragraphs (eliminating fragmented bullet lists), using italics for emphasis and removing bug-tracker status tags (`Status: [Addressed]`).
- [x] **Response Memo Cross-Reference Audit:** Verified and synchronized all section, equation, table, and figure numbers against `manuscript_R1.tex` (e.g., Section 2.3 for Demand Characteristics, Section 2.6 for DiD Strategy, Section 4.1 for Table 2, Equation 5 for generalized DiD, and Appendix Tables A.6–A.8 for full sample estimates). Re-synchronized after inserting Appendix Table A.4 / Figure A.2 (primary-sample education-alone/class-alone check), which shifted all subsequent appendix table numbers (old A.4–A.7 $\to$ A.5–A.8) and figure numbers (old A.2–A.3 $\to$ A.3–A.4) across `manuscript_R1.tex`, `response_to_reviewers.tex`, and this file.
- [x] **Global AGENTS.md Standards:** Updated `~/.config/agents/AGENTS.md` with permanent standards for Response to Reviewers memos across all projects.
- [x] **DiD Estimation Strategy (R1 #1):** Fully implemented in `R/did_models.R`, woven into narrative and equations.
- [x] **Terminology Disambiguation (R1 #2):** Reserved "baseline" strictly for Trial 1; renamed unexposed group "Control Condition"; drift termed "exposure drift".
- [x] **Survey Sampling & Descriptives (R1 #3):** Documented 2012 SSI panel recruitment, quota matching, deliberate college oversample ($43.3\%$ in primary sample), participant flow, CI inferential scope, and Table 1.
- [x] **Ex-Post Minimum Detectable Effect (MDE) Analysis (R1 #4):** Fully calculated (now via `R/06_models_appendix.R` with all cell sizes and variance inputs computed from data), documented in Appendix A, Table \ref{tbl:mde_analysis}, and Figure \ref{fig:mde_curves}.
- [x] **Treatment Vignettes in Appendix (R1 #5):** Verbatim transcription of Qualtrics survey flow, stimuli, and vignettes in Appendix B.
- [x] **IPW Causal Logic & Covariate Balance (R1 #7, #8):** Added pedagogical explanation of pseudo-populations and conditional exchangeability; documented Love plot in Section 2.5 (Figure \ref{fig:balance}).
- [x] **Separate Education & Class Models on Primary Sample (R1 #6):** Beyond the full-sample stepwise check (Appendix Table A.7), also fit the education-alone/subjective-class-alone specification directly on the primary analytic sample (Age $\ge 24$, $N = 1,981$) in Appendix Table A.4 and Appendix Figure A.2, confirming education is the more decisive single-axis moderator; cited in Section 3.2 before the four-tier disaggregation.
- [x] **Figure Polish & Color Matching (R1 #9):** Standardized title capitalization, zero-effect dashed lines, color-matched error bars, and single clean 3-level legends.
- [x] **Generalized Influence Baseline (R1 #10):** Established status-free baseline in Section 3.1 (Equation \ref{eq:generalized_did_model}), demonstrating mere exposure drift and decisive veto suppression by Generalized Dislike.
- [x] **Disaggregated Behavioral Analysis (R1 #11):** Retained and streamlined multinomial directional shift models; added sensitivity analysis in Appendix Figure A.4.
- [x] **Full Regression Tables in Appendix (R1 #12):** Relocated regression tables into Appendix (Tables A.2, A.3, A.4, A.5), showcasing figures in the main text.
- [x] **Causal Warrant Hook & Research Question Rationale (Editor, R2 #1):** Centered opening around observational vs. experimental causal gap in cultural sociology.
- [x] **Demand Characteristics & Reactivity (Editor, R2 #3):** Added Section 2.3 detailing 4 procedural safeguards based on survey protocol.
- [x] **Valence Framing around Valence Asymmetry (R2 #4):** Reframed core claim around asymmetric veto power of negative evaluations.
- [x] **Status Inconsistency Mechanism & Moderation (R2 #5, R2 #6):** Integrated status crystallization theory (Lenski 1954; Hope 1975); clarified that consistency anchors stability, whereas inconsistency breeds fluidity.
- [x] **Clear Empirical Takeaways for Researchers (R2 #7):** Added Table 2 systematically summarizing each hypothesis, DiD estimate, and statistical verdict.
- [x] **Hypothesis Alignment & Numbering:** Systematically numbered and aligned all hypotheses across Section 1.4, Section 3 results, Table 2 (Section 4.1), and Section 4.3 discussion.
- [x] **Section 3.1 Baseline Influence Figure:** Added Figure 3 (`Figure_DiD_Baseline_Influence.png`), displaying net DiD treatment effects relative to control exposure drift.
- [x] **Text Asterisk Formatting:** Removed all significance asterisks and daggers next to $p$-values from the main narrative text, preserving them strictly in regression and summary tables.
- [x] **Standardized Condition Ordering:** Imposed identical top-down y-axis ordering across all figures and tables (Generalized Like $\to$ High-Status Like $\to$ Low-Status Like $\to$ Generalized Dislike $\to$ High-Status Dislike $\to$ Low-Status Dislike).
- [x] **Preservation of Original Manuscript:** `manuscript.tex` frozen as the historical original submission (14 pages); `manuscript_R1.tex` used for all active revision work.
- [x] **Overleaf Branch Reconciliation:** Merged latest Overleaf updates (commit `81a89a8`), synchronizing Section 1.2.3 heading, Section 4.3 streamlined 4-paragraph synthesis, and literature additions across repository.
- [x] **Pre-Resubmission Replication Audit (October 2026):** Complete audit and remediation, documented in `VERIFICATION_REPORT.md`. Rebuilt the pipeline into numbered scripts (`R/01_dataproc.R` … `R/08_make_tables.R` + `R/run_all.R`); quarantined 16 superseded scripts to `R/legacy/` (they overwrote primary-sample figures with full-sample versions); reconstructed the previously unscripted 4-tier education model and converted Appendix Tables A.2, A.3, A.5, and A.8 from hand-entered inline tables into generated `\input` files; regenerated all 8 figures and 7 tables from raw data with verified sample labels; corrected all number discrepancies (age wording standardized to 25+, sensitivity N 1,643→1,649 with corrected AMEs, Appendix A prose rewritten to primary-sample values, ES/CS F-tests updated to reproducible values, SMD range 0.29–0.59, postgraduate drift +0.355, Table A.6 micro-errors, response-memo statistics including the under-25 degree share and the regional balance caveat); deleted 16 orphaned/unreferenced figure and table artifacts. Both PDFs recompiled with 0 errors (manuscript 41 pp, response memo 18 pp).
