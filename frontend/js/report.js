// ===========================================================
// AirSense — report.js (Module 10: Report Generation)
// Lets the user print or save the results dashboard as a PDF
// using the browser's native print-to-PDF, and stamps the
// report with a generated date/time.
// ===========================================================

document.addEventListener('DOMContentLoaded', () => {
  const printBtn = document.getElementById('printBtn');
  if (!printBtn) return;

  printBtn.addEventListener('click', () => {
    // Add a timestamp footer note before printing
    let stamp = document.getElementById('reportStamp');
    if (!stamp) {
      stamp = document.createElement('p');
      stamp.id = 'reportStamp';
      stamp.style.textAlign = 'center';
      stamp.style.color = '#5B6470';
      stamp.style.fontSize = '0.8rem';
      stamp.style.marginTop = '24px';
      document.getElementById('dashboard').appendChild(stamp);
    }
    stamp.textContent = `Report generated on ${new Date().toLocaleString()}`;

    window.print();
  });
});
