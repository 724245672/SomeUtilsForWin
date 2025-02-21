@echo off
setlocal enabledelayedexpansion

echo ========================================
echo   Pythonתexe �ű�
echo ========================================

:: ��� PyInstaller �Ƿ�װ
pyinstaller --version >nul 2>&1
if %errorlevel% neq 0 (
    call :askForDownload
    if %errorlevel% neq 0 (
        echo δ��װ PyInstaller���޷�������
        pause
        exit /b 1
    )
)

:begin
cls
echo ========================================
echo   Pythonתexe �ű�
echo ========================================

set "build_dir=./output/build"
set "save_dir=./output/save"
set "file_name="

set /p build_dir=�����빹��Ŀ¼(Ĭ�� %build_dir%): 
if "!build_dir!"=="" set "build_dir=./output/build"

set /p save_dir=���������Ŀ¼(Ĭ�� %save_dir%): 
if "!save_dir!"=="" set "save_dir=./output/save"

set /p file_name=������Ҫת��exe��py�ļ�ȫ��: 

if not defined file_name (
    echo ����: δ����py�ļ�ȫ�ơ�
    timeout /t 2 /nobreak >nul
    goto begin
)

:: ����ļ��Ƿ����
if not exist "!file_name!" (
    echo ����: �ļ� "!file_name!" �����ڡ�
    timeout /t 2 /nobreak >nul
    goto begin
)

:: �������Ŀ¼����������ڣ�
if not exist "!save_dir!" mkdir "!save_dir!"
if not exist "!build_dir!" mkdir "!build_dir!"

:: ִ�� PyInstaller ת��
echo ����ת�� "!file_name!" Ϊ exe �ļ�...
pyinstaller --onefile --noconsole --distpath "!save_dir!" --workpath "!build_dir!" "!file_name!"
if %errorlevel% neq 0 (
    echo ת��ʧ�ܣ������ļ�·���� PyInstaller ���á�
) else (
    echo ת���ɹ�����ִ���ļ��ѱ����� "!save_dir!"��
)

set /p quit_choice=�Ƿ��˳���(Y/N): 
if /I "!quit_choice!"=="Y" (
    goto :end
) else (
    goto begin
)

:askForDownload
echo δ��⵽ PyInstaller��
set /p choice=�Ƿ���Ҫ��װ PyInstaller��(Y/N): 
if /I "!choice!"=="Y" (
    echo ���ڼ�� Python ����...
    python --version >nul 2>&1
    if %errorlevel% neq 0 (
        echo ����: δ��װ Python�����Ȱ�װ Python��
        pause
        exit /b 1
    )
    echo ���ڰ�װ PyInstaller...
    pip install pyinstaller
    if %errorlevel% neq 0 (
        echo PyInstaller ��װʧ�ܣ���������� pip ���á�
        pause
        exit /b 1
    ) else (
        echo PyInstaller ��װ�ɹ���
        pause
        exit /b 0
    )
) else (
    echo ��ѡ���˲���װ PyInstaller��
    pause
    exit /b 1
)

:end
echo �ű�������
pause
exit