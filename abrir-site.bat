@echo off
chcp 65001 >nul
title Site VistoriaPro - servidor local
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0servidor.ps1"
pause
