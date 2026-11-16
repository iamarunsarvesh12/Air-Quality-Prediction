library(curl)
library(jsonlite)
h <- curl::new_handle(timeout = 10)
# Test 2 districts in single call:
url <- "https://air-quality-api.open-meteo.com/v1/air-quality?latitude=13.0827,11.0168&longitude=80.2707,76.9558&current=pm10,pm2_5,carbon_monoxide,nitrogen_dioxide,sulphur_dioxide,ozone,ammonia"
resp <- curl::curl_fetch_memory(url, handle = h)
cat("Status:", resp$status_code, "\n")
json <- jsonlite::fromJSON(rawToChar(resp$content))
cat("Is list/array of locations:", is.list(json), "length:", length(json), "\n")
if (is.data.frame(json)) {
  print(names(json))
  print(json[, c("latitude", "longitude")])
} else if (is.list(json)) {
  cat("Class:", class(json), "\n")
  if (is.null(names(json))) {
    cat("Array of objects with length:", length(json), "\n")
    print(json[[1]]$latitude)
    print(json[[2]]$latitude)
  } else {
    print(names(json))
  }
}
