# Legacy Scripts (Superseded -- Do Not Run)

These scripts were the pre-consolidation pipeline. They are retained for
provenance only and are **superseded by the numbered pipeline** in `R/`
(`01_dataproc.R` ... `08_make_tables.R`, orchestrated by `R/run_all.R`).

Do not run anything in this folder:

- Several scripts silently **overwrite the manuscript's primary-sample figures
  with full-sample versions** (e.g. `stepwise_status_models.R` overwrote
  `figures/Figure_DiD_Edu_Class_Separate.png`; `generate_figure_baseline_influence.R`
  overwrote `figures/Figure_DiD_Baseline_Influence.png`).
- `appendix_robustness.R` and the root `test_labels.R` hardcode a data path that
  no longer exists and fail to run.
- `analysis.qmd` (project root) duplicates the IPW/model logic without the
  primary-sample (Age >= 25) restriction and without AMEs.

Every model, figure, and table produced by these scripts is reproduced by the
new pipeline, which computes all sample sizes from data, fits the missing
4-tier education model, and assigns each output file to exactly one script.
