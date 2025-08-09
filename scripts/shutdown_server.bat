@echo off
setlocal enabledelayedexpansion

REM ============================================
REM AWS EC2 QuorumStop - Main Script
REM Implements team voting for server shutdown
REM ============================================

REM Disable AWS CLI pager and verify CLI is available
set "AWS_PAGER="
aws --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: AWS CLI not installed or not in PATH
    echo See https://aws.amazon.com/cli/ and run scripts\test_aws.bat to diagnose
    pause
    exit /b 1
)

REM Resolve script directory so paths work from anywhere
set "SCRIPT_DIR=%~dp0"

REM Load configuration
if not exist "%SCRIPT_DIR%config.bat" (
    echo ERROR: config.bat not found in scripts folder!
    echo Expected at: %SCRIPT_DIR%config.bat
    pause
    exit /b 1
)

call "%SCRIPT_DIR%config.bat" >nul 2>&1
call "%SCRIPT_DIR%config.bat" show

echo Loaded configuration for user: %YOUR_NAME%

echo === AWS EC2 QuorumStop ===

echo.

REM If placeholder IP still present, warn early (will be re-fetched later if running)
if "%SERVER_IP%"=="0.0.0.0" echo (Note: Placeholder SERVER_IP=0.0.0.0 - will refresh from AWS if instance is running)

REM Check current server status
echo Checking current server status...
aws ec2 describe-instances --region %AWS_REGION% --instance-ids %INSTANCE_ID% --query "Reservations[0].Instances[0].State.Name" --output text > "%TEMP%\qs_server_status.tmp" 2>nul
if errorlevel 1 (
    echo ERROR: Cannot check server status via AWS
    echo Please verify your AWS credentials and instance ID
    del "%TEMP%\qs_server_status.tmp" 2>nul
    pause
    exit /b 1
)

set /p CURRENT_STATUS=<"%TEMP%\qs_server_status.tmp"
del "%TEMP%\qs_server_status.tmp"

REM Trim spaces from status
for /f "tokens=* delims= " %%a in ("%CURRENT_STATUS%") do set CURRENT_STATUS=%%a
for /l %%a in (1,1,100) do if "%CURRENT_STATUS:~-1%"==" " set CURRENT_STATUS=%CURRENT_STATUS:~0,-1%

echo Current server status: [%CURRENT_STATUS%]
echo.

REM Handle server states
if "%CURRENT_STATUS%"=="stopped" goto :SERVER_STOPPED
if "%CURRENT_STATUS%"=="stopping" goto :SERVER_STOPPING
if "%CURRENT_STATUS%"=="pending" goto :SERVER_PENDING
if "%CURRENT_STATUS%"=="running" goto :SERVER_RUNNING

REM Handle unexpected status
echo WARNING: Server is in unexpected state: [%CURRENT_STATUS%]
echo Cannot proceed with shutdown
echo Please check AWS Console for more details
pause
exit /b 1

:SERVER_STOPPED
echo INFO: Server is already stopped!
echo No shutdown needed - server is not running.
echo.
echo Cost savings: Server is not charging while stopped.
echo Use scripts\start_server.bat when you need to work again.
pause
exit /b 0

:SERVER_STOPPING
echo INFO: Server is already stopping!
echo Waiting for shutdown to complete...
echo.

set WAIT_COUNT=0
:WAIT_LOOP
echo Checking shutdown progress... (attempt %WAIT_COUNT%)
timeout /t 10 /nobreak >nul
set /a WAIT_COUNT+=1

aws ec2 describe-instances --region %AWS_REGION% --instance-ids %INSTANCE_ID% --query "Reservations[0].Instances[0].State.Name" --output text > "%TEMP%\qs_wait_status.tmp" 2>nul
if errorlevel 1 (
    echo ERROR: Cannot check status during wait
    del "%TEMP%\qs_wait_status.tmp" 2>nul
    pause
    exit /b 1
)

set /p WAIT_STATUS=<"%TEMP%\qs_wait_status.tmp"
del "%TEMP%\qs_wait_status.tmp"

for /f "tokens=* delims= " %%a in ("%WAIT_STATUS%") do set WAIT_STATUS=%%a
for /l %%a in (1,1,100) do if "%WAIT_STATUS:~-1%"==" " set WAIT_STATUS=%WAIT_STATUS:~0,-1%

echo Status: [%WAIT_STATUS%]

if "%WAIT_STATUS%"=="stopped" (
    echo.
    echo SUCCESS: Server shutdown completed!
    echo Server is now stopped and not charging.
    pause
    exit /b 0
)

if "%WAIT_STATUS%"=="stopping" (
    if %WAIT_COUNT% lss 12 goto :WAIT_LOOP
    echo.
    echo Server is taking longer than expected to stop
    echo You can close this window - shutdown will complete in background
    pause
    exit /b 0
)

echo.
echo WARNING: Unexpected status change to [%WAIT_STATUS%]
echo Please check AWS Console
pause
exit /b 1

:SERVER_PENDING
echo INFO: Server is currently starting up
echo Cannot shutdown while server is starting
echo Please wait for server to reach running state first
echo.
echo You can:
echo 1. Wait for server to finish starting, then run this script again
echo 2. Check server status in AWS Console
pause
exit /b 1

:SERVER_RUNNING

echo Server is running - proceeding with democratic shutdown

echo.

REM Update IP if needed
echo Verifying server IP...
aws ec2 describe-instances --region %AWS_REGION% --instance-ids %INSTANCE_ID% --query "Reservations[0].Instances[0].PublicIpAddress" --output text > "%TEMP%\qs_current_ip.tmp" 2>nul
if not errorlevel 1 (
    set /p ACTUAL_IP=<"%TEMP%\qs_current_ip.tmp"
    for /f "tokens=* delims= " %%a in ("!ACTUAL_IP!") do set ACTUAL_IP=%%a
    for /l %%a in (1,1,100) do if "!ACTUAL_IP:~-1!"==" " set ACTUAL_IP=!ACTUAL_IP:~0,-1!
    
    if not "!ACTUAL_IP!"=="%SERVER_IP%" (
        echo Updating IP from %SERVER_IP% to !ACTUAL_IP!
        call "%SCRIPT_DIR%lib_update_config.bat" :UPDATE_CONFIG "!ACTUAL_IP!"
        call "%SCRIPT_DIR%config.bat" >nul 2>&1
        echo Configuration updated
    ) else (
        echo IP unchanged - not rewriting config
    )
)
del "%TEMP%\qs_current_ip.tmp" 2>nul

REM Guard: ensure we have a usable server IP before SSH
if "%SERVER_IP%"=="" (
    echo ERROR: Server IP is empty. Cannot initiate SSH for voting.
    echo Run scripts\start_server.bat to refresh IP, then try again.
    pause
    exit /b 1
)
if /i "%SERVER_IP%"=="None" (
    echo ERROR: Server IP not yet assigned. Cannot initiate SSH for voting.
    echo Wait a few seconds and run scripts\start_server.bat again.
    pause
    exit /b 1
)
if "%SERVER_IP%"=="0.0.0.0" (
    echo ERROR: Placeholder IP (0.0.0.0) still set after refresh attempt.
    echo Run scripts\start_server.bat or tools\sync-ip.bat to obtain the real IP.
    pause
    exit /b 1
)

REM Conduct democratic vote

echo Starting democratic vote process...

REM Ensure SSH key exists before connecting
if not exist "%KEY_FILE%" (
    echo ERROR: SSH key not found: %KEY_FILE%
    echo Update KEY_FILE in scripts\config.bat or place the key at this path.
    pause
    exit /b 1
)

echo Connecting to server: %SERVER_IP%

echo Your IP: %YOUR_IP%

echo.

ssh -o StrictHostKeyChecking=no -o BatchMode=yes -i "%KEY_FILE%" %SERVER_USER%@%SERVER_IP% "%SERVER_VOTE_SCRIPT% initiate %YOUR_IP%"
set VOTE_RESULT=%errorlevel%

REM Detect SSH transport/auth failures (commonly 255)
if %VOTE_RESULT%==255 (
    echo.
    echo ERROR: SSH connection failed while initiating the vote.
    echo Possible causes:
    echo  - Wrong KEY_FILE or passphrase-protected key (BatchMode=yes)
    echo  - Server IP or user incorrect (current user: %SERVER_USER%)
    echo  - Security Group blocks your IP on port 22
    echo  - Server not fully ready for SSH
    echo.
    echo Tips:
    echo  - Test: ssh -v -i "%KEY_FILE%" %SERVER_USER%@%SERVER_IP%
    echo  - If key has a passphrase, use an unencrypted key for automation
    pause
    exit /b 1
)

if %VOTE_RESULT%==0 (
    echo.
    echo *** VOTE PASSED - STOPPING SERVER ***
    echo.
    echo The team has approved the shutdown request.
    echo Sending shutdown command to AWS...
    
    aws ec2 stop-instances --region %AWS_REGION% --instance-ids %INSTANCE_ID%
    if %errorlevel%==0 (
        echo SUCCESS: Server stop command sent!
        echo.
        echo Cost Savings Information:
        echo - Server will stop charging once fully stopped
        echo - Use scripts\start_server.bat when ready to work again  
        echo - New IP will be assigned on next start
    ) else (
        echo ERROR: Failed to send stop command to AWS
        echo Please check your AWS permissions and instance ID
        pause
        exit /b 1
    )

    echo.
    echo You can monitor server status in AWS Console:
    echo https://%AWS_REGION%.console.aws.amazon.com/ec2/v2/home?region=%AWS_REGION#Instances:instanceId=%INSTANCE_ID%
    pause
    exit /b 0
)

echo.
echo ERROR: Vote did not pass - server will continue running
echo Please check with your team for the next steps
pause
exit /b 1
