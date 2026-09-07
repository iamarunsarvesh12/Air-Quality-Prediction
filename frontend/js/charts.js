// ===========================================================
// AeroSense TN — charts.js (Data Visualizations)
// Interactive 24-Hour Forecast & Pollutant Comparison Charts
// ===========================================================

let trendChartInstance = null;
let pollutantChartInstance = null;
let districtChartInstance = null;

const ChartService = {
  // 1. Render 24-Hour Forecast Trend Line
  renderTrendChart(canvasId, forecastData, currentAqi) {
    const canvas = document.getElementById(canvasId);
    if (!canvas || typeof Chart === 'undefined') return;

    const ctx = canvas.getContext('2d');
    if (trendChartInstance) trendChartInstance.destroy();

    const labels = ['Current', ...forecastData.map(d => d.time_label)];
    const dataPoints = [currentAqi, ...forecastData.map(d => d.predicted_aqi)];

    trendChartInstance = new Chart(ctx, {
      type: 'line',
      data: {
        labels: labels,
        datasets: [{
          label: 'Predicted AQI Trajectory',
          data: dataPoints,
          borderColor: '#0284C7',
          backgroundColor: 'rgba(2, 132, 199, 0.1)',
          borderWidth: 3,
          fill: true,
          tension: 0.35,
          pointBackgroundColor: '#0284C7',
          pointRadius: 4,
          pointHoverRadius: 7
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: { display: false },
          tooltip: {
            backgroundColor: '#0F172A',
            titleFont: { family: 'Space Grotesk', size: 13 },
            bodyFont: { family: 'Inter', size: 12 },
            padding: 10,
            cornerRadius: 8
          }
        },
        scales: {
          y: {
            beginAtZero: false,
            grid: { color: '#E2E8F0' },
            ticks: { font: { family: 'Inter' } }
          },
          x: {
            grid: { display: false },
            ticks: { font: { family: 'Inter', size: 11 } }
          }
        }
      }
    });
  },

  // 2. Render Pollutant Multi-Bar Comparison
  renderPollutantChart(canvasId, pollutants) {
    const canvas = document.getElementById(canvasId);
    if (!canvas || typeof Chart === 'undefined') return;

    const ctx = canvas.getContext('2d');
    if (pollutantChartInstance) pollutantChartInstance.destroy();

    const labels = ['PM2.5', 'PM10', 'NO₂', 'SO₂', 'CO (x10)', 'O₃', 'NH₃'];
    const values = [
      pollutants.pm25 || 0,
      pollutants.pm10 || 0,
      pollutants.no2 || 0,
      pollutants.so2 || 0,
      (pollutants.co || 0) * 10,
      pollutants.o3 || 0,
      pollutants.nh3 || 0
    ];

    pollutantChartInstance = new Chart(ctx, {
      type: 'bar',
      data: {
        labels: labels,
        datasets: [{
          label: 'Concentration (Standardized)',
          data: values,
          backgroundColor: [
            '#EF4444',
            '#F59E0B',
            '#0284C7',
            '#10B981',
            '#6366F1',
            '#8B5CF6',
            '#14B8A6'
          ],
          borderRadius: 6
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: { display: false }
        },
        scales: {
          y: {
            grid: { color: '#E2E8F0' },
            ticks: { font: { family: 'Inter' } }
          },
          x: {
            grid: { display: false },
            ticks: { font: { family: 'Inter', weight: 600 } }
          }
        }
      }
    });
  },

  // 3. Render Multi-District Comparison
  renderDistrictComparisonChart(canvasId, hubs) {
    const canvas = document.getElementById(canvasId);
    if (!canvas || typeof Chart === 'undefined' || !hubs || hubs.length === 0) return;

    const ctx = canvas.getContext('2d');
    if (districtChartInstance) districtChartInstance.destroy();

    const labels = hubs.map(h => h.district_name.replace(/ \(.*\)/, ''));
    const data = hubs.map(h => h.aqi);
    const bgColors = hubs.map(h => h.color || '#0284C7');

    districtChartInstance = new Chart(ctx, {
      type: 'bar',
      data: {
        labels: labels,
        datasets: [{
          label: 'Current Predicted AQI',
          data: data,
          backgroundColor: bgColors,
          borderRadius: 6
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: { display: false }
        },
        scales: {
          y: {
            beginAtZero: true,
            grid: { color: '#E2E8F0' }
          },
          x: {
            grid: { display: false },
            ticks: { font: { family: 'Inter', size: 10 } }
          }
        }
      }
    });
  }
};

window.ChartService = ChartService;
