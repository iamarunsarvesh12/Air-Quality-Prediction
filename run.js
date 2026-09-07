/**
 * AirSense — Node.js Single-Command Runner Script
 * Runs the backend API and frontend HTTP server in parallel.
 */

const { spawn, exec } = require('child_process');
const path = require('path');
const fs = require('fs');

const ROOT_DIR = __dirname;
const BACKEND_DIR = path.join(ROOT_DIR, 'backend');
const FRONTEND_DIR = path.join(ROOT_DIR, 'frontend');
const MODEL_PATH = path.join(BACKEND_DIR, 'model.rds');

console.log('==========================================================');
console.log('   AirSense — Air Quality Prediction & Disease Mapping');
console.log('==========================================================');

// Check model file
if (!fs.existsSync(MODEL_PATH)) {
  console.log('[Setup] Training Random Forest model...');
  const train = spawn('Rscript', ['-e', ".libPaths(c('../r_libs', 'r_libs', .libPaths())); source('train_model.R')"], {
    cwd: BACKEND_DIR,
    stdio: 'inherit'
  });
  train.on('close', (code) => {
    if (code === 0) {
      console.log('[Setup] Model trained successfully.');
      startServers();
    } else {
      console.error('[Setup] Model training failed.');
      process.exit(1);
    }
  });
} else {
  console.log('[Setup] Model file model.rds verified.');
  startServers();
}

function startServers() {
  console.log('[Backend] Starting R Plumber API on http://127.0.0.1:8000 ...');
  const backend = spawn('Rscript', [
    '-e',
    ".libPaths(c('r_libs', 'backend/r_libs', .libPaths())); pr <- plumber::pr('backend/api_server.R'); plumber::pr_run(pr, host = '0.0.0.0', port = 8000, docs = FALSE)"
  ], { cwd: ROOT_DIR, stdio: 'inherit' });

  console.log('[Frontend] Starting HTTP Server on http://localhost:5500 ...');
  const frontend = spawn('python', ['-m', 'http.server', '5500', '--directory', FRONTEND_DIR], {
    cwd: ROOT_DIR,
    stdio: 'inherit'
  });

  setTimeout(() => {
    console.log('[Launcher] Opening browser to http://localhost:5500 ...');
    const startCmd = process.platform === 'win32' ? 'start' : process.platform === 'darwin' ? 'open' : 'xdg-open';
    exec(`${startCmd} http://localhost:5500`);
  }, 2000);

  function cleanup() {
    console.log('\nShutting down AirSense servers...');
    backend.kill();
    frontend.kill();
    process.exit(0);
  }

  process.on('SIGINT', cleanup);
  process.on('SIGTERM', cleanup);
}
