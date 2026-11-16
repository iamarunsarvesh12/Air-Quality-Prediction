source("backend/telemetry_store.R")

cat("--- Testing Telemetry Store ---\n")
init_telemetry_store()
stats_initial <- get_telemetry_store_stats()
cat(sprintf("Initial records in store: %d\n", stats_initial$total_records))

# Test appending dummy records
rec1 <- data.frame(
  record_id = "trichy_2026-10-23T10:00:00",
  district_id = "trichy",
  district_name = "Tiruchirappalli (Trichy)",
  latitude = 10.7905,
  longitude = 78.7047,
  zone = "Central TN",
  observation_time = "2026-10-23T10:00:00",
  observation_time_ist = "Oct 23, 2026 - 03:30 PM IST",
  retrieval_time = format(Sys.time(), "%Y-%m-%dT%H:%M:%S%z"),
  source_name = "Open-Meteo Air Quality Telemetry Network",
  data_type = "Gridded Atmospheric Telemetry",
  data_status = "live",
  pm25 = 28.5,
  pm10 = 55.2,
  no2 = 18.4,
  so2 = 6.2,
  co = 0.45,
  o3 = 45.0,
  nh3 = 8.1,
  temperature = 31.0,
  humidity = 65.0,
  wind_speed = 12.0,
  calculated_aqi = 55,
  dominant_pollutant = "PM10",
  aqi_category = "Satisfactory",
  is_official_eligible = TRUE,
  stringsAsFactors = FALSE
)

added <- append_telemetry_records(rec1)
cat(sprintf("Added records on first insert: %d\n", added))
stopifnot(added == 1)

# Duplicate insert test: should add 0
added_dup <- append_telemetry_records(rec1)
cat(sprintf("Added records on duplicate insert: %d\n", added_dup))
stopifnot(added_dup == 0)

latest <- get_latest_district_telemetry("trichy")
stopifnot(!is.null(latest))
stopifnot(latest$district_name == "Tiruchirappalli (Trichy)")
stopifnot(latest$calculated_aqi == 55)

stats_after <- get_telemetry_store_stats()
cat(sprintf("Stats after test: %d records, %d unique districts\n", stats_after$total_records, stats_after$unique_districts))
cat("Telemetry store tests passed!\n")
