#!/usr/bin/env python3
"""
AirSense — Single-Command Runner Script
Runs the R Plumber API backend and Python HTTP frontend in parallel,
checks requirements, auto-cleans occupied ports, trains model if missing,
and opens the app in your default browser.
"""

import sys
import os
import time
import subprocess
import webbrowser
import signal

ROOT_DIR = os.path.dirname(os.path.abspath(__file__))
BACKEND_DIR = os.path.join(ROOT_DIR, "backend")
FRONTEND_DIR = os.path.join(ROOT_DIR, "frontend")
MODEL_PATH = os.path.join(BACKEND_DIR, "model.rds")
R_LIBS_DIR = os.path.join(ROOT_DIR, "r_libs")

def log(msg, label="AirSense"):
    print(f"[{label}] {msg}", flush=True)

def find_executable(name):
    from shutil import which
    return which(name)

def free_port(port):
    """Free port if already in use by a previous process."""
    try:
        if os.name == 'nt':
            out = subprocess.check_output(f'netstat -ano | findstr :{port}', shell=True, text=True, stderr=subprocess.DEVNULL)
            for line in out.strip().splitlines():
                parts = line.strip().split()
                if len(parts) >= 5 and "LISTENING" in parts:
                    pid = parts[-1]
                    if pid and pid != "0" and pid != str(os.getpid()):
                        subprocess.run(f'taskkill /F /PID {pid}', shell=True, capture_output=True)
                        log(f"Freed occupied port {port} (killed lingering process PID {pid})", "Setup")
        else:
            out = subprocess.check_output(f'lsof -ti:{port}', shell=True, text=True, stderr=subprocess.DEVNULL)
            for pid in out.strip().splitlines():
                if pid:
                    subprocess.run(f'kill -9 {pid}', shell=True, capture_output=True)
                    log(f"Freed occupied port {port}", "Setup")
    except Exception:
        pass

def check_rscript():
    rscript = find_executable("Rscript")
    if not rscript:
        log("ERROR: 'Rscript' is not found in PATH. Please install R and add it to PATH.", "Check")
        sys.exit(1)
    return rscript

def check_r_packages(rscript):
    log("Verifying R packages...", "Setup")
    check_code = (
        ".libPaths(c('r_libs', .libPaths())); "
        "pkgs <- c('readr', 'dplyr', 'tidyr', 'caret', 'randomForest', 'plumber'); "
        "missing <- pkgs[!sapply(pkgs, requireNamespace, quietly=TRUE)]; "
        "if(length(missing) > 0) { cat(paste(missing, collapse=',')) }"
    )
    try:
        res = subprocess.run([rscript, "-e", check_code], cwd=ROOT_DIR, capture_output=True, text=True)
        missing_pkgs = res.stdout.strip()
        if missing_pkgs:
            log(f"Installing missing R packages ({missing_pkgs})... This may take a moment.", "Setup")
            install_code = (
                f".libPaths(c('r_libs', .libPaths())); "
                f"install.packages(c({','.join([repr(p) for p in missing_pkgs.split(',')])}), lib='r_libs', repos='https://cloud.r-project.org')"
            )
            subprocess.run([rscript, "-e", install_code], cwd=ROOT_DIR, check=True)
            log("R packages installed successfully.", "Setup")
        else:
            log("All R packages are ready.", "Setup")
    except Exception as e:
        log(f"Warning during package check: {e}", "Setup")

def check_model(rscript):
    if not os.path.exists(MODEL_PATH):
        log("Model file 'model.rds' not found. Training Random Forest model now...", "Setup")
        train_code = ".libPaths(c('../r_libs', 'r_libs', .libPaths())); source('train_model.R')"
        subprocess.run([rscript, "-e", train_code], cwd=BACKEND_DIR, check=True)
        log("Model trained and saved to backend/model.rds", "Setup")
    else:
        log("Trained model file 'model.rds' verified.", "Setup")

def main():
    print("=" * 65)
    print("   AeroSense TN — Tamil Nadu Air Quality Predictor & Intelligence")
    print("   Understand the Air. Predict the Risk.")
    print("=" * 65)
    
    # 1. Free ports 8000 and 5500 if occupied
    free_port(8000)
    free_port(5500)

    # 2. Check environment
    rscript = check_rscript()
    check_r_packages(rscript)
    check_model(rscript)

    # 3. Start Plumber backend
    log("Starting R Plumber REST API Engine on http://127.0.0.1:8000 ...", "Backend")
    plumber_cmd = [
        rscript,
        "-e",
        ".libPaths(c('r_libs', 'backend/r_libs', .libPaths())); pr <- plumber::pr('backend/api_server.R'); plumber::pr_run(pr, host = '0.0.0.0', port = 8000, docs = FALSE)"
    ]
    backend_proc = subprocess.Popen(plumber_cmd, cwd=ROOT_DIR)

    # 4. Start Frontend HTTP server
    log("Starting Frontend HTTP Server on http://localhost:5500 ...", "Frontend")
    frontend_cmd = [
        sys.executable,
        "-m",
        "http.server",
        "5500",
        "--directory",
        FRONTEND_DIR
    ]
    frontend_proc = subprocess.Popen(frontend_cmd, cwd=ROOT_DIR)

    time.sleep(2)
    log("Opening AeroSense TN in default browser...", "Launcher")
    try:
        webbrowser.open("http://localhost:5500")
    except Exception:
        pass

    print("\n" + "=" * 65)
    print(" AeroSense TN is up and running!")
    print("  - Frontend:   http://localhost:5500")
    print("  - Backend API: http://127.0.0.1:8000/api/health")
    print(" Press Ctrl+C in this terminal to stop both servers.")
    print("=" * 65 + "\n")

    def cleanup(sig=None, frame=None):
        print("\nShutting down AirSense servers...")
        try:
            backend_proc.terminate()
            frontend_proc.terminate()
            backend_proc.wait(timeout=3)
            frontend_proc.wait(timeout=3)
        except Exception:
            backend_proc.kill()
            frontend_proc.kill()
        free_port(8000)
        free_port(5500)
        print("AirSense stopped cleanly. Goodbye!")
        sys.exit(0)

    signal.signal(signal.SIGINT, cleanup)
    signal.signal(signal.SIGTERM, cleanup)

    try:
        while True:
            time.sleep(1)
            if backend_proc.poll() is not None:
                log("Backend process exited unexpectedly.", "Error")
                cleanup()
            if frontend_proc.poll() is not None:
                log("Frontend process exited unexpectedly.", "Error")
                cleanup()
    except KeyboardInterrupt:
        cleanup()

if __name__ == "__main__":
    main()
