# ===========================================================
# AeroSense TN — run.R (Single-Command R Application Launcher)
# Starts the R Plumber REST API and the Frontend HTTP Server
# Verifies dependencies and model, cleans occupied ports,
# and automatically launches the web application in default browser.
# ===========================================================

cat("============================================================\n")
cat("   AeroSense TN — Tamil Nadu Air Quality & Disease Risk Engine\n")
cat("   Understand the Air. Predict the Risk. (R-First Backend)\n")
cat("============================================================\n\n")

# 1. Port Cleanup Helper
free_port <- function(port) {
  tryCatch({
    if (.Platform$OS.type == "windows") {
      lines <- suppressWarnings(system2("cmd", c("/c", sprintf("netstat -ano | findstr :%d", port)), stdout = TRUE, stderr = FALSE))
      for (line in lines) {
        parts <- strsplit(trimws(line), "\\s+")[[1]]
        if (length(parts) >= 5 && any(grepl("LISTENING", parts))) {
          pid <- tail(parts, 1)
          if (pid != "" && pid != "0" && pid != as.character(Sys.getpid())) {
            suppressWarnings(system2("taskkill", c("/F", "/PID", pid), stdout = FALSE, stderr = FALSE))
            cat(sprintf("[Setup] Freed occupied port %d (terminated PID %s)\n", port, pid))
          }
        }
      }
    }
  }, error = function(e) NULL)
}

free_port(8000)
free_port(5500)

# 2. Dependency Verification
req_script <- if (file.exists("backend/requirements.R")) "backend/requirements.R" else "requirements.R"
source(req_script)
pkg_ok <- verify_and_install_packages(auto_install = TRUE)
if (!pkg_ok) {
  stop("Missing R package dependencies could not be resolved.")
}

# 3. Model Verification
model_path <- if (file.exists("backend/model.rds")) "backend/model.rds" else if (file.exists("model.rds")) "model.rds" else NULL
if (is.null(model_path)) {
  cat("[Setup] Trained model.rds not found. Running training pipeline...\n")
  train_script <- if (file.exists("backend/train.R")) "backend/train.R" else "train.R"
  source(train_script)
  train_aqi_model()
  cat("[Setup] Model training complete.\n")
} else {
  cat(sprintf("[Setup] Verified trained model: %s\n", model_path))
}

# 4. Start Frontend Static Server on port 5500 using httpuv
frontend_dir <- if (dir.exists("frontend")) normalizePath("frontend") else normalizePath(".")
cat(sprintf("[Frontend] Serving static web portal from '%s' on http://localhost:5500 ...\n", frontend_dir))

frontend_server <- httpuv::startServer(
  host = "0.0.0.0",
  port = 5500,
  app = list(
    staticPaths = list(
      "/" = httpuv::staticPath(path = frontend_dir, indexhtml = TRUE, fallthrough = FALSE)
    )
  )
)

# 5. Open browser
Sys.sleep(1)
cat("[Launcher] Opening AeroSense TN in default web browser...\n")
tryCatch({
  utils::browseURL("http://localhost:5500")
}, error = function(e) NULL)

# 6. Cleanup handler on termination (only executed when R exits)
cleanup <- function() {
  cat("\n[AeroSense] Stopping application servers...\n")
  tryCatch(httpuv::stopServer(frontend_server), error = function(e) NULL)
  free_port(8000)
  free_port(5500)
  cat("[AeroSense] Stopped cleanly. Goodbye!\n")
}
on.exit({ cleanup() }, add = TRUE)

# 7. Start Plumber REST API on port 8000
cat("[Backend] Starting R Plumber REST API on http://127.0.0.1:8000 ...\n")
cat("\n============================================================\n")
cat(" AeroSense TN is up and running!\n")
cat("  • Frontend Web Portal : http://localhost:5500\n")
cat("  • Backend REST API    : http://127.0.0.1:8000/api/health\n")
cat(" Press Ctrl+C in this terminal to stop both servers.\n")
cat("============================================================\n\n")

api_script <- if (file.exists("backend/api_server.R")) "backend/api_server.R" else "api_server.R"
pr <- plumber::pr(api_script)
plumber::pr_run(pr, host = "0.0.0.0", port = 8000, docs = FALSE)
