source("backend/aqi_calculator.R")

cat("--- Running AQI Calculator Tests ---\n")

# 1. Breakpoint boundary checks
# PM2.5: 30 -> 50, 31 -> 51, 60 -> 100, 61 -> 101, 90 -> 200, 120 -> 300, 250 -> 400, 350 -> 500
test_cases_pm25 <- list(
  list(val = 30,  expected = 50),
  list(val = 31,  expected = 51),
  list(val = 60,  expected = 100),
  list(val = 61,  expected = 101),
  list(val = 90,  expected = 200),
  list(val = 120, expected = 300),
  list(val = 250, expected = 400),
  list(val = 350, expected = 500)
)

for (tc in test_cases_pm25) {
  res <- calculate_pollutant_sub_index("pm25", tc$val)
  stopifnot(res == tc$expected)
  cat(sprintf("[PASS] PM2.5 = %g -> Sub-Index: %d (Expected: %d)\n", tc$val, res, tc$expected))
}

# 2. Category boundaries
stopifnot(classify_indian_aqi(50)$category == "Good")
stopifnot(classify_indian_aqi(51)$category == "Satisfactory")
stopifnot(classify_indian_aqi(100)$category == "Satisfactory")
stopifnot(classify_indian_aqi(101)$category == "Moderately Polluted")
stopifnot(classify_indian_aqi(200)$category == "Moderately Polluted")
stopifnot(classify_indian_aqi(201)$category == "Poor")
stopifnot(classify_indian_aqi(300)$category == "Poor")
stopifnot(classify_indian_aqi(301)$category == "Very Poor")
stopifnot(classify_indian_aqi(400)$category == "Very Poor")
stopifnot(classify_indian_aqi(401)$category == "Severe")
cat("[PASS] All Indian AQI category boundaries verified!\n")

# 3. Eligibility checks
# Case A: Only PM2.5 provided -> insufficient (needs >= 3 pollutants)
p_incomplete <- list(pm25 = 45)
res_inc <- calculate_indian_aqi(p_incomplete)
stopifnot(res_inc$is_official_eligible == FALSE)
stopifnot(res_inc$status == "insufficient_data")
cat("[PASS] Incomplete pollutant coverage correctly flagged as insufficient_data!\n")

# Case B: NO2, SO2, CO (3 pollutants) but NO particulate -> insufficient
p_no_particulate <- list(no2 = 30, so2 = 20, co = 1.0)
res_no_pm <- calculate_indian_aqi(p_no_particulate)
stopifnot(res_no_pm$is_official_eligible == FALSE)
cat("[PASS] Missing mandatory particulate monitor correctly flagged!\n")

# Case C: PM2.5 + NO2 + SO2 (3 pollutants, particulate present) -> valid
p_valid <- list(pm25 = 45, no2 = 30, so2 = 20)
res_val <- calculate_indian_aqi(p_valid)
stopifnot(res_val$is_official_eligible == TRUE)
stopifnot(res_val$status == "valid")
stopifnot(res_val$calculated_aqi == 75) # PM2.5 45: in 31-60 -> (49/29)*14 + 51 = 74.6 -> 75
stopifnot(res_val$dominant_pollutant == "PM2.5")
cat(sprintf("[PASS] Valid calculation: AQI = %d, Dominant = %s\n", res_val$calculated_aqi, res_val$dominant_pollutant))

cat("\nAll aqi_calculator.R unit tests passed cleanly!\n")
