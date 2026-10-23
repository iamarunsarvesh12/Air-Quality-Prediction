/**
 * AeroSense TN — Node.js Launcher Wrapper
 * Delegates directly to Rscript run.R for R-first execution.
 */

const { spawn } = require('child_process');

console.log('==========================================================');
console.log('   AeroSense TN — Tamil Nadu Air Quality Predictor');
console.log('   Understand the Air. Predict the Risk. (R-First Backend)');
console.log('==========================================================');

const r = spawn('Rscript', ['run.R'], { stdio: 'inherit', shell: true });

r.on('close', (code) => {
  process.exit(code);
});
