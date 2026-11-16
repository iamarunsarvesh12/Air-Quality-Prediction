# 🚀 AeroSense TN — Single-Command Execution Guide

Run the entire AeroSense TN Air Quality Prediction & Health Risk Intelligence system with **one single terminal command** using the **R-First Architecture**.

---

## ⚡ How to Run in a Single Command

Open your terminal in the project directory (`C:\Users\Admin\Documents\Air_Quality_Prediction`) and execute any of the following:

### Option 1: Windows Batch Script (Recommended for Windows)
```cmd
run.bat
```
*(You can also simply double-click `run.bat` in Windows Explorer.)*

### Option 2: Windows PowerShell
```powershell
.\run.ps1
```
*(If PowerShell blocks script execution on your system, run: `powershell -ExecutionPolicy Bypass -File .\run.ps1`)*

### Option 3: Direct Rscript
```powershell
Rscript run.R
```

### Option 4: npm
```bash
npm start
```

---

## ✨ What the Single Command Does Automatically:

1. **Auto-cleans Ports**: Automatically detects and frees ports `8000` and `5500` if previously occupied.
2. **Environment & Package Verification**: Checks required R packages (`plumber`, `randomForest`, `jsonlite`, `readr`, `dplyr`, `curl`, `httr`, `httpuv`) and displays their versions.
3. **Automated ML Training**: Verifies `model.rds` exists; if missing, automatically runs the Random Forest training pipeline on `backend/dataset/air_quality.csv`.
4. **Starts Backend REST API**: Launches the R Plumber REST API on `http://127.0.0.1:8000`.
5. **Starts Frontend Static Server**: Serves the modern Hallmark web application on `http://localhost:5500` using R's lightweight `httpuv` engine.
6. **Auto-Opens Web Browser**: Automatically opens your default browser directly to `http://localhost:5500`.
7. **Clean Graceful Shutdown**: Pressing `Ctrl + C` in the terminal cleanly terminates both servers.

---

## 🌐 URLs & Verification

- **Frontend Web Application:** [http://localhost:5500](http://localhost:5500)
- **Live District Dashboard:** [http://localhost:5500/live-dashboard.html](http://localhost:5500/live-dashboard.html)
- **Manual Prediction Engine:** [http://localhost:5500/manual-prediction.html](http://localhost:5500/manual-prediction.html)
- **Backend API Health Check:** [http://127.0.0.1:8000/api/health](http://127.0.0.1:8000/api/health)
- **All 38 Districts Directory:** [http://127.0.0.1:8000/api/districts](http://127.0.0.1:8000/api/districts)

---

## 🧪 Automated Testing

Verify the complete system anytime with the automated 21-point test suite:
```powershell
Rscript scratch/test_suite.R
```
