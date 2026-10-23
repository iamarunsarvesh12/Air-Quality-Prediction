# ===========================================================
# AeroSense TN — requirements.R
# Manages, verifies, and reports all R package dependencies
# ===========================================================

possible_libs <- c("r_libs", "../r_libs", "backend/r_libs", file.path(getwd(), "r_libs"), file.path(getwd(), "backend", "r_libs"))
for (lib in possible_libs) {
  if (dir.exists(lib)) {
    .libPaths(c(normalizePath(lib), .libPaths()))
  }
}

required_packages <- c(
  "plumber",
  "randomForest",
  "jsonlite",
  "readr",
  "dplyr",
  "curl",
  "httr",
  "httpuv"
)

verify_and_install_packages <- function(auto_install = TRUE) {
  installed <- installed.packages()[, "Package"]
  missing_packages <- required_packages[!(required_packages %in% installed)]
  
  cat("--- AeroSense TN Dependency Verification ---\n")
  cat(sprintf("R Version: %s\n", R.version.string))
  
  for (pkg in required_packages) {
    if (pkg %in% installed) {
      ver <- as.character(packageVersion(pkg))
      cat(sprintf("  [OK] %-15s (v%s)\n", pkg, ver))
    } else {
      cat(sprintf("  [MISSING] %-15s\n", pkg))
    }
  }
  
  if (length(missing_packages) > 0) {
    if (auto_install) {
      cat(sprintf("\nInstalling missing R packages: %s\n", paste(missing_packages, collapse = ", ")))
      lib_dir <- if (dir.exists("r_libs")) "r_libs" else if (dir.exists("../r_libs")) "../r_libs" else NULL
      if (!is.null(lib_dir)) {
        install.packages(missing_packages, lib = lib_dir, repos = "https://cloud.r-project.org")
      } else {
        install.packages(missing_packages, repos = "https://cloud.r-project.org")
      }
      
      # Re-verify
      installed_after <- installed.packages()[, "Package"]
      still_missing <- required_packages[!(required_packages %in% installed_after)]
      if (length(still_missing) > 0) {
        stop(paste("Failed to install required packages:", paste(still_missing, collapse = ", ")))
      }
      cat("All required R packages installed successfully.\n")
      return(TRUE)
    } else {
      cat(sprintf("\nWarning: Missing packages detected: %s\n", paste(missing_packages, collapse = ", ")))
      return(FALSE)
    }
  } else {
    cat("\nAll required R packages are installed and ready.\n")
    return(TRUE)
  }
}

if (sys.nframe() == 0) {
  status <- verify_and_install_packages()
  if (!status) quit(status = 1)
}
