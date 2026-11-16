library(later)
library(httpuv)

cat("Testing later execution:\n")
later::later(function() {
  cat("Timer fired inside event loop!\n")
}, 1)

# Service loop briefly
httpuv::service(1500)
