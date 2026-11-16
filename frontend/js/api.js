// ===========================================================
// AeroSense TN - api.js (Frontend REST API Service)
// Handles HTTP requests to the R Plumber Backend Engine
// ===========================================================

// Ensure reliable IPv4 communication on Windows (avoiding IPv6 ::1 localhost resolution mismatches)
const isLocal = !window.location.hostname || window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1';
const API_HOST = isLocal ? '127.0.0.1' : window.location.hostname;
const API_BASE_URL = `http://${API_HOST}:8000/api`;

// Robust fetch helper with fallback between 127.0.0.1 and localhost
async function requestApi(endpoint, options = {}) {
  const hosts = isLocal ? ['127.0.0.1', 'localhost'] : [API_HOST];
  let lastErr = null;

  for (const host of hosts) {
    try {
      const url = `http://${host}:8000/api${endpoint}`;
      const res = await fetch(url, options);
      return res;
    } catch (e) {
      lastErr = e;
    }
  }
  throw lastErr || new Error('Network error connecting to API');
}

const ApiService = {
  // 1. Health Check
  async getHealth() {
    const res = await requestApi('/health');
    if (!res.ok) throw new Error(`API health error: ${res.status}`);
    return await res.json();
  },

  // 2. All 38 Districts Directory
  async getDistricts() {
    const res = await requestApi('/districts');
    if (!res.ok) throw new Error(`Failed to load districts: ${res.status}`);
    return await res.json();
  },

  // 3. Live Hubs Summary
  async getLiveDataSummary() {
    const res = await requestApi('/live-data');
    if (!res.ok) throw new Error(`Failed to load live summary: ${res.status}`);
    return await res.json();
  },

  // 4. District-Specific Air Quality, Prediction & Health Risk
  async getDistrictAirQuality(districtId, persona = 'general') {
    const res = await requestApi(`/air-quality/${encodeURIComponent(districtId)}?persona=${encodeURIComponent(persona)}`);
    if (!res.ok) {
      const err = await res.json().catch(() => ({}));
      throw new Error(err.error || `District data error: ${res.status}`);
    }
    return await res.json();
  },

  // 5. 24-Hour Forecast & Prediction
  async getDistrictPrediction(districtId) {
    const res = await requestApi(`/prediction/${encodeURIComponent(districtId)}`);
    if (!res.ok) throw new Error(`Prediction fetch error: ${res.status}`);
    return await res.json();
  },

  // 6. Execute Manual Prediction from Custom Sensor Inputs
  async submitManualPrediction(payload) {
    const res = await requestApi('/manual-prediction', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload)
    });
    if (!res.ok) {
      const err = await res.json().catch(() => ({}));
      throw new Error(err.error || `Prediction error ${res.status}`);
    }
    return await res.json();
  },

  // 7. System & Pipeline Status
  async getDataStatus() {
    const res = await requestApi('/data-status');
    if (!res.ok) throw new Error(`Data status error: ${res.status}`);
    return await res.json();
  }
};

window.ApiService = ApiService;
