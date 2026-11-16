// ===========================================================
// AeroSense TN — app.js (Live Dashboard Controller)
// Orchestrates Tamil Nadu district selection, telemetry, predictions, and health analysis
// ===========================================================

let allDistricts = [];
let currentDistrictId = 'trichy';
let currentPersona = 'general';
let activeRequestId = 0;

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
  const statusEl = document.getElementById('dashboardStatus');
  
  // Guard against direct file:// opening
  if (window.location.protocol === 'file:') {
    if (statusEl) {
      statusEl.innerHTML = `
        <div style="background: #FEF2F2; border: 1px solid #F87171; border-radius: 8px; padding: 12px; margin-bottom: 12px;">
          <strong style="color: #DC2626;">⚠️ Direct File Opening Detected:</strong><br>
          <span style="color: #4B5563; font-size: 0.88rem;">Browsers strictly block REST API communication from <code>file://</code> URLs for security.<br>
          Please access the application through the running local server: 
          <a href="http://127.0.0.1:5500/live-dashboard.html" style="color: #0284C7; font-weight: 600; text-decoration: underline;">http://127.0.0.1:5500/live-dashboard.html</a></span>
        </div>`;
    }
    return;
  }

  try {
    let res = null;
    // Retry loop (up to 5 attempts) to prevent race conditions during backend startup
    for (let attempt = 1; attempt <= 5; attempt++) {
      try {
        if (statusEl) statusEl.textContent = attempt === 1 ? 'Connecting to R Plumber Backend & Ingesting Telemetry…' : `Connecting to R Plumber Backend (attempt ${attempt}/5)…`;
        res = await ApiService.getDistricts();
        if (res && res.districts) break;
      } catch (err) {
        if (attempt === 5) throw err;
        await new Promise(r => setTimeout(r, 1000));
      }
    }

    // Load all 38 districts
    allDistricts = res.districts || [];
    renderDistrictList(allDistricts);

    // Search filter
    const searchInput = document.getElementById('districtSearch');
    if (searchInput) {
      searchInput.addEventListener('input', (e) => {
        const q = e.target.value.toLowerCase().trim();
        const filtered = allDistricts.filter(d => 
          d.name.toLowerCase().includes(q) || d.zone.toLowerCase().includes(q) || d.id.toLowerCase().includes(q)
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

    // Add manual refresh button handler if present
    const refreshBtn = document.getElementById('refreshTelemetryBtn');
    if (refreshBtn) {
      refreshBtn.addEventListener('click', async () => {
        refreshBtn.disabled = true;
        refreshBtn.textContent = 'Refreshing…';
        await loadDistrictDetails(currentDistrictId, currentPersona, true);
        refreshBtn.disabled = false;
        refreshBtn.textContent = '🔄 Refresh Telemetry';
      });
    }

    // Load default (Trichy)
    await loadDistrictDetails('trichy', 'general');

    // Load Hubs for comparison chart across all major Tamil Nadu districts
    const hubsRes = await ApiService.getLiveDataSummary();
    if (hubsRes.hubs && document.getElementById('districtChart')) {
      // Pick top representative districts from each zone for clean chart display
      const displayHubs = hubsRes.hubs.slice(0, 10);
      ChartService.renderDistrictComparisonChart('districtChart', displayHubs);
    }
  } catch (err) {
    console.error('Failed to initialize dashboard:', err);
    if (statusEl) {
      statusEl.innerHTML = `
        <span style="color: #DC2626;">⚠️ Unable to connect to R Backend API (http://127.0.0.1:8000). Please ensure R is running via <code>.\\run.ps1</code> or <code>run.bat</code>.</span>
        <button onclick="initLiveDashboard()" style="margin-left: 10px; padding: 4px 10px; font-size: 0.8rem; border-radius: 4px; border: 1px solid #DC2626; background: #FEF2F2; color: #DC2626; cursor: pointer; font-weight: 500;">🔄 Retry</button>`;
    }
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
async function loadDistrictDetails(districtId, persona, isManualRefresh = false) {
  const statusEl = document.getElementById('dashboardStatus');
  const thisRequestId = ++activeRequestId;
  
  if (statusEl) {
    statusEl.innerHTML = `<span style="color: #0284C7;">⏳ Fetching telemetry for ${districtId} & running Random Forest inference…</span>`;
  }

  try {
    const data = await ApiService.getDistrictAirQuality(districtId, persona);
    
    // Ignore response if user switched to another district in the meantime (race condition guard)
    if (thisRequestId !== activeRequestId) return;

    // Update Station Info
    document.getElementById('stationName').textContent = data.district_name;
    document.getElementById('stationZone').textContent = `${data.zone} · ${data.coordinates.latitude.toFixed(4)}°N, ${data.coordinates.longitude.toFixed(4)}°E`;
    
    // Live / Stale / Estimated Status
    const liveTag = document.getElementById('stationLiveStatus');
    if (liveTag) {
      const isLive = data.transparency.is_live;
      const statusClass = isLive ? '' : 'stale';
      liveTag.className = `live-indicator ${statusClass}`;
      liveTag.innerHTML = `<span class="pulse-dot"></span> ${data.transparency.data_type} (${data.transparency.data_status.toUpperCase()})`;
    }

    // AQI Dial Number & Category (Use CPCB calculated AQI if eligible, otherwise Random Forest predicted AQI)
    const aqiNum = document.getElementById('aqiNumber');
    const aqiCategory = document.getElementById('aqiCategory');
    const aqiSummary = document.getElementById('aqiSummary');

    const displayAqi = (data.cpcb_aqi && data.cpcb_aqi.calculated_aqi !== null) 
      ? Math.round(data.cpcb_aqi.calculated_aqi) 
      : Math.round(data.prediction.predicted_aqi);

    if (aqiNum) {
      aqiNum.textContent = displayAqi;
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

    // Update Dominant Pollutant
    const primaryPolEl = document.getElementById('primaryPollutant');
    if (primaryPolEl) {
      primaryPolEl.textContent = data.prediction.primary_pollutant || 'PM2.5';
    }

    // Update Pollutants Grid with verified units
    renderPollutantsGrid(data.pollutants, data.weather);

    // Update Preprocessing Pipeline Status
    renderPipelineSteps(data.preprocessing.pipeline_stages);

    // Update Disease Risk Cards
    renderDiseaseRiskCards(data.health_analysis.disease_risks);

    // Update Persona Advice Box
    renderPersonaAdvice(data.health_analysis.persona_recommendation);

    // Update Transparency Meta
    renderTransparency(data.transparency, data.prediction.model_metadata, data.prediction, data.cpcb_aqi);

    // Render Charts
    if (data.prediction.forecast_24h && document.getElementById('trendChart')) {
      ChartService.renderTrendChart('trendChart', data.prediction.forecast_24h, displayAqi);
    }
    if (data.pollutants && document.getElementById('pollutantChart')) {
      ChartService.renderPollutantChart('pollutantChart', data.pollutants);
    }

    if (statusEl) {
      statusEl.innerHTML = `<span style="color: #059669;">✓ Updated: ${data.transparency.observation_timestamp_ist || data.transparency.retrieval_timestamp_display}</span>`;
    }
  } catch (err) {
    console.error('Failed to load district:', err);
    if (thisRequestId === activeRequestId && statusEl) {
      statusEl.innerHTML = `<span style="color: #DC2626;">⚠️ Error loading district: ${err.message}. <button onclick="loadDistrictDetails('${districtId}', '${persona}')" style="margin-left: 8px; padding: 2px 8px; cursor: pointer; border-radius: 4px; border: 1px solid #DC2626; background: #FFF;">Retry</button></span>`;
    }
  }
}

// Helper: Render Pollutants with authentic CPCB units
function renderPollutantsGrid(p, w) {
  const container = document.getElementById('pollutantsGrid');
  if (!container) return;

  const formatVal = (v) => (v === null || v === undefined || isNaN(v)) ? 'N/A' : v;

  const cards = [
    { name: 'PM2.5', val: formatVal(p.pm25), unit: 'µg/m³ (24h)' },
    { name: 'PM10', val: formatVal(p.pm10), unit: 'µg/m³ (24h)' },
    { name: 'NO₂', val: formatVal(p.no2), unit: 'µg/m³ (24h)' },
    { name: 'SO₂', val: formatVal(p.so2), unit: 'µg/m³ (24h)' },
    { name: 'CO', val: formatVal(p.co), unit: 'mg/m³ (8h)' },
    { name: 'O₃', val: formatVal(p.o3), unit: 'µg/m³ (8h)' },
    { name: 'NH₃', val: formatVal(p.nh3), unit: 'µg/m³ (24h)' },
    { name: 'Temperature', val: `${w.temperature}°C`, unit: 'Ambient' },
    { name: 'Humidity', val: `${w.humidity}%`, unit: 'Relative' },
    { name: 'Wind Speed', val: `${w.wind_speed} km/h`, unit: '10m Surface' }
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
      <div class="pipeline-step-title">✓ Random Forest ML Model</div>
      <div style="font-size: 0.75rem; color: var(--text-muted);">Ensemble regression trees evaluated.</div>
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
      <div style="display: flex; gap: 16px; font-size: 0.82rem; font-weight: 600; color: #0369A1; flex-wrap: wrap;">
        <span>🏃 Exertion Limit: ${advice.outdoor_limit}</span>
        <span>😷 Gear: ${advice.mask_recommendation}</span>
      </div>
    </div>
  `;
}

// Helper: Render Transparency
function renderTransparency(t, m, pred, cpcb) {
  const container = document.getElementById('transparencyGrid');
  if (!container) return;

  const calcAqiText = (cpcb && cpcb.calculated_aqi !== null) ? `${cpcb.calculated_aqi} (${cpcb.status})` : 'Insufficient Pollutants';
  const predAqiText = pred ? `${pred.predicted_aqi}` : 'N/A';

  container.innerHTML = `
    <div class="transparency-item">
      <span>Data Source</span>
      <strong>${t.source_name}</strong>
    </div>
    <div class="transparency-item">
      <span>Data Provenance</span>
      <strong>${t.data_type} · ${t.data_status}</strong>
    </div>
    <div class="transparency-item">
      <span>Observation Time</span>
      <strong>${t.observation_timestamp_ist || t.observation_timestamp}</strong>
    </div>
    <div class="transparency-item">
      <span>Retrieval Time</span>
      <strong>${t.retrieval_timestamp_display || t.retrieval_timestamp}</strong>
    </div>
    <div class="transparency-item">
      <span>CPCB Calculated AQI</span>
      <strong>${calcAqiText}</strong>
    </div>
    <div class="transparency-item">
      <span>Random Forest Prediction</span>
      <strong>${predAqiText} (R²: ${m.r_squared}, RMSE: ${m.rmse})</strong>
    </div>
  `;
}

// 4. Initialize Home Page Ticker
async function initHomeTicker() {
  const ticker = document.getElementById('homeTicker');
  if (!ticker) return;

  try {
    const res = await ApiService.getLiveDataSummary();
    if (res.hubs && res.hubs.length > 0) {
      ticker.innerHTML = res.hubs.slice(0, 12).map(h => `
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
