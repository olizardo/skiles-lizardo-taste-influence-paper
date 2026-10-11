# R/01_dataproc.R
# ==============================================================================
# Data Processing Pipeline (Step 01)
# Paper: "Stay, React, or Conform? Examining Social Influence Effects on Aesthetic
#         Judgments" (Lizardo & Skiles, Poetics POETICS-D-26-00490)
#
# Cleans the SSI-2012 raw Stata file and constructs all analysis variables.
# Modernizes the original Stata `dataproc.do` pipeline.
#
# NOTE ON THE PRIMARY SAMPLE RESTRICTION:
#   `age` is a bracket code (2 = 18-19, 3 = 20-24, 4 = 25-29, ...). The primary
#   analytic sample filter is `age >= 4`, i.e. respondents aged 25 or older
#   (the youngest included bracket is 25-29). All manuscript wording refers to
#   this as the "Age >= 25 primary analytic sample" (N = 1,981).
# ==============================================================================

suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(tidyr)
})

# ------------------------------------------------------------------------------
# Candidate locations of the raw data (first existing path is used)
# ------------------------------------------------------------------------------
.raw_data_candidates <- c(
  "/home/omarlizardo/projects/CULTURE/cultural-consensus-musical-genres/SSI-2012/data/clean/ssi2012_cleaned.dta",
  "/home/omarlizardo/ACADEMIC AND COURSE MATERIALS/SSI-2012/data/clean/ssi2012_cleaned.dta"
)

resolve_data_path <- function(data_path = NULL) {
  if (!is.null(data_path)) {
    if (!file.exists(data_path)) {
      stop("Raw data file not found: ", data_path)
    }
    return(data_path)
  }
  found <- .raw_data_candidates[file.exists(.raw_data_candidates)]
  if (length(found) == 0) {
    stop(
      "Raw data file not found in any candidate location:\n  ",
      paste(.raw_data_candidates, collapse = "\n  "),
      "\nPass an explicit path via process_data(data_path = ...)."
    )
  }
  found[1]
}

# ------------------------------------------------------------------------------
# Core cleaning function: returns list(wide, long)
# ------------------------------------------------------------------------------
process_data <- function(data_path = NULL) {
  data_path <- resolve_data_path(data_path)
  df <- read_dta(data_path)

  # 1. Complete pre- and post-treatment evaluations (drops 22 non-evaluators)
  df_clean <- df %>%
    filter(!is.na(taste1), !is.na(taste2))

  # 2. Reverse the 1-7 taste scales (7 = like very much, 1 = dislike very much)
  df_clean <- df_clean %>%
    mutate(
      taste1_rev = 8 - taste1,
      taste2_rev = 8 - taste2
    )

  # 3. Change indicator and binary liking indicators
  df_clean <- df_clean %>%
    mutate(
      change = as.numeric(taste1_rev != taste2_rev),
      like1 = as.numeric(taste1_rev >= 6),
      like2 = as.numeric(taste2_rev >= 6)
    )

  # 4. Control and treatment indicators
  # Original control values: 0 = experimental, 1 = Control (No Feedback),
  # 2 = Control (Taste Only)
  df_clean <- df_clean %>%
    mutate(
      control2 = if_else(control %in% c(0, 1), 1, 0),
      control_new = control + 1,
      altertaste_new = altertaste + 1,
      alterclass_new = alterclass + 1
    )

  # 5. Nine experimental conditions (replicates Stata egen group mapping)
  df_clean <- df_clean %>%
    mutate(
      cond = case_when(
        control_new == 1 & altertaste_new == 2 & alterclass_new == 2 ~ 1,
        control_new == 1 & altertaste_new == 2 & alterclass_new == 3 ~ 2,
        control_new == 1 & altertaste_new == 2 & alterclass_new == 4 ~ 3,
        control_new == 1 & altertaste_new == 3 & alterclass_new == 2 ~ 4,
        control_new == 1 & altertaste_new == 3 & alterclass_new == 3 ~ 5,
        control_new == 1 & altertaste_new == 3 & alterclass_new == 4 ~ 6,
        control_new == 2 & altertaste_new == 1 & alterclass_new == 1 ~ 7,
        control_new == 3 & altertaste_new == 2 & alterclass_new == 1 ~ 8,
        control_new == 3 & altertaste_new == 3 & alterclass_new == 1 ~ 9,
        TRUE ~ NA_real_
      )
    )

  cond_labels <- c(
    "Class & Taste/Like/-Status",
    "Class & Taste/Like/+Status (ES)",
    "Class & Taste/Like/+Status (CS)",
    "Class & Taste/Dislike/-Status",
    "Class & Taste/Dislike/+Status (ES)",
    "Class & Taste/Dislike/+Status (CS)",
    "Baseline",
    "Taste Only/Like",
    "Taste Only/Dislike"
  )
  df_clean$cond_factor <- factor(df_clean$cond, levels = 1:9, labels = cond_labels)

  # 6. Respondent status variables
  # Class: percclass 1/2 = Working (0), 3/4 = Middle (1); NA stays NA
  df_clean <- df_clean %>%
    mutate(
      egoclass = socloc,
      cultcap = case_when(
        socloc %in% c(2, 3) ~ 1,
        !is.na(socloc) ~ 0,
        TRUE ~ NA_real_
      ),
      class = case_when(
        percclass %in% c(1, 2) ~ 0,
        !is.na(percclass) ~ 1,
        TRUE ~ NA_real_
      ),
      college = case_when(
        bach == 1 | ma == 1 | docprof == 1 ~ 1,
        !is.na(bach) ~ 0,
        TRUE ~ NA_real_
      )
    )

  df_clean$class_factor <- factor(df_clean$class, levels = c(0, 1), labels = c("Working Class", "Middle Class"))
  df_clean$college_factor <- factor(df_clean$college, levels = c(0, 1), labels = c("No College Degree", "College Degree"))

  # 6b. Four-tier educational attainment (highest credential)
  #   1 = High School or Less, 2 = Associate / Some College,
  #   3 = Bachelor's Degree,   4 = Postgraduate / Advanced Degree
  df_clean <- df_clean %>%
    mutate(
      edu4 = case_when(
        ma == 1 | docprof == 1 ~ 4,
        bach == 1 ~ 3,
        aadeg == 1 | somcol == 1 ~ 2,
        TRUE ~ 1
      ),
      edu4_factor = factor(
        edu4,
        levels = 1:4,
        labels = c("High School or Less", "Associate/Some College", "Bachelor's Degree", "Postgraduate")
      )
    )

  # 7. Subjective/objective status consistency quadrants
  #   1 = Working, No College; 2 = Working, College;
  #   3 = Middle, No College; 4 = Middle, College
  df_clean <- df_clean %>%
    mutate(
      objsubjclass = case_when(
        !is.na(class) & !is.na(college) & class == 0 & college == 0 ~ 1,
        !is.na(class) & !is.na(college) & class == 0 & college == 1 ~ 2,
        !is.na(class) & !is.na(college) & class == 1 & college == 0 ~ 3,
        !is.na(class) & !is.na(college) & class == 1 & college == 1 ~ 4,
        TRUE ~ NA_real_
      )
    )
  df_clean$objsubjclass_factor <- factor(
    df_clean$objsubjclass,
    levels = 1:4,
    labels = c("Working, No College", "Working, College", "Middle, No College", "Middle, College")
  )

  # 8. Simplified 7-level conditions (cond2): ES and CS collapsed into "+Status"
  df_clean <- df_clean %>%
    mutate(
      cond2 = case_when(
        cond == 1 ~ 1,
        cond == 2 | cond == 3 ~ 2,
        cond == 4 ~ 3,
        cond == 5 | cond == 6 ~ 4,
        cond == 7 ~ 5,
        cond == 8 ~ 6,
        cond == 9 ~ 7,
        TRUE ~ NA_real_
      )
    )
  cond2_labels <- c(
    "Class & Taste/Like/-Status",
    "Class & Taste/Like/+Status",
    "Class & Taste/Dislike/-Status",
    "Class & Taste/Dislike/+Status",
    "Baseline",
    "Taste Only/Like",
    "Taste Only/Dislike"
  )
  df_clean$cond2_factor <- factor(df_clean$cond2, levels = 1:7, labels = cond2_labels)

  # 9. Helper variables
  df_clean <- df_clean %>%
    mutate(
      highstatus = as.numeric(cond %in% c(2, 3, 5, 6)),
      lowstatus = as.numeric(cond %in% c(1, 4)),
      alterdis = as.numeric(cond %in% c(4, 5, 6, 9)),
      tastediff = taste1_rev - taste2_rev,
      stay = as.numeric(tastediff == 0),
      shift = 1 - stay,
      diff = taste2_rev - taste1_rev
    )

  # 10. Long format for panel (DiD) analyses
  df_long <- df_clean %>%
    pivot_longer(
      cols = c(taste1_rev, taste2_rev),
      names_to = "trial_name",
      values_to = "taste"
    ) %>%
    mutate(trial = if_else(trial_name == "taste1_rev", 1, 2)) %>%
    mutate(like = if_else(trial == 1, like1, like2)) %>%
    arrange(id, trial)

  list(wide = df_clean, long = df_long)
}

# ------------------------------------------------------------------------------
# Standard analytic samples (single source of truth for all scripts)
# ------------------------------------------------------------------------------
build_samples <- function(data_path = NULL) {
  dl <- process_data(data_path)
  df_wide <- dl$wide
  df_long <- dl$long

  # Complete cases on strictly exogenous pre-treatment covariates used by IPW
  cc_vars <- c("objsubjclass_factor", "age", "female", "raceeth", "parented")
  df_wide_cc_full <- df_wide %>%
    filter(if_all(all_of(cc_vars), ~ !is.na(.x)))

  # Primary analytic sample: age bracket >= 4 (25-29 and older), N = 1,981
  df_wide_cc_primary <- df_wide_cc_full %>%
    filter(age >= 4)

  # Race/ethnicity as a labeled factor for IPW and cobalt balance diagnostics.
  # The raw `raceeth` is a labelled numeric (1-6); cobalt treats labelled
  # numerics as continuous and computes a single SMD over the numeric codes,
  # so balance checks must use an explicit factor (raceeth_f). The numeric
  # column is retained for scripts that rely on the numeric codes (e.g.,
  # Table 1 descriptives in 06_models_appendix.R).
  raceeth_labels <- c("Asian", "Black", "Hispanic", "White", "Multiracial", "Other")
  df_wide_cc_full <- df_wide_cc_full %>%
    mutate(raceeth_f = factor(raceeth, levels = 1:6, labels = raceeth_labels))
  df_wide_cc_primary <- df_wide_cc_primary %>%
    mutate(raceeth_f = factor(raceeth, levels = 1:6, labels = raceeth_labels))

  list(
    wide_all = df_wide,                 # all complete evaluators (N = 2,253)
    long_all = df_long,
    wide_cc_full = df_wide_cc_full,     # full-sample complete cases (N = 2,252)
    wide_cc_primary = df_wide_cc_primary, # primary analytic sample (N = 1,981)
    long_cc_primary = df_long %>% filter(id %in% df_wide_cc_primary$id),
    long_cc_full = df_long %>% filter(id %in% df_wide_cc_full$id)
  )
}
