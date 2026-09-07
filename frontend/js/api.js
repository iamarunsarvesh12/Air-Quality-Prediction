// ===========================================================
// AeroSense TN — api.js (Frontend REST API Service)
// Handles HTTP requests to the R Plumber Backend Engine
// ===========================================================

const API_HOST = window.location.hostname && window.location.hostname !== '' ? window.location.hostname : '127.0.0.1';
const API_BASE_URL = `http://${API_HOST}:8000/api`;

const ApiService = {
  // 1. Health Check
  async getHealth() {
    const res = await fetch(`${API_BASE_URL}/health`);
    if (!res.ok) throw new Error(`API health error: ${res.status}`);
    return await res.json();
  },

  // 2. All 38 Districts Directory
  async getDistricts() {
    const res = await fetch(`${API_BASE_URL}/districts`);
    if (!res.ok) throw new Error(`Failed to load districts: ${res.status}`);
    return await res.json();
  },

  // 3. Live Hubs Summary
  async getLiveDataSummary() {
    const res = await fetch(`${API_BASE_URL}/live-data`);
    if (!res.ok) throw new Error(`Failed to load live summary: ${res.status}`);
    return await res.json();
  },

  // 4. District-Specific Air Quality, Prediction & Health Risk
  async getDistrictAirQuality(districtId, persona = 'general') {
    const res = await fetch(`${API_BASE_URL}/air-quality/${encodeURIComponent(districtId)}?persona=${encodeURIComponent(persona)}`);
    if (!res.ok) {
      const err = await res.json().catch(() => ({}));
      throw new Error(err.error || `District data error: ${res.status}`);
    }
    return await res.json();
  },

  // 5. 24-Hour Forecast & Prediction
  async getDistrictPrediction(districtId) {
    const res = await fetch(`${API_BASE_URL}/prediction/${encodeURIComponent(districtId)}`);
    if (!res.ok) throw new Error(`Prediction fetch error: ${res.status}`);
    return await res.json();
  },

  // 6. Execute Manual Prediction from Custom Sensor Inputs
  async submitManualPrediction(payload) {
    const res = await fetch(`${API_BASE_URL}/manual-prediction`, {
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
    const res = await fetch(`${API_BASE_URL}/data-status`);
    if (!res.ok) throw new Error(`Data status error: ${res.status}`);
    return await res.json();
  }
};

window.ApiService = ApiService;
