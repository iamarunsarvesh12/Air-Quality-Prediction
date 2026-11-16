library(curl)
library(jsonlite)
source("backend/data_fetcher.R")

districts <- get_all_districts()
cat(sprintf("Total districts: %d\n", length(districts)))

lats <- sapply(districts, function(d) sprintf("%.4f", d$lat))
lngs <- sapply(districts, function(d) sprintf("%.4f", d$lng))

lat_str <- paste(lats, collapse = ",")
lng_str <- paste(lngs, collapse = ",")

t0 <- Sys.time()
aq_url <- sprintf("https://air-quality-api.open-meteo.com/v1/air-quality?latitude=%s&longitude=%s&current=pm10,pm2_5,carbon_monoxide,nitrogen_dioxide,sulphur_dioxide,ozone,ammonia", lat_str, lng_str)
h <- curl::new_handle(timeout = 15)
resp_aq <- curl::curl_fetch_memory(aq_url, handle = h)
t1 <- Sys.time()

cat(sprintf("Fetched Air Quality for all 38 districts in %.2f seconds! HTTP Status: %d\n", as.numeric(difftime(t1, t0, units = "secs")), resp_aq$status_code))

json_aq <- jsonlite::fromJSON(rawToChar(resp_aq$content))
cat(sprintf("Response contains %d locations.\n", nrow(json_aq)))
print(head(json_aq[, c("latitude", "longitude")]))
print(head(json_aq$current))
