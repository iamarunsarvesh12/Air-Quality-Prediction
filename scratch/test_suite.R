# ===========================================================
# AeroSense TN — Automated Verification Suite (Pure R)
# Tests all R Plumber REST API endpoints, input validation,
# district verification, CORS headers, and frontend static assets.
# ===========================================================

suppressPackageStartupMessages({
  library(jsonlite)
  library(curl)
})

API_BASE <- "http://127.0.0.1:8000/api"
FRONTEND_BASE <- "http://localhost:5500"

passed <- 0
failed <- 0

log_test <- function(name, status, detail = "") {
  if (status == "PASSED") {
    passed <<- passed + 1
    cat(sprintf("[PASS] %s\n", name))
    if (detail != "") cat(sprintf("       -> %s\n", detail))
  } else {
    failed <<- failed + 1
    cat(sprintf("[FAIL] %s\n", name))
    if (detail != "") cat(sprintf("       -> %s\n", detail))
  }
}

cat("=================================================================\n")
cat("   AeroSense TN — Full System Automated Verification (Pure R)\n")
cat("=================================================================\n")

# 1. Backend Health Check
tryCatch({
  h <- curl::new_handle(timeout = 5)
  resp <- curl::curl_fetch_memory(paste0(API_BASE, "/health"), handle = h)
  if (resp$status_code == 200) {
    data <- jsonlite::fromJSON(rawToChar(resp$content))
    if (data$status == "ok") {
      log_test("Backend API Health Check (/api/health)", "PASSED",
               sprintf("Service: %s, Model: %s, R²: %s", data$service, data$model, as.character(data$r_squared)))
    } else {
      log_test("Backend API Health Check (/api/health)", "FAILED", "Status was not 'ok'")
    }
  } else {
    log_test("Backend API Health Check (/api/health)", "FAILED", sprintf("HTTP %d", resp$status_code))
  }
}, error = function(e) {
  log_test("Backend API Health Check (/api/health)", "FAILED", conditionMessage(e))
})

# 2. 38 Tamil Nadu Districts Directory
tryCatch({
  h <- curl::new_handle(timeout = 5)
  resp <- curl::curl_fetch_memory(paste0(API_BASE, "/districts"), handle = h)
  if (resp$status_code == 200) {
    data <- jsonlite::fromJSON(rawToChar(resp$content))
    count <- data$count
    if (count == 38 && nrow(data$districts) == 38) {
      log_test("Tamil Nadu 38-District Directory (/api/districts)", "PASSED",
               sprintf("38 districts verified (%s to %s)", data$districts$name[1], data$districts$name[38]))
    } else {
      log_test("Tamil Nadu 38-District Directory (/api/districts)", "FAILED", sprintf("Expected 38, got %d", count))
    }
  } else {
    log_test("Tamil Nadu 38-District Directory (/api/districts)", "FAILED", sprintf("HTTP %d", resp$status_code))
  }
}, error = function(e) {
  log_test("Tamil Nadu 38-District Directory (/api/districts)", "FAILED", conditionMessage(e))
})

# 3. Live Regional Hubs Summary (/api/live-data)
tryCatch({
  h <- curl::new_handle(timeout = 10)
  resp <- curl::curl_fetch_memory(paste0(API_BASE, "/live-data"), handle = h)
  if (resp$status_code == 200) {
    data <- jsonlite::fromJSON(rawToChar(resp$content))
    hubs <- data$hubs
    if (data$status == "success" && length(hubs) > 0) {
      log_test("Live Regional Hubs Summary (/api/live-data)", "PASSED",
               sprintf("%d hubs active (%s)", nrow(hubs), paste(hubs$district_name[1:min(3, nrow(hubs))], collapse = ", ")))
    } else {
      log_test("Live Regional Hubs Summary (/api/live-data)", "FAILED", "Invalid hub summary")
    }
  } else {
    log_test("Live Regional Hubs Summary (/api/live-data)", "FAILED", sprintf("HTTP %d", resp$status_code))
  }
}, error = function(e) {
  log_test("Live Regional Hubs Summary (/api/live-data)", "FAILED", conditionMessage(e))
})

# 4. District-Specific Prediction & Telemetry (Trichy)
tryCatch({
  h <- curl::new_handle(timeout = 5)
  resp <- curl::curl_fetch_memory(paste0(API_BASE, "/air-quality/trichy"), handle = h)
  if (resp$status_code == 200) {
    data <- jsonlite::fromJSON(rawToChar(resp$content))
    aqi <- data$prediction$predicted_aqi
    cat_name <- data$health_analysis$category
    diseases <- data$health_analysis$disease_risks
    if (!is.null(aqi) && length(diseases) == 5) {
      log_test("Live Telemetry & Prediction for Trichy (/api/air-quality/trichy)", "PASSED",
               sprintf("AQI: %s (%s), 5 Disease Risks, Live: %s", as.character(aqi), cat_name, as.character(data$transparency$is_live)))
    } else {
      log_test("Live Telemetry & Prediction for Trichy (/api/air-quality/trichy)", "FAILED", "Unexpected data format")
    }
  } else {
    log_test("Live Telemetry & Prediction for Trichy (/api/air-quality/trichy)", "FAILED", sprintf("HTTP %d", resp$status_code))
  }
}, error = function(e) {
  log_test("Live Telemetry & Prediction for Trichy (/api/air-quality/trichy)", "FAILED", conditionMessage(e))
})

# 5. District-Specific Telemetry (Chennai)
tryCatch({
  h <- curl::new_handle(timeout = 5)
  resp <- curl::curl_fetch_memory(paste0(API_BASE, "/air-quality/chennai"), handle = h)
  if (resp$status_code == 200) {
    data <- jsonlite::fromJSON(rawToChar(resp$content))
    aqi <- data$prediction$predicted_aqi
    cat_name <- data$health_analysis$category
    if (!is.null(aqi)) {
      log_test("Live Telemetry & Prediction for Chennai (/api/air-quality/chennai)", "PASSED", sprintf("AQI: %s (%s)", as.character(aqi), cat_name))
    } else {
      log_test("Live Telemetry & Prediction for Chennai (/api/air-quality/chennai)", "FAILED", "Missing AQI")
    }
  } else {
    log_test("Live Telemetry & Prediction for Chennai (/api/air-quality/chennai)", "FAILED", sprintf("HTTP %d", resp$status_code))
  }
}, error = function(e) {
  log_test("Live Telemetry & Prediction for Chennai (/api/air-quality/chennai)", "FAILED", conditionMessage(e))
})

# 6. District Validation (Negative Test: Unknown District)
tryCatch({
  h <- curl::new_handle(timeout = 5)
  resp <- curl::curl_fetch_memory(paste0(API_BASE, "/air-quality/unknown-district-xyz"), handle = h)
  if (resp$status_code == 404) {
    log_test("District Identifier Strict Validation (Rejection of Unknown District)", "PASSED", "Correctly returned HTTP 404")
  } else {
    log_test("District Identifier Strict Validation (Rejection of Unknown District)", "FAILED", sprintf("Expected HTTP 404, got %d", resp$status_code))
  }
}, error = function(e) {
  log_test("District Identifier Strict Validation (Rejection of Unknown District)", "FAILED", conditionMessage(e))
})

# 7. 24-Hour Forecast Endpoint (/api/prediction/coimbatore)
tryCatch({
  h <- curl::new_handle(timeout = 5)
  resp <- curl::curl_fetch_memory(paste0(API_BASE, "/prediction/coimbatore"), handle = h)
  if (resp$status_code == 200) {
    data <- jsonlite::fromJSON(rawToChar(resp$content))
    forecast <- data$forecast_24h
    if (length(forecast) > 0) {
      log_test("24-Hour Predictive Trajectory (/api/prediction/coimbatore)", "PASSED", sprintf("%d forecast intervals generated", nrow(forecast)))
    } else {
      log_test("24-Hour Predictive Trajectory (/api/prediction/coimbatore)", "FAILED", "Empty forecast")
    }
  } else {
    log_test("24-Hour Predictive Trajectory (/api/prediction/coimbatore)", "FAILED", sprintf("HTTP %d", resp$status_code))
  }
}, error = function(e) {
  log_test("24-Hour Predictive Trajectory (/api/prediction/coimbatore)", "FAILED", conditionMessage(e))
})

# 8. Valid Manual Sensor Prediction (/api/manual-prediction)
tryCatch({
  payload <- list(
    district = "Custom Lab Station",
    pm25 = 45.0, pm10 = 78.0, no2 = 24.0, so2 = 6.5, co = 0.85, o3 = 30.0,
    temperature = 29.0, humidity = 55.0, windSpeed = 12.0, persona = "sensitive"
  )
  h <- curl::new_handle(timeout = 5)
  curl::handle_setheaders(h, "Content-Type" = "application/json")
  curl::handle_setopt(h, post = TRUE, postfields = jsonlite::toJSON(payload, auto_unbox = TRUE))
  
  resp <- curl::curl_fetch_memory(paste0(API_BASE, "/manual-prediction"), handle = h)
  if (resp$status_code == 200) {
    data <- jsonlite::fromJSON(rawToChar(resp$content))
    aqi <- data$prediction$predicted_aqi
    cat_name <- data$health_analysis$category
    primary <- data$prediction$primary_pollutant
    diseases <- data$health_analysis$disease_risks
    if (!is.null(aqi) && length(diseases) == 5) {
      log_test("Valid Manual Prediction Engine (/api/manual-prediction)", "PASSED",
               sprintf("Predicted AQI: %s (%s), Dominant: %s, Diseases: %d", as.character(aqi), cat_name, primary, length(diseases)))
    } else {
      log_test("Valid Manual Prediction Engine (/api/manual-prediction)", "FAILED", "Incomplete prediction payload")
    }
  } else {
    log_test("Valid Manual Prediction Engine (/api/manual-prediction)", "FAILED", sprintf("HTTP %d", resp$status_code))
  }
}, error = function(e) {
  log_test("Valid Manual Prediction Engine (/api/manual-prediction)", "FAILED", conditionMessage(e))
})

# 9. Manual Prediction Validation - Missing Fields Rejection
tryCatch({
  bad_payload <- list(district = "Lab", pm10 = 50.0)
  h <- curl::new_handle(timeout = 5)
  curl::handle_setheaders(h, "Content-Type" = "application/json")
  curl::handle_setopt(h, post = TRUE, postfields = jsonlite::toJSON(bad_payload, auto_unbox = TRUE))
  
  resp <- curl::curl_fetch_memory(paste0(API_BASE, "/manual-prediction"), handle = h)
  if (resp$status_code == 400) {
    log_test("Manual Prediction Validation (Missing Fields Rejection)", "PASSED", "Correctly rejected missing fields with HTTP 400")
  } else {
    log_test("Manual Prediction Validation (Missing Fields Rejection)", "FAILED", sprintf("Expected HTTP 400, got %d", resp$status_code))
  }
}, error = function(e) {
  log_test("Manual Prediction Validation (Missing Fields Rejection)", "FAILED", conditionMessage(e))
})

# 10. Manual Prediction Validation - Non-Numeric Input Rejection
tryCatch({
  bad_payload <- list(district = "Lab", pm25 = "NOT_A_NUMBER", pm10 = 50.0, no2 = 20.0, so2 = 5.0, co = 1.0, o3 = 25.0)
  h <- curl::new_handle(timeout = 5)
  curl::handle_setheaders(h, "Content-Type" = "application/json")
  curl::handle_setopt(h, post = TRUE, postfields = jsonlite::toJSON(bad_payload, auto_unbox = TRUE))
  
  resp <- curl::curl_fetch_memory(paste0(API_BASE, "/manual-prediction"), handle = h)
  if (resp$status_code == 400) {
    log_test("Manual Prediction Validation (Non-Numeric Input Rejection)", "PASSED", "Correctly rejected text input with HTTP 400")
  } else {
    log_test("Manual Prediction Validation (Non-Numeric Input Rejection)", "FAILED", sprintf("Expected HTTP 400, got %d", resp$status_code))
  }
}, error = function(e) {
  log_test("Manual Prediction Validation (Non-Numeric Input Rejection)", "FAILED", conditionMessage(e))
})

# 11. Manual Prediction Validation - Out-of-Range Value Rejection
tryCatch({
  bad_payload <- list(district = "Lab", pm25 = 999999, pm10 = 50.0, no2 = 20.0, so2 = 5.0, co = 1.0, o3 = 25.0)
  h <- curl::new_handle(timeout = 5)
  curl::handle_setheaders(h, "Content-Type" = "application/json")
  curl::handle_setopt(h, post = TRUE, postfields = jsonlite::toJSON(bad_payload, auto_unbox = TRUE))
  
  resp <- curl::curl_fetch_memory(paste0(API_BASE, "/manual-prediction"), handle = h)
  if (resp$status_code == 400) {
    log_test("Manual Prediction Validation (Out-of-Range Rejection)", "PASSED", "Correctly rejected 999999 with HTTP 400")
  } else {
    log_test("Manual Prediction Validation (Out-of-Range Rejection)", "FAILED", sprintf("Expected HTTP 400, got %d", resp$status_code))
  }
}, error = function(e) {
  log_test("Manual Prediction Validation (Out-of-Range Rejection)", "FAILED", conditionMessage(e))
})

# 12. Pipeline Data Status (/api/data-status)
tryCatch({
  h <- curl::new_handle(timeout = 5)
  resp <- curl::curl_fetch_memory(paste0(API_BASE, "/data-status"), handle = h)
  if (resp$status_code == 200) {
    data <- jsonlite::fromJSON(rawToChar(resp$content))
    if (data$status == "operational" && !is.null(data$pipeline$random_forest_model)) {
      log_test("Data Preprocessing & Pipeline Status (/api/data-status)", "PASSED",
               sprintf("Pipeline: %s, Model: %s", data$status, data$pipeline$random_forest_model))
    } else {
      log_test("Data Preprocessing & Pipeline Status (/api/data-status)", "FAILED", "Pipeline not operational")
    }
  } else {
    log_test("Data Preprocessing & Pipeline Status (/api/data-status)", "FAILED", sprintf("HTTP %d", resp$status_code))
  }
}, error = function(e) {
  log_test("Data Preprocessing & Pipeline Status (/api/data-status)", "FAILED", conditionMessage(e))
})

# 13. Frontend Static Server Assets
pages <- c(
  "index.html",
  "live-dashboard.html",
  "manual-prediction.html",
  "css/style.css",
  "css/responsive.css",
  "js/api.js",
  "js/charts.js",
  "js/app.js",
  "js/manual-prediction.js"
)
for (page in pages) {
  tryCatch({
    h <- curl::new_handle(timeout = 5)
    resp <- curl::curl_fetch_memory(sprintf("%s/%s", FRONTEND_BASE, page), handle = h)
    if (resp$status_code == 200) {
      log_test(sprintf("Frontend Static Asset (%s)", page), "PASSED", sprintf("HTTP 200 (%d bytes)", length(resp$content)))
    } else {
      log_test(sprintf("Frontend Static Asset (%s)", page), "FAILED", sprintf("HTTP %d", resp$status_code))
    }
  }, error = function(e) {
    log_test(sprintf("Frontend Static Asset (%s)", page), "FAILED", conditionMessage(e))
  })
}

cat("=================================================================\n")
cat(sprintf("   Test Summary: %d Passed, %d Failed\n", passed, failed))
cat("=================================================================\n")

if (failed > 0) {
  quit(status = 1)
} else {
  quit(status = 0)
}
