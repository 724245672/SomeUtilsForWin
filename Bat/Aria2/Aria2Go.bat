@echo off

net session >nul 2>&1
if %errorLevel% neq 0 (
    echo 请以管理员身份运行此脚本！
    :: 如果不是以管理员权限运行，则尝试提升权限
    powershell -Command "Start-Process cmd -ArgumentList '/c %~s0' -Verb RunAs"
    exit /b
)

set "taskname=\Aria2\StartAria2"
set "taskdir=\Aria2"

:: 设置输出脚本的文件名
set "bat_file=%~dp0aria2.bat"
:: 设置输出 VBS 脚本的文件名
set "vbs_file=%~dp0start.vbs"
:: 设置配置文件
set "conf_path=%~dp0aria2.conf"

set /p type="请输入操作类型: 安装(I) 删除(D) 更新(U) 退出(任意): "

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
set /p bit_type="请输入32位还是64位: 32位/64位(32/64): "

if /i "%bit_type%"=="32" (
	set "aria2_bit=win-32bit"
) else (
	set "aria2_bit=win-64bit"
)

goto :eof

:moveFile
setlocal enabledelayedexpansion
:: 获取解压后的文件夹名称
    for /f "delims=" %%f in ('dir /b /ad "%~dp0" ^| findstr /i "%aria2_bit%"') do set "ex_dir=%%f"

    :: 检查是否找到了符合条件的文件夹
    if defined ex_dir (
        echo 找到解压后的文件夹: %ex_dir%

        :: 移动文件到当前目录并覆盖现有文件
        echo 移动文件到当前目录并覆盖现有文件...
        move /y "%~dp0%ex_dir%\*" "%~dp0"
        echo 文件已移动并覆盖完成。

        :: 删除解压后的文件夹
        rmdir /s /q "%~dp0%ex_dir%"
    ) else (
        echo 未找到包含 "%aria2_bit%" 的文件夹。
    )
	
endlocal
goto :eof

:stopTask
echo 开始停止aria2c.exe
taskkill /F /IM aria2c.exe
goto :eof

:goDownLoadFile
setlocal enabledelayedexpansion

call :stopTask

:: GitHub API URL
set "url=https://api.github.com/repos/aria2/aria2/releases/latest"

:: 临时保存 JSON 响应
set "json_file=%~dp0\aria2_latest.json"

:: 获取最新发布的 JSON 数据
powershell -Command "(Invoke-WebRequest -Uri %url% -Headers @{'User-Agent'='Mozilla/5.0'}).Content | Out-File -FilePath %json_file% -Encoding utf8"

:: 查找 Windows 64 位 zip 文件的下载链接
for /f "delims=" %%i in ('powershell -Command "(Get-Content %json_file% | ConvertFrom-Json).assets | Where-Object { $_.name -match '.*%aria2_bit%.*\.zip' } | Select-Object -ExpandProperty browser_download_url"') do set "download_url=%%i"

:: 检查是否找到了下载链接
if defined download_url (
    echo 下载链接: %download_url%
    :: 下载文件
    powershell -Command "Invoke-WebRequest -Uri '%download_url%' -OutFile '%~dp0%aria2_bit%.zip'"
    echo 下载完成: %aria2_bit%.zip
	
	:: 解压到当前目录
    powershell -Command "Expand-Archive -Path '%~dp0%aria2_bit%.zip' -DestinationPath '%~dp0'"
    echo 解压完成到当前目录。
	
	call :moveFile

    :: 删除下载的 zip 文件
    del "%~dp0%aria2_bit%.zip"
	
) else (
    echo 未找到 Windows 64 位版本的 zip 文件。
)

:: 删除临时 JSON 文件
del "%json_file%"

endlocal
goto :eof


:goDelete
setlocal enabledelayedexpansion

call :stopTask

schtasks /delete /tn "%taskname%" /f

if %errorlevel% equ 0 (
    echo %taskname% 任务计划已删除。
) else (
    echo 任务计划删除失败，错误代码：%errorlevel%
)

schtasks /delete /tn "%taskdir%" /f

if %errorlevel% equ 0 (
    echo %taskname% 任务计划文件夹已删除。
) else (
    echo 任务计划文件夹删除失败，错误代码：%errorlevel%
)

:: 获取当前批处理脚本的文件路径
set "this_bat=%~dp0%~nx0"

:: 删除当前目录下的所有文件（不删除目录）
for %%f in (%~dp0*.*) do (
    if /i not "%%f"=="%this_bat%" (
       del /f /q "%%f"
    )
)

:: 删除批处理脚本本身
::del /q "%this_bat%"
endlocal

goto :eof

:goCreateConf
setlocal enabledelayedexpansion

::输出文件转为 UTF-8 编码
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

echo 配置文件已写入完成。
endlocal
goto :eof

:goCreateFile

call :goCreateConf

:: 输出当前脚本内容到输出文件
echo @echo off > "%bat_file%"
echo :: 设置aria2c.exe和配置文件的路径 >> "%bat_file%"
echo set "aria2c_path=%%~dp0aria2c.exe" >> "%bat_file%"
echo set ""conf_path=%%~dp0aria2.conf"" >> "%bat_file%"
echo. >> "%bat_file%"
echo :: 检查aria2c.exe是否已经在运行 >> "%bat_file%"
echo tasklist /FI "IMAGENAME eq aria2c.exe" ^| findstr /I "aria2c.exe" >> "%bat_file%"
echo if not errorlevel 1 ( >> "%bat_file%"
echo     echo aria2c.exe 已经在运行 >> "%bat_file%"
echo     pause >> "%bat_file%"
echo     exit /b >> "%bat_file%"
echo ) >> "%bat_file%"
echo. >> "%bat_file%"
echo :: 运行aria2c.exe并指定配置文件路径 >> "%bat_file%"
echo %%aria2c_path%% --conf-path=%%conf_path%% >> "%bat_file%"
echo. >> "%bat_file%"
echo :: 暂停以查看运行结果 >> "%bat_file%"
echo pause >> "%bat_file%"

echo 成功生成aria2.bat

:: 输出 VBS 脚本内容到文件
echo Set objShell = CreateObject("WScript.Shell") > "%vbs_file%"
echo Set objFSO = CreateObject("Scripting.FileSystemObject") >> "%vbs_file%"
echo. >> "%vbs_file%"
echo ' 获取当前 .vbs 文件的路径 >> "%vbs_file%"
echo strCurrentPath = objFSO.GetParentFolderName(WScript.ScriptFullName) >> "%vbs_file%"
echo. >> "%vbs_file%"
echo ' 拼接 aria2.bat 文件路径 >> "%vbs_file%"
echo strBatPath = strCurrentPath ^& "\aria2.bat" >> "%vbs_file%"
echo. >> "%vbs_file%"
echo ' 运行 aria2.bat >> "%vbs_file%"
echo objShell.Run """" ^& strBatPath ^& """", 0, False >> "%vbs_file%"

echo 成功生成start.vbs

set "vbsPath=%~dp0start.vbs"

:: 使用schtasks命令创建任务计划，在用户登录时触发
schtasks /create /tn "%taskname%" /tr "%vbsPath%" /sc onlogon /ru %username% /f

if %errorlevel% equ 0 (
    echo 任务计划已创建，将在用户登录时运行。
) else (
    echo 任务计划创建失败，错误代码：%errorlevel%
)

goto :eof

:startVbs
	echo 启动aria2
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
