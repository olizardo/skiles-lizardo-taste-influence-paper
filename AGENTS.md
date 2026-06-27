# Taste Influence Paper Project

## Overview
This project modernizes and revives the analysis for the "Social Influence Effect on Aesthetic Judgments" paper (Draft 2 and Draft 3). The original Stata pipeline has been ported to a fully reproducible R workflow.

## Data
- **Raw Data Path**: `/home/omarlizardo/ACADEMIC AND COURSE MATERIALS/SSI-2012/data/clean/ssi2012_cleaned.dta`
- **Format**: Stata `.dta` file containing survey data with embedded value labels. Use `haven::read_dta()` to load it.
- **Data Processing**: The script `R/dataproc.R` contains the `process_data()` function which handles all data wrangling. It filters missing taste evaluations, reverses the 1-7 taste scales, and generates the necessary demographic and condition factors (e.g., `cond_factor`, `cond2_factor`, `objsubjclass_factor`). It returns a list containing both `wide` and `long` format datasets.

## Key Variables
- `taste1` / `taste2`: Pre and post evaluations of an artwork. (Reversed in processing: 7 = like very much, 1 = dislike very much).
- `trial`: Indicates if the rating is before (1) or after (2) exposure to the experimental condition.
- `cond_factor` / `cond2_factor`: The experimental treatment condition indicating fictional peer evaluations (Like/Dislike) and their status (+Status, -Status, No Status).
- `objsubjclass_factor`: A 4-level categorical variable capturing status consistency (Working Class vs. Middle Class crossed with College vs. No College).
- `behavior`: Derived in advanced models as 'Stay', 'Conform', or 'React' based on the direction of taste shift relative to the condition.

## Analytical Pipeline
- **`R/dataproc.R`**: Core data cleaning and reshaping.
- **`R/replication_models.R`**: Replicates the original Stata linear mixed models (`lmer`) and Wald tests.
- **`R/visualization.R`**: Generates `ggplot2` versions of the original paper's figures.
- **`R/advanced_models.R`**: Contains modern modeling strategies including Cumulative Link Mixed Models (CLMM via `ordinal`) and Multinomial Logistic Regression (`nnet::multinom`) for behavior.
- **`R/propensity_models.R`**: Implements Inverse Probability Weighting (IPW) using `WeightIt` and `cobalt` to balance covariates (age, gender, race, parent's education) across the observational status groups.
- **`R/sensitivity_analysis.R`**: Drops the "Taste Only" conditions to isolate class-based feedback effects.

## Manuscript
- **`manuscript_revived.qmd`**: A comprehensive Quarto document combining all analyses, model comparisons, robustness checks, and visualizations. Render this file to generate the complete report.
