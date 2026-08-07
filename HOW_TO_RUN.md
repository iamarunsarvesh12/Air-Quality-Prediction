# AirSense — Step-by-Step Execution Guide

This document provides clear, step-by-step instructions and exact terminal commands to run the **AirSense** Air Quality Prediction & Disease Mapping system.

---

## 📋 Overview of Running Components

The application consists of two main parts:
1. **Backend API (R Plumber)** — Runs on `http://127.0.0.1:8000`
2. **Frontend Web Interface (HTML/CSS/JS)** — Runs on `http://localhost:5500`

---

## 🚀 Step-by-Step Instructions

### Step 1: Install Required R Packages (One-Time Setup)

If R packages (`readr`, `dplyr`, `tidyr`, `caret`, `randomForest`, `plumber`) are not installed yet, run this command in your terminal:

```powershell
cd "C:\Users\Admin\Documents\Air Quality Prediction"
Rscript -e ".libPaths(c('r_libs', .libPaths())); install.packages(c('readr', 'dplyr', 'tidyr', 'caret', 'randomForest', 'plumber'), lib='r_libs', repos='https://cloud.r-project.org')"
```

---

### Step 2: Train the Model (Optional)

> **Note:** A trained model file (`model.rds`) is already provided inside `backend/`. You only need to run this step if you update or replace `backend/dataset/air_quality.csv`.

```powershell
cd "C:\Users\Admin\Documents\Air Quality Prediction\backend"
Rscript -e ".libPaths(c('../r_libs', .libPaths())); source('train_model.R')"
```

---

### Step 3: Start the Backend API Server (Terminal 1)

Open **Terminal 1**, execute the following command, and **keep this terminal running**:

```powershell
cd "C:\Users\Admin\Documents\Air Quality Prediction\backend"
Rscript -e ".libPaths(c('../r_libs', .libPaths())); plumber::pr_run(plumber::pr('api.R'), port = 8000)"
```

#### Verification:
Open your browser or run in PowerShell to verify the backend is active:
- **URL:** [http://127.0.0.1:8000/health](http://127.0.0.1:8000/health)
- Expected response: `{"status":"ok","message":"AirSense API is running"}`

---

### Step 4: Serve the Frontend Web Application (Terminal 2)

Open a **NEW Terminal window (Terminal 2)** and run one of the options below:

#### Option A: Using Python (Recommended)
```powershell
cd "C:\Users\Admin\Documents\Air Quality Prediction\frontend"
python -m http.server 5500
```

#### Option B: Using VS Code Live Server
1. In VS Code Explorer, navigate to `frontend/index.html`.
2. Right-click `index.html` -> Select **Open with Live Server**.

---

### Step 5: Access & Use the Application

1. Open your web browser and navigate to:
   - **Frontend URL:** [http://localhost:5500](http://localhost:5500)
2. Click **Analyze Air Quality**.
3. Fill in the pollutant and weather parameters:
   - PM2.5, PM10, NO₂, SO₂, CO, O₃, Temperature, Humidity, Wind Speed.
4. Click **Analyze Air Quality →** to submit.
5. View your detailed AQI prediction, interactive charts, disease risk mapping, and recommendations.
6. Click **Print / Save as PDF** to generate an academic report.

---

## 🛠️ Troubleshooting

- **Error: `Model file not found`**
  - Make sure `model.rds` exists in `backend/`. If missing, run Step 2 to train and save the model.
- **Error: `Could not reach prediction API` in browser**
  - Ensure the backend API (Step 3) is running in Terminal 1 on port 8000.
- **Port 8000 or 5500 already in use**
  - Change port numbers in the commands or update `API_BASE_URL` in `frontend/js/form.js` if changing port 8000.
