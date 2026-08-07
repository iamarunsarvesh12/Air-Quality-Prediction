# ===========================================================
# AirSense — predict.R (Module 5: Backend API — prediction logic)
# Loads the trained model and produces a full prediction result:
# AQI value, category, color code, health effects, recommendations.
# ===========================================================

library(randomForest) # <-- THIS IS THE CRITICAL FIX!

# Helper to find backend files from either root or backend/ directory
get_backend_path <- function(filename) {
  if (file.exists(filename)) return(filename)
  bpath <- file.path("backend", filename)
  if (file.exists(bpath)) return(bpath)
  filename
}

if (file.exists("category.R")) {
  source("category.R")
} else if (file.exists("backend/category.R")) {
  source("backend/category.R")
}

if (file.exists("disease_mapping.R")) {
  source("disease_mapping.R")
} else if (file.exists("backend/disease_mapping.R")) {
  source("backend/disease_mapping.R")
}

MODEL_PATH <- "model.rds"
.model_cache <- NULL

#' Load the trained model once and cache it in memory.
get_model <- function() {
  if (is.null(.model_cache)) {
    actual_path <- get_backend_path(MODEL_PATH)
    if (!file.exists(actual_path)) {
      stop(paste0("Model file not found at '", actual_path,
                   "'. Run train_model.R first."))
    }
    .model_cache <<- readRDS(actual_path)
  }
  .model_cache
}

#' Predict AQI and build the full response payload for the API.
#'
#' @param input A named list/data.frame row with the 9 feature values.
#' @return A list ready to be serialized as JSON.
predict_aqi <- function(input) {
  model <- get_model()

  new_data <- data.frame(
    pm25 = input$pm25,
    pm10 = input$pm10,
    no2 = input$no2,
    so2 = input$so2,
    co = input$co,
    o3 = input$o3,
    temperature = input$temperature,
    humidity = input$humidity,
    windSpeed = input$windSpeed
  )

  # Model predict function needs the randomForest library loaded
  predicted_aqi <- round(as.numeric(predict(model, newdata = new_data)), 1)
  category_info <- classify_aqi(predicted_aqi)
  health_info <- get_health_info(category_info$category)

  list(
    aqi = predicted_aqi,
    category = category_info$category,
    colorCode = category_info$colorCode,
    description = category_info$description,
    healthEffects = health_info$effects,
    recommendations = health_info$recommendations,
    input = input
  )
}