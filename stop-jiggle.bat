@echo off
REM Para o Jungle por completo: mata o watchdog primeiro (senao ele revive o app),
REM depois o app (jiggle-gui) e a versao CLI (jiggle.ps1).
title Parar Jungle
powershell -NoProfile -Command "$me=$PID; Get-CimInstance Win32_Process | Where-Object { $_.ProcessId -ne $me -and ($_.Name -eq 'powershell.exe' -or $_.Name -eq 'pwsh.exe') -and ($_.CommandLine -like '*watchdog.ps1*' -or $_.CommandLine -like '*jiggle-gui.ps1*' -or $_.CommandLine -like '*-File*jiggle.ps1*') } | ForEach-Object { try { Stop-Process -Id $_.ProcessId -Force -ErrorAction Stop } catch {} }"
echo Jungle parado (watchdog + app).
timeout /t 2 >nul
