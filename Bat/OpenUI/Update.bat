@echo off

net session >nul 2>&1
if %errorLevel% neq 0 (
    echo 请以管理员身份运行此脚本！
    :: 如果不是以管理员权限运行，则尝试提升权限
    powershell -Command "Start-Process cmd -ArgumentList '/c %~s0' -Verb RunAs"
    exit /b
)

tasklist /FI "IMAGENAME eq open-webui.exe" | findstr /I "open-webui.exe" 
if not errorlevel 1 (
    echo open-webui.exe 已经在运行
    taskkill /F /im open-webui.exe > NUL
)

pip install -U open-webui
pause
cscript //nologo %~dp0start.vbs
exit /b