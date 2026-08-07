# ===========================================================
# AirSense — generate_dataset.R (Synthetic Data Generator)
# Generates a realistic, large dataset for model training
# to avoid NaN issues with tiny datasets during partitioning.
# Covers the full scale of AQI values (0 to 500).
# ===========================================================

set.seed(42)
n <- 1200 # slightly larger dataset for better training

# Wind speed: higher wind disperses pollutants
windSpeed <- runif(n, 1, 35)

# Temperature: 5 to 45 °C
temperature <- runif(n, 5, 45)

# Humidity: 10 to 100%
humidity <- runif(n, 10, 100)

# Generate features to represent extremely clean to extremely hazardous days
# Use exponent/mixture distributions to capture rare hazardous events and clean days.
pm25 <- (rgamma(n, shape = 1.5, rate = 0.03)) * (18 / windSpeed)^0.4
pm25 <- pmax(1.0, pmin(280.0, pm25))

# PM10
pm10 <- pm25 * runif(n, 1.1, 1.8) + (windSpeed * 0.4) + rnorm(n, 5, 3)
pm10 <- pmax(2.0, pmin(400.0, pm10))

# NO2
no2 <- (rgamma(n, shape = 2.0, rate = 0.05)) * (15 / windSpeed)^0.3
no2 <- pmax(1.0, pmin(120.0, no2))

# SO2
so2 <- (rgamma(n, shape = 1.2, rate = 0.1)) * (10 / windSpeed)^0.3
so2 <- pmax(0.2, pmin(80.0, so2))

# CO
co <- (pm25 * 0.03 + no2 * 0.02) * runif(n, 0.7, 1.3)
co <- pmax(0.05, pmin(15.0, co))

# O3: driven heavily by solar/temperature, peaks on hot stagnant days
o3 <- (temperature * 2.8) * (20 / windSpeed)^0.2 + rnorm(n, 10, 5)
o3 <- pmax(2.0, pmin(200.0, o3))

# Calculate AQI based on max EPA sub-indices style formula
pm25_sub <- pm25 * 1.5
pm10_sub <- pm10 * 0.8
no2_sub <- no2 * 2.2
so2_sub <- so2 * 4.2
co_sub <- co * 30.0
o3_sub <- o3 * 1.8

aqi_raw <- pmax(pm25_sub, pm10_sub, no2_sub, so2_sub, co_sub, o3_sub)

# Adjust for temperature & humidity (minor adjustments) + random normal noise
aqi <- aqi_raw + (temperature - 20) * 0.4 + (humidity - 50) * 0.15 + rnorm(n, 0, 8)
aqi <- pmax(5, pmin(495, aqi)) # Clamp to valid AQI scale [5, 495]
aqi <- round(aqi)

# Create the data frame in the exact required column order
df <- data.frame(
  pm25 = round(pm25, 1),
  pm10 = round(pm10, 1),
  no2 = round(no2, 1),
  so2 = round(so2, 1),
  co = round(co, 2),
  o3 = round(o3, 1),
  temperature = round(temperature, 1),
  humidity = round(humidity),
  windSpeed = round(windSpeed, 1),
  aqi = aqi
)

# Output dataset summary
message(sprintf("Generated synthetic air quality dataset with %d records.", nrow(df)))
message(sprintf("AQI range: %d to %d", min(df$aqi), max(df$aqi)))
message("AQI categories counts:")
categories <- cut(df$aqi, breaks = c(0, 50, 100, 150, 200, 300, 500),
                  labels = c("Good", "Moderate", "Sensitive", "Unhealthy", "Very Unhealthy", "Hazardous"))
print(table(categories))

# Save to destination folder
dir.create("dataset", showWarnings = FALSE)
write.csv(df, "dataset/air_quality.csv", row.names = FALSE)
message("Dataset saved successfully to 'dataset/air_quality.csv'")
