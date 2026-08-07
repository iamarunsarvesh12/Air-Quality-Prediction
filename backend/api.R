# ===========================================================
# AirSense — api.R (Module 5: Backend API Development)
# R Plumber API that connects the frontend to the ML model.
# ===========================================================

library(plumber)

if (file.exists("predict.R")) {
  source("predict.R")
} else if (file.exists("backend/predict.R")) {
  source("backend/predict.R")
} else {
  source("predict.R")
}

#* Enable CORS headers correctly across all incoming paths
#* @filter cors
function(req, res) {
  res$setHeader("Access-Control-Allow-Origin", "*")
  res$setHeader("Access-Control-Allow-Methods", "POST, GET, OPTIONS")
  res$setHeader("Access-Control-Allow-Headers", "Content-Type, Authorization")
  
  if (req$REQUEST_METHOD == "OPTIONS") {
    res$status <- 200
    return(list())
  }
  
  plumber::forward()
}

#* Health check
#* @get /health
#* @serializer json list(auto_unbox = TRUE)
function() {
  list(status = "ok", message = "AirSense API is running")
}

#* Predict AQI from pollutant + weather readings
#* @parser json
#* @serializer json list(auto_unbox = TRUE)
#* @post /predict
function(req, res) {
  body <- req$body

  if (is.null(body) && !is.null(req$postBody)) {
    try({
      body <- jsonlite::fromJSON(req$postBody)
    }, silent = TRUE)
  }

  required <- c("pm25", "pm10", "no2", "so2", "co", "o3",
                "temperature", "humidity", "windSpeed")
  missing <- setdiff(required, names(body))

  if (length(missing) > 0) {
    res$status <- 400
    return(list(error = paste("Missing fields:", paste(missing, collapse = ", "))))
  }

  input <- lapply(body[required], as.numeric)

  tryCatch({
    result <- predict_aqi(input)
    result
  }, error = function(e) {
    res$status <- 500
    list(error = paste("Prediction failed:", conditionMessage(e)))
  })
}