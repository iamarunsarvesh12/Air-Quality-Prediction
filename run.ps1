# ===========================================================
# AeroSense TN — PowerShell Launcher (R-First Runtime)
# ===========================================================

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "   AeroSense TN — Tamil Nadu Air Quality Predictor" -ForegroundColor Cyan
Write-Host "   Understand the Air. Predict the Risk. (R-First Backend)" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan

$rscript = Get-Command Rscript -ErrorAction SilentlyContinue
if (-not $rscript) {
    Write-Host ""
    Write-Host "[ERROR] 'Rscript' was not found in PATH." -ForegroundColor Red
    Write-Host "Please install R 4.0+ from https://cloud.r-project.org and add it to PATH." -ForegroundColor Yellow
    Write-Host ""
    exit 1
}

Rscript run.R
