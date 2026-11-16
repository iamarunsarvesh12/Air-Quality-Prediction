# ===========================================================
# AeroSense TN — aqi_calculator.R (Authoritative Indian CPCB AQI Engine)
# Implements Central Pollution Control Board (CPCB) National Air Quality Index
# Linear segmented breakpoint interpolation, eligibility completeness rules,
# sub-indices calculation, dominant pollutant identification, and category classification.
# ===========================================================

# Official CPCB Breakpoints Table
# Each row: B_LO, B_HI, I_LO, I_HI
CPCB_BREAKPOINTS <- list(
  pm25 = list(
    name = "PM2.5",
    unit = "µg/m³",
    averaging_hours = 24,
    intervals = list(
      list(b_lo = 0,   b_hi = 30,  i_lo = 0,   i_hi = 50),
      list(b_lo = 31,  b_hi = 60,  i_lo = 51,  i_hi = 100),
      list(b_lo = 61,  b_hi = 90,  i_lo = 101, i_hi = 200),
      list(b_lo = 91,  b_hi = 120, i_lo = 201, i_hi = 300),
      list(b_lo = 121, b_hi = 250, i_lo = 301, i_hi = 400),
      list(b_lo = 251, b_hi = 350, i_lo = 401, i_hi = 500)
    )
  ),
  pm10 = list(
    name = "PM10",
    unit = "µg/m³",
    averaging_hours = 24,
    intervals = list(
      list(b_lo = 0,   b_hi = 50,  i_lo = 0,   i_hi = 50),
      list(b_lo = 51,  b_hi = 100, i_lo = 51,  i_hi = 100),
      list(b_lo = 101, b_hi = 250, i_lo = 101, i_hi = 200),
      list(b_lo = 251, b_hi = 350, i_lo = 201, i_hi = 300),
      list(b_lo = 351, b_hi = 430, i_lo = 301, i_hi = 400),
      list(b_lo = 431, b_hi = 500, i_lo = 401, i_hi = 500)
    )
  ),
  no2 = list(
    name = "NO₂",
    unit = "µg/m³",
    averaging_hours = 24,
    intervals = list(
      list(b_lo = 0,   b_hi = 40,  i_lo = 0,   i_hi = 50),
      list(b_lo = 41,  b_hi = 80,  i_lo = 51,  i_hi = 100),
      list(b_lo = 81,  b_hi = 180, i_lo = 101, i_hi = 200),
      list(b_lo = 181, b_hi = 280, i_lo = 201, i_hi = 300),
      list(b_lo = 281, b_hi = 400, i_lo = 301, i_hi = 400),
      list(b_lo = 401, b_hi = 500, i_lo = 401, i_hi = 500)
    )
  ),
  so2 = list(
    name = "SO₂",
    unit = "µg/m³",
    averaging_hours = 24,
    intervals = list(
      list(b_lo = 0,    b_hi = 40,   i_lo = 0,   i_hi = 50),
      list(b_lo = 41,   b_hi = 80,   i_lo = 51,  i_hi = 100),
      list(b_lo = 81,   b_hi = 380,  i_lo = 101, i_hi = 200),
      list(b_lo = 381,  b_hi = 800,  i_lo = 201, i_hi = 300),
      list(b_lo = 801,  b_hi = 1600, i_lo = 301, i_hi = 400),
      list(b_lo = 1601, b_hi = 2000, i_lo = 401, i_hi = 500)
    )
  ),
  co = list(
    name = "CO",
    unit = "mg/m³",
    averaging_hours = 8,
    intervals = list(
      list(b_lo = 0.0,  b_hi = 1.0,  i_lo = 0,   i_hi = 50),
      list(b_lo = 1.1,  b_hi = 2.0,  i_lo = 51,  i_hi = 100),
      list(b_lo = 2.1,  b_hi = 10.0, i_lo = 101, i_hi = 200),
      list(b_lo = 10.1, b_hi = 17.0, i_lo = 201, i_hi = 300),
      list(b_lo = 17.1, b_hi = 34.0, i_lo = 301, i_hi = 400),
      list(b_lo = 34.1, b_hi = 50.0, i_lo = 401, i_hi = 500)
    )
  ),
  o3 = list(
    name = "O₃",
    unit = "µg/m³",
    averaging_hours = 8,
    intervals = list(
      list(b_lo = 0,   b_hi = 50,  i_lo = 0,   i_hi = 50),
      list(b_lo = 51,  b_hi = 100, i_lo = 51,  i_hi = 100),
      list(b_lo = 101, b_hi = 168, i_lo = 101, i_hi = 200),
      list(b_lo = 169, b_hi = 208, i_lo = 201, i_hi = 300),
      list(b_lo = 209, b_hi = 748, i_lo = 301, i_hi = 400),
      list(b_lo = 749, b_hi = 1000, i_lo = 401, i_hi = 500)
    )
  ),
  nh3 = list(
    name = "NH₃",
    unit = "µg/m³",
    averaging_hours = 24,
    intervals = list(
      list(b_lo = 0,    b_hi = 200,  i_lo = 0,   i_hi = 50),
      list(b_lo = 201,  b_hi = 400,  i_lo = 51,  i_hi = 100),
      list(b_lo = 401,  b_hi = 800,  i_lo = 101, i_hi = 200),
      list(b_lo = 801,  b_hi = 1200, i_lo = 201, i_hi = 300),
      list(b_lo = 1201, b_hi = 1800, i_lo = 301, i_hi = 400),
      list(b_lo = 1801, b_hi = 2400, i_lo = 401, i_hi = 500)
    )
  )
)

#' Calculate sub-index for a specific pollutant according to Indian CPCB formula
#'
#' @param pollutant_key Pollutant identifier (e.g. "pm25", "pm10", "no2", "so2", "co", "o3", "nh3")
#' @param concentration Pollutant concentration in standard units (mg/m3 for CO, ug/m3 for others)
#' @return Numeric sub-index (rounded to integer) or NA if invalid/missing
calculate_pollutant_sub_index <- function(pollutant_key, concentration) {
  if (is.null(concentration) || is.na(concentration) || length(concentration) == 0) {
    return(NA_real_)
  }
  
  c_p <- suppressWarnings(as.numeric(concentration))
  if (is.na(c_p) || is.nan(c_p) || c_p < 0) {
    return(NA_real_)
  }
  
  bp_info <- CPCB_BREAKPOINTS[[tolower(pollutant_key)]]
  if (is.null(bp_info)) return(NA_real_)
  
  intervals <- bp_info$intervals
  
  # Check within defined intervals
  for (iv in intervals) {
    if (c_p >= iv$b_lo && c_p <= iv$b_hi) {
      if (iv$b_hi == iv$b_lo) return(as.numeric(iv$i_lo))
      sub_index <- ((iv$i_hi - iv$i_lo) / (iv$b_hi - iv$b_lo)) * (c_p - iv$b_lo) + iv$i_lo
      return(round(sub_index))
    }
  }
  
  # If concentration exceeds the highest defined upper breakpoint, extrapolate linearly from top interval
  top_iv <- intervals[[length(intervals)]]
  if (c_p > top_iv$b_hi) {
    sub_index <- ((top_iv$i_hi - top_iv$i_lo) / (top_iv$b_hi - top_iv$b_lo)) * (c_p - top_iv$b_lo) + top_iv$i_lo
    return(round(min(500, max(401, sub_index))))
  }
  
  NA_real_
}

#' Classify an AQI value into verified Indian National Air Quality Index categories
#'
#' @param aqi_val Numeric AQI value (0 to 500+)
#' @return List with category, color, bg_color, risk_level, description
classify_indian_aqi <- function(aqi_val) {
  if (is.null(aqi_val) || is.na(aqi_val)) {
    return(list(
      category = "Data Unavailable",
      color = "#64748B",
      bg_color = "#F1F5F9",
      risk_level = "Unknown",
      description = "Insufficient pollutant telemetry to determine official AQI."
    ))
  }
  
  aqi <- round(as.numeric(aqi_val))
  
  if (aqi <= 50) {
    list(
      category = "Good",
      color = "#10B981", # Green
      bg_color = "#ECFDF5",
      risk_level = "Minimal",
      description = "Minimal impact. Air quality is satisfactory and poses little or no risk."
    )
  } else if (aqi <= 100) {
    list(
      category = "Satisfactory",
      color = "#84CC16", # Light Green
      bg_color = "#F7FEE7",
      risk_level = "Minor",
      description = "Minor breathing discomfort to sensitive people."
    )
  } else if (aqi <= 200) {
    list(
      category = "Moderately Polluted",
      color = "#F59E0B", # Yellow-Orange
      bg_color = "#FFFBEB",
      risk_level = "Moderate",
      description = "Breathing discomfort to the people with lungs, asthma and heart diseases."
    )
  } else if (aqi <= 300) {
    list(
      category = "Poor",
      color = "#F97316", # Orange-Red
      bg_color = "#FFF7ED",
      risk_level = "High",
      description = "Breathing discomfort to most people on prolonged exposure."
    )
  } else if (aqi <= 400) {
    list(
      category = "Very Poor",
      color = "#EF4444", # Red
      bg_color = "#FEF2F2",
      risk_level = "Very High",
      description = "Respiratory illness on prolonged exposure. Significant impact on vulnerable groups."
    )
  } else {
    list(
      category = "Severe",
      color = "#7F1D1D", # Deep Maroon / Crimson
      bg_color = "#FEF2F2",
      risk_level = "Critical",
      description = "Affects healthy people and seriously impacts those with existing diseases."
    )
  }
}

#' Calculate Indian National Air Quality Index (NAQI / CPCB) from concentration dictionary
#'
#' @param pollutants Named list with concentration values (pm25, pm10, no2, so2, co, o3, nh3)
#' @return List with calculated_aqi, dominant_pollutant, sub_indices, eligibility_status, completeness_report
calculate_indian_aqi <- function(pollutants) {
  sub_indices <- list()
  valid_sub_indices <- list()
  
  # Standard keys
  keys <- c("pm25", "pm10", "no2", "so2", "co", "o3", "nh3")
  
  for (k in keys) {
    val <- pollutants[[k]]
    sub_val <- calculate_pollutant_sub_index(k, val)
    sub_indices[[k]] <- sub_val
    if (!is.na(sub_val)) {
      display_name <- CPCB_BREAKPOINTS[[k]]$name
      valid_sub_indices[[display_name]] <- sub_val
    }
  }
  
  # CPCB Completeness Eligibility Rule:
  # At least 3 pollutants must be monitored, of which at least one must be PM10 or PM2.5.
  has_particulate <- (!is.na(sub_indices$pm25) || !is.na(sub_indices$pm10))
  count_valid <- length(valid_sub_indices)
  
  if (count_valid < 3 || !has_particulate) {
    missing_reasons <- c()
    if (!has_particulate) missing_reasons <- c(missing_reasons, "Missing mandatory particulate monitor (PM2.5 or PM10)")
    if (count_valid < 3) missing_reasons <- c(missing_reasons, sprintf("Only %d pollutant(s) available; CPCB requires >= 3", count_valid))
    
    # Partial non-official proxy if at least 1 pollutant is available
    partial_aqi <- if (count_valid > 0) max(unlist(valid_sub_indices), na.rm = TRUE) else NA_real_
    dominant <- if (count_valid > 0) names(which.max(unlist(valid_sub_indices))) else "None"
    
    return(list(
      is_official_eligible = FALSE,
      status = "insufficient_data",
      reason = paste(missing_reasons, collapse = "; "),
      calculated_aqi = if (!is.na(partial_aqi)) round(partial_aqi) else NULL,
      dominant_pollutant = dominant,
      sub_indices = sub_indices,
      category_info = if (!is.na(partial_aqi)) classify_indian_aqi(partial_aqi) else classify_indian_aqi(NA),
      valid_pollutant_count = count_valid
    ))
  }
  
  # Official CPCB AQI is the maximum of valid pollutant sub-indices
  sub_vals_vec <- unlist(valid_sub_indices)
  overall_aqi <- max(sub_vals_vec)
  dominant_idx <- which.max(sub_vals_vec)
  dominant_pollutant <- names(sub_vals_vec)[dominant_idx]
  
  category_info <- classify_indian_aqi(overall_aqi)
  
  list(
    is_official_eligible = TRUE,
    status = "valid",
    calculated_aqi = round(overall_aqi),
    dominant_pollutant = dominant_pollutant,
    category_info = category_info,
    sub_indices = sub_indices,
    valid_pollutant_count = count_valid
  )
}
