# Taste Influence Paper Project

## Overview
This project modernizes, revises, and revives the analysis for the paper *"Stay, React, or Conform? Examining Social Influence Effects on Aesthetic Judgments"* (Omar Lizardo & Sara Skiles), currently undergoing Major Revision at *Poetics* (POETICS-D-26-00490). The original Stata pipeline and early drafts have been upgraded to a fully reproducible R workflow and connected to Overleaf.

- **Journal:** *Poetics* (Editor-in-Chief: Hannah Wohl)
- **Overleaf Project URL:** https://www.overleaf.com/project/6a3fe1ed665ddc04ec45136a
- **Overleaf Git Endpoint:** `https://git.overleaf.com/6a3fe1ed665ddc04ec45136a`
- **Revision Tracking:** `REVISION_PLAN_POETICS.md` and `response_to_reviewers.md`
- **Manuscript Files & Critical Preservation Policy:**
  - `manuscript.tex`: **DO NOT OVERWRITE OR EDIT.** Preserves the frozen, historical original version of the manuscript as initially submitted to *Poetics* (14 pages).
  - `manuscript_R1.tex`: **The ONLY active working manuscript file.** All current revisions, Overleaf edits, DiD models, IPW specifications, and text updates belong exclusively in `manuscript_R1.tex`.

---

## Data & Experimental Protocol
- **Primary Raw Data Path**: `/home/omarlizardo/projects/CULTURE/cultural-consensus-musical-genres/SSI-2012/data/clean/ssi2012_cleaned.dta` (fallback: `/home/omarlizardo/ACADEMIC AND COURSE MATERIALS/SSI-2012/data/clean/ssi2012_cleaned.dta`).
- **Format**: Stata `.dta` file containing survey data with embedded value labels, loaded via `haven::read_dta()`.
- **Sample Flow**: $3,782$ accessed survey $\to 85$ non-consent $\to 12$ under-age $\to 1,394$ quota-screened $\to 16$ early dropouts $\to N = 2,275$ completed responses ($N = 2,253$ complete pre- and post-treatment evaluations).
- **Experimental Procedures (`Skiles dissertation2.docx` & Appendix \ref{sec:appendix_vignettes})**:
  - *Trial 1 (Survey Page 4):* High-resolution image of James McNeill Whistler's *Nocturne: Battersea Bridge* (1872); verbatim prompt (*"Please look at this painting for a few seconds. Give us your first impression of this painting -- how much do you like it?"*) on a reversed 1–7 scale ($7 = \text{like very much}$, $1 = \text{dislike very much}$).
  - *Feedback Vignette & Attribution (Pages 5–6):* Treatment respondents receive naturalistic aggregate feedback from prior survey respondents (*"Our survey so far indicates that the group of people most likely to say that they [LIKE / DISLIKE] the painting you saw have completed..."*) followed by subjective similarity (5-point) and alter attribution probes.
  - *Cognitive Buffer (Pages 7–15):* Extensive 15-to-20 minute intervening survey battery (detailed educational history, degree major, parental education, occupation/SOC, income, subjective social class, and a comprehensive 20-genre musical taste battery).
  - *Trial 2 (Page 16):* Respondents view the identical painting again with verbatim prompt (*"Please look at this painting for a few seconds again. Give us your final impression of this painting -- how much do you like it?"*) on the same scale, without being reminded of their Trial 1 score and without any instructional prompt suggesting conformity.
  - *Consolidation of High-Status Alters:* Economic Specialists (ES: business degree, financial firm) and Cultural Specialists (CS: advanced degrees/PhD, higher education) are collapsed into a single High-Status (`+Status`) condition. Formal $F$-tests confirm responses to ES and CS are statistically indistinguishable ($p = 0.591$ for likes; $p = 0.803$ for dislikes), and collapsing prevents severe statistical power loss across a 36-cell design.

---

## Key Methodological Innovations & Core Findings

### 1. Difference-in-Differences Causal Architecture (Section 2.5)
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
Estimated on the 3-condition status-free subset (Control $N = 177$, Generalized Like $N = 172$, Generalized Dislike $N = 172$, total $N = 521$, $1,042$ observations) via Equation \ref{eq:generalized_did_model}:
$$\text{Taste}_{it} = \beta_0 + \beta_1 \text{Trial}_{it} + \beta_2 \text{Like}_i + \beta_3 \text{Dislike}_i + \delta_{\text{Like}} (\text{Trial}_{it} \times \text{Like}_i) + \delta_{\text{Dislike}} (\text{Trial}_{it} \times \text{Dislike}_i) + u_i + \epsilon_{it}$$
- **Mere Exposure Drift in Control:** Seeing the artwork a second time in the absence of external cues produces an intrinsic appreciation boost ($\beta_1 = +0.156^{**}, SE = 0.052, t = 3.00, p = 0.0029$).
- **Valence Asymmetry in Generalized Cues:**
  - *Generalized Like:* Raw increase ($+0.224^{***}$), but net DiD boost relative to control drift is positive and modest ($\delta_{\text{Like}} = +0.068, p = 0.367$).
  - *Generalized Dislike:* Negative feedback completely halts exposure appreciation (net change $-0.016$), resulting in a statistically significant negative DiD suppression ($\delta_{\text{Dislike}} = -0.172^{*}, SE = 0.074, t = -2.35, p = 0.0197$).
  - *Valence Contrast:* Direct contrast yields a significant directional swing ($\Delta = +0.240^{**}, SE = 0.075, \chi^2 = 10.32, p = 0.0013$), demonstrating that negative social consensus exerts an asymmetric veto power.

### 3. Moderated DiD Models & Status Consistency Matrix (Sections 3.2 & 3.3)
- **Stepwise Models (Figure 4 & Appendix Table A.2):**
  - Uses the uniform 4-group multinomial IPW weighting for complete methodological consistency across all specifications.
  - *Education Alone:* Educational capital is the primary structural fault line. Non-college respondents align positively with generalized likes ($+0.246, p = 0.034$) and shift positively under low-status dislikes ($+0.147, p = 0.136$). College graduates experience sharp evaluative suppression under High-Status Dislike ($-0.302, p = 0.0006$), Generalized Dislike ($-0.329, p = 0.0022$), and Low-Status Dislike ($-0.202, p = 0.033$).
  - *Subjective Class Alone:* Middle-class identifiers display significant negative shifts under High-Status Dislike ($-0.220, p = 0.017$) and Low-Status Like ($-0.207, p = 0.044$). Working-class identifiers adjust negatively under Generalized Dislikes ($-0.254, p = 0.015$) and High-Status Dislikes ($-0.186, p = 0.025$).
- **The Four-Quadrant Status Consistency Matrix (Figure 5 & Appendix Table A.3):**
  - Cross-cutting education and subjective class reveals that status-consistent and inconsistent actors behave distinctively.
  - *Hypothesis 3 (Same-Status Alignment):* Rejected across consistent groups ($p \ge 0.35$).
  - *Hypothesis 4 (Cultural Goodwill / Upward Alignment):* Rejected for low-status consistent workers ($p \ge 0.25$), but college-educated workers display sharp negative reactivity to high-status dislikes ($-0.394, p = 0.0010$).
  - *Hypothesis 5 (Status-Based Distancing Disalignment):* Strongly supported! High-status consistent respondents (Middle Class/College) actively abandon taste when exposed to low-status likes ($-0.296, p = 0.0391$).

### 4. Inverse Probability Weighting (IPW) Causal Architecture (`R/propensity_models.R`)
- Multinomial propensity score weighting via `WeightIt` and `cobalt` balances strictly exogenous pre-treatment baseline covariates (`age`, `female`, `raceeth`, and `parented`), excluding post-treatment adult personal income and geographic region to avoid conditioning on post-treatment socioeconomic outcomes of education and prevent overcontrol bias.
- All models (pooled baseline, stepwise education/class, status consistency quadrants, and discrete multinomial behavioral choice models) use this uniform 4-group multinomial weighting for complete methodological consistency.
- Standardized mean differences across all status groups are compressed below $0.10$ (Figure 2).

### 5. Discrete Behavioral Modeling via Marginal Effects (Section 3.4 & Figure 6)
- Evaluated via Average Marginal Effects from multinomial logit relative to *Working Class, No College*:
  - **Hypothesis 6 (Status Consistency):** Strongly supported ($p < 0.001$).
  - **Inertia (Stay):** Structural status consistency drives stability. Middle Class/College is $+4.6\%$ more likely to stay ($p < 0.001$), while Middle Class/No College is $-5.4\%$ less likely to stay ($p < 0.001$).
  - **Conformity:** Status-inconsistent individuals are significantly more susceptible to external influence: Working Class/College is $+5.4\%$ more likely to conform ($p < 0.001$), and Middle Class/No College is $+4.1\%$ more likely to conform ($p < 0.001$).
  - **Reactance:** College-educated individuals are significantly less likely to react ($-3.2\%$ and $-2.5\%$, $p < 0.01$). Oppositional reactance is concentrated among non-college workers.
  - **Sensitivity Check (Appendix Figure A.3):** Re-estimating the model excluding Taste-Only conditions ($N = 1,870$) yields identical substantive results.

---

## Active Manuscript Assets Inventory (`manuscript_R1.tex`)

All figures use **horizontal bar plots with color-matched error bars** and standardized top-down y-axis ordering:
1. High-Status Like
2. Low-Status Like
3. High-Status Dislike
4. Low-Status Dislike
5. Generalized Like
6. Generalized Dislike

| Manuscript Asset | File Path | Label | Description |
| :--- | :--- | :--- | :--- |
| **Figure 1** | `figures/experimental_stimulus.jpeg` | `\ref{fig:stimulus}` | Whistler's *Nocturne: Blue and Gold -- Old Battersea Bridge* (1872) |
| **Figure 2** | `figures/Figure8_CovariateBalance.png` | `\ref{fig:balance}` | IPW Love Plot of covariate balance across status quadrants |
| **Figure 3** | `figures/Figure_DiD_Baseline_Influence.png` | `\ref{fig:did_baseline}` | 2-panel plot of evaluative trajectories and DiD effects for Section 3.1 baseline influence |
| **Figure 4** | `figures/Figure_DiD_Edu_Class_Separate.png` | `\ref{fig:did_edu_class}` | 2-panel horizontal bar plot of DiD effects for Education alone and Class alone |
| **Figure 5** | `figures/Figure_DiD_Status_All.png` | `\ref{fig:did_status_full}` | Complete 24-cell status consistency DiD interaction grid (IPW-Weighted) |
| **Figure 6** | `figures/Figure7_MultinomialBehavior.png` | `\ref{fig:multinom}` | 3-panel horizontal bar plot of Average Marginal Effects for Stay, Conform, and React |
| **Table 1** | `manuscript_R1.tex` | `\ref{tbl:descriptives}` | Sample demographics vs. 2012 Census benchmarks across experimental conditions |
| **Table 2** | `manuscript_R1.tex` | `\ref{tbl:hypotheses_summary}` | Summary of Hypotheses, DiD Estimates, and Empirical Verdicts |
| **Appendix Fig A.1** | `figures/Figure_MDE_Power_Curves.png` | `\ref{fig:mde_curves}` | Dual-panel MDE power curves (theoretical & empirical benchmarks) |
| **Appendix Fig A.2** | `figures/Figure_DiD_Pooled.png` | `\ref{fig:did_pooled}` | Difference-in-Differences Treatment Effects in the Pooled Sample |
| **Appendix Fig A.3** | `figures/Figure11_Sens_MultinomialBehavior.png` | `\ref{fig:sens_multinom}` | Sensitivity behavioral bar plot (excluding Taste-Only conditions, $N = 1,870$) |
| **Appendix Tab A.1** | `tables/table_mde_summary.tex` | `\ref{tbl:mde_analysis}` | Ex-post Minimum Detectable Effect (MDE) analysis table |
| **Appendix Tab A.2** | `manuscript_R1.tex` | `\ref{tbl:did_edu_class}` | DiD estimates moderated separately by Education and Subjective Class |
| **Appendix Tab A.3** | `manuscript_R1.tex` | `\ref{tbl:did_status_quadrants}` | Complete 24-cell DiD matrix across Status Consistency Quadrants |
| **Appendix Tab A.4** | `manuscript_R1.tex` | `\ref{tbl:appendix_did_compare}` | Comparison of Unweighted and IPW-Weighted pooled DiD models |

---

## Revision Status Tracker (All Points Fully Addressed)

- [x] **DiD Estimation Strategy (R1 #1):** Fully implemented in `R/did_models.R`, woven into narrative and equations.
- [x] **Terminology Disambiguation (R1 #2):** Reserved "baseline" strictly for Trial 1; renamed unexposed group "Control Condition"; drift termed "exposure drift".
- [x] **Survey Sampling & Descriptives (R1 #3):** Documented 2012 SSI panel recruitment, quota matching, deliberate college oversample, participant flow ($3,782 \to 2,275$), CI inferential scope, and Table 1.
- [x] **Ex-Post Minimum Detectable Effect (MDE) Analysis (R1 #4):** Fully calculated via `R/mde_power_analysis.R`, documented in Appendix A, Table \ref{tbl:mde_analysis}, and Figure \ref{fig:mde_curves}.
- [x] **Treatment Vignettes in Appendix (R1 #5):** Verbatim transcription of Qualtrics survey flow, stimuli, and vignettes in Appendix B.
- [x] **Stepwise Main Effects for Education & Class (R1 #6):** Fully estimated in `R/stepwise_status_models.R`, integrated into Section 3.2, Figure \ref{fig:did_edu_class}, and Appendix Table \ref{tbl:did_edu_class}.
- [x] **IPW Causal Logic & Covariate Balance (R1 #7, #8):** Added pedagogical explanation of pseudo-populations and conditional exchangeability; documented Love plot in Section 2.4 (Figure \ref{fig:balance}).
- [x] **Figure Polish & Color Matching (R1 #9):** Standardized title capitalization, zero-effect dashed lines, color-matched error bars, and single clean 3-level legends.
- [x] **Generalized Influence Baseline (R1 #10):** Established status-free baseline in Section 3.1 (Equation \ref{eq:generalized_did_model}), demonstrating mere exposure drift and decisive veto suppression by Generalized Dislike.
- [x] **Disaggregated Behavioral Analysis (R1 #11):** Retained and streamlined multinomial directional shift models; added sensitivity analysis in Appendix Figure A.3.
- [x] **Full Regression Tables in Appendix (R1 #12):** Relocated Tables 2 and 3 into Appendix (Tables A.2 and A.3), showcasing figures in the main text.
- [x] **Update Literature & Theoretical Engagement (R1 #13):** Integrated scholarship on cultural cognition, dual-process habitus, aesthetic signaling, and symbolic boundaries (Lizardo et al., Wohl, Vanzella, Brand & Thomas).
- [x] **Causal Warrant Hook & Research Question Rationale (Editor, R2 #1):** Centered opening around observational vs. experimental causal gap in cultural sociology.
- [x] **Streamline Section 1.1 (R2 #2):** Organized study description into concise academic prose paragraphs.
- [x] **Demand Characteristics & Reactivity (Editor, R2 #3):** Added Section 2.3 detailing 4 procedural safeguards based on survey protocol.
- [x] **Valence Framing around Valence Asymmetry (R2 #4):** Reframed core claim around asymmetric veto power of negative evaluations.
- [x] **Status Inconsistency Mechanism & Moderation (R2 #5, R2 #6):** Integrated status crystallization theory (Lenski 1954; Hope 1975); clarified that consistency anchors stability, whereas inconsistency breeds fluidity.
- [x] **Clear Empirical Takeaways for Researchers (R2 #7):** Added Table 2 systematically summarizing each hypothesis, DiD estimate, and statistical verdict.
- [x] **Hypothesis Alignment & Numbering:** Systematically numbered and aligned all hypotheses across Section 1.3, Section 3 results, Table 2, and Section 4 discussion (H1: Mere Exposure, H2a: Positive Evaluations, H2b: Negative Evaluations, H3: Same-Status Alignment, H4: Cultural Goodwill, H5: Status-Based Distancing Disalignment, H6: Status Consistency).
- [x] **Section 3.1 Baseline Influence Figure:** Added Figure 3 (`Figure_DiD_Baseline_Influence.png`), displaying within-subject evaluative trajectories across repeated trials (Panel A) alongside net DiD treatment effects relative to control exposure drift (Panel B).
- [x] **Uniform 4-Group IPW Weighting:** Standardized all analyses (pooled baseline, stepwise education/class, status consistency quadrants, and discrete multinomial models) to use uniform 4-group multinomial IPW weights balancing strictly exogenous baseline covariates (`age`, `female`, `raceeth`, and `parented`).
- [x] **Text Asterisk Formatting:** Removed all significance asterisks and daggers next to $p$-values from the main narrative text, preserving them strictly in regression and summary tables.
- [x] **Asset Housekeeping:** Deleted obsolete `figures/Figure_DiD_Significant_Effects.*` assets.
- [x] **Standardized Condition Ordering:** Imposed identical top-down y-axis ordering across all figures and tables (High-Status Like $\to$ Generalized Dislike).
- [x] **Preservation of Original Manuscript:** `manuscript.tex` frozen as the historical original submission (14 pages); `manuscript_R1.tex` used for all active revision work.
