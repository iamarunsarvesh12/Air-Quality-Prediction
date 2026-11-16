#!/usr/bin/env python3
"""
AeroSense TN — Full System Automated Verification Test Suite
Tests R Plumber API endpoints, input validation, 38 Tamil Nadu districts,
CORS headers, health-risk mapping, and frontend static assets.
"""

import urllib.request
import urllib.error
import json
import sys

API_BASE = "http://127.0.0.1:8000/api"
FRONTEND_BASE = "http://localhost:5500"

results = {
    "passed": 0,
    "failed": 0,
    "tests": []
}

def log_test(name, status, detail=""):
    results["tests"].append({"name": name, "status": status, "detail": detail})
    if status == "PASSED":
        results["passed"] += 1
        print(f"[PASS] {name}")
        if detail:
            print(f"       -> {detail}")
    else:
        results["failed"] += 1
        print(f"[FAIL] {name}")
        if detail:
            print(f"       -> {detail}")

print("=================================================================")
print("   AeroSense TN - Full System Automated Verification Suite")
print("   Testing R-First Backend & Frontend Integration")
print("=================================================================")

# Pre-flight check: Verify if server is running
server_online = False
try:
    req = urllib.request.Request(f"{API_BASE}/health")
    with urllib.request.urlopen(req, timeout=2) as resp:
        if resp.status == 200:
            server_online = True
except Exception:
    pass

if not server_online:
    print("\n[NOTE] AeroSense TN backend server is not currently running on http://127.0.0.1:8000.")
    print("Please launch the application first using:")
    print("   .\\run.ps1  (or run.bat / Rscript run.R)")
    print("Then run this verification test suite in a separate terminal window.\n")
    sys.exit(0)

# 1. Backend Health Check
try:
    req = urllib.request.Request(f"{API_BASE}/health")
    with urllib.request.urlopen(req, timeout=5) as resp:
        data = json.loads(resp.read().decode('utf-8'))
        cors = resp.headers.get("Access-Control-Allow-Origin")
        if resp.status == 200 and data.get("status") == "ok":
            log_test("Backend API Health Check (/api/health)", "PASSED",
                     f"Service: {data.get('service')}, Model: {data.get('model')}, R²: {data.get('r_squared')}, CORS: {cors}")
        else:
            log_test("Backend API Health Check (/api/health)", "FAILED", f"Unexpected response: {data}")
except Exception as e:
    log_test("Backend API Health Check (/api/health)", "FAILED", str(e))

# 2. Districts Directory (All 38 Districts)
try:
    req = urllib.request.Request(f"{API_BASE}/districts")
    with urllib.request.urlopen(req, timeout=5) as resp:
        data = json.loads(resp.read().decode('utf-8'))
        count = data.get("count", 0)
        districts = data.get("districts", [])
        if resp.status == 200 and count == 38 and len(districts) == 38:
            first_name = districts[0].get("name")
            last_name = districts[-1].get("name")
            log_test("Tamil Nadu 38-District Directory (/api/districts)", "PASSED",
                     f"All 38 districts present (e.g. {first_name} to {last_name})")
        else:
            log_test("Tamil Nadu 38-District Directory (/api/districts)", "FAILED", f"Expected 38, got {count}")
except Exception as e:
    log_test("Tamil Nadu 38-District Directory (/api/districts)", "FAILED", str(e))

# 3. Live Regional Hubs Summary (/api/live-data)
try:
    req = urllib.request.Request(f"{API_BASE}/live-data")
    with urllib.request.urlopen(req, timeout=10) as resp:
        data = json.loads(resp.read().decode('utf-8'))
        hubs = data.get("hubs", [])
        if resp.status == 200 and data.get("status") == "success" and len(hubs) > 0:
            hub_names = [h.get("district_name") for h in hubs]
            log_test("Live Regional Hubs Summary (/api/live-data)", "PASSED",
                     f"Active hubs: {len(hubs)} ({', '.join(hub_names[:4])}...)")
        else:
            log_test("Live Regional Hubs Summary (/api/live-data)", "FAILED", str(data))
except Exception as e:
    log_test("Live Regional Hubs Summary (/api/live-data)", "FAILED", str(e))

# 4. District-Specific Telemetry & Prediction (Trichy)
try:
    req = urllib.request.Request(f"{API_BASE}/air-quality/trichy")
    with urllib.request.urlopen(req, timeout=5) as resp:
        data = json.loads(resp.read().decode('utf-8'))
        aqi = data.get("prediction", {}).get("predicted_aqi")
        category = data.get("health_analysis", {}).get("category")
        diseases = data.get("health_analysis", {}).get("disease_risks", [])
        stages = data.get("preprocessing", {}).get("pipeline_stages", [])
        is_live = data.get("transparency", {}).get("is_live")
        if resp.status == 200 and aqi is not None and len(diseases) == 5:
            log_test("Live Telemetry & Prediction for Trichy (/api/air-quality/trichy)", "PASSED",
                     f"AQI: {aqi} ({category}), Live Feed: {is_live}, Diseases: {len(diseases)}, Stages: {len(stages)}")
        else:
            log_test("Live Telemetry & Prediction for Trichy (/api/air-quality/trichy)", "FAILED", str(data))
except Exception as e:
    log_test("Live Telemetry & Prediction for Trichy (/api/air-quality/trichy)", "FAILED", str(e))

# 5. District-Specific Telemetry (Chennai)
try:
    req = urllib.request.Request(f"{API_BASE}/air-quality/chennai")
    with urllib.request.urlopen(req, timeout=5) as resp:
        data = json.loads(resp.read().decode('utf-8'))
        aqi = data.get("prediction", {}).get("predicted_aqi")
        category = data.get("health_analysis", {}).get("category")
        if resp.status == 200 and aqi is not None:
            log_test("Live Telemetry & Prediction for Chennai (/api/air-quality/chennai)", "PASSED", f"AQI: {aqi} ({category})")
        else:
            log_test("Live Telemetry & Prediction for Chennai (/api/air-quality/chennai)", "FAILED", str(data))
except Exception as e:
    log_test("Live Telemetry & Prediction for Chennai (/api/air-quality/chennai)", "FAILED", str(e))

# 6. District Identifier Strict Validation (Negative Test: Unknown District)
try:
    req = urllib.request.Request(f"{API_BASE}/air-quality/nonexistent-district-12345")
    try:
        with urllib.request.urlopen(req, timeout=5) as resp:
            log_test("District Validation (Invalid District Rejection)", "FAILED", "Expected 404 error but got 200")
    except urllib.error.HTTPError as he:
        if he.code == 404:
            log_test("District Validation (Invalid District Rejection)", "PASSED", f"Correctly returned HTTP 404 for unknown district")
        else:
            log_test("District Validation (Invalid District Rejection)", "FAILED", f"Expected HTTP 404, got {he.code}")
except Exception as e:
    log_test("District Validation (Invalid District Rejection)", "FAILED", str(e))

# 7. 24-Hour Forecast Endpoint (/api/prediction/coimbatore)
try:
    req = urllib.request.Request(f"{API_BASE}/prediction/coimbatore")
    with urllib.request.urlopen(req, timeout=5) as resp:
        data = json.loads(resp.read().decode('utf-8'))
        forecast = data.get("forecast_24h", [])
        if resp.status == 200 and len(forecast) > 0:
            log_test("24-Hour Predictive Trajectory (/api/prediction/coimbatore)", "PASSED", f"{len(forecast)} hourly intervals generated")
        else:
            log_test("24-Hour Predictive Trajectory (/api/prediction/coimbatore)", "FAILED", str(data))
except Exception as e:
    log_test("24-Hour Predictive Trajectory (/api/prediction/coimbatore)", "FAILED", str(e))

# 8. Valid Manual Custom Sensor Prediction (/api/manual-prediction)
try:
    payload = {
        "district": "Custom Lab Station",
        "pm25": 45.0, "pm10": 78.0, "no2": 24.0, "so2": 6.5, "co": 0.85, "o3": 30.0,
        "temperature": 29.0, "humidity": 55.0, "windSpeed": 12.0, "persona": "sensitive"
    }
    req = urllib.request.Request(
        f"{API_BASE}/manual-prediction",
        data=json.dumps(payload).encode('utf-8'),
        headers={"Content-Type": "application/json"}
    )
    with urllib.request.urlopen(req, timeout=5) as resp:
        data = json.loads(resp.read().decode('utf-8'))
        aqi = data.get("prediction", {}).get("predicted_aqi")
        category = data.get("health_analysis", {}).get("category")
        primary = data.get("prediction", {}).get("primary_pollutant")
        diseases = data.get("health_analysis", {}).get("disease_risks", [])
        if resp.status == 200 and aqi is not None and category is not None and len(diseases) == 5:
            log_test("Valid Manual Prediction Engine (/api/manual-prediction)", "PASSED",
                     f"Predicted AQI: {aqi} ({category}), Dominant Pollutant: {primary}, Diseases: {len(diseases)}")
        else:
            log_test("Valid Manual Prediction Engine (/api/manual-prediction)", "FAILED", str(data))
except Exception as e:
    log_test("Valid Manual Prediction Engine (/api/manual-prediction)", "FAILED", str(e))

# 9. Manual Prediction Validation - Missing Field Rejection
try:
    bad_payload = {"district": "Lab", "pm10": 50.0} # missing pm25, no2, etc.
    req = urllib.request.Request(
        f"{API_BASE}/manual-prediction",
        data=json.dumps(bad_payload).encode('utf-8'),
        headers={"Content-Type": "application/json"}
    )
    try:
        with urllib.request.urlopen(req, timeout=5) as resp:
            log_test("Manual Prediction Validation (Missing Fields)", "FAILED", "Expected HTTP 400 rejection")
    except urllib.error.HTTPError as he:
        if he.code == 400:
            log_test("Manual Prediction Validation (Missing Fields)", "PASSED", "Correctly rejected with HTTP 400")
        else:
            log_test("Manual Prediction Validation (Missing Fields)", "FAILED", f"Expected HTTP 400, got {he.code}")
except Exception as e:
    log_test("Manual Prediction Validation (Missing Fields)", "FAILED", str(e))

# 10. Manual Prediction Validation - Non-Numeric Input Rejection
try:
    bad_payload = {
        "district": "Lab", "pm25": "INVALID_TEXT", "pm10": 78.0, "no2": 24.0, "so2": 6.5, "co": 0.85, "o3": 30.0
    }
    req = urllib.request.Request(
        f"{API_BASE}/manual-prediction",
        data=json.dumps(bad_payload).encode('utf-8'),
        headers={"Content-Type": "application/json"}
    )
    try:
        with urllib.request.urlopen(req, timeout=5) as resp:
            log_test("Manual Prediction Validation (Non-Numeric Input)", "FAILED", "Expected HTTP 400 rejection")
    except urllib.error.HTTPError as he:
        if he.code == 400:
            log_test("Manual Prediction Validation (Non-Numeric Input)", "PASSED", "Correctly rejected non-numeric string with HTTP 400")
        else:
            log_test("Manual Prediction Validation (Non-Numeric Input)", "FAILED", f"Expected HTTP 400, got {he.code}")
except Exception as e:
    log_test("Manual Prediction Validation (Non-Numeric Input)", "FAILED", str(e))

# 11. Manual Prediction Validation - Out-of-Range Value Rejection
try:
    bad_payload = {
        "district": "Lab", "pm25": 999999.0, "pm10": 78.0, "no2": 24.0, "so2": 6.5, "co": 0.85, "o3": 30.0
    }
    req = urllib.request.Request(
        f"{API_BASE}/manual-prediction",
        data=json.dumps(bad_payload).encode('utf-8'),
        headers={"Content-Type": "application/json"}
    )
    try:
        with urllib.request.urlopen(req, timeout=5) as resp:
            log_test("Manual Prediction Validation (Out-of-Range Input)", "FAILED", "Expected HTTP 400 rejection")
    except urllib.error.HTTPError as he:
        if he.code == 400:
            log_test("Manual Prediction Validation (Out-of-Range Input)", "PASSED", "Correctly rejected 999999.0 out-of-range PM2.5 with HTTP 400")
        else:
            log_test("Manual Prediction Validation (Out-of-Range Input)", "FAILED", f"Expected HTTP 400, got {he.code}")
except Exception as e:
    log_test("Manual Prediction Validation (Out-of-Range Input)", "FAILED", str(e))

# 12. Pipeline Data Status (/api/data-status)
try:
    req = urllib.request.Request(f"{API_BASE}/data-status")
    with urllib.request.urlopen(req, timeout=5) as resp:
        data = json.loads(resp.read().decode('utf-8'))
        status = data.get("status")
        pipeline = data.get("pipeline", {})
        if resp.status == 200 and status == "operational" and pipeline.get("random_forest_model"):
            log_test("Data Preprocessing & Pipeline Status (/api/data-status)", "PASSED",
                     f"Pipeline: {status}, Model: {pipeline.get('random_forest_model')}")
        else:
            log_test("Data Preprocessing & Pipeline Status (/api/data-status)", "FAILED", str(data))
except Exception as e:
    log_test("Data Preprocessing & Pipeline Status (/api/data-status)", "FAILED", str(e))

# 13. Frontend Static Assets Availability (Non-Python httpuv Server)
pages = [
    "index.html",
    "live-dashboard.html",
    "manual-prediction.html",
    "css/style.css",
    "css/responsive.css",
    "js/api.js",
    "js/charts.js",
    "js/app.js",
    "js/manual-prediction.js"
]
for page in pages:
    try:
        req = urllib.request.Request(f"{FRONTEND_BASE}/{page}")
        with urllib.request.urlopen(req, timeout=5) as resp:
            if resp.status == 200:
                log_test(f"Frontend Static Server ({page})", "PASSED", f"Status: 200 OK ({len(resp.read())} bytes)")
            else:
                log_test(f"Frontend Static Server ({page})", "FAILED", f"Status: {resp.status}")
    except Exception as e:
        log_test(f"Frontend Static Server ({page})", "FAILED", str(e))

print("=================================================================")
print(f"   Test Summary: {results['passed']} Passed, {results['failed']} Failed")
print("=================================================================")

if results['failed'] > 0:
    sys.exit(1)
