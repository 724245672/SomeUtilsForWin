@echo off

net session >nul 2>&1
if %errorLevel% neq 0 (
    echo ���Թ���Ա������д˽ű���
    :: ��������Թ���ԱȨ�����У���������Ȩ��
    powershell -Command "Start-Process cmd -ArgumentList '/c %~s0' -Verb RunAs"
    exit /b
)

tasklist /FI "IMAGENAME eq open-webui.exe" | findstr /I "open-webui.exe" 
if not errorlevel 1 (
    echo open-webui.exe �Ѿ�������
    taskkill /F /im open-webui.exe > NUL
)

pip install -U open-webui
pause
cscript //nologo %~dp0start.vbs
exit /b