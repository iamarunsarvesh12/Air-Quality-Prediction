@echo off
setlocal enabledelayedexpansion
title AeroSense TN — Tamil Nadu Air Quality Predictor & Health Intelligence
echo ============================================================
echo   AeroSense TN — Tamil Nadu Air Quality Predictor
echo   Understand the Air. Predict the Risk. (R-First Backend)
echo ============================================================

:: 1. Verify Rscript is installed and accessible in PATH
where Rscript >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo [ERROR] 'Rscript' was not found in your system PATH.
    echo Please install R (version 4.0 or later) from https://cloud.r-project.org
    echo and ensure the R bin directory is added to your environment PATH:
    echo   e.g., C:\Program Files\R\R-4.x.x\bin
    echo.
    pause
    exit /b 1
)

:: 2. Launch using R runtime
echo [Launcher] Verified Rscript. Launching AeroSense TN via R runtime...
echo.
Rscript run.R
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo [ERROR] AeroSense TN stopped unexpectedly with error code %ERRORLEVEL%.
    pause
    exit /b %ERRORLEVEL%
)

pause
