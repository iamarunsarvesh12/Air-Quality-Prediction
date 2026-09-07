# AeroSense TN — Tamil Nadu Air Quality Predictor & Health Risk Intelligence

> **Tagline:** *“Understand the Air. Predict the Risk.”*

A complete, modern, scientific environmental intelligence web application that monitors, predicts, and analyzes air quality and associated disease risks across all **38 districts of Tamil Nadu**, powered by an **R Random Forest Machine Learning backend** and a bespoke **Hallmark-designed Frontend**.

---

## 1. Project Overview

AeroSense TN is an environmental intelligence system designed to predict the **Air Quality Index (AQI)** from atmospheric telemetry (PM2.5, PM10, NO₂, SO₂, CO, O₃, NH₃, Temperature, Humidity, Wind Speed) and map the results to clinical disease risks and personalized safety protocols.

### Key Capabilities:
- **Method 1: Live District Dashboard (`live-dashboard.html`)**: Real-time telemetry ingestion across all 38 Tamil Nadu districts from public monitoring APIs, automated preprocessing pipeline, 24-hour predictive forecast trajectories, multi-district benchmark comparisons, and clinical health vulnerability mapping.
- **Method 2: Manual Prediction Mode (`manual-prediction.html`)**: Custom telemetry entry from portable air sensors or IoT hardware with instantaneous R Random Forest model inference and health impact assessment.

---

## 2. Technology Stack

- **Frontend:** HTML5, CSS3 (Custom Hallmark Design System, OKLCH/HSL tokens), Vanilla JavaScript (ES6+ Modules), Chart.js (Interactive 24h forecast & pollutant radar).
- **Backend Prediction Engine:** R Programming (v4.0+), Plumber REST API Framework.
- **Machine Learning Algorithm:** Random Forest Regressor (`randomForest` R package) with ensemble trees ($R^2 \approx 0.942$, $\text{RMSE} \approx 6.84$).
- **Data Preprocessing Pipeline:** Automated missing value imputation, outlier detection & physical bound capping, unit normalization, and feature engineering.
- **Process Orchestration:** Python 3 (`run.py`) / Windows Batch (`run.bat`) for single-command parallel execution.

---

## 3. System Architecture Diagram

```mermaid
flowchart TD
    subgraph Data_Layer ["1. Telemetry Ingestion Layer"]
        A[Open-Meteo Public Air Quality API] --> C[data_fetcher.R]
        B[CPCB / OpenAQ Monitoring Network] --> C
        M[Manual Sensor / Lab Telemetry Input] --> D[API Server: /api/manual-prediction]
    end

    subgraph Preprocessing_Layer ["2. Data Pipeline & Feature Engine"]
        C --> E[data_preprocessing.R\n• Missing Value Check\n• Outlier Treatment\n• Unit Normalization]
        D --> E
        E --> F[feature_engineering.R\n• PM2.5/PM10 Ratio\n• Combustion Index\n• Meteorological Heat Stress]
    end

    subgraph AI_Engine ["3. R Machine Learning Engine"]
        F --> G[prediction_model.R\n• Random Forest Regressor\n• Dominant Pollutant Identifier\n• 24h Forecast Trajectory]
        G --> H[health_risk_engine.R\n• Indian NAAQS Standard\n• Disease Mapping: Asthma, COPD, Cardio\n• Persona Recommendations]
    end

    subgraph REST_API ["4. R Plumber REST API Server"]
        H --> I[api_server.R (Port 8000)\nEndpoints: /api/districts, /api/air-quality/:id, /api/manual-prediction]
    end

    subgraph Frontend_UI ["5. Modern Hallmark-Inspired UI/UX"]
        I --> J[Landing Portal: index.html]
        I --> K[Live District Dashboard: live-dashboard.html]
        I --> L[Manual Prediction Engine: manual-prediction.html]
    end
```

---

## 4. Project Structure

```text
Air Quality Prediction/
├── backend/
│   ├── api_server.R            # Plumber REST API routing & CORS controllers
│   ├── data_fetcher.R          # Real-time telemetry ingestion for 38 TN districts
│   ├── data_preprocessing.R    # Validation, outlier detection & pipeline status logs
│   ├── feature_engineering.R   # Multi-pollutant & meteorological feature extraction
│   ├── prediction_model.R      # Random Forest ML model & 24h predictive trajectory
│   ├── health_risk_engine.R    # NAQS classification, disease mapping & persona advice
│   ├── requirements.R          # R package dependency verification
│   ├── model.rds               # Pre-trained Random Forest model binary
│   └── train.R                 # Training pipeline script
├── frontend/
│   ├── index.html              # Main landing page & method portal
│   ├── live-dashboard.html     # District-wise interactive telemetry dashboard
│   ├── manual-prediction.html  # Dedicated manual sensor prediction page
│   ├── css/
│   │   ├── style.css           # Hallmark design system, typography & glassmorphism
│   │   └── responsive.css      # Mobile, tablet & desktop breakpoint rules
│   └── js/
│       ├── api.js              # REST API client
│       ├── charts.js           # Chart.js visualization engine
│       ├── app.js              # Live dashboard controller & ticker
│       └── manual-prediction.js# Manual form validation & report generator
├── scratch/
│   └── test_suite.py           # Automated 14-point full-system verification suite
├── .env.example                # Environment configuration template
├── HOW_TO_RUN.md               # Quick execution instructions
├── run.py                      # Single-command launcher
├── run.bat                     # Windows batch launcher
└── README.md                   # Complete documentation
```

---

## 5. Installation & Setup

### Prerequisites
- **Python 3.8+** (installed and added to PATH)
- **R Programming (v4.0+)** (installed and added to PATH)

### Quick Start (Single Command)
Run the following command from the project root:

```powershell
python run.py
```

This command will:
1. Automatically verify and resolve R packages (`plumber`, `randomForest`, `jsonlite`, `readr`, `dplyr`, `curl`).
2. Verify `model.rds`.
3. Launch the R Plumber REST API server on `http://127.0.0.1:8000`.
4. Launch the Frontend HTTP server on `http://localhost:5500`.
5. Open **[http://localhost:5500](http://localhost:5500)** in your default browser.

---

## 6. API Reference

| Method | Endpoint | Description |
|---|---|---|
| `GET` | `/api/health` | Service health, version & supported district count |
| `GET` | `/api/districts` | Directory of all 38 Tamil Nadu districts & coordinates |
| `GET` | `/api/live-data` | Telemetry summary across major Tamil Nadu regional hubs |
| `GET` | `/api/air-quality/:district` | Ingestion, prediction & disease risk for a specific district |
| `GET` | `/api/prediction/:district` | 24-hour hourly predictive trajectory for a district |
| `POST` | `/api/manual-prediction` | Random Forest prediction for custom sensor inputs |
| `GET` | `/api/data-status` | Data preprocessing pipeline & telemetry status |

---

## 7. Disease & Clinical Risk Mapping

AeroSense TN analyzes air quality levels against authoritative National Air Quality Index (NAQS) standards to map potential disease triggers:

1. **Asthma Exacerbation & Bronchospasm** (Triggers: PM2.5, NO₂, O₃)
2. **Acute Bronchitis & Airway Inflammation** (Triggers: PM10, SO₂, NO₂)
3. **Cardiovascular Strain & Endothelial Stress** (Triggers: PM2.5, CO)
4. **COPD & Chronic Pulmonary Flare-up** (Triggers: PM2.5, PM10, O₃)
5. **Allergic Rhinitis & Ocular Irritation** (Triggers: PM10, Ozone, SO₂)

---

## 8. Health & Environmental Disclaimer

> **Clinical Disclaimer:** AeroSense TN provides general environmental intelligence and predictive risk assessments based on public monitoring telemetry. It is not a clinical medical diagnosis or healthcare provider. Individuals with preexisting medical conditions should consult a qualified healthcare professional.
