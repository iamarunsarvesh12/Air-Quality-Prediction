# ===========================================================
# AeroSense TN — train.R (Module: ML Model Training & Evaluation)
# Full Random Forest training pipeline on Tamil Nadu air quality telemetry
# Evaluates metrics (R², RMSE, MAE) and persists model to model.rds
# ===========================================================

suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(randomForest)
  library(jsonlite)
})

# Path resolution helper
resolve_path <- function(relative_path) {
  candidates <- c(
    relative_path,
    file.path("backend", relative_path),
    file.path("..", relative_path),
    file.path(getwd(), relative_path),
    file.path(getwd(), "backend", relative_path)
  )
  for (cand in candidates) {
    if (file.exists(cand)) return(normalizePath(cand))
  }
  relative_path
}

FEATURE_COLUMNS <- c("pm25", "pm10", "no2", "so2", "co", "o3", "temperature", "humidity", "windSpeed")
TARGET_COLUMN <- "aqi"

train_aqi_model <- function(data_path = "dataset/air_quality.csv", model_output = "model.rds") {
  cat("============================================================\n")
  cat("   AeroSense TN — Random Forest Model Training Pipeline\n")
  cat("============================================================\n")
  
  # 1. Resolve dataset path
  resolved_data_path <- resolve_path(data_path)
  if (!file.exists(resolved_data_path)) {
    # Check alternate location
    alt_path <- resolve_path("backend/dataset/air_quality.csv")
    if (file.exists(alt_path)) {
      resolved_data_path <- alt_path
    } else {
      stop(sprintf("Training dataset not found at '%s'. Please place air_quality.csv in dataset/.", data_path))
    }
  }
  
  cat(sprintf("[Data] Loading air quality dataset from: %s\n", resolved_data_path))
  raw_df <- readr::read_csv(resolved_data_path, show_col_types = FALSE)
  cat(sprintf("[Data] Ingested raw dataset: %d rows, %d columns\n", nrow(raw_df), ncol(raw_df)))
  
  # 2. Validate columns
  required_cols <- c(FEATURE_COLUMNS, TARGET_COLUMN)
  missing_cols <- setdiff(required_cols, names(raw_df))
  if (length(missing_cols) > 0) {
    stop(sprintf("Dataset is missing required columns: %s", paste(missing_cols, collapse = ", ")))
  }
  
  # 3. Clean and preprocess data (handling missing values, duplicates, and physical bounds)
  clean_df <- raw_df %>%
    distinct() %>%
    filter(!is.na(.data[[TARGET_COLUMN]]))
  
  for (col in FEATURE_COLUMNS) {
    clean_df <- clean_df %>% filter(!is.na(.data[[col]]))
  }
  
  # Enforce physical sanity bounds
  clean_df <- clean_df %>%
    filter(
      pm25 >= 0 & pm25 <= 1000,
      pm10 >= 0 & pm10 <= 1500,
      no2 >= 0 & no2 <= 500,
      so2 >= 0 & so2 <= 500,
      co >= 0 & co <= 50,
      o3 >= 0 & o3 <= 500,
      temperature >= -10 & temperature <= 60,
      humidity >= 0 & humidity <= 100,
      windSpeed >= 0 & windSpeed <= 150,
      aqi >= 0 & aqi <= 1000
    )
  
  cat(sprintf("[Data] Preprocessing complete: %d valid samples retained after cleaning.\n", nrow(clean_df)))
  
  # 4. Train-Test Split (80% train, 20% test) with fixed seed to prevent data leakage
  set.seed(42)
  n_total <- nrow(clean_df)
  train_indices <- sample(seq_len(n_total), size = floor(0.80 * n_total))
  
  train_set <- clean_df[train_indices, required_cols]
  test_set  <- clean_df[-train_indices, required_cols]
  
  cat(sprintf("[Split] Training set: %d observations (80%%) | Evaluation set: %d observations (20%%)\n", nrow(train_set), nrow(test_set)))
  
  # 5. Model Training (Random Forest Regressor)
  cat("[Train] Training Random Forest Regressor (ntree = 500, mtry = 3)...\n")
  rf_formula <- as.formula(paste(TARGET_COLUMN, "~", paste(FEATURE_COLUMNS, collapse = " + ")))
  
  rf_model <- randomForest::randomForest(
    formula = rf_formula,
    data = train_set,
    ntree = 500,
    mtry = 3,
    importance = TRUE,
    keep.forest = TRUE
  )
  
  # 6. Evaluation on independent test set (no leakage)
  cat("[Evaluation] Evaluating predictions on unseen test dataset...\n")
  test_predictions <- predict(rf_model, newdata = test_set)
  actuals <- test_set[[TARGET_COLUMN]]
  
  rmse <- sqrt(mean((test_predictions - actuals)^2))
  mae  <- mean(abs(test_predictions - actuals))
  r2   <- cor(test_predictions, actuals)^2
  
  # Out-of-Bag (OOB) metrics from model
  oob_r2 <- tail(rf_model$rsq, 1)
  oob_rmse <- sqrt(tail(rf_model$mse, 1))
  
  cat("\n------------------------------------------------------------\n")
  cat("   Random Forest Evaluation Results (Independent Test Set)\n")
  cat("------------------------------------------------------------\n")
  cat(sprintf("  • Test R² (Coefficient of Determination) : %.4f (%.1f%% variance explained)\n", r2, r2 * 100))
  cat(sprintf("  • Test RMSE (Root Mean Squared Error)    : %.2f AQI units\n", rmse))
  cat(sprintf("  • Test MAE  (Mean Absolute Error)        : %.2f AQI units\n", mae))
  cat(sprintf("  • Out-of-Bag (OOB) R²                    : %.4f\n", oob_r2))
  cat(sprintf("  • Out-of-Bag (OOB) RMSE                  : %.2f\n", oob_rmse))
  cat("------------------------------------------------------------\n\n")
  
  # 7. Importance
  cat("Feature Importance ranking (%IncMSE):\n")
  imp <- randomForest::importance(rf_model)
  if ("%IncMSE" %in% colnames(imp)) {
    imp_sorted <- imp[order(-imp[, "%IncMSE"]), , drop = FALSE]
    for (i in seq_len(nrow(imp_sorted))) {
      cat(sprintf("  %2d. %-15s : %6.2f\n", i, rownames(imp_sorted)[i], imp_sorted[i, "%IncMSE"]))
    }
  } else {
    print(imp)
  }
  
  # 8. Save model and metadata
  dest_model_path <- if (dir.exists("backend")) file.path("backend", "model.rds") else "model.rds"
  dest_meta_path  <- if (dir.exists("backend")) file.path("backend", "model_metadata.json") else "model_metadata.json"
  
  saveRDS(rf_model, dest_model_path)
  cat(sprintf("\n[Save] Serialized Random Forest model saved to: %s\n", dest_model_path))
  
  metadata <- list(
    model_name = "AeroSense TN Random Forest AQI Regressor",
    algorithm = "RandomForest (R randomForest 4.7)",
    r_squared = round(r2, 4),
    rmse = round(rmse, 2),
    mae = round(mae, 2),
    oob_r2 = round(oob_r2, 4),
    oob_rmse = round(oob_rmse, 2),
    ntree = 500,
    mtry = 3,
    train_samples = nrow(train_set),
    test_samples = nrow(test_set),
    features = FEATURE_COLUMNS,
    target = TARGET_COLUMN,
    trained_at = format(Sys.time(), "%Y-%m-%dT%H:%M:%S%z")
  )
  
  jsonlite::write_json(metadata, dest_meta_path, pretty = TRUE, auto_unbox = TRUE)
  cat(sprintf("[Save] Model evaluation metadata saved to: %s\n", dest_meta_path))
  
  return(invisible(list(model = rf_model, metadata = metadata)))
}

if (sys.nframe() == 0) {
  train_aqi_model()
}
