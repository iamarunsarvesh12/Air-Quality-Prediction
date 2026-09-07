// ===========================================================
// AirSense — dashboard.js (Module 8: Results Dashboard)
// Reads the prediction result from sessionStorage (set by form.js)
// and populates the dashboard UI (AQI, Diseases, Safety Advisor, Summary, Charts).
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

  // Location Badge (Real-Time TN District or Manual)
  const locBadge = document.getElementById('locationBadge');
  const distName = result.districtName || input.districtName;
  if (locBadge) {
    if (distName) {
      locBadge.classList.remove('hidden');
      locBadge.innerHTML = `📍 <strong>Real-Time Station Feed:</strong> ${distName}, Tamil Nadu`;
    } else if (result.isRealTime) {
      locBadge.classList.remove('hidden');
      locBadge.innerHTML = `📍 <strong>Real-Time Air Quality Monitoring</strong>`;
    } else {
      locBadge.classList.remove('hidden');
      locBadge.innerHTML = `📝 <strong>Manual Pollutant Data Prediction</strong>`;
    }
  }

  // AQI hero card
  document.getElementById('aqiValue').textContent = result.aqi;
  document.getElementById('aqiCategory').textContent = result.category;
  document.getElementById('aqiCategory').style.background = result.colorCode || 'var(--sky)';
  document.getElementById('aqiDescription').textContent = result.description || '';

  // Summary table
  const tbody = document.querySelector('#summaryTable tbody');
  if (tbody) {
    tbody.innerHTML = '';
    const numericKeys = ['pm25', 'pm10', 'no2', 'so2', 'co', 'o3', 'temperature', 'humidity', 'windSpeed'];
    numericKeys.forEach(key => {
      if (input[key] !== undefined) {
        const label = FIELD_LABELS[key] || key;
        const row = document.createElement('tr');
        row.innerHTML = `<td>${label}</td><td>${input[key]}</td>`;
        tbody.appendChild(row);
      }
    });
  }

  // Health effects
  const effectsList = document.getElementById('healthEffects');
  if (effectsList) {
    effectsList.innerHTML = '';
    const rawEffects = result.healthEffects;
    const effects = Array.isArray(rawEffects) ? rawEffects : (rawEffects ? [rawEffects] : []);
    effects.forEach(effect => {
      const li = document.createElement('li');
      li.textContent = effect;
      effectsList.appendChild(li);
    });
  }

  // Recommendations
  const recoList = document.getElementById('recommendations');
  if (recoList) {
    recoList.innerHTML = '';
    const rawRecs = result.recommendations;
    const recs = Array.isArray(rawRecs) ? rawRecs : (rawRecs ? [rawRecs] : []);
    recs.forEach(rec => {
      const li = document.createElement('li');
      li.textContent = rec;
      recoList.appendChild(li);
    });
  }

  // Render Medical Diseases Risk Mapping
  renderDiseasesGrid(result);

  // Render Personalized Safety & Protection Hub
  renderSafetyHub(result);

  // Charts (defined in charts.js)
  if (window.renderAirSenseCharts) {
    window.renderAirSenseCharts(input, result);
  }
});

function renderDiseasesGrid(result) {
  const container = document.getElementById('diseasesGrid');
  if (!container) return;

  const rawDiseases = result.diseases;
  const diseases = Array.isArray(rawDiseases) ? rawDiseases : [];

  if (diseases.length === 0) {
    container.innerHTML = '<p style="color: var(--text-muted);">No disease mapping data available for this category.</p>';
    return;
  }

  container.innerHTML = diseases.map(d => {
    const riskClass = `risk-${(d.risk || 'moderate').toLowerCase()}`;
    return `
      <div class="disease-card">
        <div class="disease-card-header">
          <div class="disease-card-title">${d.name}</div>
          <span class="disease-risk-badge ${riskClass}">${d.risk} Risk</span>
        </div>
        <div class="disease-card-desc">${d.description}</div>
      </div>
    `;
  }).join('');
}

function renderSafetyHub(result) {
  const safety = result.safetyAdvisor;
  if (!safety) return;

  // Gear Cards
  const gearMask = document.getElementById('gearMask');
  const gearPurifier = document.getElementById('gearPurifier');
  const gearWindows = document.getElementById('gearWindows');
  const gearExertion = document.getElementById('gearExertion');

  if (gearMask) gearMask.textContent = safety.mask || 'N/A';
  if (gearPurifier) gearPurifier.textContent = safety.purifier || 'N/A';
  if (gearWindows) gearWindows.textContent = safety.windows ? `Windows: ${safety.windows}` : '';
  if (gearExertion) gearExertion.textContent = safety.exertionLimit || 'N/A';

  // Selected persona from form or default
  const storedPersona = sessionStorage.getItem('airsense_persona') || 'general';

  const personaTitles = {
    general: 'Safety Advice for General Public',
    sensitive: 'Safety Advice for Sensitive & Asthma Patients',
    children_elderly: 'Safety Advice for Children & Senior Citizens',
    athletes: 'Safety Advice for Outdoor Athletes & Runners',
    workers: 'Safety Advice for Outdoor Workers'
  };

  const groupAdvice = safety.groupAdvice || {};

  function updatePersonaAdvice(personaKey) {
    const title = personaTitles[personaKey] || 'Safety Advice';
    const advice = groupAdvice[personaKey] || 'Follow standard air quality precautions.';

    const titleEl = document.getElementById('personaAdviceTitle');
    const textEl = document.getElementById('personaAdviceText');

    if (titleEl) titleEl.textContent = title;
    if (textEl) textEl.textContent = advice;

    // Update active tab styling
    document.querySelectorAll('.persona-tab').forEach(tab => {
      tab.classList.toggle('active', tab.dataset.persona === personaKey);
    });
  }

  // Initial advice update
  updatePersonaAdvice(storedPersona);

  // Tab click event handlers
  document.querySelectorAll('.persona-tab').forEach(tab => {
    tab.addEventListener('click', () => {
      const pKey = tab.dataset.persona;
      updatePersonaAdvice(pKey);
    });
  });

  // Render Interactive Precaution Checklist
  const checklistItemsEl = document.getElementById('checklistItems');
  if (checklistItemsEl) {
    checklistItemsEl.innerHTML = '';
    const rawList = safety.actionChecklist;
    const actions = Array.isArray(rawList) ? rawList : (rawList ? [rawList] : []);

    actions.forEach((action, idx) => {
      const li = document.createElement('li');
      li.className = 'checklist-item';
      li.innerHTML = `
        <label class="checkbox-container">
          <input type="checkbox" id="check_${idx}">
          <span class="checkmark"></span>
          <span class="item-text">${action}</span>
        </label>
      `;
      checklistItemsEl.appendChild(li);
    });

    function updateProgress() {
      const total = actions.length;
      const checkedCount = checklistItemsEl.querySelectorAll('input[type="checkbox"]:checked').length;
      const pct = total > 0 ? Math.round((checkedCount / total) * 100) : 0;

      const progressText = document.getElementById('checklistProgressText');
      const barFill = document.getElementById('checklistBarFill');

      if (progressText) progressText.textContent = `${checkedCount} of ${total} Precautions Completed`;
      if (barFill) barFill.style.width = `${pct}%`;
    }

    checklistItemsEl.querySelectorAll('input[type="checkbox"]').forEach(chk => {
      chk.addEventListener('change', updateProgress);
    });

    updateProgress();
  }
}
