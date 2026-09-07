# AeroSense TN — How to Run the Application

This document provides instructions and terminal commands to run the **AeroSense TN** (Tamil Nadu Air Quality Predictor & Health Risk Intelligence) system.

---

## ⚡ Quick Start: Single Command Execution (Recommended)

You can launch both the **R Backend REST API** and **Frontend Web App** using **ONE single terminal command**:

### Option A: Using Python (Recommended)
```powershell
python run.py
```

### Option B: Using Windows Batch
```cmd
run.bat
```

### Option C: Using npm
```powershell
npm start
```

---

## 🌐 URLs Once Running:
- **Frontend Web Portal:** [http://localhost:5500](http://localhost:5500)
  - **Live District Dashboard:** [http://localhost:5500/live-dashboard.html](http://localhost:5500/live-dashboard.html)
  - **Manual Prediction Engine:** [http://localhost:5500/manual-prediction.html](http://localhost:5500/manual-prediction.html)
- **R Plumber Backend API:** [http://127.0.0.1:8000/api/health](http://127.0.0.1:8000/api/health)

---

## 🧪 Running the Full Automated Verification Test Suite:
```powershell
python scratch/test_suite.py
```
