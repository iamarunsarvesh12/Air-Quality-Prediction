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
        print(f"       -> {detail}")

print("=================================================================")
print("   AeroSense TN - Full System Automated Verification Suite")
print("=================================================================")

# 1. Backend Health Check
try:
    req = urllib.request.Request(f"{API_BASE}/health")
    with urllib.request.urlopen(req, timeout=5) as resp:
        data = json.loads(resp.read().decode('utf-8'))
        if resp.status == 200 and data.get("status") == "ok":
            log_test("Backend API Health Check (/api/health)", "PASSED", f"Service: {data.get('service')}, Model: {data.get('model')}")
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
        if resp.status == 200 and count == 38:
            log_test("Tamil Nadu 38-District Directory (/api/districts)", "PASSED", f"Count: {count} districts verified")
        else:
            log_test("Tamil Nadu 38-District Directory (/api/districts)", "FAILED", f"Expected 38, got {count}")
except Exception as e:
    log_test("Tamil Nadu 38-District Directory (/api/districts)", "FAILED", str(e))

# 3. Live District Prediction & Telemetry (Trichy)
try:
    req = urllib.request.Request(f"{API_BASE}/air-quality/trichy")
    with urllib.request.urlopen(req, timeout=5) as resp:
        data = json.loads(resp.read().decode('utf-8'))
        aqi = data.get("prediction", {}).get("predicted_aqi")
        category = data.get("health_analysis", {}).get("category")
        diseases = data.get("health_analysis", {}).get("disease_risks", [])
        stages = data.get("preprocessing", {}).get("pipeline_stages", [])
        if resp.status == 200 and aqi is not None and len(diseases) > 0:
            log_test("Live Telemetry & Prediction for Trichy (/api/air-quality/trichy)", "PASSED", f"AQI: {aqi} ({category}), Pipeline Stages: {len(stages)}, Diseases Mapped: {len(diseases)}")
        else:
            log_test("Live Telemetry & Prediction for Trichy (/api/air-quality/trichy)", "FAILED", str(data))
except Exception as e:
    log_test("Live Telemetry & Prediction for Trichy (/api/air-quality/trichy)", "FAILED", str(e))

# 4. Live District Prediction & Telemetry (Chennai)
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

# 5. 24-Hour Forecast Endpoint (/api/prediction/coimbatore)
try:
    req = urllib.request.Request(f"{API_BASE}/prediction/coimbatore")
    with urllib.request.urlopen(req, timeout=5) as resp:
        data = json.loads(resp.read().decode('utf-8'))
        forecast = data.get("forecast_24h", [])
        if resp.status == 200 and len(forecast) > 0:
            log_test("24-Hour Predictive Trajectory (/api/prediction/coimbatore)", "PASSED", f"Forecast Intervals: {len(forecast)} steps generated")
        else:
            log_test("24-Hour Predictive Trajectory (/api/prediction/coimbatore)", "FAILED", str(data))
except Exception as e:
    log_test("24-Hour Predictive Trajectory (/api/prediction/coimbatore)", "FAILED", str(e))

# 6. Manual Custom Sensor Prediction (/api/manual-prediction)
try:
    payload = {
        "district": "Custom Lab Station",
        "pm25": 45.0, "pm10": 78.0, "no2": 24.0, "so2": 6.5, "co": 0.85, "o3": 30.0,
        "temperature": 29.0, "humidity": 55.0, "windSpeed": 12.0, "persona": "sensitive"
    }
    req = urllib.request.Request(f"{API_BASE}/manual-prediction", data=json.dumps(payload).encode('utf-8'), headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=5) as resp:
        data = json.loads(resp.read().decode('utf-8'))
        aqi = data.get("prediction", {}).get("predicted_aqi")
        category = data.get("health_analysis", {}).get("category")
        primary = data.get("prediction", {}).get("primary_pollutant")
        if resp.status == 200 and aqi is not None and category is not None:
            log_test("Manual Prediction Engine (/api/manual-prediction)", "PASSED", f"Predicted AQI: {aqi} ({category}), Dominant Pollutant: {primary}")
        else:
            log_test("Manual Prediction Engine (/api/manual-prediction)", "FAILED", str(data))
except Exception as e:
    log_test("Manual Prediction Engine (/api/manual-prediction)", "FAILED", str(e))

# 7. Data Status & Pipeline Overview (/api/data-status)
try:
    req = urllib.request.Request(f"{API_BASE}/data-status")
    with urllib.request.urlopen(req, timeout=5) as resp:
        data = json.loads(resp.read().decode('utf-8'))
        status = data.get("status")
        if resp.status == 200 and status == "operational":
            log_test("Data Preprocessing & Pipeline Status (/api/data-status)", "PASSED", f"Pipeline Status: {status}")
        else:
            log_test("Data Preprocessing & Pipeline Status (/api/data-status)", "FAILED", str(data))
except Exception as e:
    log_test("Data Preprocessing & Pipeline Status (/api/data-status)", "FAILED", str(e))

# 8. Frontend Static File Server Verification
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
                log_test(f"Frontend Static Server ({page})", "PASSED", f"Size: {len(resp.read())} bytes")
            else:
                log_test(f"Frontend Static Server ({page})", "FAILED", f"Status: {resp.status}")
    except Exception as e:
        log_test(f"Frontend Static Server ({page})", "FAILED", str(e))

print("=================================================================")
print(f"   Test Summary: {results['passed']} Passed, {results['failed']} Failed")
print("=================================================================")

if results['failed'] > 0:
    sys.exit(1)
