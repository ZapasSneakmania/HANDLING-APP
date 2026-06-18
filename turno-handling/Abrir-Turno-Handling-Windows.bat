@echo off
setlocal
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0servidor-local.ps1"
echo.
echo Servidor cerrado. Puedes cerrar esta ventana.
pause >nul
