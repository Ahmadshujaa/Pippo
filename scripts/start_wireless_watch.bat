@echo off
title Pippo - Wireless Watch (flutter run)
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0wireless_watch.ps1" -Mode flutter %*
pause
