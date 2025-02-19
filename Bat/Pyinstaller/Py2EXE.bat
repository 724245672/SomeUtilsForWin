@echo off

echo ========================================
echo   Python转exe 脚本
echo ========================================

:: 检测 pyinstaller 是否安装
pyinstaller --version >nul
if %errorlevel% neq 0 (
    call askForDownload
)

:askForDownload
:: 询问用户是否开始下载文件中的信息
setlocal enabledelayedexpansion
set /p choice=是否需要安装PyInstaller？(Y/N):
    
    if /I "%choice%"=="Y" (
        echo 正在安装 PyInstaller...
        :: 检查是否安装了Python
        python --version >nul 2>&1
        if %errorlevel% neq 0 (
            echo Python 未安装，请先安装 Python。
            pause
            exit /b
        )
        :: 使用pip安装pyinstaller
        pip install pyinstaller
        if %errorlevel% neq 0 (
            echo PyInstaller 安装失败，请检查你的网络连接或pip设置。
        ) else (
            echo PyInstaller 安装成功。
        )
    ) else (
        echo 您选择了不安装 PyInstaller。
    )
	
endlocal
pause
goto begin

:begin
cls

echo ========================================
echo   Python转exe 脚本
echo ========================================

set "build_dir=./output/build"
set "save_dir=./output/save"	
set "file_name="

set /p build_dir=请输入构建目录(默认 %build_dir%): 
if "%build_dir%"=="" set build_dir=./output/build

set /p save_dir=请输入输出目录(默认 %save_dir%): 
if "%save_dir%"=="" set save_dir=./output/save

set /p file_name=请输入要转成exe的py文件全称: 

if not defined file_name (
    echo 错误: 未输入py文件全称.
	timeout /t 2 /nobreak >nul
	goto begin
)

pyinstaller --onefile --noconsole --distpath %save_dir% --workpath %build_dir% %file_name%

set /p quit_choice=是否退出？(Y/N):
 
if /I "%quit_choice%"=="Y" (
		goto end
    ) else (
		goto begin
    )

:end
exit /b