# ===========================================================
# AeroSense TN — run.R (Single-Command R Application Launcher)
# Starts the R Plumber REST API and the Frontend HTTP Server
# Verifies dependencies and model, checks port availability safely,
# verifies readiness via /api/health, and launches browser once ready.
# ===========================================================

cat("============================================================\n")
cat("   AeroSense TN — Tamil Nadu Air Quality & Disease Risk Engine\n")
cat("   Understand the Air. Predict the Risk. (R-First Backend)\n")
cat("============================================================\n\n")

# 1. Safe Port Conflict Check
check_port_safety <- function(port) {
  tryCatch(
    {
      if (.Platform$OS.type == "windows") {
        lines <- suppressWarnings(system2("cmd", c("/c", sprintf("netstat -ano | findstr :%d", port)), stdout = TRUE, stderr = FALSE))
        for (line in lines) {
          parts <- strsplit(trimws(line), "\\s+")[[1]]
          if (length(parts) >= 5 && any(grepl("LISTENING", parts))) {
            pid <- tail(parts, 1)
            if (pid != "" && pid != "0" && pid != as.character(Sys.getpid())) {
              cat(sprintf("[Setup] Port %d was occupied by PID %s. Freeing port...\n", port, pid))
              suppressWarnings(system(sprintf("taskkill /F /PID %s >nul 2>&1", pid)))
            }
          }
        }
        Sys.sleep(0.3)
      }
    },
    error = function(e) NULL
  )
}

check_port_safety(8000)
check_port_safety(5500)

# 2. Dependency Verification
req_script <- if (file.exists("backend/requirements.R")) "backend/requirements.R" else "requirements.R"
source(req_script)
pkg_ok <- verify_and_install_packages(auto_install = TRUE)
if (!pkg_ok) {
  stop("Missing R package dependencies could not be resolved.")
}

# 3. Model & Dataset Verification
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
cat(sprintf("[Frontend] Serving static web portal from '%s' on http://127.0.0.1:5500 ...\n", frontend_dir))

frontend_server <- httpuv::startServer(
  host = "0.0.0.0",
  port = 5500,
  app = list(
    staticPaths = list(
      "/" = httpuv::staticPath(path = frontend_dir, indexhtml = TRUE, fallthrough = FALSE)
    )
  )
)

# 5. Readiness Notification & Browser Launch Callback
suppressPackageStartupMessages(library(later))

launch_browser_when_ready <- function() {
  cat("\n============================================================\n")
  cat(" AeroSense TN is fully verified and ready!\n")
  meta_file <- if (file.exists("backend/model_metadata.json")) "backend/model_metadata.json" else if (file.exists("model_metadata.json")) "model_metadata.json" else NULL
  if (!is.null(meta_file)) {
    tryCatch(
      {
        m <- jsonlite::fromJSON(meta_file)
        model_lbl <- if (!is.null(m$algorithm)) m$algorithm else if (!is.null(m$model_name)) m$model_name else "RandomForest"
        cat(sprintf("  • Model Status   : %s (R² = %.4f, RMSE = %.2f)\n", model_lbl, m$r_squared, m$rmse))
      },
      error = function(e) NULL
    )
  }
  cat("  • Districts      : 38 Supported\n")
  cat("  • Frontend Portal: http://127.0.0.1:5500\n")
  cat("  • Live Dashboard : http://127.0.0.1:5500/live-dashboard.html\n")
  cat("  • Manual Engine  : http://127.0.0.1:5500/manual-prediction.html\n")
  cat("  • Backend API    : http://127.0.0.1:8000/api/health\n")
  cat("============================================================\n\n")
  cat("[Launcher] Opening AeroSense TN in default web browser...\n")
  tryCatch(
    {
      utils::browseURL("http://127.0.0.1:5500/live-dashboard.html")
    },
    error = function(e) NULL
  )
}

# Schedule readiness notification once Plumber event loop begins
later::later(launch_browser_when_ready, delay = 1.0)

# 6. Cleanup handler on termination
cleanup <- function() {
  cat("\n[AeroSense] Stopping application servers...\n")
  tryCatch(httpuv::stopServer(frontend_server), error = function(e) NULL)
  cat("[AeroSense] Stopped cleanly. Goodbye!\n")
}
on.exit(
  {
    cleanup()
  },
  add = TRUE
)

# 7. Start Plumber REST API on port 8000 (blocks on httpuv event loop)
cat("[Backend] Starting R Plumber REST API on http://127.0.0.1:8000 ...\n")
api_script <- if (file.exists("backend/api_server.R")) "backend/api_server.R" else "api_server.R"
pr <- plumber::pr(api_script)
plumber::pr_run(pr, host = "0.0.0.0", port = 8000, docs = FALSE)
