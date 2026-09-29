@echo off
setlocal
rem TGS 6.19.2 DeploymentActivation: %1 = deployment directory (also on rollback).
powershell.exe -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "%~dp0ExternalRsc.ps1" -Mode Activate -DeploymentDirectory "%~1"
if errorlevel 1 echo [external-rsc] ERROR: activation hook failed unexpectedly; deployment continues. Check resources.txt for stale URLs.
exit /b 0
