# 🚀 AirSense — Single-Command Execution Guide

Run the entire AirSense Air Quality Prediction & Disease Mapping system with **one single terminal command**.

---

## ⚡ How to Run in a Single Command

Open your terminal in the project directory (`C:\Users\Admin\Documents\Air Quality Prediction`) and execute:

### Option 1: Python (Recommended)
```bash
python run.py
```

### Option 2: npm
```bash
npm start
```

### Option 3: Windows Batch Script (Double-click or CMD)
```cmd
run.bat
```

### Option 4: Windows PowerShell
```powershell
.\run.ps1
```

---

## ✨ What the Single Command Does Automatically:

1. **Auto-cleans Ports**: Automatically detects and frees ports `8000` and `5500` if previously occupied.
2. **Environment & Package Verification**: Checks required R packages (`readr`, `dplyr`, `tidyr`, `caret`, `randomForest`, `plumber`) and installs any missing ones into `r_libs/`.
3. **Automated ML Training**: Verifies `model.rds` exists; if missing, automatically trains the Random Forest model on `dataset/air_quality.csv`.
4. **Starts Backend API**: Launches the R Plumber API on `http://127.0.0.1:8000`.
5. **Starts Frontend Server**: Serves the modern Light Theme web app on `http://localhost:5500`.
6. **Auto-Opens Web Browser**: Launches your default browser directly to `http://localhost:5500`.
7. **Clean Graceful Shutdown**: Pressing `Ctrl + C` in the terminal cleanly terminates both servers.

---

## 🌐 URLs & Verification

- **Frontend Web Application (Light Theme):** [http://localhost:5500](http://localhost:5500)
- **Backend API Health Check:** [http://127.0.0.1:8000/health](http://127.0.0.1:8000/health)
- **Interactive Swagger Docs:** [http://127.0.0.1:8000/__docs__/](http://127.0.0.1:8000/__docs__/)

---

## 🛡️ New Feature Highlights (Light Theme)

1. **Personalized Safety & Protection Hub**:
   - Filter safety recommendations for **Athletes**, **Asthma & Sensitive Groups**, **Children & Seniors**, and **Outdoor Workers**.
2. **Actionable Gear Cards**:
   - Recommended mask types (N95 / KN95), HEPA air purifier settings, and physical exertion limits.
3. **Interactive Precaution Checklist**:
   - Check off safety precautions with a real-time progress bar.
4. **Instant PDF/Print Export**:
   - Download or print academic reports with clean light-theme typography.
