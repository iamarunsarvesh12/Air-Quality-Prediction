# ===========================================================
# AeroSense TN — category.R (Indian CPCB AQI Category Classification)
# Maps a numeric AQI prediction into the official Indian standard categories
# ===========================================================

get_cat_script_dir <- function() {
  candidates <- c("backend", ".", file.path(getwd(), "backend"), "..")
  for (c in candidates) {
    if (file.exists(file.path(c, "aqi_calculator.R"))) return(c)
  }
  "."
}
c_dir <- get_cat_script_dir()
source(file.path(c_dir, "aqi_calculator.R"), local = TRUE)

#' Classify a numeric AQI value into Indian CPCB standard category.
#'
#' @param aqi Numeric AQI value.
#' @return A list with category, colorCode, and description.
classify_aqi <- function(aqi) {
  if (is.null(aqi) || is.na(aqi)) {
    stop("AQI value is NA — cannot classify.")
  }
  
  c_info <- classify_indian_aqi(aqi)
  list(
    category = c_info$category,
    colorCode = c_info$color,
    description = c_info$description
  )
}
