# ===========================================================
# AeroSense TN — feature_engineering.R (Module 3: Feature Engineering)
# Extracts meteorological & pollutant interaction features for ML inference
# ===========================================================

#' Engineer features for prediction model
#'
#' @param cleaned_data Preprocessed pollutant and weather data
#' @return List with feature data frame and feature metadata
engineer_features <- function(cleaned_data) {
  pm25 <- cleaned_data$pm25
  pm10 <- cleaned_data$pm10
  no2 <- cleaned_data$no2
  so2 <- cleaned_data$so2
  co <- cleaned_data$co
  o3 <- cleaned_data$o3
  temp <- cleaned_data$temperature
  humidity <- cleaned_data$humidity
  wind <- cleaned_data$windSpeed
  
  # Engineered metrics
  pm_ratio <- if (pm10 > 0) round(pm25 / pm10, 3) else 0.5
  gaseous_sum <- round(no2 + so2 + o3, 2)
  combustion_index <- round((co * 10) + no2, 2)
  dispersion_index <- if (wind > 0) round(100 / (wind + 1), 2) else 10.0
  heat_stress_index <- round(temp + (0.5555 * ((humidity / 100 * 6.112 * exp((17.67 * temp) / (temp + 243.5))) - 10)), 1)
  
  # Data frame formatted for Random Forest model
  model_df <- data.frame(
    pm25 = pm25,
    pm10 = pm10,
    no2 = no2,
    so2 = so2,
    co = co,
    o3 = o3,
    temperature = temp,
    humidity = humidity,
    windSpeed = wind,
    stringsAsFactors = FALSE
  )
  
  list(
    model_df = model_df,
    engineered_features = list(
      pm_ratio = pm_ratio,
      gaseous_sum = gaseous_sum,
      combustion_index = combustion_index,
      dispersion_index = dispersion_index,
      heat_stress_index = heat_stress_index
    )
  )
}
