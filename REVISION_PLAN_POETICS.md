# Revision Strategy and Action Plan: *Poetics* (POETICS-D-26-00490)

**Manuscript Title:** *Stay, React, or Conform? Examining Social Influence Effects on Aesthetic Judgments*  
**Authors:** Omar Lizardo & Sara Skiles  
**Editor-in-Chief:** Hannah Wohl  
**Decision:** Major Revision (Resubmission Target: October 15, 2026)  

---

## File Preservation & Revision Policy
- **`manuscript.tex`**: **DO NOT OVERWRITE.** Preserves the original submitted manuscript from the initial *Poetics* submission (14 pages).
- **`manuscript_R1.tex`**: **The ONLY active manuscript file.** All Major Revision updates, new analyses, and Overleaf synchronizations are made exclusively here.

---

## Executive Summary

The editorial decision from *Poetics* provides a clear and constructive pathway to publication via a **Major Revision**. Both reviewers recognize the value and high potential of the experimental study. The Editor (Hannah Wohl) has offered the option to revise either as a streamlined **Research Note** (sharpening empirical contributions and established facts) or to expand into a **Full Research Article** (fleshing out theoretical contributions and engaging recent debates).

Key critical issues raised across the editor and reviewers include:
1. **Editor (Hannah Wohl):**
   - Provide a sharper empirical hook/warrant: clarify what unanswered question this study addresses (i.e., providing the first causal/experimental test of taste influence dynamics previously inferred only from observational/cross-sectional work).
   - Streamline the front-end theoretical framing so findings across multiple literatures do not become muddled.
   - Address methodological points (Difference-in-Differences, baseline terminology, demand characteristics).
2. **Reviewer 1 (Methodological Rigor, Design Transparency & Model Presentation - 13 Points):**
   - Adopt a Difference-in-Differences (DiD) framework comparing treatment conditions against the no-information control condition across pre/post trials.
   - Disambiguate baseline terminology ("control condition" vs. "pre-treatment measurement").
   - Include survey sampling details (SSI opt-in panel, quota matching, deliberate college oversample), descriptive statistics table, exact treatment wording, ex-post Minimum Detectable Effect (MDE) power analysis, and full model tables in an appendix.
   - Report separate education and subjective class models prior to combined status.
   - Clarify the logic of Inverse Probability Weighting (IPW) and covariate balance for observational status categories.
   - Address apparent discrepancies in the interpretation of generalized influence (no-status conditions).
   - Reconsider or remove the disaggregated analysis to avoid redundancy with average effects.
3. **Reviewer 2 (Theoretical Framing, Mechanisms & Demand Awareness - 7 Points):**
   - Sharpen the research question's rationale: contrast the experimental causal design against past observational/cross-sectional work.
   - Streamline Section 1.1: eliminate meandering theoretical loops and focus squarely on core concepts.
   - Address experimenter demand characteristics and respondent reactivity.
   - Reframe the valence finding around **valence asymmetry** (positivity facilitating vs. negativity suppressing drift) rather than claiming valence was previously ignored.
   - Provide a clear theoretical mechanism for **status inconsistency**: explain why status consistency (high and low) promotes stability/inertia ("staying"), whereas status inconsistency produces evaluative fluidity.
   - Clarify findings on inertia/stay rates across high and low consistent groups.
   - Deliver clear, unambiguous empirical facts for other researchers.

---

## Prioritized Revision Plan

The revision points are grouped below into three prioritized tiers:
- **Tier 1: Critical Methodological, Analytical & Modeling Revisions** (DiD models, MDE analysis, IPW explanation, model tables, separated status models)
- **Tier 2: Key Theoretical Reframing & Mechanism Revisions** (Causal warrant hook, streamlining Section 1.1, valence asymmetry, status inconsistency mechanism)
- **Tier 3: Design Details, Reactivity, Descriptives & Appendix Additions** (Demand awareness, survey sampling, descriptive table, exact vignettes, figure polish)

---

### Tier 1: Critical Methodological & Analytical Revisions

#### 1. Implement Difference-in-Differences (DiD) Analytical Framework
* **Reviewer Concern (R1 #1):**  
  > *"The analytical strategy may not be the most appropriate. To better isolate the treatment effects, the authors may consider applying a difference-in-differences approach, using the no-information condition as the control group and exploiting the pre-treatment measurement. Without such a comparison, the observed changes could potentially be attributed to repeated measurement rather than the information treatment itself."*
* **Status:** `[Addressed]`
* **Location in Manuscript:** Section 2.5 (Analytic Strategy), Section 3.2 (Difference-in-Differences Estimation of Treatment Effects), Table \ref{tbl:did_models}
* **Actions Completed:**
  1. Formalized repeated-measures linear mixed models and change score regressions into a DiD framework with the unexposed Control Condition as reference (`R/did_models.R`).
  2. Documented empirical exposure drift in the Control Condition ($\beta_{\text{Trial}} = +0.107, p = 0.041$ unweighted; $\beta_{\text{Trial}} = +0.156, p = 0.0038$ IPW-weighted).
  3. Confirmed and sharpened Valence Asymmetry: High-Status Dislike ($\text{DiD} = -0.201, p = 0.0011^{**}$) and Generalized Dislike ($\text{DiD} = -0.172, p = 0.0238^{*}$) significantly suppress baseline exposure drift.
  4. Discovered direct empirical support for Hypothesis 3 (Cross-status reactance): High-status respondents exposed to Low-Status Likes show a statistically significant negative divergence relative to control drift ($\text{DiD} = -0.296, p = 0.0391^{*}$), demonstrating active taste abandonment.
  5. Added Table \ref{tbl:did_models} and dedicated narrative to `manuscript_R1.tex`.

#### 2. Disambiguate Baseline vs. Control Terminology
* **Reviewer Concern (R1 #2):**  
  > *"I also suggest avoiding the term 'baseline' when referring to the no-information condition, because the study includes a pre-treatment measurement that may also be understood as a baseline. Using the same term for both is confusing. The authors could instead refer to the no-information condition as the control condition."*
* **Status:** `[Addressed]`
* **Location in Manuscript:** Throughout `manuscript_R1.tex` (Section 2.3, Section 3.2, Section 3.3)
* **Actionable Steps:**
  1. Systematically replace "baseline condition" with **"control condition"** or **"no-information control group"**.
  2. Reserve the term **"baseline measurement"** or **"pre-treatment rating"** strictly for Trial 1 ($t_1$).

#### 3. Perform Ex-Post Minimum Detectable Effect (MDE) Power Analysis
* **Reviewer Concern (R1 #4):**  
  > *"The sample sizes within conditions are relatively small. If an a priori power analysis was not conducted during the study design, I recommend reporting an ex post minimum detectable effect (MDE) analysis in the appendix. This would help readers assess which effect sizes the study was capable of detecting."*
* **Status:** `[Addressed]`
* **Location in Manuscript:** Section 2.2 (Inferential Scope and Interpretation of Confidence Intervals), Appendix \ref{sec:appendix_power_mde}, Table \ref{tbl:mde_analysis}, Figure \ref{fig:mde_curves}, `tables/table_mde_summary.tex`, `figures/Figure_MDE_Power_Curves.png`
* **Actions Completed:**
  1. Developed dedicated calculation and visualization script `R/mde_power_analysis.R` calculating formal MDE benchmarks following Bloom (1995), Hoenig and Heisey (2001), and Gelman and Carlin (2014).
  2. Incorporated empirical repeated-measures test-retest correlation ($r = 0.8945$, reducing change score SD to $\sigma_{\Delta} = 0.702$ vs. $\sigma_1 = 1.500$).
  3. Computed MDE across all design tiers: within-subject exposure drift ($d \ge 0.028$ full, $d \ge 0.099$ control), pooled DiD ($d \ge 0.113$--$0.140$), and status quadrant DiD ($d \ge 0.203$--$0.348$).
  4. Added Table \ref{tbl:mde_analysis} and Figure \ref{fig:mde_curves} to Appendix \ref{sec:appendix_power_mde} in `manuscript_R1.tex`, with detailed narrative explaining detection thresholds and cautioning against interpreting nulls in small cells as zero effects.

#### 4. Disaggregate Models: Separate Subjective Class and Education
* **Reviewer Concern (R1 #6):**  
  > *"Before moving to the analysis of combined status, please report the results for subjective social class and education separately. These results could be presented as additional subfigures or included in the appendix. The robustness check using an alternative categorization is useful... It would also be relevant to mention this robustness check when the combined-status variable is first described."*
* **Status:** `[Addressed]`
* **Location in Manuscript:** Section 2.4, Section 3.4, Figure \ref{fig:did_edu_class}, Table \ref{tbl:did_edu_class}, Appendix \ref{sec:appendix_sens_multinom}, Appendix \ref{sec:appendix_class_robustness}
* **Actions Completed:**
  1. Estimated stepwise models for Education alone and Subjective Class alone (`R/stepwise_status_models.R`).
  2. Created two-panel publication horizontal bar plot `figures/Figure_DiD_Edu_Class_Separate.png` (and `.pdf`).
  3. Exported formal regression table `tables/table_did_edu_class_separate.tex` (and `.rds`).
  4. Added Section 3.4 to `manuscript_R1.tex`, discussing findings and showing why four-quadrant status consistency is necessary.
  5. Added forward-pointer in Section 2.4 to alternative class categorization check in Appendix \ref{sec:appendix_class_robustness}.
  6. Embedded sensitivity multinomial behavioral model excluding Taste-Only conditions (Figure 11 / `Figure11_Sens_MultinomialBehavior.png`) into Appendix \ref{sec:appendix_sens_multinom} with main text forward-pointer in Section 3.6.

#### 5. Clarify Causal Interpretation and Logic of Inverse Probability Weighting (IPW)
* **Reviewer Concern (R1 #7, R1 #8):**  
  > *"Although the information treatment was randomly assigned, membership in categories such as 'low–high' and 'low–low' is also determined by respondents’ pre-existing education or subjective social class... respondents do not necessarily have the same probability of entering each combined-status category... The authors acknowledge this problem and address it using inverse probability weighting (IPW), but it would be valuable to devote a few additional sentences to explaining the logic of this approach and its implications for causal interpretation."*
* **Status:** `[Addressed]`
* **Location in Manuscript:** Section 2.4 (Variables and Measurement: IPW and Causal Logic), Section 3.1 (Covariate Balance Across Observational Status Categories)
* **Actionable Steps:**
  1. Clarify that while experimental conditions were randomly assigned, respondents' social locations (Education $\times$ Class) are observational attributes (citing Cruces et al., 2013).
  2. Dedicate a focused paragraph explaining how IPW balances baseline covariates (age, gender, race, parental education) across status groups to recover conditional exchangeability.
  3. Clearly define how covariate balance was evaluated (across all status/experimental cells) and provide complete cobalt love plots and balance tables in the Appendix.

#### 6. Clarify Generalized Influence Results (No-Status Conditions)
* **Reviewer Concern (R1 #10):**  
  > *"In discussing generalized influence, the authors state that 'exposure to generalized negative evaluations largely suppresses the positive baseline drift across all groups.' If I understand correctly, readers are expected to interpret the 'dislike (no status)' effect in Figure 3. However, only one effect appears to be statistically significant, and it is in the opposite direction... The authors should clarify which results support this conclusion."*
* **Status:** `[Addressed]`
* **Location in Manuscript:** Section 3.3 (Valence Asymmetry in Difference-in-Differences Effects), Table \ref{tbl:did_models}, Table \ref{tbl:hypotheses_summary}
* **Actions Completed:**
  1. Clarified that the unexposed Control Condition drifts upward significantly ($+0.107, p = 0.041$).
  2. Evaluated Generalized Dislike (Taste Only / Dislike), showing it halts drift ($\Delta = -0.017$), yielding a negative DiD shift ($\text{DiD} = -0.125, p = 0.095^\dagger$ unweighted; $\text{DiD} = -0.172, p = 0.0238^*$ IPW-weighted) that suppresses the counterfactual appreciation.

#### 7. Evaluate and Streamline / Refine Disaggregated Behavioral Models
* **Reviewer Concern (R1 #11):**  
  > *"The contribution of the disaggregated analysis is unclear to me. The categorical analysis also reports average effects, as do all the regression models in the paper. If the authors intend to move beyond average effects, they would need to apply methods that explicitly examine distributional differences or treatment-effect heterogeneity. I recommend removing this analysis, which would also free up space to develop other aspects of the research note."*
* **Status:** `[Addressed]`
* **Location in Manuscript:** Section 3.6 (Discrete Behavioral Choices: Inertia, Conformity, and Reactance), Figure \ref{fig:multinom}, Appendix \ref{sec:appendix_sens_multinom}, Appendix Figure \ref{fig:sens_multinom}
* **Actions Completed:**
  1. Retained multinomial models framed strictly as discrete directional modes (Stay, Conform, React) that decompose continuous means and uncover hidden structural inertia and oppositional reactance.
  2. Added sensitivity analysis in Appendix \ref{sec:appendix_sens_multinom} (Figure \ref{fig:sens_multinom}) excluding Taste-Only conditions, confirming findings hold with exceptional stability.

#### 8. Provide Full Model Regression Tables in Appendix
* **Reviewer Concern (R1 #12):**  
  > *"Report tables with full models in the appendix."*
* **Status:** `[Addressed]`
* **Location in Manuscript:** Table \ref{tbl:descriptives}, Table \ref{tbl:did_models}, Table \ref{tbl:did_edu_class}, Table \ref{tbl:hypotheses_summary}, Appendix Table \ref{tbl:mde_analysis}, Appendix Table \ref{tbl:appendix_did_compare}, Appendix Figure \ref{fig:did_status_full}
* **Actions Completed:**
  1. Exported complete regression tables, coefficients, standard errors, test statistics, and variance components across all models.

---

### Tier 2: Key Theoretical Reframing & Mechanism Revisions

#### 9. Sharpen Empirical Hook & Causal Warrant (Section 1.1)
* **Editor & Reviewer Concern (Editor, R2 #1):**  
  > *"Reviewer 2 suggested that the empirical novelty and warrant for the research question could be made clearer... As I read it, you are offering the first empirical test of what can be inferred from a synthesis of the literature, but has not yet been empirically proven as such."* (Editor)  
  > *"It’s not clear why this research question needs to be asked, given the literature that just got reviewed... However, I think there is room to ask whether these relationships have been rigorously demonstrated with data that are designed to assess causal relationships. I think it might be the case that past work is observational and cross-sectional. Perhaps that should be the hook that highlights the novelty and contribution of the findings?"* (R2)
* **Status:** `[Addressed]`
* **Location in Manuscript:** Section 1 (Introduction), Section 1.1 (Theoretical Background)
* **Actions Completed:**
  1. Restructured opening around the observational vs. experimental causal gap: homophily in static surveys conflates selection and social influence.
  2. Framed study as providing the first clean experimental identification of real-time evaluative shifts.

#### 10. Streamline Section 1.1 (Eliminate Theoretical Meandering)
* **Reviewer Concern (R2 #2):**  
  > *"The third paragraph of section 1.1 reviews work showing that high status groups’ tastes tend to induce conformity... The fourth paragraph brings the status of the self back in... The last paragraph adds in a new consideration: the distinction between objective and subjective class status... I think section 1.1 has to be rewritten to be more focused and streamlined on the concepts central to the data analysis. Right now it is meandering."*
* **Status:** `[Addressed]`
* **Location in Manuscript:** Section 1.1
* **Actions Completed:**
  1. Rewrote Section 1.1 into three linear, cumulative concepts: (1) Informational vs. Status-Based Influence, (2) Relational Status Matching, and (3) Status Consistency vs. Inconsistency.

#### 11. Reframe Valence Findings around "Valence Asymmetry"
* **Reviewer Concern (R2 #4):**  
  > *"In section 4, the authors write, 'While previous research suggests that information about others’ choices acts as a heuristic to resolve uncertainty (Strang and Macy, 2001; Salganik et al., 2006), we find that valence matters.' Isn’t it true that valence mattered in past research as well, insofar as others’ likes vs dislikes mattered? Instead, isn’t the novel finding here is that there is an asymmetry to the valence?"*
* **Status:** `[Addressed]`
* **Location in Manuscript:** Section 1.1, Section 2, Section 3.3, Section 5
* **Actions Completed:**
  1. Reframed claims around valence asymmetry: negative evaluations act as a potent suppressive veto against exposure drift, whereas positive evaluations act conditionally.

#### 12. Develop Theoretical Mechanism for Status Inconsistency & Evaluative Stability
* **Reviewer Concern (R2 #5, R2 #6):**  
  > *"Although the discussion very briefly describes status inconsistency as a driver of evaluative fluidity, that finding is not sufficiently integrated with the hypotheses and there is no clear mechanism attributed to it. The authors should formally test whether status inconsistency moderates the experimental conditions... This sentence needs clarification: '...we see that status consistent individuals, and particularly high-status consistent individuals have the highest propensity to stay with their initial judgment... a classic behavioral indicator of high status (Correll and Ridgeway, 2003).' The lowest status individuals have a much higher propensity to stay than the two inconsistent groups who both have higher status. What does this imply about the link between high status and staying with a taste judgment?"*
* **Status:** `[Addressed]`
* **Location in Manuscript:** Section 1.1, Section 2 (Hypothesis 4), Section 3.6, Section 5
* **Actions Completed:**
  1. Formulated explicit theoretical mechanism grounded in Lenski (1954) status crystallization: status consistency anchors normative certainty and inertia ("staying"), whereas status inconsistency induces evaluative fluidity.
  2. Reframed staying away from "high status" to "structural status consistency".

#### 13. Update Literature & Theoretical Engagement
* **Reviewer Concern (R1 #13):**  
  > *"My only comment on the theoretical discussion is that the authors should engage more directly with the latest debates on taste and social influence, including more recent papers and book chapters by Lizardo and other scholars working in this area."*
* **Status:** `[Addressed]`
* **Location in Manuscript:** Section 1, Section 5, `references.bib`
* **Actions Completed:**
  1. Integrated contemporary scholarship on cultural cognition, dual-process habitus, aesthetic signaling, and symbolic boundaries.

---

### Tier 3: Design Details, Reactivity, Descriptives & Appendix Additions

#### 14. Address Demand Characteristics & Respondent Reactivity
* **Editor & Reviewer Concern (Editor, R2 #3):**  
  > *"Reviewer 2’s point about whether the experimental design might have been obvious to participants was something I wondered too, and providing more methodological detail might help alleviate these concerns."* (Editor)  
  > *"I’m wondering whether this design made respondents aware that a shift in their preference was being measured, and how that might influence their responses. Where any steps taken to minimize demand awareness or respondent reactivity?"* (R2)
* **Status:** `[Addressed]`
* **Location in Manuscript:** Section 2.4 (Mitigation of Experimenter Demand Characteristics and Respondent Reactivity)
* **Actions Completed:**
  1. Documented four procedural safeguards: extensive 15-20 min intervening survey buffer, naturalistic aggregate framing, unexposed control benchmark, and empirical evidence against demand compliance (high inertia and active reactance).

#### 15. Survey Sampling Details & Descriptive Statistics Table
* **Reviewer Concern (R1 #3):**  
  > *"Please provide more details about the survey sampling procedure. Because this is an experimental study, external validity is less central than internal validity. However, if the survey used probability sampling, this would strengthen the conclusions. This information is also important for assessing what the reported confidence intervals represent—for example, whether they reflect only experimental uncertainty within the sample or can support population-level inference. Relatedly, the authors should include a table presenting descriptive statistics for the sample."*
* **Status:** `[Addressed]`
* **Location in Manuscript:** Section 2.1–2.2, Table \ref{tbl:descriptives}
* **Actions Completed:**
  1. Documented 2012 SSI panel recruitment, quota matching to 2010/2012 Census benchmarks, deliberate college oversample, participant flow ($3,782 \to 2,275$), inferential scope of CIs, and Table 1.

#### 16. Exact Treatment Wording & Vignettes in Appendix
* **Reviewer Concern (R1 #5):**  
  > *"Please report the exact wording of the information treatments in the appendix. For example, readers need to know whether the wording indicated that the reference group had the same or a different social status from the participants."*
* **Status:** `[Addressed]`
* **Location in Manuscript:** Appendix \ref{sec:appendix_vignettes} (Survey Vignettes and Treatment Prompts)
* **Actions Completed:**
  1. Transcribed verbatim survey instrument flow, stimuli, prompts, attribution items, and response options into Appendix B.

#### 17. Figure Formatting & Polishing
* **Reviewer Concern (R1 #9):**  
  > *"In Figure 2, please explain what the dashed line represents and capitalize the variable labels consistently."*
* **Status:** `[Addressed]`
* **Location in Manuscript:** All figures and captions
* **Actions Completed:**
  1. Replaced all forest plots with publication-standard horizontal bar plots with 95% error bars, colored by statistical significance.
  2. Explicitly defined dashed zero line in captions and standardized title capitalization.

---

## Complete Reviewer-to-Item Audit Matrix

| Source & Item | Description / Requirement | Captured in `REVISION_PLAN_POETICS.md`? | Captured in `response_to_reviewers.md`? |
| :--- | :--- | :---: | :---: |
| **Editor #1** | Format choice: Research Note vs. Full Article | Yes (Exec Summary) | Yes (Editor Point 1) |
| **Editor #2** | Sharpen empirical novelty & research question warrant | Yes (Tier 2, Item 9) | Yes (Editor Point 2) |
| **Editor #3** | Streamline theoretical front-end & multiple literatures | Yes (Tier 2, Item 10) | Yes (Editor Point 3) |
| **Editor #4** | Address DiD, methodology context, demand awareness | Yes (Tier 1 & Tier 3) | Yes (Editor Point 4) |
| **R1 #1** | Difference-in-Differences (DiD) using control group & T1 | Yes (Tier 1, Item 1) | Yes (R1 Point 1) |
| **R1 #2** | Rename no-info to "control condition"; reserve "baseline" for T1 | Yes (Tier 1, Item 2) | Yes (R1 Point 2) |
| **R1 #3** | Survey sampling details, inference scope of CIs, Table 1 | Yes (Tier 3, Item 15) | Yes (R1 Point 3 - Detailed with Dissertation data) |
| **R1 #4** | Ex-post Minimum Detectable Effect (MDE) power analysis | Yes (Tier 1, Item 3) | Yes (R1 Point 4) |
| **R1 #5** | Exact wording of information treatments & stimuli in Appendix | Yes (Tier 3, Item 16) | Yes (R1 Point 5) |
| **R1 #6** | Separate models for Subjective Class & Education before combined | Yes (Tier 1, Item 4) | Yes (R1 Point 6) |
| **R1 #7** | Observational nature of status categories & IPW causal logic | Yes (Tier 1, Item 5) | Yes (R1 Point 7) |
| **R1 #8** | Covariate balance explanation & full diagnostics in Appendix | Yes (Tier 1, Item 5) | Yes (R1 Point 8) |
| **R1 #9** | Figure 2 dashed line definition & label capitalization | Yes (Tier 3, Item 17) | Yes (R1 Point 9) |
| **R1 #10** | Clarification of generalized influence results (no status dislike) | Yes (Tier 1, Item 6) | Yes (R1 Point 10) |
| **R1 #11** | Evaluation / streamlining of disaggregated behavioral analysis | Yes (Tier 1, Item 7) | Yes (R1 Point 11) |
| **R1 #12** | Full regression model tables in Appendix | Yes (Tier 1, Item 8) | Yes (R1 Point 12) |
| **R1 #13** | Theoretical engagement with recent taste & influence literature | Yes (Tier 2, Item 13) | Yes (R1 Point 13) |
| **R2 #1** | Research question rationale: experimental causal hook vs. obs. | Yes (Tier 2, Item 9) | Yes (R2 Point 1) |
| **R2 #2** | Streamline Section 1.1: eliminate meandering loops | Yes (Tier 2, Item 10) | Yes (R2 Point 2) |
| **R2 #3** | Demand characteristics & respondent reactivity | Yes (Tier 3, Item 14) | Yes (R2 Point 3) |
| **R2 #4** | Valence framing: reframe around valence asymmetry | Yes (Tier 2, Item 11) | Yes (R2 Point 4) |
| **R2 #5** | Mechanism for status inconsistency & moderation tests | Yes (Tier 2, Item 12) | Yes (R2 Point 5) |
| **R2 #6** | Clarify "Stay" finding across consistent high/low groups | Yes (Tier 2, Item 12) | Yes (R2 Point 6) |
| **R2 #7** | Clear empirical takeaways and utility for researchers | Yes (Tier 2, Item 9 & Tier 1) | Yes (R2 Point 7) |
