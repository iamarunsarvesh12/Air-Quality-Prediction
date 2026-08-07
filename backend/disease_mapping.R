# ===========================================================
# AirSense — disease_mapping.R (Module 7: Disease Mapping)
# Maps an AQI category to possible health effects and
# preventive recommendations, using health_data.csv as the
# source of truth (falls back to built-in defaults if missing).
# ===========================================================

library(readr)
library(dplyr)

DEFAULT_HEALTH_MAP <- list(
  "Good" = list(
    effects = c("No significant health risk."),
    recommendations = c("Enjoy normal outdoor activities.")
  ),
  "Moderate" = list(
    effects = c("Mild respiratory irritation possible for unusually sensitive individuals."),
    recommendations = c("Sensitive individuals should reduce prolonged or heavy exertion outdoors.")
  ),
  "Unhealthy for Sensitive Groups" = list(
    effects = c("Increased likelihood of respiratory symptoms in children, elderly, and people with asthma or heart disease."),
    recommendations = c("Sensitive groups should limit prolonged outdoor exertion.",
                         "Keep quick-relief medication on hand if you have asthma.")
  ),
  "Unhealthy" = list(
    effects = c("Increased respiratory effects in the general population.",
                "Aggravation of heart or lung disease."),
    recommendations = c("Reduce prolonged outdoor exertion.",
                         "Consider wearing a mask (N95) outdoors.")
  ),
  "Very Unhealthy" = list(
    effects = c("Significant aggravation of heart or lung disease.",
                "Premature mortality risk in people with cardiopulmonary disease and the elderly."),
    recommendations = c("Avoid outdoor exertion.", "Keep windows closed and use an air purifier indoors.")
  ),
  "Hazardous" = list(
    effects = c("Serious risk of respiratory effects for the entire population."),
    recommendations = c("Remain indoors and keep activity levels low.",
                         "Use an air purifier and avoid all outdoor exertion.")
  )
)

#' Load the health mapping table from CSV, if available.
load_health_data <- function(path = "health_data.csv") {
  actual_path <- path
  if (!file.exists(actual_path) && file.exists(file.path("backend", path))) {
    actual_path <- file.path("backend", path)
  }
  if (file.exists(actual_path)) {
    readr::read_csv(actual_path, show_col_types = FALSE)
  } else {
    NULL
  }
}

#' Get health effects & recommendations for an AQI category.
#'
#' @param category AQI category string (from category.R -> classify_aqi()).
#' @return A list with `effects` and `recommendations` character vectors.
get_health_info <- function(category) {
  table <- load_health_data()

  if (!is.null(table) && category %in% table$category) {
    rows <- dplyr::filter(table, category == !!category)
    return(list(
      effects = rows$effect,
      recommendations = rows$recommendation
    ))
  }

  # Fallback to built-in defaults
  if (category %in% names(DEFAULT_HEALTH_MAP)) {
    return(DEFAULT_HEALTH_MAP[[category]])
  }

  list(effects = c("No data available."), recommendations = c("Consult local health guidance."))
}

# Quick manual test: Rscript disease_mapping.R
if (sys.nframe() == 0) {
  info <- get_health_info("Unhealthy")
  print(info)
}
