@echo off
setlocal
rem TGS 6.19.2 CompileComplete: %1 = deployment directory, %2 = engine version.
powershell.exe -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "%~dp0ExternalRsc.ps1" -Mode Publish -DeploymentDirectory "%~1"
if errorlevel 1 echo [external-rsc] ERROR: hook failed unexpectedly; deployment continues. Check resources.txt for stale URLs.
exit /b 0
