@echo off
echo Starting Finance Tracker dev environment...

:: Kill any existing server on port 3000
for /f "tokens=5" %%p in ('netstat -ano ^| findstr ":3000" ^| findstr "LISTENING"') do (
    taskkill /PID %%p /F >nul 2>&1
)

:: Start backend in a new window
start "Backend API" cmd /k "cd /d C:\Users\LENOVO\Desktop\finance-tracker\backend && node server.js"

:: Wait for server to start
timeout /t 2 /nobreak >nul

:: Set up ADB reverse tunnel
echo Setting up ADB tunnel...
C:\Users\LENOVO\AppData\Local\Android\Sdk\platform-tools\adb.exe reverse tcp:3000 tcp:3000

:: Run Flutter app
echo Starting Flutter app...
cd /d C:\Users\LENOVO\Desktop\finance-tracker\finance_tracker
set GRADLE_OPTS=-Dorg.gradle.offline=true
C:\Users\LENOVO\flutter\bin\flutter.bat run
