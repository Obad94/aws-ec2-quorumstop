@echo off
setlocal enabledelayedexpansion
for %%F in ("%~dp0server_ip.txt") do if exist %%F for /f "usebackq tokens=*" %%L in (%%F) do set "_DYN_IP=%%L"
REM Added /auto flag to allow non-interactive execution
for %%A in (%*) do (
  if /i "%%~A"=="/auto" set "AUTO=1"
  if /i "%%~A"=="-auto" set "AUTO=1"
  if /i "%%~A"=="/debug" set "DEBUG=1"
)
if defined DEBUG echo [debug] Flags parsed AUTO=!AUTO! DEBUG=!DEBUG!

set "AWS_PAGER="
if defined DEBUG echo [debug] Checking AWS CLI availability
aws --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: AWS CLI not installed or not in PATH
    if defined DEBUG echo [debug] Exiting due to missing AWS CLI
    if not defined AUTO pause
    exit /b 1
)

set "SCRIPT_DIR=%~dp0"
if defined DEBUG echo [debug] SCRIPT_DIR=%SCRIPT_DIR%

if not exist "%SCRIPT_DIR%config.bat" (
    echo ERROR: config.bat not found in scripts folder!
    if defined DEBUG echo [debug] Missing config.bat path=%SCRIPT_DIR%config.bat
    if not defined AUTO pause
    exit /b 1
)

call "%SCRIPT_DIR%config.bat" >nul 2>&1
if defined _DYN_IP set "SERVER_IP=%_DYN_IP%"
call "%SCRIPT_DIR%config.bat" show
if defined DEBUG echo [debug] Config loaded INSTANCE_ID=%INSTANCE_ID% AWS_REGION=%AWS_REGION% SERVER_IP=%SERVER_IP%
echo Loaded configuration for user: %YOUR_NAME%
echo === AWS EC2 QuorumStop ===
echo.
if defined DEBUG echo [debug] Starting validation loop
REM Quick validation of required vars
for %%V in (INSTANCE_ID AWS_REGION KEY_FILE SERVER_USER SERVER_VOTE_SCRIPT YOUR_IP) do (
  call if "%%%V%%"=="" echo ERROR: %%V is not set in config.bat & set _CFG_ERR=1
)
if defined DEBUG echo [debug] Validation loop complete _CFG_ERR=!_CFG_ERR!
if defined DEBUG echo [debug] Current directory: %CD%

if defined _CFG_ERR (
  echo Fix the above configuration issues and re-run.
  if defined DEBUG echo [debug] Exiting due to _CFG_ERR
  if not defined AUTO pause
  exit /b 1
)
if not exist "%KEY_FILE%" (
  echo WARNING: SSH key not found: %KEY_FILE%
  if defined DEBUG echo [debug] KEY_FILE missing but continuing
)
if "%SERVER_IP%"=="0.0.0.0" echo (Note: Placeholder SERVER_IP=0.0.0.0 - will refresh from AWS if instance is running)
if not exist "%SCRIPT_DIR%lib_ec2.bat" (
  echo ERROR: Missing helper library lib_ec2.bat
  if defined DEBUG echo [debug] Missing lib_ec2.bat at %SCRIPT_DIR%lib_ec2.bat
  if not defined AUTO pause
  exit /b 1
)
if defined DEBUG echo [debug] Helper library present
echo Checking current server status...
if defined DEBUG echo [debug] About to call lib_ec2 :GET_STATE
call "%SCRIPT_DIR%lib_ec2.bat" :GET_STATE >nul 2>&1
set "_LS_ERR=%errorlevel%"
if defined DEBUG echo [debug] Returned from lib_ec2 STATE=%STATE% err=%_LS_ERR%
if %_LS_ERR% GEQ 1 (
  echo ERROR: Cannot retrieve server status via AWS CLI.
  if defined DEBUG echo [debug] Exiting err from lib_ec2
  if not defined AUTO pause
  exit /b 1
)
set "CURRENT_STATUS=%STATE%"
echo Current server status: [%CURRENT_STATUS%]
if defined DEBUG echo [debug] Branching on CURRENT_STATUS=%CURRENT_STATUS%
echo.

REM Handle server states
if /i "%CURRENT_STATUS%"=="stopped" goto SERVER_STOPPED
if /i "%CURRENT_STATUS%"=="stopping" goto SERVER_STOPPING
if /i "%CURRENT_STATUS%"=="pending" goto SERVER_PENDING
if /i "%CURRENT_STATUS%"=="running" goto SERVER_RUNNING

REM Handle unexpected status
echo WARNING: Server is in unexpected state: [%CURRENT_STATUS%]
echo Cannot proceed with shutdown
echo Please check AWS Console for more details
if defined DEBUG echo [debug] Exiting unexpected state
if not defined AUTO pause
exit /b 1

:SERVER_RUNNING
if defined DEBUG echo [debug] Entered SERVER_RUNNING branch
echo Server is running - proceeding with democratic shutdown
echo.
echo Verifying server IP...
call "%SCRIPT_DIR%lib_ec2.bat" :GET_PUBLIC_IP /quiet >"%TEMP%\_pubip.tmp" 2>nul
set "ACTUAL_IP="
for /f "usebackq tokens=*" %%I in ("%TEMP%\_pubip.tmp") do set "ACTUAL_IP=%%I"
if exist "%TEMP%\_pubip.tmp" del "%TEMP%\_pubip.tmp" >nul 2>&1
if defined DEBUG echo [debug] Retrieved ACTUAL_IP=%ACTUAL_IP%
if not "%ACTUAL_IP%"=="" if not "%ACTUAL_IP%"=="%SERVER_IP%" (
  echo Updating IP from %SERVER_IP% to %ACTUAL_IP%
  set "SERVER_IP=%ACTUAL_IP%"
  call "%SCRIPT_DIR%lib_update_config.bat" :UPDATE_CONFIG "%ACTUAL_IP%" >nul 2>&1
  >"%SCRIPT_DIR%server_ip.txt" (echo %SERVER_IP%)
  echo Configuration updated (runtime SERVER_IP=%SERVER_IP%)
) else (
  echo IP unchanged - not rewriting config
  if defined DEBUG echo [debug] IP unchanged or ACTUAL_IP empty
)
if "%SERVER_IP%"=="" (
  echo ERROR: Server IP empty.
  if not defined AUTO pause
  exit /b 1
)
if /i "%SERVER_IP%"=="None" (
  echo ERROR: Server IP None.
  if not defined AUTO pause
  exit /b 1
)
if "%SERVER_IP%"=="0.0.0.0" (
  echo ERROR: Placeholder IP 0.0.0.0.
  if not defined AUTO pause
  exit /b 1
)
echo Syncing team map to server...
if defined DEBUG echo [debug] Calling sync_team.bat
REM Verbose sync when not AUTO or when DEBUG; quiet only in AUTO non-debug mode
if defined DEBUG (
  call "%SCRIPT_DIR%sync_team.bat"
) else (
  if defined AUTO (
    call "%SCRIPT_DIR%sync_team.bat" >nul 2>&1
  ) else (
    call "%SCRIPT_DIR%sync_team.bat"
  )
)
set "SYNC_ERR=%errorlevel%"
if defined DEBUG echo [debug] Raw SYNC_ERR after call: %SYNC_ERR%
echo [info] SYNC_ERR=%SYNC_ERR%
if "%SYNC_ERR%"=="0" goto SYNC_OK
echo WARNING: Team map sync failed (err %SYNC_ERR%). Falling back to server defaults.
goto AFTER_SYNC
:SYNC_OK
echo Team map sync complete.
:AFTER_SYNC

echo Starting democratic vote process...
echo Using SSH key: %KEY_FILE%
echo Connecting to server: %SERVER_IP%
echo Your IP: %YOUR_IP%
echo.
if defined DEBUG echo [debug] Initiating remote vote via SSH
ssh -o StrictHostKeyChecking=no -o BatchMode=yes -i "%KEY_FILE%" %SERVER_USER%@%SERVER_IP% "AWS_PAGER= AWS_PAGER='' %SERVER_VOTE_SCRIPT% initiate %YOUR_IP%" 
set "VOTE_RESULT=%errorlevel%"
if defined DEBUG echo [debug] SSH returned VOTE_RESULT=%VOTE_RESULT%
if %VOTE_RESULT%==255 (
  echo ERROR: SSH connection failed.
  if not defined AUTO pause
  exit /b 1
)
if %VOTE_RESULT%==0 goto VOTE_PASSED
echo ERROR: Vote did not pass - server will continue running
if not defined AUTO pause
exit /b 1

:VOTE_PASSED
echo *** VOTE PASSED - STOPPING SERVER ***
echo Sending shutdown command to AWS...
aws ec2 stop-instances --region %AWS_REGION% --instance-ids %INSTANCE_ID% >"%TEMP%\qs_stop.out" 2>&1
if errorlevel 1 (
  echo ERROR: Failed to send stop command.
  type "%TEMP%\qs_stop.out" 2>nul
  del "%TEMP%\qs_stop.out" 2>nul
  if not defined AUTO pause
  exit /b 1
)
type "%TEMP%\qs_stop.out" | more +1 >nul 2>&1
if exist "%TEMP%\qs_stop.out" del "%TEMP%\qs_stop.out" 2>nul
echo SUCCESS: Stop command sent.
if not defined AUTO pause
exit /b 0

:SERVER_STOPPED
echo INFO: Server already stopped.
if not defined AUTO pause
exit /b 0
:SERVER_STOPPING
echo INFO: Server stopping (no action taken in auto mode).
if not defined AUTO pause
exit /b 0
:SERVER_PENDING
echo INFO: Server pending (cannot shutdown yet).
if not defined AUTO pause
exit /b 1
