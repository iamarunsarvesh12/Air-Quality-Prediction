# AeroSense TN — How to Run the Application

This document provides instructions and terminal commands to run the **AeroSense TN** (Tamil Nadu Air Quality Predictor & Health Risk Intelligence) system using its **R-First Backend Architecture**.

---

## ⚡ Quick Start: Single Command Execution (Recommended)

You can launch both the **R Backend REST API** and **Frontend Web Portal** using **ONE single terminal command** without needing any Python backend:

### Option A: Using Windows Batch Script (Recommended for Windows)
Double-click `run.bat` in File Explorer or run in CMD / PowerShell:
```cmd
run.bat
```

### Option B: Using PowerShell
```powershell
.\run.ps1
```

### Option C: Using Direct Rscript
```powershell
Rscript run.R
```

### Option D: Using npm (calls Rscript)
```powershell
npm start
```

---

## 🌐 URLs Once Running:
- **Frontend Web Portal:** [http://localhost:5500](http://localhost:5500)
  - **Live District Dashboard:** [http://localhost:5500/live-dashboard.html](http://localhost:5500/live-dashboard.html)
  - **Manual Prediction Engine:** [http://localhost:5500/manual-prediction.html](http://localhost:5500/manual-prediction.html)
- **R Plumber Backend REST API:** [http://127.0.0.1:8000/api/health](http://127.0.0.1:8000/api/health)

---

## 🛠️ Model Training (Optional):
The Random Forest model is pre-trained and serialized in `backend/model.rds`. If you ever want to re-train the model from scratch on `backend/dataset/air_quality.csv`:
```powershell
Rscript backend/train.R
```

---

## 🧪 Running the Full Automated Verification Test Suite:

### Via Native R:
```powershell
Rscript scratch/test_suite.R
```

### Via Python (Optional Testing Client):
```powershell
python scratch/test_suite.py
```

Both test suites perform 21 comprehensive checks covering all endpoints, 38 districts, input validation, disease risk mappings, and frontend static assets.
