# Taste Influence Paper Project

## Overview
This project modernizes, revises, and revives the analysis for the paper *"Stay, React, or Conform? Examining Social Influence Effects on Aesthetic Judgments"* (Omar Lizardo & Sara Skiles), currently undergoing Major Revision at *Poetics* (POETICS-D-26-00490). The original Stata pipeline and early drafts have been upgraded to a fully reproducible R workflow and connected to Overleaf.

- **Journal:** *Poetics* (Editor-in-Chief: Hannah Wohl)
- **Overleaf Project URL:** https://www.overleaf.com/project/6a3fe1ed665ddc04ec45136a
- **Overleaf Git Endpoint:** `https://git.overleaf.com/6a3fe1ed665ddc04ec45136a`
- **Revision Tracking:** `REVISION_PLAN_POETICS.md` and `response_to_reviewers.md`
- **Manuscript Files:**
  - `manuscript.tex`: The original submitted version of the paper as originally submitted to *Poetics* (Original Submission).
  - `manuscript_R1.tex`: The active, fully updated Major Revision manuscript for *Poetics* (R1), synchronized with Overleaf.

---

## Data & Experimental Protocol
- **Primary Raw Data Path**: `/home/omarlizardo/projects/CULTURE/cultural-consensus-musical-genres/SSI-2012/data/clean/ssi2012_cleaned.dta` (fallback: `/home/omarlizardo/ACADEMIC AND COURSE MATERIALS/SSI-2012/data/clean/ssi2012_cleaned.dta`).
- **Format**: Stata `.dta` file containing survey data with embedded value labels, loaded via `haven::read_dta()`.
- **Sample Flow**: $3,782$ accessed survey $\to 85$ non-consent $\to 12$ under-age $\to 1,394$ quota-screened $\to 16$ early dropouts $\to N = 2,275$ completed responses ($N = 2,253$ complete pre- and post-treatment evaluations).
- **Experimental Procedures (`Skiles dissertation2.docx`)**:
  - *Trial 1 (Survey Page 4):* High-resolution image of James McNeill Whistler's *Nocturne: Battersea Bridge* (1872); respondents provide their "first impression" on a reversed 1–7 scale ($7 = \text{like very much}$, $1 = \text{dislike very much}$).
  - *Feedback Vignette & Attribution (Page 5):* Treatment respondents receive naturalistic aggregate feedback from prior survey respondents (*"Our survey so far indicates that the group of people most likely to say that they [LIKE / DISLIKE] the painting you saw have completed..."*) followed by subjective similarity and attribution items.
  - *Cognitive Buffer (Pages 6–15):* Extensive 15-to-20 minute intervening survey battery (detailed educational history, degree major, parental education, occupation/SOC, income, subjective social class, and a comprehensive 20-genre musical taste battery).
  - *Trial 2 (Page 16):* Respondents view the identical painting again and give their "final impression" on the same scale, without being reminded of their Trial 1 score and without any instructional prompt suggesting conformity.
  - *Consolidation of High-Status Alters:* Economic Specialists (ES: business degree, financial firm) and Cultural Specialists (CS: advanced degrees/PhD, higher education) are collapsed into a single High-Status (`+Status`) condition. Formal $F$-tests confirm responses to ES and CS are statistically indistinguishable ($p = 0.591$ for likes; $p = 0.803$ for dislikes), and collapsing prevents severe statistical power loss across a 36-cell design.

---

## Key Methodological Innovations & Core Findings

### 1. Shift from Pooled Models to Moderated & Status Consistency DiD Framework
Rather than relying on uninteresting pooled models (which wash out opposing relational effects by aggregating socially dissimilar actors), the main manuscript centers on **Difference-in-Differences models moderated by educational attainment, subjective class, and status consistency**:

$$\text{Taste}_{it} = \beta_0 + \beta_1 \text{Trial}_{it} + \sum_{k=2}^{K} \beta_k \text{Cond}_{ik} + \sum_{k=2}^{K} \delta_k (\text{Trial}_{it} \times \text{Cond}_{ik}) + u_i + \epsilon_{it}$$

- **Exposure Drift Moderated by Cultural Capital:** In the unexposed Control Condition ($N = 177$), repeated exposure produces an intrinsic upward appreciation specifically among college-educated respondents ($\text{Trial} \times \text{College} = +0.247^{**}, p = 0.0027$; total college drift $= +0.279^{***}, p < 0.001$), while non-college respondents show flat evaluative stability ($\beta_1 = +0.032, p = 0.582$).
- **Primary Stepwise Models (Table 2 & Figure 3):**
  - *Education Alone:* College graduates exhibit strong baseline drift that is actively curtailed by negative cues (High-Status Dislike: $-0.275^{**}$; Generalized Dislike: $-0.302^{*}$; Low-Status Dislike: $-0.226^{*}$) and Low-Status Likes ($-0.248^{*}$). Non-college respondents show flat drift but positive shifts under Generalized Likes ($+0.228^{*}$) and Low-Status Dislikes ($+0.198^{*}$).
  - *Subjective Class Alone:* Middle-class respondents show modest negative shifts under High-Status Dislike ($-0.182^{*}$) and Low-Status Like ($-0.202^{*}$), while working-class respondents show no statistically reliable shifts in the aggregate.
- **The Four-Quadrant Status Consistency Interaction Matrix (Table 3):**
  - Because education and subjective class cross-cut each other (28% of working-class identifiers hold college degrees, while 28% of middle-class identifiers lack degrees), univariate models conflate consistent and inconsistent actors.
  - *Hypothesis 1 (Same-Status Alignment):* Rejected across consistent groups ($p \ge 0.35$).
  - *Hypothesis 2 (Cultural Goodwill / Upward Alignment):* Rejected for low-status consistent workers ($-0.006$ and $+0.130$, $p \ge 0.25$), but college-educated workers display sharp negative reactivity to high-status dislikes ($-0.394^{***}, p = 0.001$).
  - *Hypothesis 3 (Cross-Status Reactance / Taste Abandonment):* Strongly supported! High-status consistent respondents (Middle Class/College) actively abandon taste when exposed to low-status likes ($-0.296^{*}, p = 0.039$).

### 2. Inverse Probability Weighting (IPW) Causal Architecture (`R/propensity_models.R`)
- Experimental conditions were randomized; respondent social location (Education $\times$ Subjective Class) is observational.
- Multinomial propensity score weighting via `WeightIt` and `cobalt` balances baseline age, gender, race/ethnicity, and parental education across status groups, compressing all standardized mean differences below $0.10$ (Figure 2).

### 3. Discrete Behavioral Modeling via Marginal Effects (`R/generate_did_barplots.R`)
- Categorizes choices into **Stay** ($\Delta = 0$), **Conform** (shifting in direction of cue), and **React** (shifting away).
- Evaluated via Average Marginal Effects from multinomial logit relative to *Working Class, No College*:
  - **Inertia (Stay):** Structural status consistency drives stability. Middle Class/College is $+4.6\%$ more likely to stay ($p < 0.001$), while Middle Class/No College is $-5.4\%$ less likely to stay ($p < 0.001$).
  - **Conformity:** Status-inconsistent individuals are significantly more susceptible to external influence: Working Class/College is $+5.4\%$ more likely to conform ($p < 0.001$), and Middle Class/No College is $+4.1\%$ more likely to conform ($p < 0.001$).
  - **Reactance:** College-educated individuals are significantly less likely to react ($-3.2\%$ and $-2.5\%$, $p < 0.01$). Oppositional reactance is concentrated among non-college workers.
  - **Sensitivity Check (Appendix Figure A.4):** Re-estimating the model excluding Taste-Only conditions ($N = 1,870$) yields identical substantive results.

---

## Active Manuscript Assets Inventory

All forest plots have been replaced with **horizontal bar plots with error bars** colored by statistical significance (Red: $p < 0.05$, Orange: $p < 0.10$, Grey: $p \ge 0.10$):

| Manuscript Asset | File Path | Label | Description |
| :--- | :--- | :--- | :--- |
| **Figure 1** | `figures/experimental_stimulus.jpeg` | `\ref{fig:stimulus}` | Whistler's *Nocturne: Battersea Bridge* (1872) |
| **Figure 2** | `figures/Figure8_CovariateBalance.png` | `\ref{fig:balance}` | IPW Love Plot of covariate balance across status quadrants |
| **Figure 3** | `figures/Figure_DiD_Edu_Class_Separate.png` | `\ref{fig:did_edu_class}` | 2-panel horizontal bar plot of DiD effects for Education alone and Class alone |
| **Figure 4** | `figures/Figure7_MultinomialBehavior.png` | `\ref{fig:multinom}` | 3-panel horizontal bar plot of Average Marginal Effects for Stay, Conform, and React |
| **Table 1** | `manuscript.tex` / `manuscript_R1.tex` | `\ref{tbl:descriptives}` | Sample demographics vs. 2012 Census benchmarks across experimental conditions |
| **Table 2** | `manuscript.tex` / `manuscript_R1.tex` | `\ref{tbl:did_edu_class}` | Primary DiD models moderated separately by Education and Subjective Class |
| **Table 3** | `manuscript.tex` / `manuscript_R1.tex` | `\ref{tbl:did_status_quadrants}` | Complete 24-cell DiD matrix across Status Consistency Quadrants (IPW-Weighted) |
| **Table 4** | `manuscript.tex` / `manuscript_R1.tex` | `\ref{tbl:hypotheses_summary}` | Hypothesis evaluation matrix (estimates, expectations, and empirical verdicts) |
| **Appendix Fig A.1** | `figures/Figure_MDE_Power_Curves.png` | `\ref{fig:mde_curves}` | Dual-panel MDE power curves (theoretical & empirical benchmarks) |
| **Appendix Fig A.2** | `figures/Figure_DiD_Pooled.png` | `\ref{fig:did_pooled}` | Unweighted DiD estimates for the pooled sample with 95% confidence intervals |
| **Appendix Fig A.3** | `figures/Figure_DiD_Status_All.png` | `\ref{fig:did_status_full}` | Full 24-cell status DiD bar plot with error bars |
| **Appendix Fig A.4** | `figures/Figure11_Sens_MultinomialBehavior.png` | `\ref{fig:sens_multinom}` | Sensitivity behavioral bar plot (excluding Taste-Only conditions, $N = 1,870$) |
| **Appendix Tab A.1** | `tables/table_mde_summary.tex` | `\ref{tbl:mde_analysis}` | Ex-post Minimum Detectable Effect (MDE) analysis table |
| **Appendix Tab A.2** | `manuscript.tex` / `manuscript_R1.tex` | `\ref{tbl:appendix_did_compare}` | Comparison of Unweighted and IPW-Weighted pooled DiD models |

---

## Revision Status Tracker (All Points Fully Addressed)

- [x] **DiD Estimation Strategy (R1 #1):** Fully implemented in `R/did_models.R`, woven into narrative and Table 2.
- [x] **Terminology Disambiguation (R1 #2):** Reserved "baseline" strictly for Trial 1; renamed unexposed group "Control Condition"; drift termed "exposure drift".
- [x] **Survey Sampling & Descriptives (R1 #3):** Documented 2012 SSI panel recruitment, quota matching, deliberate college oversample, participant flow ($3,782 \to 2,275$), CI inferential scope, and Table 1.
- [x] **Ex-Post Minimum Detectable Effect (MDE) Analysis (R1 #4):** Fully calculated via `R/mde_power_analysis.R`, documented in Appendix A, Table \ref{tbl:mde_analysis}, and Figure \ref{fig:mde_curves}.
- [x] **Treatment Vignettes in Appendix (R1 #5):** Verbatim transcription of Qualtrics survey flow, stimuli, and vignettes in Appendix B.
- [x] **Stepwise Main Effects for Education & Class (R1 #6):** Fully estimated in `R/stepwise_status_models.R`, integrated into Section 3.3, Figure \ref{fig:did_edu_class}, and Table \ref{tbl:did_edu_class}.
- [x] **IPW Causal Logic & Covariate Balance (R1 #7, #8):** Added pedagogical explanation of pseudo-populations and conditional exchangeability; documented Love plot.
- [x] **Figure Polish & Dashed Line Definition (R1 #9):** Standardized title capitalization, zero-effect dashed lines, and error bar aesthetics across all plots.
- [x] **Generalized Influence Results (R1 #10):** Clarified suppression of positive exposure drift by generalized dislike.
- [x] **Disaggregated Behavioral Analysis (R1 #11):** Retained and streamlined multinomial directional shift models; added sensitivity analysis in Appendix Figure A.4.
- [x] **Full Regression Tables in Appendix (R1 #12):** Provided complete tables across main text and Appendix (Tables 1–4, Appendix Tables A.1–A.2).
- [x] **Update Literature & Theoretical Engagement (R1 #13):** Integrated recent scholarship on cultural cognition, dual-process habitus, aesthetic signaling, and symbolic boundaries (Lizardo et al., Wohl, Vanzella).
- [x] **Causal Warrant Hook & Research Question Rationale (Editor, R2 #1):** Centered the opening around the observational vs. experimental causal gap in cultural sociology.
- [x] **Streamline Section 1.1 (R2 #2):** Organized theoretical framework into 3 linear, cumulative pillars.
- [x] **Demand Characteristics & Reactivity (Editor, R2 #3):** Added Section 2.4 detailing 4 procedural safeguards based on `Skiles dissertation2.docx` survey protocol.
- [x] **Valence Framing around Valence Asymmetry (R2 #4):** Reframed core claim around asymmetric veto power of negative evaluations.
- [x] **Status Inconsistency Mechanism & Moderation (R2 #5, R2 #6):** Integrated status crystallization theory (Lenski 1954; Hope 1975); clarified that consistency anchors stability, whereas inconsistency breeds fluidity.
- [x] **Clear Empirical Takeaways for Researchers (R2 #7):** Added Table 4 systematically summarizing each hypothesis, DiD estimate, and statistical verdict.
- [x] **Purge "Peers" $\to$ "Others":** Standardized terminology across entire manuscript.
- [x] **Standardize "Arms" $\to$ "Conditions":** Standardized experimental terminology across entire manuscript and responses.
- [x] **Clean Up Equation 1 Notation:** Changed $\text{Taste}_{ijt} \to \text{Taste}_{it}$, $\sum_{k=1}^K \delta_k \to \sum_{k=2}^K \delta_k$, and removed unnecessary $\mathbf{X}_i \boldsymbol{\gamma}$ covariate vector.
- [x] **Eliminate Bullet Points:** Replaced all list structures in hypotheses and discussion with continuous academic prose paragraphs.
- [x] **Refocus Results on Interaction Models:** Removed redundant/uninteresting pooled models from main text; showcased Table 2 (Education & Class moderation) and Table 3 (24-cell Status Consistency matrix).
- [x] **Overleaf Git Synchronization:** Local repository rebased on top of Overleaf (`40e6fdf`), with `manuscript.tex` and `manuscript_R1.tex` maintained 100% identical.
