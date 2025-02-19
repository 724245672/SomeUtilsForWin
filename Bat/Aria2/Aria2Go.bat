@echo off

net session >nul 2>&1
if %errorLevel% neq 0 (
    echo ���Թ���Ա������д˽ű���
    :: ��������Թ���ԱȨ�����У���������Ȩ��
    powershell -Command "Start-Process cmd -ArgumentList '/c %~s0' -Verb RunAs"
    exit /b
)

set "taskname=\Aria2\StartAria2"
set "taskdir=\Aria2"

:: ��������ű����ļ���
set "bat_file=%~dp0aria2.bat"
:: ������� VBS �ű����ļ���
set "vbs_file=%~dp0start.vbs"
:: ���������ļ�
set "conf_path=%~dp0aria2.conf"

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
set /p bit_type="������32λ����64λ: 32λ/64λ(32/64): "

if /i "%bit_type%"=="32" (
	set "aria2_bit=win-32bit"
) else (
	set "aria2_bit=win-64bit"
)

goto :eof

:moveFile
setlocal enabledelayedexpansion
:: ��ȡ��ѹ����ļ�������
    for /f "delims=" %%f in ('dir /b /ad "%~dp0" ^| findstr /i "%aria2_bit%"') do set "ex_dir=%%f"

    :: ����Ƿ��ҵ��˷����������ļ���
    if defined ex_dir (
        echo �ҵ���ѹ����ļ���: %ex_dir%

        :: �ƶ��ļ�����ǰĿ¼�����������ļ�
        echo �ƶ��ļ�����ǰĿ¼�����������ļ�...
        move /y "%~dp0%ex_dir%\*" "%~dp0"
        echo �ļ����ƶ���������ɡ�

        :: ɾ����ѹ����ļ���
        rmdir /s /q "%~dp0%ex_dir%"
    ) else (
        echo δ�ҵ����� "%aria2_bit%" ���ļ��С�
    )
	
endlocal
goto :eof

:stopTask
echo ��ʼֹͣaria2c.exe
taskkill /F /IM aria2c.exe
goto :eof

:goDownLoadFile
setlocal enabledelayedexpansion

call :stopTask

:: GitHub API URL
set "url=https://api.github.com/repos/aria2/aria2/releases/latest"

:: ��ʱ���� JSON ��Ӧ
set "json_file=%~dp0\aria2_latest.json"

:: ��ȡ���·����� JSON ����
powershell -Command "(Invoke-WebRequest -Uri %url% -Headers @{'User-Agent'='Mozilla/5.0'}).Content | Out-File -FilePath %json_file% -Encoding utf8"

:: ���� Windows 64 λ zip �ļ�����������
for /f "delims=" %%i in ('powershell -Command "(Get-Content %json_file% | ConvertFrom-Json).assets | Where-Object { $_.name -match '.*%aria2_bit%.*\.zip' } | Select-Object -ExpandProperty browser_download_url"') do set "download_url=%%i"

:: ����Ƿ��ҵ�����������
if defined download_url (
    echo ��������: %download_url%
    :: �����ļ�
    powershell -Command "Invoke-WebRequest -Uri '%download_url%' -OutFile '%~dp0%aria2_bit%.zip'"
    echo �������: %aria2_bit%.zip
	
	:: ��ѹ����ǰĿ¼
    powershell -Command "Expand-Archive -Path '%~dp0%aria2_bit%.zip' -DestinationPath '%~dp0'"
    echo ��ѹ��ɵ���ǰĿ¼��
	
	call :moveFile

    :: ɾ�����ص� zip �ļ�
    del "%~dp0%aria2_bit%.zip"
	
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

:: ɾ��������ű�����
::del /q "%this_bat%"
endlocal

goto :eof

:goCreateConf
setlocal enabledelayedexpansion

::����ļ�תΪ UTF-8 ����
powershell -Command "Set-Content -Path '%conf_path%' -Value \"dir=%~dp0download`r`n^
log=%~dp0Aria2.log`r`n^
log-level=error`r`n^
disk-cache=0`r`n^
file-allocation=prealloc`r`n^
continue=true`r`n^
max-concurrent-downloads=4`r`n^
max-connection-per-server=4`r`n^
min-split-size=10M`r`n^
split=4`r`n^
disable-ipv6=false`r`n^
input-file=%~dp0aria2.session`r`n^
save-session=%~dp0aria2.session`r`n^
save-session-interval=60`r`n^
enable-rpc=true`r`n^
rpc-allow-origin-all=true`r`n^
rpc-listen-all=true`r`n^
rpc-listen-port=6800`r`n^
rpc-save-upload-metadata=true`r`n^
rpc-secure=false`r`n^
follow-torrent=true`r`n^
listen-port=51413`r`n^
enable-dht=true`r`n^
enable-dht6=true`r`n^
bt-enable-lpd=true`r`n^
enable-peer-exchange=true`r`n^
peer-id-prefix=-TR2770-`r`n^
user-agent=Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Safari/537.36`r`n^
seed-ratio=1.0`r`n^
seed-time=0`r`n^
force-save=false`r`n^
bt-seed-unverified=true`r`n^
bt-save-metadata=true`r`n^
max-overall-upload-limit=100K`r`n^
max-upload-limit=100K`r`n^
auto-file-renaming=false`r`n^
keep-unfinished-download-result=true`r`n^
bt-request-peer-speed-limit=100K`r`n^
daemon=true`r`n^
enable-mmap=true`r`n^
max-download-result=2000`r`n^
force-sequential=true`r`n^
parameterized-uri=true`r`n^
retry-wait=60`r`n^
max-tries=5\" -Encoding utf8"

echo �����ļ���д����ɡ�
endlocal
goto :eof

:goCreateFile

call :goCreateConf

:: �����ǰ�ű����ݵ�����ļ�
echo @echo off > "%bat_file%"
echo :: ����aria2c.exe�������ļ���·�� >> "%bat_file%"
echo set "aria2c_path=%%~dp0aria2c.exe" >> "%bat_file%"
echo set ""conf_path=%%~dp0aria2.conf"" >> "%bat_file%"
echo. >> "%bat_file%"
echo :: ���aria2c.exe�Ƿ��Ѿ������� >> "%bat_file%"
echo tasklist /FI "IMAGENAME eq aria2c.exe" ^| findstr /I "aria2c.exe" >> "%bat_file%"
echo if not errorlevel 1 ( >> "%bat_file%"
echo     echo aria2c.exe �Ѿ������� >> "%bat_file%"
echo     pause >> "%bat_file%"
echo     exit /b >> "%bat_file%"
echo ) >> "%bat_file%"
echo. >> "%bat_file%"
echo :: ����aria2c.exe��ָ�������ļ�·�� >> "%bat_file%"
echo %%aria2c_path%% --conf-path=%%conf_path%% >> "%bat_file%"
echo. >> "%bat_file%"
echo :: ��ͣ�Բ鿴���н�� >> "%bat_file%"
echo pause >> "%bat_file%"

echo �ɹ�����aria2.bat

:: ��� VBS �ű����ݵ��ļ�
echo Set objShell = CreateObject("WScript.Shell") > "%vbs_file%"
echo Set objFSO = CreateObject("Scripting.FileSystemObject") >> "%vbs_file%"
echo. >> "%vbs_file%"
echo ' ��ȡ��ǰ .vbs �ļ���·�� >> "%vbs_file%"
echo strCurrentPath = objFSO.GetParentFolderName(WScript.ScriptFullName) >> "%vbs_file%"
echo. >> "%vbs_file%"
echo ' ƴ�� aria2.bat �ļ�·�� >> "%vbs_file%"
echo strBatPath = strCurrentPath ^& "\aria2.bat" >> "%vbs_file%"
echo. >> "%vbs_file%"
echo ' ���� aria2.bat >> "%vbs_file%"
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
	echo ����aria2
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
