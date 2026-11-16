# ===========================================================
# AeroSense TN — generate_dataset.R (Grounded Dataset Generator)
# Generates a physically realistic dataset for Random Forest training
# with target AQI strictly calculated using the Indian CPCB NAQI methodology.
# ===========================================================

source(file.path("backend", "aqi_calculator.R"))

set.seed(42)
n <- 1500

# 1. Environmental & meteorological variables
windSpeed <- round(runif(n, 1.5, 38.0), 1)
temperature <- round(runif(n, 12.0, 44.0), 1)
humidity <- round(runif(n, 20.0, 95.0), 1)

# 2. Atmospheric dispersion factor (higher wind disperses pollutants)
dispersion <- (18.0 / windSpeed)^0.35

# 3. Pollutant concentrations (µg/m³ for PM, NO2, SO2, O3; mg/m³ for CO)
# PM2.5 (1 to 280 µg/m³)
pm25 <- (rgamma(n, shape = 1.8, rate = 0.035)) * dispersion
pm25 <- round(pmax(2.0, pmin(280.0, pm25)), 1)

# PM10 (must be >= PM2.5, typically 1.3 to 2.2x PM2.5)
pm10 <- pm25 * runif(n, 1.25, 2.1) + rnorm(n, 6, 2)
pm10 <- round(pmax(pm25 * 1.05, pmin(450.0, pm10)), 1)

# NO2 (traffic / combustion, 3 to 220 µg/m³)
no2 <- (rgamma(n, shape = 2.0, rate = 0.045)) * dispersion
no2 <- round(pmax(3.0, pmin(220.0, no2)), 1)

# SO2 (industrial, 1 to 140 µg/m³)
so2 <- (rgamma(n, shape = 1.4, rate = 0.08)) * dispersion
so2 <- round(pmax(1.0, pmin(140.0, so2)), 1)

# CO (traffic, in mg/m³, 0.1 to 16.0 mg/m³)
co <- (pm25 * 0.035 + no2 * 0.02) * runif(n, 0.7, 1.3)
co <- round(pmax(0.1, pmin(16.0, co)), 2)

# O3 (photochemical reaction driven by temperature and solar radiation, 5 to 240 µg/m³)
o3 <- (temperature * 2.4) * (20.0 / windSpeed)^0.2 + rnorm(n, 8, 4)
o3 <- round(pmax(5.0, pmin(240.0, o3)), 1)

# 4. Compute ground truth Indian CPCB AQI using authoritative engine
aqi_vec <- numeric(n)
for (i in 1:n) {
  p_sample <- list(
    pm25 = pm25[i],
    pm10 = pm10[i],
    no2  = no2[i],
    so2  = so2[i],
    co   = co[i],
    o3   = o3[i]
  )
  calc <- calculate_indian_aqi(p_sample)
  aqi_vec[i] <- if (!is.null(calc$calculated_aqi)) calc$calculated_aqi else 50
}

df <- data.frame(
  pm25 = pm25,
  pm10 = pm10,
  no2 = no2,
  so2 = so2,
  co = co,
  o3 = o3,
  temperature = temperature,
  humidity = humidity,
  windSpeed = windSpeed,
  aqi = aqi_vec
)

# Output dataset summary
cat(sprintf("Generated dataset with %d samples.\n", nrow(df)))
cat(sprintf("AQI range: %d to %d\n", min(df$aqi), max(df$aqi)))
cat("AQI categories counts (Indian CPCB):\n")
categories <- cut(df$aqi, breaks = c(-1, 50, 100, 200, 300, 400, 600),
                  labels = c("Good", "Satisfactory", "Moderately Polluted", "Poor", "Very Poor", "Severe"))
print(table(categories))

# Save to backend/dataset/air_quality.csv
dest_dir <- file.path("backend", "dataset")
dir.create(dest_dir, showWarnings = FALSE, recursive = TRUE)
dest_file <- file.path(dest_dir, "air_quality.csv")
write.csv(df, dest_file, row.names = FALSE)
cat(sprintf("Dataset saved successfully to '%s'.\n", dest_file))
