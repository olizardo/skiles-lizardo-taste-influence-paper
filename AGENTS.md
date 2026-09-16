# Taste Influence Paper Project

## Overview
This project modernizes, revises, and revives the analysis for the paper *"Stay, React, or Conform? Examining Social Influence Effects on Aesthetic Judgments"* (Omar Lizardo & Sara Skiles), currently undergoing Major Revision at *Poetics* (POETICS-D-26-00490). The original Stata pipeline and early drafts have been upgraded to a fully reproducible R workflow and connected to Overleaf.

- **Journal:** *Poetics* (Editor-in-Chief: Hannah Wohl)
- **Overleaf Project URL:** https://www.overleaf.com/project/6a3fe1ed665ddc04ec45136a
- **Overleaf Git Endpoint:** `https://git.overleaf.com/6a3fe1ed665ddc04ec45136a`
- **Revision Tracking:** `REVISION_PLAN_POETICS.md` and `response_to_reviewers.md`

---

## Data
- **Primary Raw Data Path**: `/home/omarlizardo/projects/CULTURE/cultural-consensus-musical-genres/SSI-2012/data/clean/ssi2012_cleaned.dta` (fallback: `/home/omarlizardo/ACADEMIC AND COURSE MATERIALS/SSI-2012/data/clean/ssi2012_cleaned.dta`).
- **Format**: Stata `.dta` file containing survey data with embedded value labels. Loaded via `haven::read_dta()`.
- **Data Processing (`R/dataproc.R`)**:
  - Filters missing evaluations on `taste1` and `taste2` ($N = 2,275$ completed responses; $N = 2,253$ complete pre/post evaluations).
  - Reverses the 1--7 taste scales so $7 = \text{like very much}$ and $1 = \text{dislike very much}$.
  - Constructs the 9-condition experimental factor (`cond_factor`) and collapsed 7-condition factor (`cond2_factor`).
  - Constructs the 4-level status consistency variable (`objsubjclass_factor`: Working Class/No College, Working Class/College, Middle Class/No College, Middle Class/College).
  - Reshapes data into wide (`df_wide`) and long (`df_long`) formats for repeated-measures analysis.

---

## Key Methodological Innovations & Core Findings

### 1. Difference-in-Differences (DiD) Analytic Strategy (`R/did_models.R`)
Replacing the original draft's simple within-condition pre/post change tests ($\bar{Y}_2 - \bar{Y}_1 \ne 0$), the analysis now uses a formal Difference-in-Differences design benchmarking all treatments against the unexposed **Control Condition**:
$$\text{Taste}_{ijt} = \beta_0 + \beta_1 \text{Trial}_{it} + \sum_{k=2}^{K} \beta_k \text{Cond}_{ik} + \sum_{k=1}^{K} \delta_k (\text{Trial}_{it} \times \text{Cond}_{ik}) + \mathbf{X}_i \boldsymbol{\gamma} + u_i + \epsilon_{ijt}$$
- **The Exposure Drift Counterfactual:** In the Control Condition (where respondents saw zero information), liking drifted upward significantly ($\beta_1 = +0.107, p = 0.041$). Crucially, this drift is concentrated among college graduates ($\beta_1 = +0.257, p = 0.016$), but completely absent among non-college respondents ($\beta_1 = 0.000, p = 1.00$).
- **The False-Positive Discovery:** In the original draft, apparent "positive conformity" in college-educated groups was an artifact of this unmeasured baseline drift. For example, Working Class/College respondents shifted $+0.288$ under "Like/High Status", but their control group drifted $+0.311$ with no information ($\text{DiD} = -0.024, p = 0.845$).
- **Valence Asymmetry Confirmed as an Asymmetric Veto:** In the pooled sample, negative evaluations significantly halt and reverse exposure drift: High-Status Dislike ($\text{DiD} = -0.121, p = 0.043^*$) and Generalized Dislike ($\text{DiD} = -0.125, p = 0.095^\dagger$). Positive evaluations fail to reach significance in the pooled sample ($p \ge 0.198$).
- **Cross-Status Reactance & Taste Abandonment (Hypothesis 3):** High-status consistent respondents (Middle Class/College) exposed to Low-Status Likes show a statistically significant negative DiD divergence ($\text{DiD} = -0.296, p = 0.039^*$), confirming Bourdieusian taste abandonment.

### 2. Inverse Probability Weighting (IPW) Causal Logic (`R/propensity_models.R`)
- Experimental conditions (information from others) were randomized.
- Respondent status consistency (`objsubjclass_factor`) is **observational**.
- IPW weights (via `WeightIt` and `cobalt`) balance age, gender, race/ethnicity, and parental education across status quadrants, achieving standardized mean differences $< 0.10$ across all covariates (Figure 1: `Figure8_CovariateBalance.png`).

### 3. Discrete Behavioral Modeling via Marginal Effects (`R/generate_did_barplots.R`)
- Categorizes choices into **Stay** ($\Delta = 0$), **Conform** (shifting in direction of cue), and **React** (shifting away).
- Evaluated via Average Marginal Effects from multinomial logit relative to *Working Class, No College*:
  - **Inertia (Stay):** Structural status consistency drives stability. Middle Class/College is $+4.6\%$ more likely to stay ($p < 0.001$), while Middle Class/No College is $-5.4\%$ less likely to stay ($p < 0.001$).
  - **Conformity:** Status-inconsistent individuals are significantly more susceptible to external influence: Working Class/College is $+5.4\%$ more likely to conform ($p < 0.001$), and Middle Class/No College is $+4.1\%$ more likely to conform ($p < 0.001$).
  - **Reactance:** College-educated individuals are significantly less likely to react ($-3.2\%$ and $-2.5\%$, $p < 0.01$). Oppositional reactance is concentrated among non-college workers.

---

## Active Manuscript Assets & Figure Inventory

All forest plots have been replaced with **horizontal bar plots with error bars** colored by statistical significance (Red: $p < 0.05$, Orange: $p < 0.10$, Grey: $p \ge 0.10$):

| Manuscript Asset | File Path | Description |
| :--- | :--- | :--- |
| **Stimulus Image** | `figures/experimental_stimulus.jpeg` | Whistler's *Nocturne: Battersea Bridge* (1872) |
| **Figure 1** | `figures/Figure8_CovariateBalance.png` | IPW Love Plot of covariate balance across status quadrants |
| **Figure 2** | `figures/Figure_DiD_Significant_Effects.png` | Focused 3-panel horizontal bar plot of the 9 statistically reliable DiD effects ($p < 0.10$) |
| **Figure 3** | `figures/Figure7_MultinomialBehavior.png` | 3-panel horizontal bar plot of Average Marginal Effects for Stay, Conform, and React |
| **Table 1** | `manuscript_R1.tex` (Table 1) | Sample demographics vs. 2012 Census benchmarks across experimental conditions |
| **Figure 3** | `figures/Figure_DiD_Edu_Class_Separate.png` | 2-panel horizontal bar plot of DiD effects for Education alone and Class alone |
| **Figure 4** | `figures/Figure_DiD_Significant_Effects.png` | Focused 3-panel horizontal bar plot of the 9 statistically reliable DiD effects ($p < 0.10$) |
| **Figure 5** | `figures/Figure7_MultinomialBehavior.png` | 3-panel horizontal bar plot of Average Marginal Effects for Stay, Conform, and React |
| **Table 1** | `manuscript_R1.tex` (Table 1) | Sample demographics vs. 2012 Census benchmarks across experimental conditions |
| **Table 2** | `manuscript_R1.tex` (Table 2) | Primary unweighted DiD linear mixed model (pooled sample) |
| **Table 3** | `manuscript_R1.tex` (Table 3) | Difference-in-Differences estimates moderated separately by Education and Class |
| **Table 4** | `manuscript_R1.tex` (Table 4) | Hypothesis evaluation matrix (estimates, expectations, and verdicts) |
| **Appendix Figure A.1** | `figures/Figure_MDE_Power_Curves.png` | Dual-panel MDE power curves (theoretical & empirical benchmarks) |
| **Appendix Figure A.2** | `figures/Figure_DiD_Status_All.png` | Full 24-cell status DiD bar plot with error bars |
| **Appendix Figure A.3** | `figures/Figure11_Sens_MultinomialBehavior.png` | Sensitivity behavioral bar plot (excluding Taste-Only conditions) |
| **Appendix Table A.1** | `tables/table_mde_summary.tex` | Ex-post Minimum Detectable Effect (MDE) analysis table |
| **Appendix Table A.2** | `tables/table_did_edu_class_separate.tex` | Separate DiD models for Education and Subjective Class |
| **Appendix Table A.3** | `manuscript_R1.tex` (Table A.2) | Comparison of Unweighted and IPW-Weighted pooled DiD models |

---

## Revision Status Tracker

### Completed Items:
- [x] **DiD Estimation Strategy (R1 #1):** Fully implemented in `R/did_models.R`, woven into narrative and Table 2.
- [x] **Terminology Disambiguation (R1 #2):** Reserved "baseline" strictly for Trial 1; renamed unexposed group "Control Condition"; drift termed "exposure drift".
- [x] **Survey Sampling & Descriptives (R1 #3):** Documented 2012 SSI panel recruitment, quota matching, deliberate college oversample, participant flow ($3,782 \to 2,275$), CI inferential scope, and Table 1.
- [x] **Ex-Post Minimum Detectable Effect (MDE) Analysis (R1 #4):** Fully calculated via `R/mde_power_analysis.R`, documented in Appendix A, Table \ref{tbl:mde_analysis}, and Figure \ref{fig:mde_curves}.
- [x] **Treatment Vignettes in Appendix (R1 #5):** Verbatim transcription of Qualtrics survey flow, stimuli, and vignettes in Appendix B.
- [x] **Stepwise Main Effects for Education & Class (R1 #6):** Fully estimated in `R/stepwise_status_models.R`, integrated into Section 3.4, Figure \ref{fig:did_edu_class}, and Table \ref{tbl:did_edu_class}.
- [x] **Sensitivity Analysis Excluding Taste-Only Cues (R1 #11):** Embedded Figure 11 (`Figure11_Sens_MultinomialBehavior.png`) in Appendix \ref{sec:appendix_sens_multinom} with main text pointer in Section 3.6.
- [x] **IPW Causal Logic & Covariate Balance (R1 #7, #8):** Added pedagogical explanation of pseudo-populations and conditional exchangeability; documented Love plot.
- [x] **Hypothesis Summary Table (R2 #7):** Added Table 4 systematically summarizing each hypothesis, DiD estimate, and statistical verdict.
- [x] **Purge "Peers" $\to$ "Others":** Standardized terminology across entire manuscript.
- [x] **Bar Plots with Error Bars:** Replaced forest plots with horizontal bar plots with error bars.
- [x] **Clean Up Figures Folder:** Deleted obsolete legacy within-subject plots (`Figure2_*` through `Figure6_*`, `Figure10_*`).
- [x] **Compliance with Global Guidelines (`~/.config/agents/AGENTS.md`):** Zero local LaTeX compilation, zero banned words, no lists in main text, CUA tripartite Discussion.
- [x] **Overleaf Git Remote:** Configured and synchronized (`git push overleaf main`).

- [x] **Demand Characteristics & Reactivity (R2 #3 & Editor):** Added Section 2.4 detailing the 4 procedural and behavioral safeguards against demand compliance.
- [x] **Export Full Model Regression Tables to LaTeX (R1 #12):** Generated full model tables across main text and Appendix (Table 1, Table 2, Table 3, Table 4, Appendix Table A.1, Appendix Table A.2, and Appendix Figure A.3).
- [x] **Deepen Theoretical Citations (R1 #13):** Integrated recent literature on cultural cognition, dual-process habitus, aesthetic signaling, and symbolic boundaries (Lizardo et al., Wohl, Vanzella) into `references.bib` and Sections 1 and 5.
- [x] **Incorporate All New Plots:** Embedded all 9 publication assets across main text and Appendix (`experimental_stimulus.jpeg`, `Figure8_CovariateBalance.png`, `Figure_DiD_Edu_Class_Separate.png`, `Figure_DiD_Significant_Effects.png`, `Figure7_MultinomialBehavior.png`, `Figure_MDE_Power_Curves.png`, `Figure_DiD_Pooled.png`, `Figure_DiD_Status_All.png`, `Figure11_Sens_MultinomialBehavior.png`).
- [x] **Eliminate Bullet Points:** Replaced all list structures in hypotheses and discussion with continuous academic prose paragraphs.
- [x] **Synchronize Root Manuscripts:** `manuscript.tex` and `manuscript_R1.tex` are fully identical and synchronized for seamless Overleaf rendering.
