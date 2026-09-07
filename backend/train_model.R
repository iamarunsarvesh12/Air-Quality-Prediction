# ===========================================================
# AirSense — train_model.R (Module 4: ML Model Development)
# Trains a Random Forest model to predict AQI from pollutant
# and weather readings, evaluates it, and saves it to model.rds
# ===========================================================

library(caret)
library(randomForest)

if (file.exists("load_dataset.R")) {
  source("load_dataset.R")
} else if (file.exists("backend/load_dataset.R")) {
  source("backend/load_dataset.R")
}

if (file.exists("preprocess.R")) {
  source("preprocess.R")
} else if (file.exists("backend/preprocess.R")) {
  source("backend/preprocess.R")
}

set.seed(42)

train_aqi_model <- function() {
  # 1. Load + preprocess
  raw <- load_dataset()
  data <- preprocess_data(raw)

  # 2. Feature selection
  model_data <- data[, c(FEATURE_COLUMNS, TARGET_COLUMN)]

  # 3. Train-test split (80/20)
  train_index <- createDataPartition(model_data[[TARGET_COLUMN]], p = 0.8, list = FALSE)
  train_set <- model_data[train_index, ]
  test_set  <- model_data[-train_index, ]

  # 4. Train Random Forest model
  message("Training Random Forest model...")
  model <- randomForest(
    formula = as.formula(paste(TARGET_COLUMN, "~ .")),
    data = train_set,
    ntree = 500,
    importance = TRUE
  )

  # 5. Evaluate on test set
  predictions <- predict(model, newdata = test_set)
  rmse <- sqrt(mean((predictions - test_set[[TARGET_COLUMN]])^2))
  r_squared <- cor(predictions, test_set[[TARGET_COLUMN]])^2

  message(sprintf("Test RMSE: %.2f", rmse))
  message(sprintf("Test R-squared: %.3f", r_squared))
  print(importance(model))

  # 6. Save trained model
  out_path <- "model.rds"
  if (dir.exists("backend")) {
    out_path <- file.path("backend", "model.rds")
  }
  saveRDS(model, out_path)
  message(sprintf("Model saved to '%s'", out_path))

  return(model)
}

# Run directly: Rscript train_model.R
if (sys.nframe() == 0) {
  train_aqi_model()
}
