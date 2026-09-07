// ===========================================================
// AeroSense TN — manual-prediction.js (Manual Prediction Controller)
// Handles custom sensor value submissions, validation, and scientific ML result display
// ===========================================================

document.addEventListener('DOMContentLoaded', () => {
  const form = document.getElementById('manualForm');
  const resultCard = document.getElementById('manualResultCard');
  const statusEl = document.getElementById('formStatus');
  const submitBtn = document.getElementById('submitBtn');

  if (!form) return;

  const fields = [
    { id: 'pm25', label: 'PM2.5', min: 0, max: 1000 },
    { id: 'pm10', label: 'PM10', min: 0, max: 1500 },
    { id: 'no2', label: 'NO₂', min: 0, max: 500 },
    { id: 'so2', label: 'SO₂', min: 0, max: 500 },
    { id: 'co', label: 'CO', min: 0, max: 50 },
    { id: 'o3', label: 'O₃', min: 0, max: 500 }
  ];

  function validateField(field) {
    const input = document.getElementById(field.id);
    const errorEl = document.getElementById(`${field.id}-error`);
    if (!input) return true;

    const val = input.value.trim();
    let msg = '';

    if (val === '') {
      msg = `${field.label} is required.`;
    } else {
      const num = Number(val);
      if (Number.isNaN(num)) {
        msg = `${field.label} must be a valid number.`;
      } else if (num < field.min) {
        msg = `${field.label} cannot be negative.`;
      } else if (num > field.max) {
        msg = `${field.label} cannot exceed ${field.max}.`;
      }
    }

    input.classList.toggle('error', Boolean(msg));
    if (errorEl) errorEl.textContent = msg;
    return msg === '';
  }

  fields.forEach(f => {
    const el = document.getElementById(f.id);
    if (el) el.addEventListener('input', () => validateField(f));
  });

  form.addEventListener('submit', async (e) => {
    e.preventDefault();
    if (statusEl) statusEl.textContent = '';

    const allValid = fields.map(validateField).every(Boolean);
    if (!allValid) {
      if (statusEl) statusEl.textContent = 'Please correct the highlighted fields before submitting.';
      return;
    }

    const payload = {
      district: document.getElementById('districtSelect')?.value || 'Custom Station',
      persona: document.getElementById('personaSelect')?.value || 'general',
      pm25: Number(document.getElementById('pm25').value),
      pm10: Number(document.getElementById('pm10').value),
      no2: Number(document.getElementById('no2').value),
      so2: Number(document.getElementById('so2').value),
      co: Number(document.getElementById('co').value),
      o3: Number(document.getElementById('o3').value),
      nh3: Number(document.getElementById('nh3')?.value || 10),
      temperature: Number(document.getElementById('temperature')?.value || 30),
      humidity: Number(document.getElementById('humidity')?.value || 60),
      windSpeed: Number(document.getElementById('windSpeed')?.value || 10)
    };

    if (submitBtn) {
      submitBtn.disabled = true;
      submitBtn.textContent = 'Processing in R Engine…';
    }

    try {
      const res = await ApiService.submitManualPrediction(payload);
      renderManualResult(res);
      if (resultCard) {
        resultCard.classList.remove('hidden');
        resultCard.scrollIntoView({ behavior: 'smooth', block: 'start' });
      }
    } catch (err) {
      console.error(err);
      if (statusEl) statusEl.textContent = `Prediction failed: ${err.message}`;
    } finally {
      if (submitBtn) {
        submitBtn.disabled = false;
        submitBtn.textContent = 'Predict Air Quality →';
      }
    }
  });

  // Reset handler
  form.addEventListener('reset', () => {
    if (resultCard) resultCard.classList.add('hidden');
    if (statusEl) statusEl.textContent = '';
    document.querySelectorAll('.error-text').forEach(el => el.textContent = '');
    document.querySelectorAll('.form-control').forEach(el => el.classList.remove('error'));
  });
});

function renderManualResult(data) {
  const container = document.getElementById('manualResultCard');
  if (!container) return;

  const h = data.health_analysis;
  const p = data.prediction;

  container.innerHTML = `
    <div style="border-bottom: 2px solid #E2E8F0; padding-bottom: 20px; margin-bottom: 24px; display: flex; justify-content: space-between; align-items: center; flex-wrap: wrap; gap: 16px;">
      <div>
        <span class="eyebrow">R PREDICTION OUTPUT · ${data.district_name}</span>
        <h2 style="font-size: 2rem; color: var(--text-primary); margin-top: 4px;">Predicted Air Quality Report</h2>
        <span style="font-size: 0.85rem; color: var(--text-muted);">Timestamp: ${data.timestamp_display}</span>
      </div>
      <div style="text-align: right;">
        <span style="display: block; font-size: 0.8rem; font-weight: 700; color: var(--text-muted);">PRIMARY POLLUTANT</span>
        <span style="font-size: 1.4rem; font-weight: 800; color: #DC2626;">${p.primary_pollutant}</span>
      </div>
    </div>

    <!-- Hero AQI Metric -->
    <div style="display: grid; grid-template-columns: 200px 1fr; gap: 24px; align-items: center; background: #F8FAFC; border: 1px solid #E2E8F0; border-radius: 16px; padding: 24px; margin-bottom: 24px;">
      <div style="text-align: center;">
        <div style="font-size: 3.8rem; font-weight: 800; line-height: 1; color: ${h.color};">${Math.round(p.predicted_aqi)}</div>
        <div style="font-size: 0.75rem; font-weight: 700; color: var(--text-muted); text-transform: uppercase; margin-top: 4px;">Predicted AQI Index</div>
      </div>
      <div>
        <span class="aqi-status-pill" style="background: ${h.bg_color}; color: ${h.color}; font-size: 1rem; margin-bottom: 8px;">${h.category}</span>
        <p style="color: var(--text-secondary); font-size: 1rem; line-height: 1.5;">${h.summary}</p>
        <p style="color: #0369A1; font-weight: 600; font-size: 0.9rem; margin-top: 6px;">💡 Recommendation: ${h.general_advice}</p>
      </div>
    </div>

    <!-- Disease Risk Mapping -->
    <h3 style="font-size: 1.3rem; margin-bottom: 12px;">🏥 Potential Disease Vulnerabilities & Health Effects</h3>
    <div class="diseases-grid">
      ${h.disease_risks.map(d => `
        <div class="disease-card">
          <div>
            <div class="disease-header">
              <h4 class="disease-name">${d.name}</h4>
              <span class="risk-badge risk-${d.risk_level.toLowerCase()}">${d.risk_level} Risk</span>
            </div>
            <div class="disease-symptoms"><strong>Triggers:</strong> ${d.trigger_pollutants.join(', ')}<br><strong>Symptoms:</strong> ${d.symptoms}</div>
          </div>
          <div class="disease-mitigation">🛡️ ${d.mitigation}</div>
        </div>
      `).join('')}
    </div>

    <!-- Transparency & Disclaimer -->
    <div class="disclaimer-box">
      <strong>Data & Clinical Disclaimer:</strong> ${h.disclaimer}
    </div>
  `;
}
