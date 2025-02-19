@echo off

echo ========================================
echo   N_m3u8DL-RE ���ؽű�
echo ========================================

:: ����Ĭ����ʱĿ¼�ͱ���Ŀ¼
set "tmp_dir="
set "save_dir="	
set tmp_dir=D:/
set save_dir=E:/

set /p tmp_dir=��������ʱ�ļ�Ŀ¼(Ĭ�� %tmp_dir%): 
if "%tmp_dir%"=="" set tmp_dir=D:/

set /p save_dir=�����뱣���ļ�Ŀ¼(Ĭ�� %save_dir%): 
if "%save_dir%"=="" set save_dir=E:/

if exist finish.txt (
	del finish.txt
)

:begin
cls
::������������,��Ҫ����һ��
set "url="
set "savename="	

if exist m3u.txt (
	:: չʾ m3u.txt �ļ�����
	echo ��ǰ m3u.txt �ļ�����������:
	echo.
	echo ----------------------------------------
	type m3u.txt
	echo ----------------------------------------
	echo.
)

:: �û������µ�������Ϣ�����浽�ļ�
set /p url=������m3u8����: 

if not defined url (
    call :askForDownload
)

set /p savename=�����뱣���ļ���: 

if not defined savename (
    echo ����: δ���뱣���ļ���.
	timeout /t 2 /nobreak >nul
	goto begin
)

:: ����Ҫ���������
set command=N_m3u8DL-RE.exe "%url%" --save-name "%savename%" --check-segments-count false --no-log --tmp-dir "%tmp_dir%" --save-dir "%save_dir%"
  
:: URL�ظ����
findstr /c:"%url%" m3u.txt >nul
if %errorlevel%==0 (
    echo ��URL�Ѿ����ڣ��������档
	timeout /t 2 /nobreak >nul
    goto begin
)

:: ���浽 m3u.txt
echo %command% >> m3u.txt

echo ----------------------------------------

:: ѯ���û��Ƿ�ʼ��������������Ϣ
call :askForDownload

echo ----------------------------------------
goto begin

:end
echo ���˳��ű���
pause
exit /b

:askForDownload
:: ѯ���û��Ƿ�ʼ�����ļ��е���Ϣ
setlocal enabledelayedexpansion
set /p download=�Ƿ�ʼ�����ļ��е���Ϣ����Y/N, Ĭ��ΪN��: 
if "%download%"=="" set download=N

if /i "%download%"=="Y" (
    if not exist N_m3u8DL-RE.exe (
        echo ����: δ�ҵ� N_m3u8DL-RE.exe �ļ�.
        pause
        exit /b
    )

    :: ����������Ϣ
    call :processDownloads
)
endlocal
goto :eof

:processDownloads
:: ���� m3u.txt ������ÿһ��
if exist m3u.txt (
    for /f "usebackq tokens=*" %%a in (m3u.txt) do (
        echo ��������...
        %%a
        :: ִ�������������״̬
        if %errorlevel%==0 (
            echo �������: %%a
        ) else (
            echo ����ʧ��: %%a
        )
    )

    :: ������ɺ��������ļ�
    echo ��������������ɣ������� m3u.txt Ϊ finish.txt...	
    ren m3u.txt finish.txt
    echo ��������ɣ�
) else (
    echo û���ҵ� m3u.txt �ļ�.
)

goto :eof
