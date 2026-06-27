suppressMessages({
  library(haven)
  library(dplyr)
  library(ordinal)
})

source("R/dataproc.R")
data_list <- process_data()
df_long <- data_list$long
df_long$taste_ord <- factor(df_long$taste, ordered = TRUE, levels = 1:7)

# Unweighted mixed model without weights
t0 <- Sys.time()
mod_clmm <- clmm(taste_ord ~ factor(trial) * cond2_factor + (1 | id), data = df_long)
print(Sys.time() - t0)
saveRDS(summary(mod_clmm)$coefficients, "clmm_coefs.rds")
