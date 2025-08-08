@echo off

REM ============================================
REM EC2 Democratic Shutdown - Configuration Viewer
REM Displays current configuration and system status
REM ============================================

echo === EC2 Democratic Shutdown - Configuration Viewer ===
echo.

if not exist config.bat (
    echo ERROR: config.bat not found!
    echo Please ensure config.bat is in the same directory
    pause
    exit /b 1
)

call config.bat show

echo.
echo Additional Information:
echo   Config file: config.bat
echo   Last modified: 
for %%i in (config.bat) do echo     %%~ti
echo.

echo Available commands:
echo   view_config.bat       - Show current configuration
echo   start_server.bat      - Start server and update IP
echo   shutdown_server.bat   - Democratic shutdown with team vote
echo   test_aws.bat          - Test AWS CLI connectivity
echo.

pause