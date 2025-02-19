@echo off

net session >nul 2>&1
if %errorLevel% neq 0 (
    echo ���Թ���Ա������д˽ű���
    :: ��������Թ���ԱȨ�����У���������Ȩ��
    powershell -Command "Start-Process cmd -ArgumentList '/c %~s0' -Verb RunAs"
    exit /b
)

set "taskname=\Alist\����alist"
set "taskdir=\Alist"

:: ��������ű����ļ���
set "bat_file=%~dp0alist.bat"
:: ������� VBS �ű����ļ���
set "vbs_file=%~dp0start.vbs"

set /p type="�������������: ��װ(I) ɾ��(D) ����(U) �˳�(����): "

if /i "%type%"=="I" (
	call :askForBit
    call :goCreate
)

if /i "%type%"=="D" (
	call :goDelete
)

if /i "%type%"=="U" (
	call :askForBit
	call :goUpdate
)

pause
exit /b

:askForBit
set /p bit_type="���������ص��ļ�����(amd64/arm64/386): "

if /i "%bit_type%"=="386" (
	set "alist_bit=alist-windows-386"
) 

if /i "%bit_type%"=="arm64" (
	set "alist_bit=alist-windows-arm64"
) else (
	set "alist_bit=alist-windows-amd64"
)

goto :eof

:stopTask
echo ��ʼֹͣalist.exe
taskkill /F /IM alist.exe
goto :eof

:goDownLoadFile
setlocal enabledelayedexpansion

call :stopTask

:: GitHub API URL
set "url=https://api.github.com/repos/AlistGo/alist/releases/latest"

:: ��ʱ���� JSON ��Ӧ
set "json_file=%~dp0\alist_latest.json"

:: ��ȡ���·����� JSON ����
powershell -Command "(Invoke-WebRequest -Uri %url% -Headers @{'User-Agent'='Mozilla/5.0'}).Content | Out-File -FilePath %json_file% -Encoding utf8"

:: ���� Windows 64 λ zip �ļ�����������
for /f "delims=" %%i in ('powershell -Command "(Get-Content %json_file% | ConvertFrom-Json).assets | Where-Object { $_.name -match '.*%alist_bit%\.zip' } | Select-Object -ExpandProperty browser_download_url"') do set "download_url=%%i"

:: ����Ƿ��ҵ�����������
if defined download_url (
    echo ��������: %download_url%
    :: �����ļ�
    powershell -Command "Invoke-WebRequest -Uri '%download_url%' -OutFile '%~dp0%alist_bit%.zip'"
    echo �������: %alist_bit%.zip
	
	:: ��ѹ����ǰĿ¼
    powershell -Command "Expand-Archive -Force -Path '%~dp0%alist_bit%.zip' -DestinationPath '%~dp0'"
    echo ��ѹ��ɵ���ǰĿ¼��	

    :: ɾ�����ص� zip �ļ�
    del "%~dp0%alist_bit%.zip"
	
) else (
    echo δ�ҵ� Windows 64 λ�汾�� zip �ļ���
)

:: ɾ����ʱ JSON �ļ�
del "%json_file%"

endlocal
goto :eof


:goDelete
setlocal enabledelayedexpansion
call :stopTask

schtasks /delete /tn "%taskname%" /f

if %errorlevel% equ 0 (
    echo %taskname% ����ƻ���ɾ����
) else (
    echo ����ƻ�ɾ��ʧ�ܣ�������룺%errorlevel%
)

schtasks /delete /tn "%taskdir%" /f

if %errorlevel% equ 0 (
    echo %taskname% ����ƻ��ļ�����ɾ����
) else (
    echo ����ƻ��ļ���ɾ��ʧ�ܣ�������룺%errorlevel%
)

:: ��ȡ��ǰ������ű����ļ�·��
set "this_bat=%~dp0%~nx0"

:: ɾ����ǰĿ¼�µ������ļ�����ɾ��Ŀ¼��
for %%f in (%~dp0*.*) do (
    if /i not "%%f"=="%this_bat%" (
       del /f /q "%%f"
    )
)

:: ɾ����ǰĿ¼�е��ļ��м�������
for /d %%d in (%~dp0*) do (
    echo ����ɾ���ļ���: %%d
    rmdir /s /q "%%d"
)

:: ɾ��������ű�����
::del /q "%this_bat%"

endlocal

goto :eof

:goCreateFile

:: �����ǰ�ű����ݵ�����ļ�
echo @echo off > "%bat_file%"
echo :: ����alist.exe��·�� >> "%bat_file%"
echo set "alist_path=%%~dp0alist.exe" >> "%bat_file%"
echo. >> "%bat_file%"
echo :: ���alist.exe�Ƿ��Ѿ������� >> "%bat_file%"
echo tasklist /FI "IMAGENAME eq alist.exe" ^| findstr /I "alist.exe" >> "%bat_file%"
echo if not errorlevel 1 ( >> "%bat_file%"
echo     echo alist.exe �Ѿ������� >> "%bat_file%"
echo     pause >> "%bat_file%"
echo     exit /b >> "%bat_file%"
echo ) >> "%bat_file%"
echo. >> "%bat_file%"
echo :: ����alist.exe >> "%bat_file%"
echo "%%alist_path%%" server --force-bin-dir false >> "%bat_file%"
echo. >> "%bat_file%"
echo :: ��ͣ�Բ鿴���н�� >> "%bat_file%"
echo pause >> "%bat_file%"

echo �ɹ�����alist.bat

:: ��� VBS �ű����ݵ��ļ�
echo Set objShell = CreateObject("WScript.Shell") > "%vbs_file%"
echo Set objFSO = CreateObject("Scripting.FileSystemObject") >> "%vbs_file%"
echo. >> "%vbs_file%"
echo ' ��ȡ��ǰ .vbs �ļ���·�� >> "%vbs_file%"
echo strCurrentPath = objFSO.GetParentFolderName(WScript.ScriptFullName) >> "%vbs_file%"
echo. >> "%vbs_file%"
echo ' ƴ�� alist.bat �ļ�·�� >> "%vbs_file%"
echo strBatPath = strCurrentPath ^& "\alist.bat" >> "%vbs_file%"
echo. >> "%vbs_file%"
echo ' ���� alist.bat >> "%vbs_file%"
echo objShell.Run """" ^& strBatPath ^& """", 0, False >> "%vbs_file%"

echo �ɹ�����start.vbs

set "vbsPath=%~dp0start.vbs"

:: ʹ��schtasks���������ƻ������û���¼ʱ����
schtasks /create /tn "%taskname%" /tr "%vbsPath%" /sc onlogon /ru %username% /f

if %errorlevel% equ 0 (
    echo ����ƻ��Ѵ����������û���¼ʱ���С�
) else (
    echo ����ƻ�����ʧ�ܣ�������룺%errorlevel%
)

goto :eof


:startVbs
	echo ����alist
	cscript //nologo %~dp0start.vbs
goto :eof


:goCreate

call :goDownLoadFile
call :goCreateFile
call :startVbs

goto :eof

:goUpdate

call :goDownLoadFile
call :startVbs

goto :eof