# R/00_get_data.R
# ==============================================================================
# Downloads the cleaned SSI-2012 Stata file from the public release
# (https://olizardo.github.io/SSI-2012/, data files hosted at
# https://github.com/olizardo/SSI-2012) if no local copy exists.
#
# The release is CC BY 4.0. Its 2,275 records match the analysis file used for
# the paper; the only difference is a blank, all-missing row that the local
# working copy carried, which the released file omits.
# ==============================================================================

SSI_DATA_URL <- "https://raw.githubusercontent.com/olizardo/SSI-2012/master/data/clean/ssi2012_cleaned.dta"
SSI_DATA_MD5 <- "3843d6b52b6e8c865cd84c47dede5cbe"

get_ssi_data <- function(dest = file.path("data", "ssi2012_cleaned.dta"),
                         overwrite = FALSE) {
  if (file.exists(dest) && !overwrite) {
    return(invisible(dest))
  }
  dir.create(dirname(dest), showWarnings = FALSE, recursive = TRUE)
  utils::download.file(SSI_DATA_URL, dest, mode = "wb")
  md5 <- unname(tools::md5sum(dest))
  if (md5 != SSI_DATA_MD5) {
    warning(
      "Downloaded SSI-2012 file has MD5 ", md5, ", expected ", SSI_DATA_MD5,
      ". The public release may have changed; check the release notes before ",
      "comparing estimates with the paper."
    )
  }
  invisible(dest)
}
