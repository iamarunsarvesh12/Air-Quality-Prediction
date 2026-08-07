// ===========================================================
// AirSense — form.js (Module 2: Air Quality Data Input)
// Validates pollutant inputs, then POSTs to the R Plumber API
// and forwards the response to result.html
// ===========================================================

// Base URL of the R Plumber API (Module 5). Change the port if
// your api.R is started on a different port.
const API_BASE_URL = 'http://127.0.0.1:8000';

document.addEventListener('DOMContentLoaded', () => {
  const form = document.getElementById('aqiForm');
  const statusEl = document.getElementById('formStatus');
  const analyzeBtn = document.getElementById('analyzeBtn');

  if (!form) return;

  const fields = [
    { id: 'pm25', label: 'PM2.5', min: 0 },
    { id: 'pm10', label: 'PM10', min: 0 },
    { id: 'no2', label: 'NO₂', min: 0 },
    { id: 'so2', label: 'SO₂', min: 0 },
    { id: 'co', label: 'CO', min: 0 },
    { id: 'o3', label: 'O₃', min: 0 },
    { id: 'temperature', label: 'Temperature', min: -50 },
    { id: 'humidity', label: 'Humidity', min: 0, max: 100 },
    { id: 'windSpeed', label: 'Wind Speed', min: 0 },
  ];

  function validateField(field) {
    const input = document.getElementById(field.id);
    const errorEl = form.querySelector(`.error-msg[data-for="${field.id}"]`);
    const value = input.value.trim();
    let message = '';

    if (value === '') {
      message = `${field.label} is required.`;
    } else {
      const num = Number(value);
      if (Number.isNaN(num)) {
        message = `${field.label} must be a number.`;
      } else if (field.min !== undefined && num < field.min) {
        message = `${field.label} cannot be below ${field.min}.`;
      } else if (field.max !== undefined && num > field.max) {
        message = `${field.label} cannot be above ${field.max}.`;
      }
    }

    input.classList.toggle('invalid', Boolean(message));
    errorEl.textContent = message;
    return message === '';
  }

  // Live validation as the user types
  fields.forEach(field => {
    const input = document.getElementById(field.id);
    input.addEventListener('input', () => validateField(field));
  });

  form.addEventListener('submit', async (e) => {
    e.preventDefault();
    statusEl.textContent = '';

    const allValid = fields.map(validateField).every(Boolean);
    if (!allValid) {
      statusEl.textContent = 'Please fix the highlighted fields before continuing.';
      return;
    }

    const payload = {};
    fields.forEach(field => {
      payload[field.id] = Number(document.getElementById(field.id).value);
    });

    analyzeBtn.disabled = true;
    analyzeBtn.textContent = 'Analyzing…';

    try {
      const response = await fetch(`${API_BASE_URL}/predict`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload),
      });

      if (!response.ok) {
        throw new Error(`API responded with status ${response.status}`);
      }

      const result = await response.json();

      // Pass the input + result to the dashboard via sessionStorage
      sessionStorage.setItem('airsense_input', JSON.stringify(payload));
      sessionStorage.setItem('airsense_result', JSON.stringify(result));

      window.location.href = 'result.html';
    } catch (err) {
      console.error(err);
      statusEl.textContent =
        'Could not reach the prediction API. Make sure api.R is running (see README), then try again.';
      analyzeBtn.disabled = false;
      analyzeBtn.textContent = 'Analyze Air Quality →';
    }
  });
});
