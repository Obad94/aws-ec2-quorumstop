@echo off
setlocal EnableDelayedExpansion
REM ============================================
REM AWS EC2 QuorumStop - Server Startup (Robust Display Version)
REM ============================================

set "AWS_PAGER="
aws --version >nul 2>&1 || (echo ERROR: AWS CLI missing & pause & exit /b 1)
set "SCRIPT_DIR=%~dp0"
if not exist "%SCRIPT_DIR%config.bat" (echo ERROR: scripts\config.bat missing & pause & exit /b 1)
call "%SCRIPT_DIR%config.bat" >nul 2>&1

REM Dynamic config display (no dependence on config.bat show)
echo ============================================
echo AWS EC2 QuorumStop - Configuration Snapshot
echo ============================================
echo Instance ID: %INSTANCE_ID%
echo Region: %AWS_REGION%
echo Server IP: %SERVER_IP%
echo SSH Key: %KEY_FILE%
echo User: %SERVER_USER%
echo.
echo Team Entries:
if not defined TEAM_COUNT (
  echo   (None defined)
) else (
  for /L %%n in (1,1,%TEAM_COUNT%) do (
    call set _IP=%%DEV%%n_IP%%
    call set _NM=%%DEV%%n_NAME%%
    if defined _IP (
      if not defined _NM set _NM=Dev%%n
      REM Properly escape parentheses so they render
      call echo     DEV%%n_IP=%%_IP%% ^(%%_NM%%^)
    )
    set _IP=
    set _NM=
  )
)
echo.
echo Current User: %YOUR_NAME% (%YOUR_IP%)
echo ============================================
echo.
echo === AWS EC2 QuorumStop - Server Startup ===
echo.

for %%V in (INSTANCE_ID AWS_REGION KEY_FILE SERVER_USER) do call if "%%%V%%"=="" echo ERROR: %%V missing in config.bat & set _CFG_ERR=1
if defined _CFG_ERR (echo Fix config values and re-run.& pause & exit /b 1)
if not exist "%KEY_FILE%" echo WARNING: SSH key not found: %KEY_FILE%

echo [1/4] Checking current server status...
echo Instance ID: %INSTANCE_ID% (Region: %AWS_REGION%)
echo Config IP: %SERVER_IP%
if "%SERVER_IP%"=="0.0.0.0" echo (Placeholder IP will refresh once running)
if not exist "%SCRIPT_DIR%lib_ec2.bat" (echo ERROR: lib_ec2.bat missing & pause & exit /b 1)

call "%SCRIPT_DIR%lib_ec2.bat" :GET_STATE >nul 2>&1
if errorlevel 1 (echo ERROR: Unable to retrieve instance state & pause & exit /b 1)
set SERVER_STATUS=%STATE%
echo Current server status: [%SERVER_STATUS%]

if /i "%SERVER_STATUS%"=="stopping" goto :HANDLE_STOPPING
if /i "%SERVER_STATUS%"=="running"  goto :HANDLE_RUNNING
if /i "%SERVER_STATUS%"=="stopped"  goto :START_SERVER
if /i "%SERVER_STATUS%"=="pending"  goto :HANDLE_PENDING

echo WARNING: Unexpected server status: [%SERVER_STATUS%]
pause
exit /b 1

:HANDLE_STOPPING
echo.
echo INFO: Instance stopping - waiting to stop before start.
set STOP_WAIT=0
:STOP_WAIT_LOOP
call "%SCRIPT_DIR%lib_ec2.bat" :GET_STATE >nul 2>&1
set CUR=%STATE%
echo   Attempt %STOP_WAIT% Status: [%CUR%]
if /i "%CUR%"=="stopped" (echo Reached stopped state.& goto :START_SERVER)
set /a STOP_WAIT+=1
if %STOP_WAIT% geq 12 (echo Timeout waiting for stop.& pause & exit /b 1)
timeout /t 10 /nobreak >nul
goto :STOP_WAIT_LOOP

:HANDLE_RUNNING
echo.
echo SUCCESS: Instance already running.
echo [2/4] Resolving current public IP...
set IP_TRY=0
:RUNNING_IP_LOOP
call "%SCRIPT_DIR%lib_ec2.bat" :GET_PUBLIC_IP >nul 2>&1 || (echo ERROR: Failed public IP lookup & pause & exit /b 1)
set CUR_IP=%PUBLIC_IP%
echo   IP lookup attempt %IP_TRY% -> %CUR_IP%
if /i "%CUR_IP%"=="None" (
  if %IP_TRY% lss 4 (set /a IP_TRY+=1 & timeout /t 5 >nul & goto :RUNNING_IP_LOOP) else (echo Public IP not yet assigned; try later.& pause & exit /b 1)
)
if not "%CUR_IP%"=="%SERVER_IP%" (
  echo IP changed from %SERVER_IP% to %CUR_IP% - updating config...
  call "%SCRIPT_DIR%lib_update_config.bat" :UPDATE_CONFIG "%CUR_IP%" >nul 2>&1
  call "%SCRIPT_DIR%config.bat" >nul 2>&1
  echo Config updated.
) else (
  echo IP unchanged.
)
echo.
echo SSH command: ssh -i "%KEY_FILE%" %SERVER_USER%@%CUR_IP%
echo.
echo [3/4] Health hints: view_config / shutdown script available.
echo [4/4] Done.
pause
exit /b 0

:START_SERVER
echo.
echo [2/4] Sending start command...
aws ec2 start-instances --region %AWS_REGION% --instance-ids %INSTANCE_ID% > "%TEMP%\qs_start.out" 2>&1 || (echo ERROR: Start command failed & type "%TEMP%\qs_start.out" & del "%TEMP%\qs_start.out" & pause & exit /b 1)
del "%TEMP%\qs_start.out" 2>nul
echo Start command sent.
echo.
echo [3/4] Waiting for running state...
set W=0
:WAIT_RUN_LOOP
call "%SCRIPT_DIR%lib_ec2.bat" :GET_STATE >nul 2>&1 || (echo ERROR: State poll failed & pause & exit /b 1)
set CUR=%STATE%
echo   Attempt %W% Status: [%CUR%]
if /i "%CUR%"=="running" goto :POST_START_RUNNING
set /a W+=1
if %W% geq 10 (echo Timeout waiting for running state.& pause & exit /b 1)
timeout /t 12 >nul
goto :WAIT_RUN_LOOP

:POST_START_RUNNING
echo Reached running state.
echo.
echo Getting public IP...
set IP_TRY=0
:NEW_IP_LOOP
call "%SCRIPT_DIR%lib_ec2.bat" :GET_PUBLIC_IP >nul 2>&1 || (echo ERROR: Public IP lookup failed & pause & exit /b 1)
set NEW_IP=%PUBLIC_IP%
echo   IP attempt %IP_TRY% -> %NEW_IP%
if /i "%NEW_IP%"=="None" (
  if %IP_TRY% lss 6 (set /a IP_TRY+=1 & timeout /t 5 >nul & goto :NEW_IP_LOOP) else (echo Public IP not assigned yet; try later.& pause & exit /b 1)
)
echo New server IP: %NEW_IP%
if not "%NEW_IP%"=="%SERVER_IP%" (
  echo Updating config with new IP...
  call "%SCRIPT_DIR%lib_update_config.bat" :UPDATE_CONFIG "%NEW_IP%" >nul 2>&1
  call "%SCRIPT_DIR%config.bat" >nul 2>&1
  echo Config updated.
) else echo IP matches config (no update needed).
echo.
echo SSH command: ssh -i "%KEY_FILE%" %SERVER_USER%@%NEW_IP%
echo.
echo [4/4] Server is ready for use.
pause
exit /b 0

:HANDLE_PENDING
echo INFO: Instance pending startup; wait until running then re-run.
pause
exit /b 0
