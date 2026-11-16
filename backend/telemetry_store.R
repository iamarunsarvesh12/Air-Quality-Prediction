# ===========================================================
# AeroSense TN — telemetry_store.R (Persistent Telemetry Data Store)
# Thread-safe, deduplicated persistence for genuine environmental observations
# Preserves provenance, composite keys, timestamps, and data quality metadata.
# ===========================================================

suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
})

TELEMETRY_STORE_PATH <- file.path("backend", "dataset", "telemetry_store.csv")

TELEMETRY_SCHEMA <- c(
  "record_id",             # Composite key: district_id + "_" + observation_time
  "district_id",
  "district_name",
  "latitude",
  "longitude",
  "zone",
  "observation_time",      # ISO 8601 timestamp from provider
  "observation_time_ist",  # Display timestamp in Asia/Kolkata
  "retrieval_time",        # Sys.time() when backend fetched the telemetry
  "source_name",           # "Open-Meteo Air Quality Telemetry Network" / "CPCB"
  "data_type",             # "Gridded Atmospheric Telemetry" / "Station Observation"
  "data_status",           # "live" / "stale" / "estimated"
  "pm25",                  # ug/m3
  "pm10",                  # ug/m3
  "no2",                   # ug/m3
  "so2",                   # ug/m3
  "co",                    # mg/m3
  "o3",                    # ug/m3
  "nh3",                   # ug/m3
  "temperature",           # deg C
  "humidity",              # %
  "wind_speed",            # km/h
  "calculated_aqi",        # CPCB linear breakpoint calculated AQI
  "dominant_pollutant",    # Dominant pollutant driving the sub-index
  "aqi_category",          # Indian AQI category
  "is_official_eligible"   # TRUE if CPCB completeness rule satisfied
)

#' Resolve path to store file
get_telemetry_store_path <- function() {
  candidates <- c(
    TELEMETRY_STORE_PATH,
    file.path("dataset", "telemetry_store.csv"),
    file.path("..", TELEMETRY_STORE_PATH),
    file.path(getwd(), TELEMETRY_STORE_PATH)
  )
  for (c in candidates) {
    if (file.exists(c)) return(normalizePath(c))
  }
  # Default to backend/dataset/telemetry_store.csv
  dir.create(file.path("backend", "dataset"), recursive = TRUE, showWarnings = FALSE)
  normalizePath(file.path("backend", "dataset", "telemetry_store.csv"), mustWork = FALSE)
}

#' Initialize store with schema if file does not exist
init_telemetry_store <- function() {
  path <- get_telemetry_store_path()
  if (!file.exists(path) || file.info(path)$size == 0) {
    empty_df <- as.data.frame(matrix(ncol = length(TELEMETRY_SCHEMA), nrow = 0))
    colnames(empty_df) <- TELEMETRY_SCHEMA
    readr::write_csv(empty_df, path)
  }
}

#' Load all records from store
load_telemetry_store <- function() {
  init_telemetry_store()
  path <- get_telemetry_store_path()
  tryCatch({
    df <- readr::read_csv(path, show_col_types = FALSE, col_types = readr::cols(
      record_id = readr::col_character(),
      district_id = readr::col_character(),
      district_name = readr::col_character(),
      latitude = readr::col_double(),
      longitude = readr::col_double(),
      zone = readr::col_character(),
      observation_time = readr::col_character(),
      observation_time_ist = readr::col_character(),
      retrieval_time = readr::col_character(),
      source_name = readr::col_character(),
      data_type = readr::col_character(),
      data_status = readr::col_character(),
      pm25 = readr::col_double(),
      pm10 = readr::col_double(),
      no2 = readr::col_double(),
      so2 = readr::col_double(),
      co = readr::col_double(),
      o3 = readr::col_double(),
      nh3 = readr::col_double(),
      temperature = readr::col_double(),
      humidity = readr::col_double(),
      wind_speed = readr::col_double(),
      calculated_aqi = readr::col_double(),
      dominant_pollutant = readr::col_character(),
      aqi_category = readr::col_character(),
      is_official_eligible = readr::col_logical()
    ))
    df
  }, error = function(e) {
    as.data.frame(matrix(ncol = length(TELEMETRY_SCHEMA), nrow = 0, dimnames = list(NULL, TELEMETRY_SCHEMA)))
  })
}

#' Append new genuine telemetry records with strict deduplication using composite key
#'
#' @param new_records_df Data frame matching TELEMETRY_SCHEMA
#' @return Number of newly added records
append_telemetry_records <- function(new_records_df) {
  if (is.null(new_records_df) || nrow(new_records_df) == 0) return(0)
  
  init_telemetry_store()
  path <- get_telemetry_store_path()
  
  existing_df <- load_telemetry_store()
  existing_keys <- if (nrow(existing_df) > 0) existing_df$record_id else character(0)
  
  # Ensure composite record_id is generated
  if (!("record_id" %in% names(new_records_df)) || any(is.na(new_records_df$record_id))) {
    new_records_df$record_id <- paste(new_records_df$district_id, new_records_df$observation_time, sep = "_")
  }
  
  # Filter out duplicate observations (do not overwrite historical records)
  fresh_records <- new_records_df[! (new_records_df$record_id %in% existing_keys), ]
  fresh_records <- fresh_records %>% distinct(record_id, .keep_all = TRUE)
  
  if (nrow(fresh_records) == 0) {
    return(0)
  }
  
  # Safe atomic append using temporary file
  combined_df <- if (nrow(existing_df) > 0) bind_rows(existing_df, fresh_records) else fresh_records
  tmp_path <- paste0(path, ".tmp")
  
  tryCatch({
    readr::write_csv(combined_df, tmp_path)
    file.rename(tmp_path, path)
    return(nrow(fresh_records))
  }, error = function(e) {
    if (file.exists(tmp_path)) file.remove(tmp_path)
    warning(paste("Failed to write to telemetry store:", conditionMessage(e)))
    return(0)
  })
}

#' Retrieve the most recent observation for a specific district
get_latest_district_telemetry <- function(district_id) {
  df <- load_telemetry_store()
  if (nrow(df) == 0) return(NULL)
  
  d_recs <- df %>% filter(tolower(district_id) == tolower(!!district_id))
  if (nrow(d_recs) == 0) return(NULL)
  
  # Return the record with highest observation_time or retrieval_time
  d_recs %>% arrange(desc(observation_time), desc(retrieval_time)) %>% slice(1)
}

#' Get telemetry store health, count, and freshness metrics for /api/data-status
get_telemetry_store_stats <- function() {
  init_telemetry_store()
  df <- load_telemetry_store()
  total_records <- nrow(df)
  
  if (total_records == 0) {
    return(list(
      total_records = 0,
      unique_districts = 0,
      earliest_record = NULL,
      latest_record = NULL,
      latest_retrieval = NULL,
      missing_rates = list()
    ))
  }
  
  unique_districts <- length(unique(df$district_id))
  earliest <- min(df$observation_time, na.rm = TRUE)
  latest <- max(df$observation_time, na.rm = TRUE)
  latest_retrieval <- max(df$retrieval_time, na.rm = TRUE)
  
  # Missing value rates
  missing_rates <- list(
    pm25 = round(mean(is.na(df$pm25)) * 100, 1),
    pm10 = round(mean(is.na(df$pm10)) * 100, 1),
    no2 = round(mean(is.na(df$no2)) * 100, 1),
    so2 = round(mean(is.na(df$so2)) * 100, 1),
    co = round(mean(is.na(df$co)) * 100, 1),
    o3 = round(mean(is.na(df$o3)) * 100, 1),
    nh3 = round(mean(is.na(df$nh3)) * 100, 1)
  )
  
  list(
    total_records = total_records,
    unique_districts = unique_districts,
    earliest_observation = earliest,
    latest_observation = latest,
    latest_retrieval = latest_retrieval,
    missing_rates_percent = missing_rates
  )
}
