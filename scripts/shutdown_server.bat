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

call "%SCRIPT_DIR%config.bat"
echo Loaded configuration for user: %YOUR_NAME%

echo === AWS EC2 QuorumStop ===

echo.

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
        call :UPDATE_CONFIG "!ACTUAL_IP!"
        call "%SCRIPT_DIR%config.bat"
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
        echo - New IP will be assigned on next startup
        echo.
        echo Monitoring shutdown progress...
        
        REM Quick status check
        timeout /t 5 /nobreak >nul
        aws ec2 describe-instances --region %AWS_REGION% --instance-ids %INSTANCE_ID% --query "Reservations[0].Instances[0].State.Name" --output text > "%TEMP%\qs_final_status.tmp" 2>nul
        if not errorlevel 1 (
            set /p FINAL_STATUS=<"%TEMP%\qs_final_status.tmp"
            for /f "tokens=* delims= " %%a in ("!FINAL_STATUS!") do set FINAL_STATUS=%%a
            for /l %%a in (1,1,100) do if "!FINAL_STATUS:~-1!"==" " set FINAL_STATUS=!FINAL_STATUS:~0,-1!
            echo Current status: [!FINAL_STATUS!]
        )
        del "%TEMP%\qs_final_status.tmp" 2>nul
        
    ) else (
        echo ERROR: Failed to stop server via AWS
        echo Please check your AWS credentials and permissions
    )
) else (
    echo.
    echo *** VOTE FAILED - SERVER CONTINUES ***
    echo.
    echo The team has decided to keep the server running.
    echo.
    echo Possible reasons:
    echo - Other team members rejected the shutdown
    echo - Not all team members voted (default = NO)
    echo - Team members are currently working
    echo - SSH connection issues prevented voting
    echo.
    echo Server will continue running and charging.
    echo You can try again later when the team agrees.
)

echo.

echo Democratic shutdown process completed.

pause

exit /b 0

REM ============================================
REM Function to update configuration file
REM ============================================
:UPDATE_CONFIG
if /i "%~1"=="%SERVER_IP%" goto :eof
set NEW_IP_ADDRESS=%~1
for /f "tokens=* delims= " %%a in ("%NEW_IP_ADDRESS%") do set NEW_IP_ADDRESS=%%a
for /l %%a in (1,1,100) do if "%NEW_IP_ADDRESS:~-1%"==" " set NEW_IP_ADDRESS=%NEW_IP_ADDRESS:~0,-1%

set TIMESTAMP=%date% %time%

(
echo @echo off
echo REM ============================================
echo REM AWS EC2 QuorumStop - Configuration
echo REM This file is automatically updated by scripts
echo REM Last updated: %TIMESTAMP%
echo REM ============================================
echo.
echo REM =============================
echo REM AWS Configuration
echo REM =============================
echo set INSTANCE_ID=%INSTANCE_ID%
echo set AWS_REGION=%AWS_REGION%
echo.
echo REM =============================
echo REM Server Connection ^(Dynamic^)
echo REM =============================
echo set SERVER_IP=%NEW_IP_ADDRESS%
echo set KEY_FILE=%KEY_FILE%
echo.
echo REM =============================
echo REM Team IP Mappings
echo REM =============================
echo set DEV1_IP=%DEV1_IP%
echo set DEV2_IP=%DEV2_IP%
echo set DEV3_IP=%DEV3_IP%
echo.
echo REM =============================
echo REM Current User Configuration
echo REM =============================
echo set YOUR_NAME=%YOUR_NAME%
echo set YOUR_IP=%YOUR_IP%
echo.
echo REM =============================
echo REM Server Configuration
echo REM =============================
echo set SERVER_VOTE_SCRIPT=%SERVER_VOTE_SCRIPT%
echo set SERVER_USER=%SERVER_USER%
echo.
echo REM =============================
echo REM Display Configuration
echo REM =============================
echo if "%%1"=="show" ^(
echo     echo ============================================
echo     echo AWS EC2 QuorumStop - Configuration
echo     echo ============================================
echo     echo.
echo     echo AWS Settings:
echo     echo   Instance ID: %%INSTANCE_ID%%
echo     echo   Region: %%AWS_REGION%%
echo     echo.
echo     echo Server Connection:
echo     echo   IP Address: %%SERVER_IP%%
echo     echo   SSH Key: %%KEY_FILE%%
echo     echo   User: %%SERVER_USER%%
echo     echo.
echo     echo Team IP Mappings:
echo     echo   Developer 1: %%DEV1_IP%%
echo     echo   Developer 2: %%DEV2_IP%%
echo     echo   Developer 3: %%DEV3_IP%%
echo     echo.
echo     echo Current User:
echo     echo   Name: %%YOUR_NAME%%
echo     echo   IP: %%YOUR_IP%%
echo     echo.
echo     echo Server Paths:
echo     echo   Vote Script: %%SERVER_VOTE_SCRIPT%%
echo     echo.
echo     echo Configuration Status:
echo     if exist "%%KEY_FILE%%" ^(
echo         echo   SSH Key: ✓ Found
echo     ^) else ^(
echo         echo   SSH Key: ✗ Not found - Update KEY_FILE path
echo     ^)
echo     echo.
echo     echo Last Updated: %%date%% %%time%%
echo     echo ============================================
echo ^)
) > "%SCRIPT_DIR%config_temp.bat"

move /y "%SCRIPT_DIR%config_temp.bat" "%SCRIPT_DIR%config.bat" >nul
goto :eof
