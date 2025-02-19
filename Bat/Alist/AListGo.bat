@echo off

net session >nul 2>&1
if %errorLevel% neq 0 (
    echo 请以管理员身份运行此脚本！
    :: 如果不是以管理员权限运行，则尝试提升权限
    powershell -Command "Start-Process cmd -ArgumentList '/c %~s0' -Verb RunAs"
    exit /b
)

set "taskname=\Alist\启动alist"
set "taskdir=\Alist"

:: 设置输出脚本的文件名
set "bat_file=%~dp0alist.bat"
:: 设置输出 VBS 脚本的文件名
set "vbs_file=%~dp0start.vbs"

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
set /p bit_type="请输入下载的文件类型(amd64/arm64/386): "

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
echo 开始停止alist.exe
taskkill /F /IM alist.exe
goto :eof

:goDownLoadFile
setlocal enabledelayedexpansion

call :stopTask

:: GitHub API URL
set "url=https://api.github.com/repos/AlistGo/alist/releases/latest"

:: 临时保存 JSON 响应
set "json_file=%~dp0\alist_latest.json"

:: 获取最新发布的 JSON 数据
powershell -Command "(Invoke-WebRequest -Uri %url% -Headers @{'User-Agent'='Mozilla/5.0'}).Content | Out-File -FilePath %json_file% -Encoding utf8"

:: 查找 Windows 64 位 zip 文件的下载链接
for /f "delims=" %%i in ('powershell -Command "(Get-Content %json_file% | ConvertFrom-Json).assets | Where-Object { $_.name -match '.*%alist_bit%\.zip' } | Select-Object -ExpandProperty browser_download_url"') do set "download_url=%%i"

:: 检查是否找到了下载链接
if defined download_url (
    echo 下载链接: %download_url%
    :: 下载文件
    powershell -Command "Invoke-WebRequest -Uri '%download_url%' -OutFile '%~dp0%alist_bit%.zip'"
    echo 下载完成: %alist_bit%.zip
	
	:: 解压到当前目录
    powershell -Command "Expand-Archive -Force -Path '%~dp0%alist_bit%.zip' -DestinationPath '%~dp0'"
    echo 解压完成到当前目录。	

    :: 删除下载的 zip 文件
    del "%~dp0%alist_bit%.zip"
	
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

:: 删除当前目录中的文件夹及其内容
for /d %%d in (%~dp0*) do (
    echo 正在删除文件夹: %%d
    rmdir /s /q "%%d"
)

:: 删除批处理脚本本身
::del /q "%this_bat%"

endlocal

goto :eof

:goCreateFile

:: 输出当前脚本内容到输出文件
echo @echo off > "%bat_file%"
echo :: 设置alist.exe的路径 >> "%bat_file%"
echo set "alist_path=%%~dp0alist.exe" >> "%bat_file%"
echo. >> "%bat_file%"
echo :: 检查alist.exe是否已经在运行 >> "%bat_file%"
echo tasklist /FI "IMAGENAME eq alist.exe" ^| findstr /I "alist.exe" >> "%bat_file%"
echo if not errorlevel 1 ( >> "%bat_file%"
echo     echo alist.exe 已经在运行 >> "%bat_file%"
echo     pause >> "%bat_file%"
echo     exit /b >> "%bat_file%"
echo ) >> "%bat_file%"
echo. >> "%bat_file%"
echo :: 运行alist.exe >> "%bat_file%"
echo "%%alist_path%%" server --force-bin-dir false >> "%bat_file%"
echo. >> "%bat_file%"
echo :: 暂停以查看运行结果 >> "%bat_file%"
echo pause >> "%bat_file%"

echo 成功生成alist.bat

:: 输出 VBS 脚本内容到文件
echo Set objShell = CreateObject("WScript.Shell") > "%vbs_file%"
echo Set objFSO = CreateObject("Scripting.FileSystemObject") >> "%vbs_file%"
echo. >> "%vbs_file%"
echo ' 获取当前 .vbs 文件的路径 >> "%vbs_file%"
echo strCurrentPath = objFSO.GetParentFolderName(WScript.ScriptFullName) >> "%vbs_file%"
echo. >> "%vbs_file%"
echo ' 拼接 alist.bat 文件路径 >> "%vbs_file%"
echo strBatPath = strCurrentPath ^& "\alist.bat" >> "%vbs_file%"
echo. >> "%vbs_file%"
echo ' 运行 alist.bat >> "%vbs_file%"
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
	echo 启动alist
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