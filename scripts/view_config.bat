@echo off

REM ============================================
REM AWS EC2 QuorumStop - Configuration Viewer
REM Displays current configuration and system status (enhanced team listing)
REM ============================================

set "SCRIPT_DIR=%~dp0"

echo === AWS EC2 QuorumStop - Configuration Viewer ===

if not exist "%SCRIPT_DIR%config.bat" (
    echo ERROR: scripts\config.bat not found!
    echo Please ensure config.bat is in the scripts directory
    pause
    exit /b 1
)

REM Load variables only (suppress embedded display block)
call "%SCRIPT_DIR%config.bat" >nul 2>&1

REM Now render a clean report (avoids broken dynamic expansion inside config.bat)
echo ============================================
echo AWS EC2 QuorumStop - Configuration
echo ============================================
echo Instance ID: %INSTANCE_ID%
echo Region: %AWS_REGION%
echo Server IP: %SERVER_IP%
echo SSH Key: %KEY_FILE%
echo User: %SERVER_USER%
echo.
echo Team Entries:
if not defined TEAM_COUNT (
  echo   (No teams defined)
) else (
  for /L %%n in (1,1,%TEAM_COUNT%) do (
    call set "_IP=%%DEV%%n_IP%%"
    call set "_NM=%%DEV%%n_NAME%%"
    if defined _IP (
      if not defined _NM set "_NM=Dev%%n"
      REM Escape parentheses inside code block
      call echo     DEV%%n_IP=%%_IP%% ^(%%_NM%%^)
    )
    set "_IP=" & set "_NM="
  )
)

echo.
echo Current User: %YOUR_NAME% (%YOUR_IP%)

echo.
echo Team Detail Table:
if not defined TEAM_COUNT (
  echo   (No TEAM_COUNT set)
) else (
  echo   Index  IP                 Name
  echo   -----  -----------------  -----------------
  for /L %%n in (1,1,%TEAM_COUNT%) do (
    call set "_IP=%%DEV%%n_IP%%"
    call set "_NM=%%DEV%%n_NAME%%"
    if defined _IP (
      if not defined _NM set "_NM=Dev%%n"
      call echo   %%n      %%_IP%%    %%_NM%%
    )
    set "_IP=" & set "_NM="
  )
)

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
