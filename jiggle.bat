@echo off
REM 1-clique: roda o jiggler. Fecha esta janela = para o jiggler.
title Mouse Jiggler
cd /d "%~dp0"
powershell -NoProfile -File "%~dp0jiggle.ps1" -NoSleep
pause
