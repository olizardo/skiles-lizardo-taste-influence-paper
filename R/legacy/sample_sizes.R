source("R/dataproc.R")
data_list <- process_data()
df <- data_list$wide
cat("Total sample size:", nrow(df), "\n")
cat("\nBy Cond:\n")
print(table(df$cond_factor, useNA = "ifany"))
cat("\nBy Cond2:\n")
print(table(df$cond2_factor, useNA = "ifany"))
