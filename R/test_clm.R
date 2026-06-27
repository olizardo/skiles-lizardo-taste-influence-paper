suppressMessages({
  library(haven)
  library(dplyr)
  library(ordinal)
})
source("R/dataproc.R")
df_long <- process_data()$long
df_long$taste_ord <- factor(df_long$taste, ordered = TRUE, levels = 1:7)
mod <- clm(taste_ord ~ factor(trial) * cond2_factor, data = df_long)
print(summary(mod))
