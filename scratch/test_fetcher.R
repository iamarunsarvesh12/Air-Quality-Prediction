source("backend/data_fetcher.R")

cat("--- Testing data_fetcher.R ---\n")

t0 <- Sys.time()
ok <- refresh_all_districts_telemetry(force = TRUE)
t1 <- Sys.time()

cat(sprintf("Batch refresh completed in %.2f seconds! Success: %s\n", as.numeric(difftime(t1, t0, units = "secs")), as.character(ok)))
stopifnot(ok == TRUE)

status <- get_telemetry_pipeline_status()
cat(sprintf("Pipeline status: %s, Cached districts: %d / %d\n", status$status, status$cached_districts_count, status$total_districts_supported))
stopifnot(status$cached_districts_count == 38)

# Check single district
trichy <- fetch_district_air_quality("trichy")
stopifnot(!is.null(trichy))
cat(sprintf("Trichy: PM2.5 = %g, PM10 = %g, Calc AQI = %s, Category = %s, Dominant = %s\n",
            trichy$pollutants$pm25, trichy$pollutants$pm10, as.character(trichy$cpcb_aqi$calculated_aqi),
            trichy$cpcb_aqi$category, trichy$cpcb_aqi$dominant_pollutant))
stopifnot(!is.null(trichy$cpcb_aqi$calculated_aqi))

# Check 24-hour forecast
fc <- fetch_district_hourly_forecast("trichy")
stopifnot(!is.null(fc))
cat(sprintf("Forecast generated for %s: %d hourly points\n", fc$district_name, length(fc$forecast)))
stopifnot(length(fc$forecast) >= 20)
cat(sprintf("First forecast point: %s -> AQI: %d, Dominant: %s\n",
            fc$forecast[[1]]$time_label, fc$forecast[[1]]$predicted_aqi, fc$forecast[[1]]$dominant_pollutant))

cat("All data_fetcher.R tests passed successfully!\n")
