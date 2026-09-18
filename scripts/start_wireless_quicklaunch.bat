@echo off
title Pippo - Wireless Watch (quick launch, no rebuild)
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0wireless_watch.ps1" -Mode app %*
pause
