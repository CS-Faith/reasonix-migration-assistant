@echo off
setlocal

:HEADER
cls
echo ==============================================
echo   Reasonix 配置迁移升级助手 (Migration Assistant)
echo ==============================================
echo.
echo 将旧版 0.53 的对话、MCP、记忆等数据完整迁移到新版 1.X。
echo 迁移后旧对话出现在历史列表中，可随时打开继续交流。
echo 自动备份原有数据，安全可回退。
echo.
echo ==============================================
echo.
echo   [1] 标准升级 - C盘已有旧版0.53，新装了1.5
echo       自动检测 C:\Users\...\.reasonix\
echo       适用：之前用的安装版0.53，现在装了1.5
echo.
echo   [2] 便携版升级 - U盘/同步盘便携版0.53
echo       使用本bat所在目录的 .reasonix\ 数据
echo       !! 先把本bat和ps1文件复制到便携版根目录
echo.
echo   [3] 预览模式 - 只看不写，安全预览
echo.
echo   [Q] 退出
echo.
set /p CHOICE=请选择 [1/2/3/Q]: 

if /i "%CHOICE%"=="Q" goto END
if "%CHOICE%"=="1" goto STANDARD
if "%CHOICE%"=="2" goto PORTABLE
if "%CHOICE%"=="3" goto DRYRUN

echo 无效选择，请重新输入...
timeout /t 2 >nul
goto HEADER

:STANDARD
echo.
echo === 标准升级（C盘检测） ===
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Migrate-053to1X.ps1"
echo.
if %errorlevel% equ 0 (echo ==============================================
    echo   处理完成！启动 1.5 查看效果。
    echo ==============================================
    echo   按任意键关闭...
    pause >nul
    exit
) else (
    echo 处理出错，按任意键关闭...
    pause >nul
    exit
)

:PORTABLE
echo.
echo === 便携版升级 ===
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Migrate-053to1X.ps1" -Portable
echo.
if %errorlevel% equ 0 (echo ==============================================
    echo   处理完成！启动 1.5 查看效果。
    echo ==============================================
    echo   按任意键关闭...
    pause >nul
    exit
) else (
    echo 处理出错，按任意键关闭...
    pause >nul
    exit
)

:DRYRUN
echo.
echo === 预览模式（不写入任何文件） ===
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Migrate-053to1X.ps1" -DryRun
echo.
echo 按任意键关闭...
pause >nul
exit

:END
endlocal
