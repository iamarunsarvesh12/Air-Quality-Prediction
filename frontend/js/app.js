// ===========================================================
// AeroSense TN — app.js (Live Dashboard Controller)
// Orchestrates Tamil Nadu district selection, telemetry, predictions, and health analysis
// ===========================================================

let allDistricts = [];
let currentDistrictId = 'trichy';
let currentPersona = 'general';

document.addEventListener('DOMContentLoaded', async () => {
  // Mobile Nav Toggle
  const navToggle = document.getElementById('navToggle');
  const navLinks = document.getElementById('navLinks');
  if (navToggle && navLinks) {
    navToggle.addEventListener('click', () => {
      navLinks.classList.toggle('open');
    });
  }

  // Initialize Dashboard if on live-dashboard.html
  if (document.getElementById('districtList')) {
    await initLiveDashboard();
  }

  // Initialize Home Ticker if on index.html
  if (document.getElementById('homeTicker')) {
    await initHomeTicker();
  }
});

// 1. Initialize Live District Dashboard
async function initLiveDashboard() {
  try {
    // Load all 38 districts
    const res = await ApiService.getDistricts();
    allDistricts = res.districts || [];
    renderDistrictList(allDistricts);

    // Search filter
    const searchInput = document.getElementById('districtSearch');
    if (searchInput) {
      searchInput.addEventListener('input', (e) => {
        const q = e.target.value.toLowerCase().trim();
        const filtered = allDistricts.filter(d => 
          d.name.toLowerCase().includes(q) || d.zone.toLowerCase().includes(q)
        );
        renderDistrictList(filtered);
      });
    }

    // Persona switch
    const personaSelect = document.getElementById('personaSelect');
    if (personaSelect) {
      personaSelect.addEventListener('change', (e) => {
        currentPersona = e.target.value;
        loadDistrictDetails(currentDistrictId, currentPersona);
      });
    }

    // Load default (Trichy)
    await loadDistrictDetails('trichy', 'general');

    // Load Hubs for comparison chart
    const hubsRes = await ApiService.getLiveDataSummary();
    if (hubsRes.hubs && document.getElementById('districtChart')) {
      ChartService.renderDistrictComparisonChart('districtChart', hubsRes.hubs);
    }
  } catch (err) {
    console.error('Failed to initialize dashboard:', err);
  }
}

// 2. Render District Sidebar List
function renderDistrictList(districts) {
  const container = document.getElementById('districtList');
  if (!container) return;

  container.innerHTML = '';
  if (districts.length === 0) {
    container.innerHTML = '<div style="padding: 12px; text-align: center; color: var(--text-muted); font-size: 0.85rem;">No matching districts.</div>';
    return;
  }

  districts.forEach(d => {
    const item = document.createElement('div');
    item.className = `district-item ${d.id === currentDistrictId ? 'active' : ''}`;
    item.setAttribute('data-id', d.id);
    item.innerHTML = `
      <span>📍 ${d.name}</span>
      <span class="district-zone-tag">${d.zone}</span>
    `;
    item.addEventListener('click', () => {
      currentDistrictId = d.id;
      document.querySelectorAll('.district-item').forEach(el => el.classList.remove('active'));
      item.classList.add('active');
      loadDistrictDetails(d.id, currentPersona);
    });
    container.appendChild(item);
  });
}

// 3. Load & Render Full District Data
async function loadDistrictDetails(districtId, persona) {
  const statusEl = document.getElementById('dashboardStatus');
  if (statusEl) statusEl.textContent = 'Fetching telemetry & generating AI prediction…';

  try {
    const data = await ApiService.getDistrictAirQuality(districtId, persona);
    
    // Update Station Info
    document.getElementById('stationName').textContent = data.district_name;
    document.getElementById('stationZone').textContent = `${data.zone} · ${data.coordinates.latitude.toFixed(2)}°N, ${data.coordinates.longitude.toFixed(2)}°E`;
    
    // Live / Estimated Status
    const liveTag = document.getElementById('stationLiveStatus');
    if (liveTag) {
      liveTag.innerHTML = `<span class="pulse-dot"></span> ${data.transparency.data_type}`;
    }

    // AQI Dial Number & Category
    const aqiNum = document.getElementById('aqiNumber');
    const aqiCategory = document.getElementById('aqiCategory');
    const aqiSummary = document.getElementById('aqiSummary');

    if (aqiNum) {
      aqiNum.textContent = Math.round(data.prediction.predicted_aqi);
      aqiNum.style.color = data.health_analysis.color;
    }
    if (aqiCategory) {
      aqiCategory.textContent = data.health_analysis.category;
      aqiCategory.style.backgroundColor = data.health_analysis.bg_color;
      aqiCategory.style.color = data.health_analysis.color;
    }
    if (aqiSummary) {
      aqiSummary.textContent = data.health_analysis.summary;
    }

    // Update Primary Pollutant
    const primaryPolEl = document.getElementById('primaryPollutant');
    if (primaryPolEl) {
      primaryPolEl.textContent = data.prediction.primary_pollutant;
    }

    // Update Pollutants Grid
    renderPollutantsGrid(data.pollutants, data.weather);

    // Update Preprocessing Pipeline Status
    renderPipelineSteps(data.preprocessing.pipeline_stages);

    // Update Disease Risk Cards
    renderDiseaseRiskCards(data.health_analysis.disease_risks);

    // Update Persona Advice Box
    renderPersonaAdvice(data.health_analysis.persona_recommendation);

    // Update Transparency Meta
    renderTransparency(data.transparency, data.prediction.model_metadata);

    // Render Charts
    if (data.prediction.forecast_24h && document.getElementById('trendChart')) {
      ChartService.renderTrendChart('trendChart', data.prediction.forecast_24h, data.prediction.predicted_aqi);
    }
    if (data.pollutants && document.getElementById('pollutantChart')) {
      ChartService.renderPollutantChart('pollutantChart', data.pollutants);
    }

    if (statusEl) statusEl.textContent = '';
  } catch (err) {
    console.error('Failed to load district:', err);
    if (statusEl) statusEl.textContent = `Error loading data: ${err.message}`;
  }
}

// Helper: Render Pollutants
function renderPollutantsGrid(p, w) {
  const container = document.getElementById('pollutantsGrid');
  if (!container) return;

  const cards = [
    { name: 'PM2.5', val: p.pm25, unit: 'µg/m³' },
    { name: 'PM10', val: p.pm10, unit: 'µg/m³' },
    { name: 'NO₂', val: p.no2, unit: 'ppb' },
    { name: 'SO₂', val: p.so2, unit: 'ppb' },
    { name: 'CO', val: p.co, unit: 'ppm' },
    { name: 'O₃', val: p.o3, unit: 'ppb' },
    { name: 'Temperature', val: `${w.temperature}°C`, unit: 'Ambient' },
    { name: 'Humidity', val: `${w.humidity}%`, unit: 'Relative' },
    { name: 'Wind Speed', val: `${w.wind_speed} km/h`, unit: 'Velocity' }
  ];

  container.innerHTML = cards.map(c => `
    <div class="pollutant-card">
      <div class="pollutant-label">${c.name}</div>
      <div class="pollutant-val">${c.val}</div>
      <div class="pollutant-unit">${c.unit}</div>
    </div>
  `).join('');
}

// Helper: Render Pipeline Status Steps
function renderPipelineSteps(steps) {
  const container = document.getElementById('pipelineSteps');
  if (!container || !steps) return;

  container.innerHTML = steps.map(s => `
    <div class="pipeline-step">
      <div class="pipeline-step-title">✓ ${s.label}</div>
      <div style="font-size: 0.75rem; color: var(--text-muted);">${s.message}</div>
    </div>
  `).join('') + `
    <div class="pipeline-step" style="border-left-color: #10B981;">
      <div class="pipeline-step-title">✓ Model Ingestion</div>
      <div style="font-size: 0.75rem; color: var(--text-muted);">Random Forest Regressor executed.</div>
    </div>
  `;
}

// Helper: Render Disease Cards
function renderDiseaseRiskCards(diseases) {
  const container = document.getElementById('diseasesGrid');
  if (!container || !diseases) return;

  container.innerHTML = diseases.map(d => {
    const riskClass = `risk-${d.risk_level.toLowerCase().replace(/[^a-z]/g, '')}`;
    return `
      <div class="disease-card">
        <div>
          <div class="disease-header">
            <h4 class="disease-name">${d.name}</h4>
            <span class="risk-badge ${riskClass}">${d.risk_level} Risk</span>
          </div>
          <div class="disease-symptoms"><strong>Triggers:</strong> ${d.trigger_pollutants.join(', ')}<br><strong>Symptoms:</strong> ${d.symptoms}</div>
        </div>
        <div class="disease-mitigation">💡 <strong>Action:</strong> ${d.mitigation}</div>
      </div>
    `;
  }).join('');
}

// Helper: Render Persona Box
function renderPersonaAdvice(advice) {
  const box = document.getElementById('personaAdviceBox');
  if (!box || !advice) return;

  box.innerHTML = `
    <div style="background: #F0F9FF; border: 1px solid #BAE6FD; border-radius: 12px; padding: 18px; margin-top: 16px;">
      <h4 style="color: #0284C7; font-size: 1.05rem; margin-bottom: 6px;">🛡️ ${advice.title}</h4>
      <p style="font-size: 0.9rem; color: var(--text-primary); margin-bottom: 8px;">${advice.action}</p>
      <div style="display: flex; gap: 16px; font-size: 0.82rem; font-weight: 600; color: #0369A1;">
        <span>🏃 Exertion Limit: ${advice.outdoor_limit}</span>
        <span>😷 Gear: ${advice.mask_recommendation}</span>
      </div>
    </div>
  `;
}

// Helper: Render Transparency
function renderTransparency(t, m) {
  const container = document.getElementById('transparencyGrid');
  if (!container) return;

  container.innerHTML = `
    <div class="transparency-item">
      <span>Data Source</span>
      <strong>${t.source_name}</strong>
    </div>
    <div class="transparency-item">
      <span>Data Type</span>
      <strong>${t.data_type}</strong>
    </div>
    <div class="transparency-item">
      <span>Last Updated</span>
      <strong>${t.timestamp_display}</strong>
    </div>
    <div class="transparency-item">
      <span>Prediction Model</span>
      <strong>${m.model_name} (R²: ${m.r_squared})</strong>
    </div>
  `;
}

// 4. Initialize Home Page Ticker
async function initHomeTicker() {
  const ticker = document.getElementById('homeTicker');
  if (!ticker) return;

  try {
    const res = await ApiService.getLiveDataSummary();
    if (res.hubs) {
      ticker.innerHTML = res.hubs.map(h => `
        <div class="ticker-item">
          <span>${h.district_name}:</span>
          <span class="ticker-val" style="background: ${h.color}20; color: ${h.color}; font-weight: 700;">AQI ${h.aqi} (${h.category})</span>
        </div>
      `).join('');
    }
  } catch (e) {
    console.warn('Ticker load failed:', e);
  }
}
