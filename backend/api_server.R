# ===========================================================
# AeroSense TN — api_server.R (Plumber REST API Controller)
# Exposes clean, validated, scientifically sound REST API endpoints
# for Frontend consumption, health intelligence, and manual predictions.
# ===========================================================

# Manage library paths
possible_libs <- c("r_libs", "../r_libs", "backend/r_libs", file.path(getwd(), "r_libs"), file.path(getwd(), "backend", "r_libs"))
for (lib in possible_libs) {
  if (dir.exists(lib)) {
    .libPaths(c(normalizePath(lib), .libPaths()))
  }
}

suppressPackageStartupMessages({
  library(plumber)
  library(jsonlite)
})

# Load modular components with directory resolution
get_script_dir <- function() {
  candidates <- c("backend", ".", file.path(getwd(), "backend"), "..")
  for (c in candidates) {
    if (file.exists(file.path(c, "data_fetcher.R"))) return(c)
  }
  "."
}
s_dir <- get_script_dir()
source(file.path(s_dir, "aqi_calculator.R"), local = TRUE)
source(file.path(s_dir, "telemetry_store.R"), local = TRUE)
source(file.path(s_dir, "data_fetcher.R"), local = TRUE)
source(file.path(s_dir, "data_preprocessing.R"), local = TRUE)
source(file.path(s_dir, "feature_engineering.R"), local = TRUE)
source(file.path(s_dir, "prediction_model.R"), local = TRUE)
source(file.path(s_dir, "health_risk_engine.R"), local = TRUE)

#* @apiTitle AeroSense TN — Tamil Nadu Air Quality & Health Risk API
#* @apiDescription R Plumber REST API providing real-time air quality telemetry, Random Forest AQI predictions, 24h forecasting, and health risk intelligence across Tamil Nadu districts.
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
function(res) {
  meta <- get_model_metadata()
  pipe_status <- get_telemetry_pipeline_status()
  
  list(
    status = "ok",
    service = "AeroSense TN API Engine",
    version = "2.0.0",
    r_version = R.version.string,
    model = "RandomForest (R randomForest 4.7)",
    r_squared = meta$r_squared,
    rmse = meta$rmse,
    mae = meta$mae,
    districts_supported = length(get_all_districts()),
    pipeline_state = pipe_status$status,
    timestamp = format(Sys.time(), "%Y-%m-%dT%H:%M:%S%z")
  )
}

#* Get All 38 Tamil Nadu Districts Directory
#* @serializer unboxedJSON
#* @get /api/districts
function(res) {
  districts <- get_all_districts()
  list(
    status = "success",
    count = length(districts),
    districts = districts
  )
}

#* Get Live Air Quality Summary for All 38 Tamil Nadu Districts
#* @serializer unboxedJSON
#* @get /api/live-data
function(res) {
  # Ensure telemetry cache is refreshed
  refresh_all_districts_telemetry(force = FALSE)
  districts <- get_all_districts()
  now <- Sys.time()
  
  # Process all 38 districts
  all_data <- lapply(districts, function(d) {
    raw <- fetch_district_air_quality(d$id)
    if (is.null(raw)) return(NULL)
    
    # Feature engineering for RF prediction
    raw_input <- c(raw$pollutants, raw$weather)
    prep <- preprocess_air_quality_data(raw_input)
    feat <- engineer_features(prep$cleaned_data)
    pred <- run_aqi_prediction(feat$model_df, raw$pollutants, raw$weather)
    health <- analyze_health_risks(pred$predicted_aqi, pred$primary_pollutant)
    
    # Established AQI: calculated CPCB AQI if available, else predicted AQI
    effective_aqi <- if (!is.null(raw$cpcb_aqi$calculated_aqi) && !is.na(raw$cpcb_aqi$calculated_aqi)) {
      round(raw$cpcb_aqi$calculated_aqi)
    } else {
      round(pred$predicted_aqi)
    }
    
    list(
      district_id = d$id,
      district_name = d$name,
      zone = d$zone,
      coordinates = list(latitude = d$lat, longitude = d$lng),
      aqi = effective_aqi,
      calculated_aqi = raw$cpcb_aqi$calculated_aqi,
      predicted_aqi = pred$predicted_aqi,
      category = health$category,
      color = health$color,
      bg_color = health$bg_color,
      risk_level = health$risk_level,
      primary_pollutant = pred$primary_pollutant,
      is_live = isTRUE(raw$transparency$is_live),
      data_status = raw$transparency$data_status,
      observation_timestamp = raw$transparency$observation_timestamp_ist
    )
  })
  
  all_data <- all_data[!sapply(all_data, is.null)]
  pipe_status <- get_telemetry_pipeline_status()
  
  list(
    status = "success",
    timestamp = format(now, "%Y-%m-%dT%H:%M:%S%z"),
    telemetry_source = pipe_status$provider,
    districts_count = length(all_data),
    hubs = all_data  # Backward-compatible hubs array containing all districts
  )
}

#* Get Full Air Quality, Prediction & Health Risk for a Specific District
#* @serializer unboxedJSON
#* @get /api/air-quality/<district>
function(district, persona = "general", res) {
  # Strict district validation
  raw_feed <- fetch_district_air_quality(district)
  if (is.null(raw_feed)) {
    res$status <- 404
    return(list(
      status = "error",
      error = sprintf("District '%s' not recognized. Please provide a valid Tamil Nadu district ID or name.", district)
    ))
  }
  
  # Preprocessing
  raw_input <- c(raw_feed$pollutants, raw_feed$weather)
  prep_result <- preprocess_air_quality_data(raw_input)
  
  # Feature Engineering
  feat_result <- engineer_features(prep_result$cleaned_data)
  
  # Fetch 24-hour hourly forecast
  hourly_fc <- fetch_district_hourly_forecast(raw_feed$district_id)
  
  # ML Prediction Model
  pred_result <- run_aqi_prediction(feat_result$model_df, raw_feed$pollutants, raw_feed$weather, hourly_fc)
  
  # Health Risk Engine
  effective_aqi <- if (!is.null(raw_feed$cpcb_aqi$calculated_aqi) && !is.na(raw_feed$cpcb_aqi$calculated_aqi)) {
    raw_feed$cpcb_aqi$calculated_aqi
  } else {
    pred_result$predicted_aqi
  }
  health_result <- analyze_health_risks(effective_aqi, pred_result$primary_pollutant, persona)
  
  list(
    status = "success",
    district_id = raw_feed$district_id,
    district_name = raw_feed$district_name,
    zone = raw_feed$zone,
    coordinates = raw_feed$coordinates,
    pollutants = raw_feed$pollutants,
    weather = raw_feed$weather,
    cpcb_aqi = raw_feed$cpcb_aqi,
    transparency = raw_feed$transparency,
    preprocessing = list(
      pipeline_stages = prep_result$pipeline_stages,
      missing_fields = prep_result$missing_fields,
      issues_treated = prep_result$issues
    ),
    prediction = list(
      calculated_aqi = raw_feed$cpcb_aqi$calculated_aqi,
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
function(district, res) {
  raw_feed <- fetch_district_air_quality(district)
  if (is.null(raw_feed)) {
    res$status <- 404
    return(list(
      status = "error",
      error = sprintf("District '%s' not recognized. Please provide a valid Tamil Nadu district ID or name.", district)
    ))
  }
  
  hourly_fc <- fetch_district_hourly_forecast(raw_feed$district_id)
  prep_result <- preprocess_air_quality_data(c(raw_feed$pollutants, raw_feed$weather))
  feat_result <- engineer_features(prep_result$cleaned_data)
  pred_result <- run_aqi_prediction(feat_result$model_df, raw_feed$pollutants, raw_feed$weather, hourly_fc)
  
  list(
    status = "success",
    district_id = raw_feed$district_id,
    district_name = raw_feed$district_name,
    calculated_aqi = raw_feed$cpcb_aqi$calculated_aqi,
    predicted_aqi = pred_result$predicted_aqi,
    primary_pollutant = pred_result$primary_pollutant,
    horizon = hourly_fc$forecast_horizon,
    source = hourly_fc$forecast_source,
    generated_at = hourly_fc$generated_at,
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
  if (!is.list(body) || length(body) == 0) {
    res$status <- 400
    return(list(status = "error", error = "Empty or invalid JSON body provided."))
  }
  
  persona <- if (!is.null(body$persona) && body$persona != "") as.character(body$persona) else "general"
  district_name <- if (!is.null(body$district) && body$district != "") as.character(body$district) else "Custom Lab Station"
  
  # Physical validation bounds for manual inputs
  BOUNDS <- list(
    pm25        = list(min = 0, max = 1000, label = "PM2.5 (µg/m³)"),
    pm10        = list(min = 0, max = 1500, label = "PM10 (µg/m³)"),
    no2         = list(min = 0, max = 500,  label = "NO₂ (µg/m³)"),
    so2         = list(min = 0, max = 500,  label = "SO₂ (µg/m³)"),
    co          = list(min = 0, max = 50,   label = "CO (mg/m³)"),
    o3          = list(min = 0, max = 500,  label = "O₃ (µg/m³)"),
    temperature = list(min = -10, max = 60, label = "Temperature (°C)"),
    humidity    = list(min = 0, max = 100,  label = "Humidity (%)"),
    windSpeed   = list(min = 0, max = 150,  label = "Wind Speed (km/h)")
  )
  
  required_fields <- c("pm25", "pm10", "no2", "so2", "co", "o3")
  
  # Check missing required fields
  for (f in required_fields) {
    if (is.null(body[[f]]) || is.na(body[[f]]) || body[[f]] == "") {
      res$status <- 400
      return(list(status = "error", error = paste("Missing required parameter:", f)))
    }
  }
  
  # Validate numeric types and ranges
  for (f in names(BOUNDS)) {
    val <- body[[f]]
    if (f == "windSpeed" && is.null(val) && !is.null(body$wind_speed)) {
      val <- body$wind_speed
    }
    
    if (!is.null(val) && !is.na(val) && val != "") {
      num_val <- suppressWarnings(as.numeric(val))
      if (is.na(num_val) || is.nan(num_val)) {
        res$status <- 400
        return(list(status = "error", error = paste("Field must be a valid numeric value:", f)))
      }
      
      b <- BOUNDS[[f]]
      if (num_val < b$min || num_val > b$max) {
        res$status <- 400
        return(list(status = "error", error = sprintf("%s is out of physical range (value: %s, permitted: %g to %g).", b$label, as.character(val), b$min, b$max)))
      }
    }
  }
  
  # Preprocess
  prep_result <- preprocess_air_quality_data(body)
  
  # Feature Engineering
  feat_result <- engineer_features(prep_result$cleaned_data)
  
  # ML Prediction Model & Indian CPCB calculation
  pred_result <- run_aqi_prediction(feat_result$model_df, body, body, hourly_forecast = NULL)
  
  # Health Analysis
  effective_aqi <- if (!is.null(pred_result$calculated_aqi) && !is.na(pred_result$calculated_aqi)) {
    pred_result$calculated_aqi
  } else {
    pred_result$predicted_aqi
  }
  health_result <- analyze_health_risks(effective_aqi, pred_result$primary_pollutant, persona)
  
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
      calculated_aqi = pred_result$calculated_aqi,
      predicted_aqi = pred_result$predicted_aqi,
      primary_pollutant = pred_result$primary_pollutant,
      cpcb_eligibility = pred_result$cpcb_eligibility,
      sub_indices = pred_result$sub_indices,
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

#* Get Preprocessing & Pipeline Data Status
#* @serializer unboxedJSON
#* @get /api/data-status
function(res) {
  meta <- get_model_metadata()
  pipe_status <- get_telemetry_pipeline_status()
  
  list(
    status = pipe_status$status,
    pipeline = list(
      raw_ingestion = "Active (Batch Telemetry Ingestion)",
      cpcb_aqi_engine = "Active (Indian CPCB NAAQS 2014)",
      missing_value_imputation = "Active",
      outlier_normalization = "Active",
      feature_engineering = "Active",
      random_forest_model = "Loaded (R 4.7)",
      health_risk_engine = "Active (Indian CPCB Categories)"
    ),
    model_metrics = list(
      r_squared = meta$r_squared,
      rmse = meta$rmse,
      mae = meta$mae
    ),
    active_districts = length(get_all_districts()),
    data_sources = list(
      primary = "Open-Meteo Air Quality Telemetry Network (CAMS Global)",
      secondary = "AeroSense TN Persistent Telemetry Store",
      weather = "Open-Meteo Atmospheric Weather API"
    ),
    telemetry_pipeline = pipe_status,
    server_time = format(Sys.time(), "%Y-%m-%dT%H:%M:%S%z")
  )
}
