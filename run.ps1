# ===========================================================
# AeroSense TN - PowerShell Launcher (R-First Runtime)
# ===========================================================

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "   AeroSense TN - Tamil Nadu Air Quality Predictor" -ForegroundColor Cyan
Write-Host "   Understand the Air. Predict the Risk. (R-First Backend)" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan

# Check if Rscript is in PATH, or search common installation paths
$rscript = Get-Command Rscript -ErrorAction SilentlyContinue

if (-not $rscript) {
    # Check common R installation paths on Windows
    $commonPaths = @(
        "$env:USERPROFILE\R\*\bin\Rscript.exe",
        "$env:ProgramFiles\R\*\bin\Rscript.exe",
        "${env:ProgramFiles(x86)}\R\*\bin\Rscript.exe",
        "$env:LOCALAPPDATA\Programs\R\*\bin\Rscript.exe"
    )
    foreach ($pattern in $commonPaths) {
        $found = Resolve-Path $pattern -ErrorAction SilentlyContinue | Select-Object -Last 1 -ExpandProperty Path
        if ($found -and (Test-Path $found)) {
            $rscript = $found
            $rBinDir = Split-Path -Parent $found
            $env:PATH = "$rBinDir;$env:PATH"
            break
        }
    }
}

if (-not $rscript) {
    Write-Host ""
    Write-Host "[ERROR] 'Rscript' was not found in PATH or standard R directories." -ForegroundColor Red
    Write-Host "Please install R 4.0+ from https://cloud.r-project.org and add it to PATH." -ForegroundColor Yellow
    Write-Host ""
    exit 1
}

# Clean up any leftover listeners on ports 8000 or 5500 before starting
Get-NetTCPConnection -LocalPort 8000, 5500 -State Listen -ErrorAction SilentlyContinue |
    Select-Object -ExpandProperty OwningProcess -Unique |
    ForEach-Object {
        try { Stop-Process -Id $_ -Force -ErrorAction SilentlyContinue } catch {}
    }

# Run the single-command R launcher
Rscript run.R
