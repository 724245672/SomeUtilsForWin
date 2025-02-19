@echo off

echo ========================================
echo   N_m3u8DL-RE 下载脚本
echo ========================================

:: 设置默认临时目录和保存目录
set "tmp_dir="
set "save_dir="	
set tmp_dir=D:/
set save_dir=E:/

set /p tmp_dir=请输入临时文件目录(默认 %tmp_dir%): 
if "%tmp_dir%"=="" set tmp_dir=D:/

set /p save_dir=请输入保存文件目录(默认 %save_dir%): 
if "%save_dir%"=="" set save_dir=E:/

if exist finish.txt (
	del finish.txt
)

:begin
cls
::这里跳过来后,需要重置一下
set "url="
set "savename="	

if exist m3u.txt (
	:: 展示 m3u.txt 文件内容
	echo 当前 m3u.txt 文件的内容如下:
	echo.
	echo ----------------------------------------
	type m3u.txt
	echo ----------------------------------------
	echo.
)

:: 用户输入新的下载信息并保存到文件
set /p url=请输入m3u8链接: 

if not defined url (
    call :askForDownload
)

set /p savename=请输入保存文件名: 

if not defined savename (
    echo 错误: 未输入保存文件名.
	timeout /t 2 /nobreak >nul
	goto begin
)

:: 创建要保存的命令
set command=N_m3u8DL-RE.exe "%url%" --save-name "%savename%" --check-segments-count false --no-log --tmp-dir "%tmp_dir%" --save-dir "%save_dir%"
  
:: URL重复检查
findstr /c:"%url%" m3u.txt >nul
if %errorlevel%==0 (
    echo 该URL已经存在，跳过保存。
	timeout /t 2 /nobreak >nul
    goto begin
)

:: 保存到 m3u.txt
echo %command% >> m3u.txt

echo ----------------------------------------

:: 询问用户是否开始下载现有下载信息
call :askForDownload

echo ----------------------------------------
goto begin

:end
echo 已退出脚本。
pause
exit /b

:askForDownload
:: 询问用户是否开始下载文件中的信息
setlocal enabledelayedexpansion
set /p download=是否开始下载文件中的信息？（Y/N, 默认为N）: 
if "%download%"=="" set download=N

if /i "%download%"=="Y" (
    if not exist N_m3u8DL-RE.exe (
        echo 错误: 未找到 N_m3u8DL-RE.exe 文件.
        pause
        exit /b
    )

    :: 处理下载信息
    call :processDownloads
)
endlocal
goto :eof

:processDownloads
:: 处理 m3u.txt 并下载每一项
if exist m3u.txt (
    for /f "usebackq tokens=*" %%a in (m3u.txt) do (
        echo 正在下载...
        %%a
        :: 执行命令后检查下载状态
        if %errorlevel%==0 (
            echo 下载完成: %%a
        ) else (
            echo 下载失败: %%a
        )
    )

    :: 下载完成后重命名文件
    echo 所有下载任务完成，重命名 m3u.txt 为 finish.txt...	
    ren m3u.txt finish.txt
    echo 重命名完成！
) else (
    echo 没有找到 m3u.txt 文件.
)

goto :eof
