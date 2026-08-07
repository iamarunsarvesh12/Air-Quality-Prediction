// ===========================================================
// AirSense — dashboard.js (Module 8: Results Dashboard)
// Reads the prediction result from sessionStorage (set by form.js)
// and populates the dashboard UI.
// ===========================================================

function getStoredResult() {
  const resultRaw = sessionStorage.getItem('airsense_result');
  const inputRaw = sessionStorage.getItem('airsense_input');

  if (!resultRaw || !inputRaw) return null;

  try {
    return {
      result: JSON.parse(resultRaw),
      input: JSON.parse(inputRaw),
    };
  } catch {
    return null;
  }
}

const FIELD_LABELS = {
  pm25: 'PM2.5 (µg/m³)',
  pm10: 'PM10 (µg/m³)',
  no2: 'NO₂ (ppb)',
  so2: 'SO₂ (ppb)',
  co: 'CO (ppm)',
  o3: 'O₃ (ppb)',
  temperature: 'Temperature (°C)',
  humidity: 'Humidity (%)',
  windSpeed: 'Wind Speed (km/h)',
};

document.addEventListener('DOMContentLoaded', () => {
  const data = getStoredResult();

  if (!data) {
    document.getElementById('dashboard').innerHTML = `
      <div class="panel" style="max-width:520px;margin:60px auto;text-align:center;">
        <h2>No analysis found</h2>
        <p>Please run a new air quality analysis first.</p>
        <a href="analysis.html" class="btn btn-primary">Go to analysis →</a>
      </div>`;
    return;
  }

  const { result, input } = data;

  // AQI hero card
  document.getElementById('aqiValue').textContent = result.aqi;
  document.getElementById('aqiCategory').textContent = result.category;
  document.getElementById('aqiCategory').style.background = result.colorCode || 'var(--sky)';
  document.getElementById('aqiDescription').textContent = result.description || '';

  // Summary table
  const tbody = document.querySelector('#summaryTable tbody');
  Object.entries(input).forEach(([key, value]) => {
    const label = FIELD_LABELS[key] || key;
    const row = document.createElement('tr');
    row.innerHTML = `<td>${label}</td><td>${value}</td>`;
    tbody.appendChild(row);
  });

  // Health effects
  const effectsList = document.getElementById('healthEffects');
  (result.healthEffects || []).forEach(effect => {
    const li = document.createElement('li');
    li.textContent = effect;
    effectsList.appendChild(li);
  });

  // Recommendations
  const recoList = document.getElementById('recommendations');
  (result.recommendations || []).forEach(rec => {
    const li = document.createElement('li');
    li.textContent = rec;
    recoList.appendChild(li);
  });

  // Charts (defined in charts.js)
  if (window.renderAirSenseCharts) {
    window.renderAirSenseCharts(input, result);
  }
});
