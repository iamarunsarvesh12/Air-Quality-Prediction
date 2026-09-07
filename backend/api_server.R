# ===========================================================
# AeroSense TN — api_server.R (Plumber REST API Controller)
# Exposes clean REST API endpoints for Frontend consumption
# ===========================================================

# Manage library paths
possible_libs <- c("r_libs", "../r_libs", "backend/r_libs", file.path(getwd(), "r_libs"))
for (lib in possible_libs) {
  if (dir.exists(lib)) {
    .libPaths(c(normalizePath(lib), .libPaths()))
  }
}

library(plumber)
library(jsonlite)

# Load modular components with directory resolution
get_script_dir <- function() {
  candidates <- c("backend", ".", file.path(getwd(), "backend"))
  for (c in candidates) {
    if (file.exists(file.path(c, "data_fetcher.R"))) return(c)
  }
  "."
}
s_dir <- get_script_dir()
source(file.path(s_dir, "data_fetcher.R"), local = TRUE)
source(file.path(s_dir, "data_preprocessing.R"), local = TRUE)
source(file.path(s_dir, "feature_engineering.R"), local = TRUE)
source(file.path(s_dir, "prediction_model.R"), local = TRUE)
source(file.path(s_dir, "health_risk_engine.R"), local = TRUE)

#* @apiTitle AeroSense TN — Tamil Nadu Air Quality & Disease Predictor API
#* @apiDescription R Plumber REST API providing real-time air quality telemetry, Random Forest AQI predictions, 24h forecasting, and disease risk intelligence across Tamil Nadu districts.
#* @apiVersion 2.0.0

#* Enable Cross-Origin Resource Sharing (CORS)
#* @filter cors
function(req, res) {
  res$setHeader("Access-Control-Allow-Origin", "*")
  res$setHeader("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
  res$setHeader("Access-Control-Allow-Headers", "Content-Type, Authorization, X-Requested-With")
  
  if (req$REQUEST_METHOD == "OPTIONS") {
    res$status <- 200
    return(list())
  }
  
  plumber::forward()
}

#* System Health & Readiness Check
#* @serializer unboxedJSON
#* @get /api/health
function() {
  list(
    status = "ok",
    service = "AeroSense TN API Engine",
    version = "2.0.0",
    r_version = R.version.string,
    model = "RandomForest (R randomForest 4.7)",
    districts_supported = length(get_all_districts()),
    timestamp = format(Sys.time(), "%Y-%m-%dT%H:%M:%S%z")
  )
}

#* Get All 38 Tamil Nadu Districts Directory
#* @serializer unboxedJSON
#* @get /api/districts
function() {
  list(
    status = "success",
    count = length(get_all_districts()),
    districts = get_all_districts()
  )
}

#* Get Live Air Quality Summary for All Major Tamil Nadu Hubs
#* @serializer unboxedJSON
#* @get /api/live-data
function() {
  districts <- get_all_districts()
  major_ids <- c("trichy", "chennai", "coimbatore", "madurai", "salem", "tirunelveli", "erode", "vellore")
  
  hub_data <- lapply(districts, function(d) {
    if (d$id %in% major_ids) {
      raw <- fetch_district_air_quality(d$id)
      pre <- preprocess_air_quality_data(c(raw$pollutants, raw$weather))
      feat <- engineer_features(pre$cleaned_data)
      pred <- run_aqi_prediction(feat$model_df, raw$pollutants, raw$weather)
      health <- analyze_health_risks(pred$predicted_aqi, pred$primary_pollutant)
      
      list(
        district_id = d$id,
        district_name = d$name,
        zone = d$zone,
        aqi = pred$predicted_aqi,
        category = health$category,
        color = health$color,
        primary_pollutant = pred$primary_pollutant,
        is_live = raw$transparency$is_live
      )
    } else {
      NULL
    }
  })
  
  # Remove nulls
  hub_data <- hub_data[!sapply(hub_data, is.null)]
  
  list(
    status = "success",
    timestamp = format(Sys.time(), "%Y-%m-%dT%H:%M:%S%z"),
    hubs = hub_data
  )
}

#* Get Full Air Quality, Prediction & Health Risk for a Specific District
#* @serializer unboxedJSON
#* @get /api/air-quality/<district>
function(district, persona = "general") {
  raw_feed <- fetch_district_air_quality(district)
  
  # Preprocessing
  raw_input <- c(raw_feed$pollutants, raw_feed$weather)
  prep_result <- preprocess_air_quality_data(raw_input)
  
  # Feature Engineering
  feat_result <- engineer_features(prep_result$cleaned_data)
  
  # Prediction Model
  pred_result <- run_aqi_prediction(feat_result$model_df, raw_feed$pollutants, raw_feed$weather)
  
  # Health Risk Engine
  health_result <- analyze_health_risks(pred_result$predicted_aqi, pred_result$primary_pollutant, persona)
  
  list(
    status = "success",
    district_id = raw_feed$district_id,
    district_name = raw_feed$district_name,
    zone = raw_feed$zone,
    coordinates = raw_feed$coordinates,
    pollutants = raw_feed$pollutants,
    weather = raw_feed$weather,
    transparency = raw_feed$transparency,
    preprocessing = list(
      pipeline_stages = prep_result$pipeline_stages,
      issues_treated = prep_result$issues
    ),
    prediction = list(
      predicted_aqi = pred_result$predicted_aqi,
      primary_pollutant = pred_result$primary_pollutant,
      horizon = pred_result$prediction_horizon,
      model_metadata = pred_result$model_metadata,
      forecast_24h = pred_result$forecast_24h
    ),
    health_analysis = list(
      category = health_result$category,
      color = health_result$color,
      bg_color = health_result$bg_color,
      risk_level = health_result$risk_level,
      summary = health_result$summary,
      general_advice = health_result$general_advice,
      disease_risks = health_result$disease_risks,
      persona_recommendation = health_result$persona_recommendation,
      disclaimer = health_result$disclaimer
    )
  )
}

#* Get 24-Hour Forecast & Prediction for a District
#* @serializer unboxedJSON
#* @get /api/prediction/<district>
function(district) {
  raw_feed <- fetch_district_air_quality(district)
  prep_result <- preprocess_air_quality_data(c(raw_feed$pollutants, raw_feed$weather))
  feat_result <- engineer_features(prep_result$cleaned_data)
  pred_result <- run_aqi_prediction(feat_result$model_df, raw_feed$pollutants, raw_feed$weather)
  
  list(
    status = "success",
    district_name = raw_feed$district_name,
    predicted_aqi = pred_result$predicted_aqi,
    primary_pollutant = pred_result$primary_pollutant,
    horizon = pred_result$prediction_horizon,
    model_metadata = pred_result$model_metadata,
    forecast_24h = pred_result$forecast_24h
  )
}

#* Execute Manual Air Quality Prediction from User Inputs
#* @serializer unboxedJSON
#* @post /api/manual-prediction
function(req, res) {
  # Parse body
  body <- req$body
  if (is.character(body)) {
    body <- tryCatch(jsonlite::fromJSON(body), error = function(e) list())
  }
  if (is.data.frame(body)) {
    body <- as.list(body[1, , drop = FALSE])
  }
  
  persona <- if (!is.null(body$persona) && body$persona != "") body$persona else "general"
  district_name <- if (!is.null(body$district) && body$district != "") body$district else "Custom Station"
  
  # Validate required fields
  required_fields <- c("pm25", "pm10", "no2", "so2", "co", "o3")
  for (f in required_fields) {
    if (is.null(body[[f]]) || is.na(body[[f]])) {
      res$status <- 400
      res$setHeader("Access-Control-Allow-Origin", "*")
      return(list(error = paste("Missing required parameter:", f)))
    }
  }
  
  # Preprocess
  prep_result <- preprocess_air_quality_data(body)
  
  # Feature Engineering
  feat_result <- engineer_features(prep_result$cleaned_data)
  
  # Prediction Model
  pred_result <- run_aqi_prediction(feat_result$model_df, body, body)
  
  # Health Analysis
  health_result <- analyze_health_risks(pred_result$predicted_aqi, pred_result$primary_pollutant, persona)
  
  list(
    status = "success",
    data_status = "manual",
    district_name = district_name,
    timestamp = format(Sys.time(), "%Y-%m-%dT%H:%M:%S%z"),
    timestamp_display = format(Sys.time(), "%b %d, %Y - %I:%M %p IST"),
    input_values = prep_result$cleaned_data,
    preprocessing = list(
      pipeline_stages = prep_result$pipeline_stages,
      issues_treated = prep_result$issues
    ),
    prediction = list(
      predicted_aqi = pred_result$predicted_aqi,
      primary_pollutant = pred_result$primary_pollutant,
      horizon = "Instantaneous Custom Prediction",
      model_metadata = pred_result$model_metadata,
      forecast_24h = pred_result$forecast_24h
    ),
    health_analysis = list(
      category = health_result$category,
      color = health_result$color,
      bg_color = health_result$bg_color,
      risk_level = health_result$risk_level,
      summary = health_result$summary,
      general_advice = health_result$general_advice,
      disease_risks = health_result$disease_risks,
      persona_recommendation = health_result$persona_recommendation,
      disclaimer = health_result$disclaimer
    )
  )
}

#* Get Preprocessing & System Data Status
#* @serializer unboxedJSON
#* @get /api/data-status
function() {
  list(
    status = "operational",
    pipeline = list(
      raw_ingestion = "Active",
      missing_value_imputation = "Active",
      outlier_normalization = "Active",
      feature_engineering = "Active",
      random_forest_model = "Loaded (R 4.7)",
      health_risk_engine = "Active (Indian NAAQS)"
    ),
    active_districts = length(get_all_districts()),
    data_sources = list(
      primary = "Open-Meteo Air Quality Telemetry",
      secondary = "Central Pollution Control Board (CPCB) Station Network Baseline",
      fallback = "District Geographic Baseline Generator"
    ),
    server_time = format(Sys.time(), "%Y-%m-%dT%H:%M:%S%z")
  )
}
