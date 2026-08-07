# ===========================================================
# AirSense — load_dataset.R (Module 3: Dataset Management)
# Reads the raw air quality CSV dataset used for model training.
# ===========================================================

library(readr)

#' Load the raw air quality dataset from disk.
#'
#' @param path Path to the CSV file. Defaults to dataset/air_quality.csv
#' @return A tibble/data.frame with the raw dataset.
load_dataset <- function(path = "dataset/air_quality.csv") {
  actual_path <- path
  if (!file.exists(actual_path) && file.exists(file.path("backend", path))) {
    actual_path <- file.path("backend", path)
  }
  if (!file.exists(actual_path)) {
    stop(paste0("Dataset not found at '", path, "'. ",
                "Place your air_quality.csv inside backend/dataset/."))
  }

  data <- readr::read_csv(actual_path, show_col_types = FALSE)
  message(sprintf("Loaded dataset: %d rows, %d columns", nrow(data), ncol(data)))
  return(data)
}

# Allow running this file directly for a quick sanity check:
# Rscript load_dataset.R
if (sys.nframe() == 0) {
  df <- load_dataset()
  print(head(df))
  print(str(df))
}
