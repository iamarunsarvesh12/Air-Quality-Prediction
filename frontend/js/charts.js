// ===========================================================
// AirSense — charts.js (Module 9: Data Visualization)
// Renders Bar, Radar, and Pie charts using Chart.js
// Configured to look stunning on dark theme.
// ===========================================================

window.renderAirSenseCharts = function (input, result) {

  const pollutantLabels = ['PM2.5', 'PM10', 'NO₂', 'SO₂', 'CO', 'O₃'];
  const pollutantValues = [
    input.pm25, input.pm10, input.no2, input.so2, input.co, input.o3,
  ];

  const palette = ['#3182CE', '#4299E1', '#63B3ED', '#F6E05E', '#ED8936', '#E53E3E'];

  // ---- Bar Chart: Pollutant Levels ----
  const barCtx = document.getElementById('barChart');
  if (barCtx) {
    new Chart(barCtx, {
      type: 'bar',
      data: {
        labels: pollutantLabels,
        datasets: [{
          label: 'Pollutant level',
          data: pollutantValues,
          backgroundColor: palette,
          borderRadius: 6,
        }],
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: { legend: { display: false } },
        scales: {
          x: {
            grid: { color: 'rgba(255, 255, 255, 0.08)' },
            ticks: { color: '#A0AEC0', font: { family: 'Inter', size: 11 } }
          },
          y: {
            beginAtZero: true,
            grid: { color: 'rgba(255, 255, 255, 0.08)' },
            ticks: { color: '#A0AEC0', font: { family: 'Inter', size: 11 } }
          }
        },
      },
    });
  }

  // ---- Radar Chart: Pollutant Comparison ----
  const radarCtx = document.getElementById('radarChart');
  if (radarCtx) {
    new Chart(radarCtx, {
      type: 'radar',
      data: {
        labels: pollutantLabels,
        datasets: [{
          label: 'Current reading',
          data: pollutantValues,
          backgroundColor: 'rgba(66, 153, 225, 0.2)',
          borderColor: '#4299E1',
          pointBackgroundColor: '#4299E1',
          pointBorderColor: '#fff',
        }],
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: { legend: { display: false } },
        scales: {
          r: {
            grid: { color: 'rgba(255, 255, 255, 0.08)' },
            angleLines: { color: 'rgba(255, 255, 255, 0.08)' },
            pointLabels: { color: '#A0AEC0', font: { family: 'Inter', size: 11 } },
            ticks: { color: '#A0AEC0', backdropColor: 'transparent', font: { size: 9 } }
          }
        },
      },
    });
  }

  // ---- Pie Chart: AQI Category Reference ----
  const pieCtx = document.getElementById('pieChart');
  if (pieCtx) {
    new Chart(pieCtx, {
      type: 'pie',
      data: {
        labels: ['Good', 'Moderate', 'Unhealthy (Sensitive)', 'Unhealthy', 'Very Unhealthy', 'Hazardous'],
        datasets: [{
          data: [50, 50, 50, 50, 100, 100], // range widths, illustrative reference
          backgroundColor: ['#10B981', '#FBBF24', '#F59E0B', '#EF4444', '#8B5CF6', '#B91C1C'],
          borderColor: '#1A202C',
          borderWidth: 2,
        }],
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: { 
            position: 'bottom', 
            labels: { 
              boxWidth: 12, 
              color: '#A0AEC0',
              font: { size: 10, family: 'Inter' } 
            } 
          },
          tooltip: {
            callbacks: {
              label: (ctx) => `Category ${ctx.label}: Active prediction is "${result.category}"`,
            },
          },
        },
      },
    });
  }
};
