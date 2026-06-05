@echo off
REM Mata todos os jigglers escondidos (powershell rodando jiggle.ps1).
title Parar Jiggler
powershell -NoProfile -Command "Get-CimInstance Win32_Process | Where-Object { $_.CommandLine -like '*jiggle.ps1*' } | ForEach-Object { Stop-Process -Id $_.ProcessId -Force }"
echo Jiggler parado.
timeout /t 2 >nul
