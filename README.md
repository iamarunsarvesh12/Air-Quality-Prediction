# AirSense — Air Quality Analysis & Disease Prediction Using Machine Learning with R

A full-stack academic project: an HTML/CSS/JS frontend talking to an R Plumber
backend that predicts Air Quality Index (AQI) with a Random Forest model, maps
it to a category, and surfaces the associated health effects and
recommendations.

## Project structure

```
AirQualityPrediction/
│
├── frontend/
│   ├── index.html          Module 1  — Home page
│   ├── analysis.html       Module 2  — Data input form
│   ├── result.html         Module 8  — Results dashboard
│   ├── css/
│   │   ├── style.css       Global styles
│   │   ├── form.css        Module 2 styles
│   │   └── dashboard.css   Module 8 styles
│   ├── js/
│   │   ├── main.js         Module 1  — nav + hero
│   │   ├── form.js         Module 2  — validation + API call
│   │   ├── dashboard.js    Module 8  — renders results
│   │   ├── charts.js       Module 9  — Chart.js visualizations
│   │   └── report.js       Module 10 — print / save report
│   └── images/
│
├── backend/
│   ├── dataset/
│   │   └── air_quality.csv     Sample training data (replace with real data)
│   ├── load_dataset.R      Module 3 — read CSV
│   ├── preprocess.R        Module 3 — clean & prepare data
│   ├── train_model.R       Module 4 — train & save Random Forest model
│   ├── category.R          Module 6 — AQI → category/color mapping
│   ├── disease_mapping.R   Module 7 — category → health effects
│   ├── predict.R           Module 5 — prediction logic
│   ├── api.R               Module 5 — Plumber API entry point
│   ├── health_data.csv     Health effects/recommendations table
│   └── model.rds           Generated after training (not included yet)
│
└── README.md
```

## Prerequisites

- **VS Code** with the extensions:
  - *R* (REditorSupport.r) and *R LSP Client* — for running `.R` files
  - *Live Server* (ritwickdey.LiveServer) — for serving the frontend
- **R (≥ 4.2)** installed and on PATH
- **R packages**: `readr`, `dplyr`, `tidyr`, `caret`, `randomForest`, `plumber`

Install the R packages once, from the R console or VS Code's R terminal:

```r
install.packages(c("readr", "dplyr", "tidyr", "caret", "randomForest", "plumber"))
```

## Run order (first time)

Open a terminal in VS Code, `cd` into `backend/`, then:

1. **Train the model** (reads `dataset/air_quality.csv`, writes `model.rds`):
   ```bash
   Rscript train_model.R
   ```
   Replace `dataset/air_quality.csv` with your real historical dataset first —
   the included file is a small sample so the pipeline runs end-to-end.

2. **Start the API** (keep this terminal running):
   ```bash
   R -e "plumber::pr('api.R') |> plumber::pr_run(port = 8000)"
   ```
   You should see `Running plumber API at http://127.0.0.1:8000`.
   Check it in a browser: `http://127.0.0.1:8000/health`.

3. **Serve the frontend**, in a second terminal, from `frontend/`:
   - Easiest: right-click `index.html` in VS Code → **Open with Live Server**.
   - Or with Python: `python -m http.server 5500` then open
     `http://localhost:5500`.

4. Open the site, click **Analyze Air Quality**, fill in the form, and submit.
   The request goes to `http://127.0.0.1:8000/predict` (see
   `API_BASE_URL` at the top of `frontend/js/form.js` — change the port there
   if you started the API on a different one).

## Day-to-day run order

Once the model is trained, you only need steps 2 and 3 above each time you
work on the project — no need to retrain unless the dataset changes.

## Notes

- CORS is enabled in `api.R` so the frontend (served on a different port) can
  call the API directly.
- `sessionStorage` is used to pass the prediction result from `analysis.html`
  to `result.html` — no backend session state is needed.
- Swap in your own dataset by replacing `backend/dataset/air_quality.csv` and
  re-running `train_model.R`; update `FEATURE_COLUMNS` in `preprocess.R` if
  your column names differ.
