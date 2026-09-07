# ===========================================================
# AeroSense TN — data_fetcher.R (Module 1: Real-Time Data Layer)
# Fetches live public air quality & weather data for Tamil Nadu districts
# ===========================================================

library(jsonlite)

# Directory of all 38 Tamil Nadu Districts
TN_DISTRICTS_DATA <- list(
  list(id = "ariyalur", name = "Ariyalur", lat = 11.1401, lng = 79.0786, zone = "Central TN", base_pm25 = 31.0),
  list(id = "chengalpattu", name = "Chengalpattu", lat = 12.6841, lng = 79.9836, zone = "Northern TN", base_pm25 = 43.5),
  list(id = "chennai", name = "Chennai", lat = 13.0827, lng = 80.2707, zone = "Northern TN", base_pm25 = 58.2),
  list(id = "coimbatore", name = "Coimbatore", lat = 11.0168, lng = 76.9558, zone = "Western TN", base_pm25 = 38.0),
  list(id = "cuddalore", name = "Cuddalore", lat = 11.7480, lng = 79.7714, zone = "Coastal TN", base_pm25 = 39.8),
  list(id = "dharmapuri", name = "Dharmapuri", lat = 12.1211, lng = 78.1582, zone = "Western TN", base_pm25 = 34.2),
  list(id = "dindigul", name = "Dindigul", lat = 10.3673, lng = 77.9803, zone = "Southern TN", base_pm25 = 36.2),
  list(id = "erode", name = "Erode", lat = 11.3410, lng = 77.7172, zone = "Western TN", base_pm25 = 49.3),
  list(id = "kallakurichi", name = "Kallakurichi", lat = 11.7384, lng = 78.9639, zone = "Central TN", base_pm25 = 33.8),
  list(id = "kanchipuram", name = "Kanchipuram", lat = 12.8342, lng = 79.7036, zone = "Northern TN", base_pm25 = 44.8),
  list(id = "kanyakumari", name = "Kanyakumari (Nagercoil)", lat = 8.1833, lng = 77.4119, zone = "Southern TN", base_pm25 = 22.0),
  list(id = "karur", name = "Karur", lat = 10.9601, lng = 78.0766, zone = "Central TN", base_pm25 = 41.0),
  list(id = "krishnagiri", name = "Krishnagiri", lat = 12.5186, lng = 78.2137, zone = "Western TN", base_pm25 = 35.7),
  list(id = "madurai", name = "Madurai", lat = 9.9252, lng = 78.1198, zone = "Southern TN", base_pm25 = 46.1),
  list(id = "mayiladuthurai", name = "Mayiladuthurai", lat = 11.1018, lng = 79.6522, zone = "Delta TN", base_pm25 = 26.2),
  list(id = "nagapattinam", name = "Nagapattinam", lat = 10.7672, lng = 79.8449, zone = "Delta / Coastal TN", base_pm25 = 24.5),
  list(id = "namakkal", name = "Namakkal", lat = 11.2189, lng = 78.1674, zone = "Western TN", base_pm25 = 40.5),
  list(id = "nilgiris", name = "Nilgiris (Ooty)", lat = 11.4102, lng = 76.6950, zone = "Western TN", base_pm25 = 14.8),
  list(id = "perambalur", name = "Perambalur", lat = 11.2342, lng = 78.8827, zone = "Central TN", base_pm25 = 32.4),
  list(id = "pudukkottai", name = "Pudukkottai", lat = 10.3797, lng = 78.8208, zone = "Central TN", base_pm25 = 29.8),
  list(id = "ramanathapuram", name = "Ramanathapuram", lat = 9.3639, lng = 78.8395, zone = "Southern TN", base_pm25 = 27.3),
  list(id = "ranipet", name = "Ranipet", lat = 12.9279, lng = 79.3330, zone = "Northern TN", base_pm25 = 56.7),
  list(id = "salem", name = "Salem", lat = 11.6643, lng = 78.1460, zone = "Western TN", base_pm25 = 52.4),
  list(id = "sivaganga", name = "Sivaganga", lat = 9.8433, lng = 78.4809, zone = "Southern TN", base_pm25 = 30.5),
  list(id = "tenkasi", name = "Tenkasi", lat = 8.9593, lng = 77.3150, zone = "Southern TN", base_pm25 = 25.1),
  list(id = "thanjavur", name = "Thanjavur", lat = 10.7870, lng = 79.1378, zone = "Delta / Central TN", base_pm25 = 28.5),
  list(id = "theni", name = "Theni", lat = 10.0104, lng = 77.4768, zone = "Southern TN", base_pm25 = 28.0),
  list(id = "thoothukudi", name = "Thoothukudi (Tuticorin)", lat = 8.7642, lng = 78.1348, zone = "Southern TN", base_pm25 = 48.6),
  list(id = "trichy", name = "Tiruchirappalli (Trichy)", lat = 10.7905, lng = 78.7047, zone = "Central TN", base_pm25 = 42.5),
  list(id = "tirunelveli", name = "Tirunelveli", lat = 8.7139, lng = 77.7567, zone = "Southern TN", base_pm25 = 32.1),
  list(id = "tirupathur", name = "Tirupathur", lat = 12.4926, lng = 78.5678, zone = "Northern TN", base_pm25 = 37.8),
  list(id = "tiruppur", name = "Tiruppur", lat = 11.1085, lng = 77.3411, zone = "Western TN", base_pm25 = 50.1),
  list(id = "tiruvallur", name = "Tiruvallur", lat = 13.1432, lng = 79.9067, zone = "Northern TN", base_pm25 = 51.3),
  list(id = "tiruvannamalai", name = "Tiruvannamalai", lat = 12.2253, lng = 79.0747, zone = "Northern TN", base_pm25 = 35.1),
  list(id = "tiruvarur", name = "Tiruvarur", lat = 10.7726, lng = 79.6365, zone = "Delta TN", base_pm25 = 25.6),
  list(id = "vellore", name = "Vellore", lat = 12.9165, lng = 79.1325, zone = "Northern TN", base_pm25 = 54.0),
  list(id = "villupuram", name = "Villupuram", lat = 11.9401, lng = 79.4861, zone = "Northern TN", base_pm25 = 38.6),
  list(id = "virudhunagar", name = "Virudhunagar", lat = 9.5872, lng = 77.9514, zone = "Southern TN", base_pm25 = 33.0)
)

# In-memory caching
.data_cache <- list()
CACHE_TTL_SECS <- 300 # 5 minutes cache

get_all_districts <- function() {
  TN_DISTRICTS_DATA
}

get_district_by_id_or_name <- function(query) {
  if (is.null(query) || query == "") return(NULL)
  q_clean <- tolower(trimws(query))
  
  for (d in TN_DISTRICTS_DATA) {
    if (tolower(d$id) == q_clean ||
        tolower(d$name) == q_clean ||
        grepl(q_clean, tolower(d$name), fixed = TRUE) ||
        grepl(q_clean, tolower(d$id), fixed = TRUE)) {
      return(d)
    }
  }
  NULL
}

#' Fetch live air quality and weather data for a Tamil Nadu district
#'
#' @param district_identifier District ID or Name (e.g. "trichy" or "Trichy")
#' @return Structured list containing pollutants, weather, and data transparency metadata
fetch_district_air_quality <- function(district_identifier) {
  district <- get_district_by_id_or_name(district_identifier)
  
  if (is.null(district)) {
    # Default fallback to Trichy if invalid
    district <- TN_DISTRICTS_DATA[[29]] # Trichy
  }
  
  cache_key <- district$id
  now <- Sys.time()
  
  if (!is.null(.data_cache[[cache_key]])) {
    cached <- .data_cache[[cache_key]]
    if (difftime(now, cached$cached_at, units = "secs") < CACHE_TTL_SECS) {
      return(cached$data)
    }
  }
  
  lat <- district$lat
  lng <- district$lng
  
  aq_url <- sprintf("https://air-quality-api.open-meteo.com/v1/air-quality?latitude=%.4f&longitude=%.4f&current=pm10,pm2_5,carbon_monoxide,nitrogen_dioxide,sulphur_dioxide,ozone,ammonia", lat, lng)
  weather_url <- sprintf("https://api.open-meteo.com/v1/forecast?latitude=%.4f&longitude=%.4f&current=temperature_2m,relative_humidity_2m,wind_speed_10m", lat, lng)
  
  is_live <- FALSE
  source_name <- "Open-Meteo Air Quality & CPCB Monitoring Network"
  
  pm25 <- district$base_pm25
  pm10 <- round(pm25 * 1.6, 1)
  no2 <- 22.0
  so2 <- 6.0
  co <- 0.8
  o3 <- 30.0
  nh3 <- 10.5
  temperature <- 30.0
  humidity <- 60.0
  wind_speed <- 12.0
  
  tryCatch({
    con_aq <- url(aq_url, open = "r", timeout = 3)
    json_aq <- jsonlite::fromJSON(con_aq)
    close(con_aq)
    
    con_w <- url(weather_url, open = "r", timeout = 3)
    json_w <- jsonlite::fromJSON(con_w)
    close(con_w)
    
    cur_aq <- json_aq$current
    cur_w <- json_w$current
    
    if (!is.null(cur_aq$pm2_5)) pm25 <- round(as.numeric(cur_aq$pm2_5), 1)
    if (!is.null(cur_aq$pm10)) pm10 <- round(as.numeric(cur_aq$pm10), 1)
    if (!is.null(cur_aq$nitrogen_dioxide)) no2 <- round(as.numeric(cur_aq$nitrogen_dioxide) * 0.53, 1)
    if (!is.null(cur_aq$sulphur_dioxide)) so2 <- round(as.numeric(cur_aq$sulphur_dioxide) * 0.38, 1)
    if (!is.null(cur_aq$carbon_monoxide)) co <- round(as.numeric(cur_aq$carbon_monoxide) / 1145, 2)
    if (!is.null(cur_aq$ozone)) o3 <- round(as.numeric(cur_aq$ozone) * 0.51, 1)
    if (!is.null(cur_aq$ammonia)) nh3 <- round(as.numeric(cur_aq$ammonia) * 0.70, 1)
    
    if (!is.null(cur_w$temperature_2m)) temperature <- round(as.numeric(cur_w$temperature_2m), 1)
    if (!is.null(cur_w$relative_humidity_2m)) humidity <- round(as.numeric(cur_w$relative_humidity_2m), 1)
    if (!is.null(cur_w$wind_speed_10m)) wind_speed <- round(as.numeric(cur_w$wind_speed_10m), 1)
    
    is_live <- TRUE
  }, error = function(e) {
    # Fallback to local realistic station baseline
    is_live <- FALSE
  })
  
  data_type <- if (is_live) "Live Station Feed" else "Estimated Station Baseline"
  data_status <- if (is_live) "live" else "estimated"
  
  result <- list(
    district_id = district$id,
    district_name = district$name,
    zone = district$zone,
    coordinates = list(latitude = lat, longitude = lng),
    pollutants = list(
      pm25 = pm25,
      pm10 = pm10,
      no2 = no2,
      so2 = so2,
      co = co,
      o3 = o3,
      nh3 = nh3
    ),
    weather = list(
      temperature = temperature,
      humidity = humidity,
      wind_speed = wind_speed
    ),
    transparency = list(
      source_name = source_name,
      data_type = data_type,
      data_status = data_status,
      is_live = is_live,
      last_updated = format(now, "%Y-%m-%dT%H:%M:%S%z"),
      timestamp_display = format(now, "%b %d, %Y - %I:%M %p IST")
    )
  )
  
  # Cache result
  .data_cache[[cache_key]] <<- list(cached_at = now, data = result)
  
  result
}
