# PowerShell script to capture GratiStellar debug logs from Android device
# Usage: .\get_device_logs.ps1

Write-Host "Connecting to Android device..." -ForegroundColor Cyan

# Check if adb is available
$adbPath = Get-Command adb -ErrorAction SilentlyContinue
if (-not $adbPath) {
    Write-Host "ERROR: adb not found. Please install Android SDK Platform Tools." -ForegroundColor Red
    Write-Host "Install Android Studio or add platform-tools to your PATH." -ForegroundColor Yellow
    exit 1
}

# Check if device is connected
$devices = adb devices
if ($devices -match "device$") {
    Write-Host "Device connected!" -ForegroundColor Green
} else {
    Write-Host "ERROR: No Android device connected." -ForegroundColor Red
    Write-Host "Please connect your device via USB and enable USB debugging." -ForegroundColor Yellow
    exit 1
}

Write-Host "`nClearing old logs..." -ForegroundColor Cyan
adb logcat -c

Write-Host "`nStarting log capture. Reproduce the issue now..." -ForegroundColor Yellow
Write-Host "Press Ctrl+C to stop capturing after reproducing the issue.`n" -ForegroundColor Yellow

# Capture logs and filter for relevant patterns
$logFile = "device_logs_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
Write-Host "Logs will be saved to: $logFile" -ForegroundColor Cyan
Write-Host "`nFiltering for GratiStellar debug logs...`n" -ForegroundColor Cyan

adb logcat | Select-String -Pattern "DEBUG|SYNC|AUTH|ERROR|gratistellar|flutter" | Tee-Object -FilePath $logFile

Write-Host "`nLog capture complete! Check $logFile for details." -ForegroundColor Green

