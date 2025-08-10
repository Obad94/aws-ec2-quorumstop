@echo off
setlocal EnableDelayedExpansion
REM ============================================
REM AWS EC2 QuorumStop - Server Startup (Minimal IP persist + debug)
REM ============================================
for %%A in (%*) do (
  if /i "%%~A"=="/auto" set "AUTO_MODE=1"
  if /i "%%~A"=="/debug" set "DEBUG=1"
)
if defined DEBUG echo [debug] Flags: AUTO_MODE=%AUTO_MODE% DEBUG=%DEBUG%
set "AWS_PAGER="
aws --version >nul 2>&1 || (echo ERROR: AWS CLI missing & if not defined AUTO_MODE pause & exit /b 1)
REM Replace original SCRIPT_DIR assignment with robust fallback
REM ORIGINAL: set "SCRIPT_DIR=%~dp0"
for %%Z in ("%~dp0") do set "_RAW_DIR=%%~fZ"
if exist "%CD%\scripts\config.bat" (
  set "SCRIPT_DIR=%CD%\scripts\"
) else (
  set "SCRIPT_DIR=%_RAW_DIR%"
)
if /i "%SCRIPT_DIR%"=="C:\" if exist "%CD%\scripts\config.bat" set "SCRIPT_DIR=%CD%\scripts\"
if defined DEBUG echo [debug] Resolved SCRIPT_DIR=%SCRIPT_DIR%
if not exist "%SCRIPT_DIR%config.bat" (echo ERROR: scripts\config.bat missing & if not defined AUTO_MODE pause & exit /b 1)
call "%SCRIPT_DIR%config.bat" >nul 2>&1
if defined DEBUG call "%SCRIPT_DIR%config.bat" show

for %%V in (INSTANCE_ID AWS_REGION KEY_FILE SERVER_USER) do call if "%%%V%%"=="" echo ERROR: %%V missing in config.bat & set _CFG_ERR=1
if defined _CFG_ERR (echo Fix config values and re-run.& if not defined AUTO_MODE pause & exit /b 1)

if defined DEBUG echo [debug] Querying initial state...
if defined DEBUG (
  call "%SCRIPT_DIR%lib_ec2.bat" :GET_STATE
) else (
  call "%SCRIPT_DIR%lib_ec2.bat" :GET_STATE >nul 2>&1
)
set SERVER_STATUS=%STATE%
if /i "%SERVER_STATUS%"=="running" goto RUNNING
if /i "%SERVER_STATUS%"=="stopped" goto START_FROM_STOP
if /i "%SERVER_STATUS%"=="stopping" (echo Instance stopping; retry later.& if not defined AUTO_MODE pause & exit /b 1)
if /i "%SERVER_STATUS%"=="pending" (echo Instance pending; retry later.& if not defined AUTO_MODE pause & exit /b 1)
echo Unexpected state %SERVER_STATUS% & if not defined AUTO_MODE pause & exit /b 1

:RUNNING
echo Instance already running. Resolving current public IP...
set IP_TRY=0
:RUN_IP
if defined DEBUG echo [debug] Attempt !IP_TRY! resolve public IP
if defined DEBUG (
  call "%SCRIPT_DIR%lib_ec2.bat" :GET_PUBLIC_IP
) else (
  call "%SCRIPT_DIR%lib_ec2.bat" :GET_PUBLIC_IP >nul 2>&1
)
set CUR_IP=%PUBLIC_IP%
echo   Attempt !IP_TRY! -> %CUR_IP%
if /i "%CUR_IP%"=="None" (
  if !IP_TRY! lss 4 (set /a IP_TRY+=1 & timeout /t 5 >nul & goto RUN_IP) else (echo Public IP not assigned yet.& if not defined AUTO_MODE pause & exit /b 1)
)
if not "%CUR_IP%"=="%SERVER_IP%" (
  echo Updating config SERVER_IP %SERVER_IP% -> %CUR_IP%
  if defined DEBUG echo [debug] Calling updater
  if defined DEBUG (
    call "%SCRIPT_DIR%lib_update_config.bat" :SET_IP "%CUR_IP%" /debug
  ) else (
    call "%SCRIPT_DIR%lib_update_config.bat" :SET_IP "%CUR_IP%" /quiet >nul 2>&1
  )
  set "_UPD_ERR=%errorlevel%"
  if not "!_UPD_ERR!"=="0" (
    echo [start_server] ERROR: IP update failed code !_UPD_ERR!
    if "!_UPD_ERR!"=="5" echo [start_server] Cause: SERVER_IP line not found in config.bat
    if not defined AUTO_MODE pause
    exit /b 2
  )
  set "_CHK_IP="
  for /f "tokens=1,* delims==" %%A in ('findstr /i /c:"set SERVER_IP=" "%SCRIPT_DIR%config.bat"') do if /i "%%A"=="set SERVER_IP" set "_CHK_IP=%%B"
  if defined DEBUG echo [debug] Post-write line shows IP: !_CHK_IP!
  call "%SCRIPT_DIR%config.bat" show | find "Server IP:" 2>nul
  if defined _CHK_IP (
    for /f "tokens=*" %%Z in ("!_CHK_IP!") do set "_CHK_IP=%%Z"
    if /i not "!_CHK_IP!"=="%CUR_IP%" echo [start_server] WARNING: Mismatch after update expected %CUR_IP% got !_CHK_IP!
  ) else echo [start_server] WARNING: Could not read back SERVER_IP line.
) else echo IP unchanged (%SERVER_IP%).
if not defined AUTO_MODE pause
exit /b 0

:START_FROM_STOP
echo Starting stopped instance...
aws ec2 start-instances --region %AWS_REGION% --instance-ids %INSTANCE_ID% >"%TEMP%\qs_start.out" 2>&1 || (echo ERROR: Start failed & type "%TEMP%\qs_start.out" & del "%TEMP%\qs_start.out" & if not defined AUTO_MODE pause & exit /b 1)
del "%TEMP%\qs_start.out" 2>nul
echo Waiting for running state...
set W=0
:WLOOP
if defined DEBUG (
  call "%SCRIPT_DIR%lib_ec2.bat" :GET_STATE
) else (
  call "%SCRIPT_DIR%lib_ec2.bat" :GET_STATE >nul 2>&1
)
if /i "%STATE%"=="running" goto GOT_RUN
set /a W+=1
if %W% geq 12 (echo Timeout waiting for running state.& if not defined AUTO_MODE pause & exit /b 1)
timeout /t 10 >nul
goto WLOOP
:GOT_RUN
echo Running. Resolving IP...
set IP_TRY=0
:NEW_IP
if defined DEBUG (
  call "%SCRIPT_DIR%lib_ec2.bat" :GET_PUBLIC_IP
) else (
  call "%SCRIPT_DIR%lib_ec2.bat" :GET_PUBLIC_IP >nul 2>&1
)
set NEW_IP=%PUBLIC_IP%
echo   Attempt !IP_TRY! -> %NEW_IP%
if /i "%NEW_IP%"=="None" (
  if !IP_TRY! lss 6 (set /a IP_TRY+=1 & timeout /t 5 >nul & goto NEW_IP) else (echo Public IP not assigned yet.& if not defined AUTO_MODE pause & exit /b 1)
)
echo New IP: %NEW_IP%
if not "%NEW_IP%"=="%SERVER_IP%" (
  echo Updating config SERVER_IP %SERVER_IP% -> %NEW_IP%
  if defined DEBUG echo [debug] Calling updater
  if defined DEBUG (
    call "%SCRIPT_DIR%lib_update_config.bat" :SET_IP "%NEW_IP%" /debug
  ) else (
    call "%SCRIPT_DIR%lib_update_config.bat" :SET_IP "%NEW_IP%" /quiet >nul 2>&1
  )
  set "_UPD_ERR=%errorlevel%"
  if not "!_UPD_ERR!"=="0" (
    echo [start_server] ERROR: IP update failed code !_UPD_ERR!
    if "!_UPD_ERR!"=="5" echo [start_server] Cause: SERVER_IP line not found in config.bat
    if not defined AUTO_MODE pause
    exit /b 2
  )
  set "_CHK_IP="
  for /f "tokens=1,* delims==" %%A in ('findstr /i /c:"set SERVER_IP=" "%SCRIPT_DIR%config.bat"') do if /i "%%A"=="set SERVER_IP" set "_CHK_IP=%%B"
  if defined DEBUG echo [debug] Post-write line shows IP: !_CHK_IP!
  call "%SCRIPT_DIR%config.bat" show | find "Server IP:" 2>nul
  if defined _CHK_IP (
    for /f "tokens=*" %%Z in ("!_CHK_IP!") do set "_CHK_IP=%%Z"
    if /i not "!_CHK_IP!"=="%NEW_IP%" echo [start_server] WARNING: Mismatch after update expected %NEW_IP% got !_CHK_IP!
  ) else echo [start_server] WARNING: Could not read back SERVER_IP line.
) else echo IP already matches config.
if not defined AUTO_MODE pause
exit /b 0
