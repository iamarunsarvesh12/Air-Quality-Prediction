# ===========================================================
# AirSense — category.R (Module 6: AQI Category Classification)
# Converts a numeric AQI prediction into a standard category,
# label, and color code.
# ===========================================================

#' Classify a numeric AQI value into a standard category.
#'
#' @param aqi Numeric AQI value.
#' @return A list with category, colorCode, and description.
classify_aqi <- function(aqi) {
  if (is.na(aqi)) {
    stop("AQI value is NA — cannot classify.")
  }

  if (aqi <= 50) {
    list(category = "Good",
         colorCode = "#4CAF7D",
         description = "Air quality is satisfactory, and air pollution poses little or no risk.")
  } else if (aqi <= 100) {
    list(category = "Moderate",
         colorCode = "#A3C94A",
         description = "Air quality is acceptable. Unusually sensitive people should consider limiting prolonged outdoor exertion.")
  } else if (aqi <= 150) {
    list(category = "Unhealthy for Sensitive Groups",
         colorCode = "#E8A23D",
         description = "Sensitive groups (children, elderly, respiratory/heart conditions) may experience health effects.")
  } else if (aqi <= 200) {
    list(category = "Unhealthy",
         colorCode = "#D9663D",
         description = "Everyone may begin to experience health effects; sensitive groups more seriously.")
  } else if (aqi <= 300) {
    list(category = "Very Unhealthy",
         colorCode = "#D64545",
         description = "Health alert: everyone may experience more serious health effects.")
  } else {
    list(category = "Hazardous",
         colorCode = "#7B2D8B",
         description = "Health warning of emergency conditions; the entire population is likely to be affected.")
  }
}

# Quick manual test: Rscript category.R
if (sys.nframe() == 0) {
  for (v in c(30, 80, 130, 180, 260, 350)) {
    result <- classify_aqi(v)
    message(sprintf("AQI %d -> %s (%s)", v, result$category, result$colorCode))
  }
}
