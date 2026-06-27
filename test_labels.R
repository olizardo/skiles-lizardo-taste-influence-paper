library(haven)

df <- read_dta("/home/omarlizardo/ACADEMIC AND COURSE MATERIALS/SSI-2012/data/clean/ssi2012_cleaned.dta")
cols_of_interest <- c("age", "female", "raceeth", "parented", "percclass", "bach", "ma", "docprof", "taste1", "taste2")

for (col in cols_of_interest) {
  cat("\n---", col, "---\n")
  if (!is.null(attr(df[[col]], "labels"))) {
    print(attr(df[[col]], "labels"))
  } else {
    cat("Continuous or no labels\n")
  }
}
