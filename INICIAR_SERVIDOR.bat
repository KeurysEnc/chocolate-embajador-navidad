@echo off
title Chocolate Embajador - Servidor Local
cd /d "%~dp0"
echo ==============================================================
echo   Iniciando Servidor Web Local para Chocolate Embajador...
echo ==============================================================
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0server.ps1"
pause
