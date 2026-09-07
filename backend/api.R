# ===========================================================
# AirSense — api.R (Module 5: Backend API Development)
# R Plumber API that connects the frontend to the ML model.
# ===========================================================

# Auto-add local r_libs folder to library paths if present
possible_libs <- c("r_libs", "../r_libs", file.path(getwd(), "r_libs"), file.path(getwd(), "..", "r_libs"))
for (lib in possible_libs) {
  if (dir.exists(lib)) {
    .libPaths(c(normalizePath(lib), .libPaths()))
  }
}

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
  # Always ensure CORS headers on response
  res$setHeader("Access-Control-Allow-Origin", "*")
  res$setHeader("Access-Control-Allow-Methods", "POST, GET, OPTIONS")
  res$setHeader("Access-Control-Allow-Headers", "Content-Type, Authorization")

  body <- req$body

  if (is.character(body)) {
    try({ body <- jsonlite::fromJSON(body) }, silent = TRUE)
  }
  if (is.null(body) && !is.null(req$postBody)) {
    try({ body <- jsonlite::fromJSON(req$postBody) }, silent = TRUE)
  }
  if (is.data.frame(body) && nrow(body) > 0) {
    body <- as.list(body[1, ])
  }

  if (is.null(body)) {
    res$status <- 400
    return(list(error = "Empty or invalid JSON body provided."))
  }

  required <- c("pm25", "pm10", "no2", "so2", "co", "o3",
                "temperature", "humidity", "windSpeed")
  
  input <- list()
  for (f in required) {
    val <- body[[f]]
    if (is.null(val) || is.na(val)) {
      res$status <- 400
      return(list(error = paste("Missing required field:", f)))
    }
    num_val <- suppressWarnings(as.numeric(val))
    if (is.na(num_val)) {
      res$status <- 400
      return(list(error = paste("Field must be numeric:", f)))
    }
    input[[f]] <- num_val
  }

  if (!is.null(body$districtName)) {
    input$districtName <- as.character(body$districtName)
  }
  if (!is.null(body$isRealTime)) {
    input$isRealTime <- as.logical(body$isRealTime)
  }

  tryCatch({
    result <- predict_aqi(input)
    result
  }, error = function(e) {
    cat("Prediction Error:", conditionMessage(e), "\n")
    res$status <- 500
    list(error = paste("Prediction failed:", conditionMessage(e)))
  })
}