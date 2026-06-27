# data_proc.R - Data processing pipeline for Taste Influence Paper
# Replicates and modernizes do/dataproc.do using R tidyverse and haven

library(haven)
library(dplyr)
library(tidyr)

# Function to process the SSI-2012 dataset
process_data <- function(data_path = "/home/omarlizardo/ACADEMIC AND COURSE MATERIALS/SSI-2012/data/clean/ssi2012_cleaned.dta") {
  
  # Load raw Stata data
  df <- read_dta(data_path)
  
  # 1. Clean column names and drop missing values on taste1 and taste2
  df_clean <- df %>%
    filter(!is.na(taste1), !is.na(taste2))
  
  # 2. Reverse the 1-7 taste scales (so 7 = highly like, 1 = highly dislike)
  df_clean <- df_clean %>%
    mutate(
      taste1_rev = 8 - taste1,
      taste2_rev = 8 - taste2
    )
  
  # 3. Create change indicator and binary liking indicators
  df_clean <- df_clean %>%
    mutate(
      change = as.numeric(taste1_rev != taste2_rev),
      like1 = as.numeric(taste1_rev >= 6), # originally taste1 1/5 = 0, 6/7 = 1
      like2 = as.numeric(taste2_rev >= 6)  # originally taste2 1/5 = 0, 6/7 = 1
    )
  
  # 4. Process control and treatment indicators
  # Note: in Stata control is replace control = control + 1
  # and recode control 0/1 = 1 2 = 0, g(control2) is run BEFORE that.
  # Original control values: 0 = experimental, 1 = Control 1 (No Feedback), 2 = Control 2 (Taste Only)
  df_clean <- df_clean %>%
    mutate(
      control2 = if_else(control %in% c(0, 1), 1, 0),
      control_new = control + 1,
      altertaste_new = altertaste + 1,
      alterclass_new = alterclass + 1
    )
  
  # 5. Create the 9 experimental condition variable (cond)
  # Deterministic mapping matching Stata's egen cond = group(control altertaste alterclass)
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
  
  # Set condition labels
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
  
  # 6. Create respondent class and cultural capital variables
  df_clean <- df_clean %>%
    mutate(
      egoclass = socloc,
      cultcap = if_else(socloc %in% c(2, 3), 1, 0), # High vs Low Cultural Capital
      # Class variable based on percclass: 1/2 = 0 (Working), 3/4 = 1 (Middle)
      class = if_else(percclass %in% c(1, 2), 0, 1),
      # Education/College variable: college degree if bach, ma, or docprof
      college = if_else(bach == 1 | ma == 1 | docprof == 1, 1, 0)
    )
  
  # Labels for demographic groups
  df_clean$class_factor <- factor(df_clean$class, levels = c(0, 1), labels = c("Working Class", "Middle Class"))
  df_clean$college_factor <- factor(df_clean$college, levels = c(0, 1), labels = c("No College Degree", "College Degree"))
  df_clean$cultcap_factor <- factor(df_clean$cultcap, levels = c(0, 1), labels = c("Low Cultural Capital", "High Cultural Capital"))
  
  # 7. Create subjective/objective status consistency (objsubjclass)
  # 1 = Working Class, No College
  # 2 = Working Class, College
  # 3 = Middle Class, No College
  # 4 = Middle Class, College
  df_clean <- df_clean %>%
    mutate(
      objsubjclass = case_when(
        class == 0 & college == 0 ~ 1,
        class == 0 & college == 1 ~ 2,
        class == 1 & college == 0 ~ 3,
        class == 1 & college == 1 ~ 4,
        TRUE ~ NA_real_
      )
    )
  
  objsubj_labels <- c(
    "Working, No College",
    "Working, College",
    "Middle, No College",
    "Middle, College"
  )
  df_clean$objsubjclass_factor <- factor(df_clean$objsubjclass, levels = 1:4, labels = objsubj_labels)
  
  # 8. Simplified conditions (cond2)
  # Collapse ES and CS (+Status conditions)
  df_clean <- df_clean %>%
    mutate(
      cond2 = case_match(
        cond,
        1 ~ 1, # Class & Taste/Like/-Status
        c(2, 3) ~ 2, # Class & Taste/Like/+Status
        4 ~ 3, # Class & Taste/Dislike/-Status
        c(5, 6) ~ 4, # Class & Taste/Dislike/+Status
        7 ~ 5, # Baseline
        8 ~ 6, # Taste Only/Like
        9 ~ 7  # Taste Only/Dislike
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
  
  # 9. Other helper variables
  df_clean <- df_clean %>%
    mutate(
      highstatus = as.numeric(cond %in% c(2, 3, 5, 6)),
      lowstatus = as.numeric(cond %in% c(1, 4)),
      alterdis = as.numeric(cond %in% c(4, 5, 6, 9)),
      tastediff = taste1_rev - taste2_rev,
      stay = as.numeric(tastediff == 0),
      shift = 1 - stay
    )
  
  # 10. Reshape to long format for panel analyses
  df_long <- df_clean %>%
    pivot_longer(
      cols = c(taste1_rev, taste2_rev),
      names_to = "trial_name",
      values_to = "taste"
    ) %>%
    mutate(
      trial = if_else(trial_name == "taste1_rev", 1, 2)
    ) %>%
    # Add long version of binary like variable
    mutate(
      like = if_else(trial == 1, like1, like2)
    ) %>%
    arrange(id, trial)
  
  return(list(wide = df_clean, long = df_long))
}
