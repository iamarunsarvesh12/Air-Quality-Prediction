# ===========================================================
# AirSense — preprocess.R (Module 3: Dataset Management)
# Cleans and prepares the dataset for model training:
#   - removes duplicate rows
#   - handles missing values
#   - normalizes numeric columns (optional, min-max)
#   - saves the cleaned dataset
# ===========================================================

library(dplyr)
library(tidyr)

# Columns expected in the raw dataset. Adjust to match your CSV.
FEATURE_COLUMNS <- c("pm25", "pm10", "no2", "so2", "co", "o3",
                      "temperature", "humidity", "windSpeed")
TARGET_COLUMN <- "aqi"

#' Clean and preprocess the raw air quality dataset.
#'
#' @param data Raw data.frame/tibble (e.g. from load_dataset()).
#' @param normalize Whether to min-max normalize the feature columns.
#' @return A cleaned data.frame ready for training.
preprocess_data <- function(data, normalize = FALSE) {

  cleaned <- data %>%
    distinct() %>%                          # remove duplicate rows
    drop_na(any_of(c(FEATURE_COLUMNS, TARGET_COLUMN)))  # remove rows with missing key values

  # Fill any remaining minor NAs in optional columns with column median
  for (col in FEATURE_COLUMNS) {
    if (col %in% names(cleaned) && any(is.na(cleaned[[col]]))) {
      med <- median(cleaned[[col]], na.rm = TRUE)
      cleaned[[col]][is.na(cleaned[[col]])] <- med
    }
  }

  if (normalize) {
    minmax <- function(x) (x - min(x)) / (max(x) - min(x))
    cleaned <- cleaned %>%
      mutate(across(all_of(FEATURE_COLUMNS), minmax))
  }

  message(sprintf("Preprocessing complete: %d rows remain after cleaning.", nrow(cleaned)))
  return(cleaned)
}

#' Save the cleaned dataset to disk.
save_processed <- function(data, path = "dataset/air_quality_clean.csv") {
  readr::write_csv(data, path)
  message(paste0("Saved cleaned dataset to '", path, "'"))
}

# Run directly: Rscript preprocess.R
if (sys.nframe() == 0) {
  source("load_dataset.R")
  raw <- load_dataset()
  clean <- preprocess_data(raw)
  save_processed(clean)
}
