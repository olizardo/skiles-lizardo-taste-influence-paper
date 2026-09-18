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
- **Sample Flow & Primary Population Restriction:**
  - $3,782$ accessed survey $\to 85$ non-consent $\to 12$ under-age $\to 1,394$ quota-screened $\to 16$ early dropouts $\to N = 2,275$ completed responses ($N = 2,253$ complete pre- and post-treatment evaluations).
  - **Primary Analytic Sample ($\text{Age} \ge 24$ / $\ge 25$):** To ensure all respondents have had the opportunity to complete higher education and eliminate right-censoring in educational attainment among the college-age cohort (18–24, where only 20.3% held a bachelor's degree), the primary analytic sample is restricted to respondents aged 24 or older ($N = 1,981$ complete cases; $3,962$ repeated observations across trials). College degree holders represent $43.3\%$ of this primary sample.
  - **Full Sample Preservation:** The full unrestricted sample ($N = 2,253$) is preserved as a complete sensitivity robustness check in Appendix \ref{sec:appendix_full_sample} (Tables \ref{tbl:full_sample_descriptives}, \ref{tbl:did_edu_class_full}, \ref{tbl:did_status_quadrants_full}), confirming that all empirical findings and hypothesis verdicts are identical across the entire age spectrum.
- **Experimental Procedures (`Skiles dissertation2.docx` & Appendix \ref{sec:appendix_vignettes})**:
  - *Trial 1 (Survey Page 4):* High-resolution image of James McNeill Whistler's *Nocturne: Battersea Bridge* (1872); verbatim prompt (*"Please look at this painting for a few seconds. Give us your first impression of this painting -- how much do you like it?"*) on a reversed 1–7 scale ($7 = \text{like very much}$, $1 = \text{dislike very much}$).
  - *Feedback Vignette & Attribution (Pages 5–6):* Treatment respondents receive naturalistic aggregate feedback from prior survey respondents (*"Our survey so far indicates that the group of people most likely to say that they [LIKE / DISLIKE] the painting you saw have completed..."*) followed by subjective similarity (5-point) and alter attribution probes.
  - *Cognitive Buffer (Pages 7–15):* Extensive 15-to-20 minute intervening survey battery (detailed educational history, degree major, parental education, occupation/SOC, income, subjective social class, and a comprehensive 20-genre musical taste battery).
  - *Trial 2 (Page 16):* Respondents view the identical painting again with verbatim prompt (*"Please look at this painting for a few seconds again. Give us your final impression of this painting -- how much do you like it?"*) on the same scale, without being reminded of their Trial 1 score and without any instructional prompt suggesting conformity.
  - *Consolidation of High-Status Alters:* Economic Specialists (ES: business degree, financial firm) and Cultural Specialists (CS: advanced degrees/PhD, higher education) are collapsed into a single High-Status (`+Status`) condition. Formal $F$-tests confirm responses to ES and CS are statistically indistinguishable ($p = 0.591$ for likes; $p = 0.803$ for dislikes), and collapsing prevents severe statistical power loss across a 36-cell design.

---

## Streamlined Results Architecture & Core Findings

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
Estimated on the 3-condition status-free subset of the primary sample (Control $N = 157$, Generalized Like $N = 152$, Generalized Dislike $N = 148$, total $N = 457$, $914$ observations) via Equation \ref{eq:generalized_did_model}:
$$\text{Taste}_{it} = \beta_0 + \beta_1 \text{Trial}_{it} + \beta_2 \text{Like}_i + \beta_3 \text{Dislike}_i + \delta_{\text{Like}} (\text{Trial}_{it} \times \text{Like}_i) + \delta_{\text{Dislike}} (\text{Trial}_{it} \times \text{Dislike}_i) + u_i + \epsilon_{it}$$
- **Mere Exposure Drift in Control (H1):** Seeing the artwork a second time in the absence of external cues produces an intrinsic appreciation boost ($\beta_1 = +0.156^{**}, SE = 0.055, t = 2.86, p = 0.0044$).
- **Valence Asymmetry in Generalized Cues:**
  - *Generalized Like (H2a):* Raw increase ($+0.203^{**}$), but net DiD boost relative to control drift is positive and modest ($\delta_{\text{Like}} = +0.047, p = 0.555$).
  - *Generalized Dislike (H2b):* Negative feedback completely halts exposure appreciation (raw change $-0.030$), resulting in statistically significant negative DiD suppression ($\delta_{\text{Dislike}} = -0.186^{*}, SE = 0.078, t = -2.40, p = 0.0169$).
  - *Valence Contrast:* Direct contrast yields a significant directional swing ($\Delta = +0.233^{**}, SE = 0.080, \chi^2 = 8.51, p = 0.0035$), demonstrating that negative social consensus exerts an asymmetric veto power.

### 3. Status-Differentiated Influence Across Four Educational Tiers (Section 3.2 & Figure 4)
Because the treatment vignettes explicitly differentiated alter status via educational credentials and occupations, educational attainment is the primary structural axis of cultural capital matching ego to alter. With $N = 1,981$ and high repeated-measures test-retest precision ($r = 0.899, \sigma_{\Delta} = 0.688$), the design has ample statistical power to test four granular educational tiers via multinomial IPW (Figure \ref{fig:did_edu_4tiers} and Appendix Table \ref{tbl:did_edu_4tiers}):
- **Tier 1: High School or Less ($N = 468$):** Exclusively positive or inert shifts. Positive facilitation under Generalized Likes ($\text{DiD} = +0.284^{\dagger}, p = 0.0608$) and Low-Status Dislikes ($\text{DiD} = +0.240^{\dagger}, p = 0.0737$). Unresponsive to elite cues ($+0.032, p = 0.777$ for like; $-0.140, p = 0.215$ for dislike).
  - *Hypothesis 4 (Cultural Goodwill) is decisively rejected:* Lower-status individuals exhibit no deference or upward alignment with elite consensus.
- **Tier 2: Two-Year Associate / Some College ($N = 655$):** Complete evaluative stability and inertia across all six conditions ($p \ge 0.25$, estimates tightly bounded between $-0.113$ and $+0.145$). Functions as an evaluative buffer.
- **Tier 3: Four-Year Bachelor's Degree ($N = 577$):** Onset of downward evaluative suppression under High-Status Dislikes ($\text{DiD} = -0.271^{*}, p = 0.0296$) and Generalized Dislikes ($\text{DiD} = -0.308^{*}, p = 0.0455$), with complete unresponsiveness to positive cues ($p \ge 0.75$).
  - *Hypothesis 3 (Same-Status Alignment) is rejected across strata:* BA holders do not follow high-status likes ($-0.030, p = 0.809$).
- **Tier 4: Postgraduate / Advanced Degree ($N = 281$):** Severe, pervasive Bourdieusian boundary-drawing and status distancing:
  - *Hypothesis 5 (Status-Based Distancing) is strongly supported:* Learning that working-class peers liked the painting triggers an immediate evaluative collapse of nearly half a point ($\text{DiD} = -0.491^{***}, SE = 0.135, t = -3.64, p = 0.0003$, Cohen's $d = 0.33$)—the single largest negative treatment effect in the study.
  - Reinforced by severe downward vetoes across all dislike conditions (Generalized Dislike: $-0.442^{**}$; Low-Status Dislike: $-0.345^{**}$; High-Status Dislike: $-0.266^{*}$).

### 4. Status Inconsistency and Discrete Behavioral Choices (Section 3.3 & Figure 5)
Subjective social class identification (Middle Class vs. Working Class) is reserved for its true theoretical home: cross-cutting education to form the four status consistency quadrants (Working/No College, Working/College, Middle/No College, Middle/College) to test **Hypothesis 6 (Status Consistency)** via multinomial logistic regression (Figure \ref{fig:multinom}):
- **Baseline Reference Group (Working Class, No College):** $73.8\%$ Stay, $14.2\%$ Conform, $12.0\%$ React.
- **Inertia (Stay):** Status consistency anchors stability. Middle Class/College is $+7.3\%$ more likely to stay ($\text{AME} = +0.073^{***}, SE = 0.013, z = 5.47, p < 0.001$, overall stay rate $81.1\%$). Inconsistent non-college actors are less stable ($\text{AME} = -0.026^{\dagger}, p = 0.070$, stay rate $71.2\%$).
- **Conformity:** Status-inconsistent individuals are significantly more susceptible to external influence: Working Class/College is $+4.2\%$ more likely to conform ($\text{AME} = +0.042^{***}, p = 0.0003$), and Middle Class/No College is $+4.3\%$ more likely to conform ($\text{AME} = +0.043^{***}, p = 0.0002$). High-status consistent respondents are significantly less likely to conform ($\text{AME} = -0.033^{**}, p = 0.0021$).
- **Reactance:** College-educated individuals shun oppositional reactance ($-3.0\%$ and $-4.0\%, p < 0.003$). Oppositional defiance is concentrated among non-college workers.
- **Sensitivity Check (Appendix Figure A.3):** Re-estimating the model excluding Taste-Only conditions ($N = 1,643$) yields identical substantive results (Middle Class with College stay $+7.6\%, p < 0.001$).
- **Streamlining Benefit:** Eliminating the old 24-cell continuous grid from the main text removed narrative redundancy and statistical dilution; the full 24-cell regression table is retained in Appendix Table \ref{tbl:did_status_quadrants} for reference.

### 5. Inverse Probability Weighting (IPW) Causal Architecture
- Propensity score weighting via `WeightIt` and `cobalt` balances strictly exogenous pre-treatment baseline covariates (`age`, `female`, `raceeth`, and `parented`), excluding post-treatment adult personal income and geographic region to avoid conditioning on post-treatment socioeconomic outcomes of education.
- Multinomial IPW across the four educational tiers is applied to the DiD models in Section 3.2 (Figure 4).
- Multinomial IPW across the four status consistency quadrants is applied to the discrete behavioral models in Section 3.3 (Figure 5).
- Standardized mean differences across all status groups are compressed below $0.10$ (Figure 2).

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
| **Figure 2** | `figures/Figure8_CovariateBalance.png` | `\ref{fig:balance}` | IPW Love Plot of covariate balance across status quadrants |
| **Figure 3** | `figures/Figure_DiD_Baseline_Influence.png` | `\ref{fig:did_baseline}` | Horizontal bar plot of net DiD treatment effects for Section 3.1 generalized influence ($N = 457$) |
| **Figure 4** | `figures/Figure_DiD_Edu_4Tiers.png` | `\ref{fig:did_edu_4tiers}` | 4-panel horizontal bar plot of DiD effects across four educational tiers ($N = 1,981$) |
| **Figure 5** | `figures/Figure7_MultinomialBehavior.png` | `\ref{fig:multinom}` | 3-panel horizontal bar plot of AMEs for Stay, Conform, and React across status consistency quadrants |
| **Table 1** | `manuscript_R1.tex` | `\ref{tbl:descriptives}` | Primary sample demographics (Age $\ge 24$, $N = 1,981$) vs. 2012 Census benchmarks across experimental arms |
| **Table 2** | `manuscript_R1.tex` | `\ref{tbl:hypotheses_summary}` | Summary of Hypotheses (H1–H6), Theoretical Expectations, and Empirical Verdicts |
| **Appendix Fig A.1** | `figures/Figure_MDE_Power_Curves.png` | `\ref{fig:mde_curves}` | Dual-panel MDE power curves (theoretical & empirical benchmarks for Age $\ge 24$ sample) |
| **Appendix Fig A.2** | `figures/Figure_DiD_Pooled.png` | `\ref{fig:did_pooled}` | Difference-in-Differences Treatment Effects in the Pooled Primary Sample ($N = 1,981$) |
| **Appendix Fig A.3** | `figures/Figure11_Sens_MultinomialBehavior.png` | `\ref{fig:sens_multinom}` | Sensitivity behavioral bar plot (excluding Taste-Only conditions, $N = 1,643$) |
| **Appendix Tab A.1** | `tables/table_mde_summary.tex` | `\ref{tbl:mde_analysis}` | Ex-post Minimum Detectable Effect (MDE) analysis table |
| **Appendix Tab A.2** | `manuscript_R1.tex` | `\ref{tbl:did_edu_4tiers}` | DiD estimates across Four Educational Tiers ($N = 1,981$) |
| **Appendix Tab A.3** | `manuscript_R1.tex` | `\ref{tbl:did_status_quadrants}` | Complete 24-cell DiD matrix across Status Consistency Quadrants (Reference) |
| **Appendix Tab A.4** | `manuscript_R1.tex` | `\ref{tbl:appendix_did_compare}` | Comparison of Unweighted and IPW-Weighted pooled DiD models ($N = 1,981$) |
| **Appendix Tab G.1** | `manuscript_R1.tex` | `\ref{tbl:full_sample_descriptives}` | Full unrestricted sample demographics ($N = 2,275$) |
| **Appendix Tab G.2** | `manuscript_R1.tex` | `\ref{tbl:did_edu_class_full}` | Full unrestricted sample stepwise DiD estimates ($N = 2,253$) |
| **Appendix Tab G.3** | `manuscript_R1.tex` | `\ref{tbl:did_status_quadrants_full}` | Full unrestricted sample 24-cell status consistency matrix ($N = 2,252$) |

---

## Revision Status Tracker (All Points Fully Addressed)

- [x] **Primary Sample Restriction ($\text{Age} \ge 24$):** Restricts main analysis to respondents aged 24+ ($N = 1,981$) to ensure completed college attainment, preserving full unrestricted sample ($N = 2,253$) in Appendix G.
- [x] **Four-Tier Educational Disaggregation (Section 3.2 & Figure 4):** Promoted the 4-tier education model to Section 3.2 as Figure 4, testing H3, H4, and H5 directly.
- [x] **Streamlined Status Consistency (Section 3.3 & Figure 5):** Eliminated the unwieldy 24-cell continuous grid from the main text; dedicated Section 3.3 exclusively to the discrete multinomial model of Stay, Conform, and React (Figure 5) testing Hypothesis 6.
- [x] **Reviewer 1 Response Framing (Point 6):** Framed the reorganization in `response_to_reviewers.md` as inspired by Reviewer 1's recommendation to separate education and class, explaining that our repeated-measures statistical power enabled the four-tier education analysis.
- [x] **Multiple Comparisons Audit:** Verified that focal findings across baseline influence (H1, H2b) and behavioral choices (H6) survive Benjamini-Hochberg False Discovery Rate (FDR $q < 0.05$) and Holm-Bonferroni corrections.
- [x] **DiD Estimation Strategy (R1 #1):** Fully implemented in `R/did_models.R`, woven into narrative and equations.
- [x] **Terminology Disambiguation (R1 #2):** Reserved "baseline" strictly for Trial 1; renamed unexposed group "Control Condition"; drift termed "exposure drift".
- [x] **Survey Sampling & Descriptives (R1 #3):** Documented 2012 SSI panel recruitment, quota matching, deliberate college oversample ($43.3\%$ in primary sample), participant flow, CI inferential scope, and Table 1.
- [x] **Ex-Post Minimum Detectable Effect (MDE) Analysis (R1 #4):** Fully calculated via `R/mde_power_analysis.R`, documented in Appendix A, Table \ref{tbl:mde_analysis}, and Figure \ref{fig:mde_curves}.
- [x] **Treatment Vignettes in Appendix (R1 #5):** Verbatim transcription of Qualtrics survey flow, stimuli, and vignettes in Appendix B.
- [x] **IPW Causal Logic & Covariate Balance (R1 #7, #8):** Added pedagogical explanation of pseudo-populations and conditional exchangeability; documented Love plot in Section 2.4 (Figure \ref{fig:balance}).
- [x] **Figure Polish & Color Matching (R1 #9):** Standardized title capitalization, zero-effect dashed lines, color-matched error bars, and single clean 3-level legends.
- [x] **Generalized Influence Baseline (R1 #10):** Established status-free baseline in Section 3.1 (Equation \ref{eq:generalized_did_model}), demonstrating mere exposure drift and decisive veto suppression by Generalized Dislike.
- [x] **Disaggregated Behavioral Analysis (R1 #11):** Retained and streamlined multinomial directional shift models; added sensitivity analysis in Appendix Figure A.3.
- [x] **Full Regression Tables in Appendix (R1 #12):** Relocated regression tables into Appendix (Tables A.2, A.3, A.4), showcasing figures in the main text.
- [x] **Update Literature & Theoretical Engagement (R1 #13):** Integrated scholarship on cultural cognition, dual-process habitus, aesthetic signaling, and symbolic boundaries (Lizardo et al., Wohl, Vanzella, Brand & Thomas, Okada, Pomiès & Arsel, Kahneman).
- [x] **Causal Warrant Hook & Research Question Rationale (Editor, R2 #1):** Centered opening around observational vs. experimental causal gap in cultural sociology.
- [x] **Streamline Section 1.1 (R2 #2):** Organized study description into concise academic prose paragraphs.
- [x] **Demand Characteristics & Reactivity (Editor, R2 #3):** Added Section 2.3 detailing 4 procedural safeguards based on survey protocol.
- [x] **Valence Framing around Valence Asymmetry (R2 #4):** Reframed core claim around asymmetric veto power of negative evaluations.
- [x] **Status Inconsistency Mechanism & Moderation (R2 #5, R2 #6):** Integrated status crystallization theory (Lenski 1954; Hope 1975); clarified that consistency anchors stability, whereas inconsistency breeds fluidity.
- [x] **Clear Empirical Takeaways for Researchers (R2 #7):** Added Table 2 systematically summarizing each hypothesis, DiD estimate, and statistical verdict.
- [x] **Hypothesis Alignment & Numbering:** Systematically numbered and aligned all hypotheses across Section 1.3, Section 3 results, Table 2, and Section 4 discussion (H1: Mere Exposure, H2a: Positive Evaluations, H2b: Negative Evaluations, H3: Same-Status Alignment, H4: Cultural Goodwill, H5: Status-Based Distancing, H6: Status Consistency).
- [x] **Section 3.1 Baseline Influence Figure:** Added Figure 3 (`Figure_DiD_Baseline_Influence.png`), displaying within-subject evaluative trajectories across repeated trials (Panel A) alongside net DiD treatment effects relative to control exposure drift (Panel B).
- [x] **Text Asterisk Formatting:** Removed all significance asterisks and daggers next to $p$-values from the main narrative text, preserving them strictly in regression and summary tables.
- [x] **Asset Housekeeping:** Deleted obsolete `figures/Figure_DiD_Significant_Effects.*` assets.
- [x] **Standardized Condition Ordering:** Imposed identical top-down y-axis ordering across all figures and tables (Generalized Like $\to$ High-Status Like $\to$ Low-Status Like $\to$ Generalized Dislike $\to$ High-Status Dislike $\to$ Low-Status Dislike).
- [x] **Preservation of Original Manuscript:** `manuscript.tex` frozen as the historical original submission (14 pages); `manuscript_R1.tex` used for all active revision work.
