# Replication Package: *Stay, React, or Conform? Examining Social Influence Effects on Aesthetic Judgments*

Omar Lizardo (UCLA) and Sara Skiles (Notre Dame). Under review at *Poetics* (Manuscript ID POETICS-D-26-00490, Major Revision).

This repository contains the data-analysis pipeline that generates the numerical results, tables, and figures reported in the paper, along with the generated LaTeX tables and PDF figures the manuscript includes.

## Contents

```
R/
  01_dataproc.R            Cleans the raw SSI-2012 file and builds analysis variables
  02_samples.R             Sample sizes, shares, and design parameters (tables/sample_sizes.csv)
  03_models_did.R          Difference-in-differences mixed models (Sections 3.1-3.2)
  04_models_behavioral.R   Multinomial Stay / Conform / React average marginal effects (Section 3.3)
  05_ipw_balance.R         Covariate balance (Love plot data) for the IPW specification
  06_models_appendix.R     MDE analysis, descriptives, class robustness, tier-2 homogeneity check
  07_make_figures.R        All manuscript figures (PDF to figures/)
  08_make_tables.R         All generated LaTeX results tables (tables/)
  run_all.R                Runs steps 01-08 in order
tables/                    Generated LaTeX tables, \input into the manuscript (*.tex)
figures/                   Generated figures (PDF)
renv.lock, renv/           R environment specification
```

## Requirements

- R 4.5 or later
- Packages are pinned in `renv.lock`. To restore the environment:

```r
install.packages("renv")
renv::restore()
```

## Data

The analysis uses the 2012 Survey of Social Influence (SSI-2012) experimental data. The cleaned Stata file (`ssi2012_cleaned.dta`) is not included in this repository. Point the pipeline to your local copy with the `SSI_DATA_PATH` environment variable, for example in `~/.Renviron`:

```
SSI_DATA_PATH=/path/to/SSI-2012/data/clean/ssi2012_cleaned.dta
```

If the variable is unset, the pipeline looks for `data/ssi2012_cleaned.dta` inside the repository. The data directory is git-ignored.

## Running the pipeline

From the repository root:

```r
source("R/run_all.R")
```

The numbered steps can also be run individually, in order, starting with `R/01_dataproc.R`. The full pipeline took about 3 minutes in testing.

## Outputs

- `tables/table_did_edu_4tiers.tex`, `table_did_status_quadrants.tex`, `table_did_status_quadrants_full.tex`: DiD and status-consistency results (Section 3 and Appendix C, G)
- `tables/table_did_edu_class_primary.tex`, `table_did_edu_class_separate.tex`, `table_did_pooled_compare.tex`: Appendix C, D, and G robustness tables
- `tables/table_mde_summary.tex`: ex-post minimum detectable effect analysis (Appendix A)
- `figures/Figure8_CovariateBalance.pdf`: IPW covariate balance (Section 2.5)
- `figures/Figure_DiD_Baseline_Influence.pdf`: net DiD effects for the status-free baseline (Section 3.1)
- `figures/Figure_DiD_Edu_4Tiers.pdf`: DiD effects across four educational tiers (Section 3.2)
- `figures/Figure7_MultinomialBehavior.pdf`: Stay / Conform / React AMEs by status quadrant (Section 3.3)
- `figures/Figure11_Sens_MultinomialBehavior.pdf`: sensitivity analysis excluding Taste-Only conditions (Appendix E)
- `figures/Figure_MDE_Power_Curves.pdf`, `Figure_DiD_Edu_Class_Separate.pdf`, `Figure_DiD_Pooled.pdf`: Appendix A, C, and D figures

Model results are saved as `tables/*.rds` (git-ignored). Figures and tables read those files, so downstream steps do not refit models. The manuscript's sample sizes come from `tables/sample_sizes.csv`.

## Notes on the analysis

- The primary analytic sample is restricted to respondents aged 25 or older (N = 1,981). The full sample (N = 2,253) appears in the appendix as a robustness check.
- Propensity weights (inverse probability weights, via `WeightIt`) use categorical age and race/ethnicity along with gender and parental education. Adult personal income and region are excluded because they are post-treatment.
- The `age` variable is a bracket code. The filter `age >= 4` selects respondents aged 25 and older.

## Citation

Lizardo, Omar, and Sara Skiles. "Stay, React, or Conform? Examining Social Influence Effects on Aesthetic Judgments." *Poetics*. Under review.
