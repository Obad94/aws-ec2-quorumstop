@echo off

REM ============================================
REM AWS EC2 QuorumStop - Configuration Viewer
REM Displays current configuration and system status
REM ============================================

REM Resolve script directory so paths work from anywhere
set "SCRIPT_DIR=%~dp0"

echo === AWS EC2 QuorumStop - Configuration Viewer ===
echo.

if not exist "%SCRIPT_DIR%config.bat" (
    echo ERROR: scripts\config.bat not found!
    echo Please ensure config.bat is in the scripts directory
    pause
    exit /b 1
)

call "%SCRIPT_DIR%config.bat" show

echo.
echo Additional Information:
echo   Config file: %SCRIPT_DIR%config.bat
echo   Last modified: 
for %%i in ("%SCRIPT_DIR%config.bat") do echo     %%~ti

echo.
echo Available commands:
echo   scripts\view_config.bat       - Show current configuration
echo   scripts\start_server.bat      - Start server and update IP
echo   scripts\shutdown_server.bat   - Democratic shutdown with team vote
echo   scripts\test_aws.bat          - Test AWS CLI connectivity

echo.
pause
