@echo off

tasklist /FI "IMAGENAME eq open-webui.exe" | findstr /I "open-webui.exe" 
if not errorlevel 1 (
    echo open-webui.exe �Ѿ�������
    pause
    exit /b
)

open-webui serve