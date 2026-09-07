# ===========================================================
# AeroSense TN — requirements.R
# Manages and verifies all R package dependencies
# ===========================================================

possible_libs <- c("r_libs", "../r_libs", file.path(getwd(), "r_libs"), file.path(getwd(), "..", "r_libs"))
for (lib in possible_libs) {
  if (dir.exists(lib)) {
    .libPaths(c(normalizePath(lib), .libPaths()))
  }
}

required_packages <- c("plumber", "randomForest", "jsonlite", "readr", "dplyr", "curl", "httr")

verify_and_install_packages <- function() {
  missing_packages <- required_packages[!(required_packages %in% installed.packages()[, "Package"])]
  
  if (length(missing_packages) > 0) {
    message(paste("Installing missing R packages:", paste(missing_packages, collapse = ", ")))
    lib_dir <- if (dir.exists("r_libs")) "r_libs" else if (dir.exists("../r_libs")) "../r_libs" else NULL
    if (!is.null(lib_dir)) {
      install.packages(missing_packages, lib = lib_dir, repos = "https://cloud.r-project.org")
    } else {
      install.packages(missing_packages, repos = "https://cloud.r-project.org")
    }
  } else {
    message("All required R packages are installed and ready.")
  }
}

if (sys.nframe() == 0) {
  verify_and_install_packages()
}
