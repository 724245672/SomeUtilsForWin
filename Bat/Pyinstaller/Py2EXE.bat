@echo off

echo ========================================
echo   Pythonתexe �ű�
echo ========================================

:: ��� pyinstaller �Ƿ�װ
pyinstaller --version >nul
if %errorlevel% neq 0 (
    call askForDownload
)

:askForDownload
:: ѯ���û��Ƿ�ʼ�����ļ��е���Ϣ
setlocal enabledelayedexpansion
set /p choice=�Ƿ���Ҫ��װPyInstaller��(Y/N):
    
    if /I "%choice%"=="Y" (
        echo ���ڰ�װ PyInstaller...
        :: ����Ƿ�װ��Python
        python --version >nul 2>&1
        if %errorlevel% neq 0 (
            echo Python δ��װ�����Ȱ�װ Python��
            pause
            exit /b
        )
        :: ʹ��pip��װpyinstaller
        pip install pyinstaller
        if %errorlevel% neq 0 (
            echo PyInstaller ��װʧ�ܣ���������������ӻ�pip���á�
        ) else (
            echo PyInstaller ��װ�ɹ���
        )
    ) else (
        echo ��ѡ���˲���װ PyInstaller��
    )
	
endlocal
pause
goto begin

:begin
cls

echo ========================================
echo   Pythonתexe �ű�
echo ========================================

set "build_dir=./output/build"
set "save_dir=./output/save"	
set "file_name="

set /p build_dir=�����빹��Ŀ¼(Ĭ�� %build_dir%): 
if "%build_dir%"=="" set build_dir=./output/build

set /p save_dir=���������Ŀ¼(Ĭ�� %save_dir%): 
if "%save_dir%"=="" set save_dir=./output/save

set /p file_name=������Ҫת��exe��py�ļ�ȫ��: 

if not defined file_name (
    echo ����: δ����py�ļ�ȫ��.
	timeout /t 2 /nobreak >nul
	goto begin
)

pyinstaller --onefile --noconsole --distpath %save_dir% --workpath %build_dir% %file_name%

set /p quit_choice=�Ƿ��˳���(Y/N):
 
if /I "%quit_choice%"=="Y" (
		goto end
    ) else (
		goto begin
    )

:end
exit /b