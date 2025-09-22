@echo off
:: =========================================
:: Basic KeepAliveAudioService Manager
:: Simple and clear output for beginners
:: =========================================

:: Check for administrator privileges
net session >nul 2>&1
if %errorLevel% NEQ 0 (
    echo Administrator rights required. Restarting...
    powershell -Command "Start-Process '%~f0' -Verb runAs"
    exit /b
)

chcp 65001 >nul
set SERVICE=KeepAliveAudioService
set SCRIPT_DIR=%~dp0

:menu
cls
echo =========================================
echo   Managing %SERVICE%
echo =========================================
echo [1] Install service
echo [2] Start service
echo [3] Stop service
echo [4] Remove service
echo [5] Check status
echo [0] Exit
echo =========================================
set /p choice=Select an action:

:: -----------------------------------------
:: Install service
if "%choice%"=="1" (
    python "%SCRIPT_DIR%KeepAliveService.py" install
    echo.
    set /p dummy=Press Enter to return to menu...
    goto menu
)

:: -----------------------------------------
:: Start service
if "%choice%"=="2" (
    python "%SCRIPT_DIR%KeepAliveService.py" start
    echo.
    set /p dummy=Press Enter to return to menu...
    goto menu
)

:: -----------------------------------------
:: Stop service
if "%choice%"=="3" (
    python "%SCRIPT_DIR%KeepAliveService.py" stop
    echo.
    set /p dummy=Press Enter to return to menu...
    goto menu
)

:: -----------------------------------------
:: Remove service
if "%choice%"=="4" (
    python "%SCRIPT_DIR%KeepAliveService.py" remove
    echo.
    set /p dummy=Press Enter to return to menu...
    goto menu
)

:: -----------------------------------------
:: Check service status
:: Enable delayed variable expansion
setlocal enabledelayedexpansion

if "%choice%"=="5" (
    cls
    echo =========================================
    echo   %SERVICE% status
    echo =========================================

    :: Display full standard output
    sc query %SERVICE%

    :: Initialize variables
    set STATE_HUMAN=Unable to determine state
    set WIN32_CODE=?
    set SERVICE_CODE=?

    :: Process each line of sc query output
    for /f "delims=" %%L in ('sc query %SERVICE%') do (
        set line=%%L

        :: Determine state
        echo !line! | findstr /C:"STATE" >nul && (
            echo !line! | findstr /C:"RUNNING" >nul && set STATE_HUMAN=Service is running
            echo !line! | findstr /C:"STOPPED" >nul && set STATE_HUMAN=Service is stopped
            echo !line! | findstr /C:"START_PENDING" >nul && set STATE_HUMAN=Service is starting
            echo !line! | findstr /C:"STOP_PENDING" >nul && set STATE_HUMAN=Service is stopping
            echo !line! | findstr /C:"PAUSED" >nul && set STATE_HUMAN=Service is paused
        )

        :: Get error codes
        echo !line! | findstr /C:"WIN32_EXIT_CODE" >nul && set WIN32_CODE=!line:*: =!
        echo !line! | findstr /C:"SERVICE_EXIT_CODE" >nul && set SERVICE_CODE=!line:*: =!
    )

    :: Build human-readable form
    if "!WIN32_CODE!"=="0 (0x0)" if "!SERVICE_CODE!"=="0 (0x0)" (
        set STATE_HUMAN=!STATE_HUMAN! (no errors)
    ) else (
        set STATE_HUMAN=!STATE_HUMAN! (WIN32_CODE=!WIN32_CODE!, SERVICE_CODE=!SERVICE_CODE!)
    )

    echo.
    echo Readable form: !STATE_HUMAN!
    echo.
    set /p dummy=Press Enter to return to menu...
    goto menu
)

:: -----------------------------------------
:: Exit
if "%choice%"=="0" (
    exit
)

:: -----------------------------------------
:: Invalid input
echo Invalid choice, try again.
timeout /t 2 >nul
goto menu
