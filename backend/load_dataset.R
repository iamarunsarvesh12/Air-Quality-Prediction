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
  if (!file.exists(actual_path)) {
    candidates <- c(
      file.path("backend", path),
      file.path("..", path),
      file.path("..", "backend", path),
      "air_quality.csv",
      file.path("dataset", "air_quality.csv"),
      file.path("backend", "dataset", "air_quality.csv")
    )
    for (cand in candidates) {
      if (file.exists(cand)) {
        actual_path <- cand
        break
      }
    }
  }
  if (!file.exists(actual_path)) {
    stop(paste0("Dataset not found at '", path, "'. ",
                "Place your air_quality.csv inside backend/dataset/."))
  }

  data <- readr::read_csv(actual_path, show_col_types = FALSE)
  message(sprintf("Loaded dataset from '%s': %d rows, %d columns", actual_path, nrow(data), ncol(data)))
  return(data)
}

# Allow running this file directly for a quick sanity check:
# Rscript load_dataset.R
if (sys.nframe() == 0) {
  df <- load_dataset()
  print(head(df))
  print(str(df))
}
