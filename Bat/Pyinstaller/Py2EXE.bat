@echo off
setlocal enabledelayedexpansion

echo ========================================
echo   Python转exe 脚本
echo ========================================

:: 检查 PyInstaller 是否安装
pyinstaller --version >nul 2>&1
if %errorlevel% neq 0 (
    call :askForDownload
    if %errorlevel% neq 0 (
        echo 未安装 PyInstaller，无法继续。
        pause
        exit /b 1
    )
)

:begin
cls
echo ========================================
echo   Python转exe 脚本
echo ========================================

set "build_dir=./output/build"
set "save_dir=./output/save"
set "file_name="

set /p build_dir=请输入构建目录(默认 %build_dir%): 
if "!build_dir!"=="" set "build_dir=./output/build"

set /p save_dir=请输入输出目录(默认 %save_dir%): 
if "!save_dir!"=="" set "save_dir=./output/save"

set /p file_name=请输入要转成exe的py文件全称: 

if not defined file_name (
    echo 错误: 未输入py文件全称。
    timeout /t 2 /nobreak >nul
    goto begin
)

:: 检查文件是否存在
if not exist "!file_name!" (
    echo 错误: 文件 "!file_name!" 不存在。
    timeout /t 2 /nobreak >nul
    goto begin
)

:: 创建输出目录（如果不存在）
if not exist "!save_dir!" mkdir "!save_dir!"
if not exist "!build_dir!" mkdir "!build_dir!"

:: 执行 PyInstaller 转换
echo 正在转换 "!file_name!" 为 exe 文件...
pyinstaller --onefile --noconsole --distpath "!save_dir!" --workpath "!build_dir!" "!file_name!"
if %errorlevel% neq 0 (
    echo 转换失败，请检查文件路径或 PyInstaller 配置。
) else (
    echo 转换成功！可执行文件已保存至 "!save_dir!"。
)

set /p quit_choice=是否退出？(Y/N): 
if /I "!quit_choice!"=="Y" (
    goto :end
) else (
    goto begin
)

:askForDownload
echo 未检测到 PyInstaller。
set /p choice=是否需要安装 PyInstaller？(Y/N): 
if /I "!choice!"=="Y" (
    echo 正在检查 Python 环境...
    python --version >nul 2>&1
    if %errorlevel% neq 0 (
        echo 错误: 未安装 Python，请先安装 Python。
        pause
        exit /b 1
    )
    echo 正在安装 PyInstaller...
    pip install pyinstaller
    if %errorlevel% neq 0 (
        echo PyInstaller 安装失败，请检查网络或 pip 配置。
        pause
        exit /b 1
    ) else (
        echo PyInstaller 安装成功！
        pause
        exit /b 0
    )
) else (
    echo 您选择了不安装 PyInstaller。
    pause
    exit /b 1
)

:end
echo 脚本结束。
pause
exit