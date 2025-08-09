@echo off
setlocal enabledelayedexpansion

REM ============================================
REM AWS EC2 QuorumStop - Server Startup (Enhanced)
REM Adds shared library usage, validation, and clearer errors
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

echo === AWS EC2 QuorumStop - Server Startup ===

echo.

REM Basic validation of critical vars
for %%V in (INSTANCE_ID AWS_REGION KEY_FILE SERVER_USER) do (
  call if "%%%V%%"=="" echo ERROR: %%V is not set in config.bat & set _CFG_ERR=1
)
if defined _CFG_ERR (
  echo Fix the above configuration issues and re-run.
  pause
  exit /b 1
)
if not exist "%KEY_FILE%" (
  echo WARNING: SSH key not found at: %KEY_FILE%
  echo You will not be able to SSH until this path is corrected.
)

echo [1/4] Checking current server status...

echo Instance ID: %INSTANCE_ID% (Region: %AWS_REGION%)
echo Current config IP: %SERVER_IP%
if "%SERVER_IP%"=="0.0.0.0" echo (Note: Placeholder SERVER_IP=0.0.0.0 - will get real IP when instance runs)

REM Use shared library for state retrieval
if not exist "%SCRIPT_DIR%lib_ec2.bat" (
  echo ERROR: Missing helper library lib_ec2.bat (should be in scripts folder)
  pause
  exit /b 1
)
call "%SCRIPT_DIR%lib_ec2.bat" :GET_STATE
if errorlevel 1 (
  echo ERROR: Could not retrieve instance state via AWS CLI.
  pause
  exit /b 1
)
set SERVER_STATUS=%STATE%

echo Current server status: [%SERVER_STATUS%]

REM Handle stopping state FIRST (before any other checks)
if /i "%SERVER_STATUS%"=="stopping" (
    echo.
    echo INFO: Server is currently stopping
    echo Waiting for it to reach stopped state, then will start it...
    set STOP_WAIT_COUNT=0
    :STOP_WAIT_LOOP
    echo Waiting for stop to complete... (attempt %STOP_WAIT_COUNT%)
    timeout /t 10 /nobreak >nul
    set /a STOP_WAIT_COUNT+=1
    call "%SCRIPT_DIR%lib_ec2.bat" :GET_STATE >nul 2>&1
    set STOP_STATUS=%STATE%
    echo Status: [%STOP_STATUS%]
    if /i "%STOP_STATUS%"=="stopped" (
        echo.
        echo SUCCESS: Server is now stopped. Starting it now...
        goto :START_SERVER
    )
    if %STOP_WAIT_COUNT% geq 12 (
        echo.
        echo WARNING: Server taking too long to stop
        echo Current status: [%STOP_STATUS%]
        pause
        exit /b 1
    )
    goto :STOP_WAIT_LOOP
)

REM Handle running state
if /i "%SERVER_STATUS%"=="running" (
    echo.
    echo SUCCESS: Server is already running!
    echo [2/4] Getting current IP address...
    set IP_TRIES=0
    :GET_RUNNING_IP
    call "%SCRIPT_DIR%lib_ec2.bat" :GET_PUBLIC_IP >nul 2>&1
    if errorlevel 1 (
       echo ERROR: Failed to retrieve public IP.
       if !IP_TRIES! lss 3 (
         set /a IP_TRIES+=1
         echo Retrying (!IP_TRIES!/3)...
         timeout /t 5 /nobreak >nul
         goto :GET_RUNNING_IP
       ) else (
         echo Aborting after multiple failures.
         pause
         exit /b 1
       )
    )
    set CURRENT_IP=%PUBLIC_IP%
    if /i "%CURRENT_IP%"=="None" (
        if !IP_TRIES! lss 4 (
            set /a IP_TRIES+=1
            echo IP not assigned yet. Retrying (!IP_TRIES!/4)...
            timeout /t 5 /nobreak >nul
            goto :GET_RUNNING_IP
        ) else (
            echo Server is running but no public IP assigned yet
            echo Associate an Elastic IP or ensure auto-assign public IP is enabled.
        )
    ) else (
        echo Server IP: %CURRENT_IP%
        echo SSH command: ssh -i "%KEY_FILE%" %SERVER_USER%@%CURRENT_IP%
        if /i "%CURRENT_IP%"=="%SERVER_IP%" (
            if "%CURRENT_IP%"=="0.0.0.0" (
                echo WARNING: Config still holds placeholder IP; try tools\sync-ip.bat or restart instance if needed.
            ) else (
                echo IP unchanged - skipping config rewrite
            )
        ) else (
            echo.
            echo IP has changed from %SERVER_IP% to %CURRENT_IP%
            echo Updating configuration...
            call "%SCRIPT_DIR%lib_update_config.bat" :UPDATE_CONFIG "%CURRENT_IP%"
            call "%SCRIPT_DIR%config.bat" >nul 2>&1
            echo Configuration updated successfully
        )
    )
    echo.
    echo Server is ready for use!
    echo [3/4] Quick health hints:
    echo   - Run scripts\view_config.bat to verify settings
    echo   - Run scripts\shutdown_server.bat to initiate democratic shutdown
    echo [4/4] Done.
    pause
    exit /b 0
)

REM Handle stopped state
if /i "%SERVER_STATUS%"=="stopped" (
    :START_SERVER
    echo.
    echo [2/4] Server is stopped. Starting now...
    aws ec2 start-instances --region %AWS_REGION% --instance-ids %INSTANCE_ID% > "%TEMP%\qs_start_output.tmp"
    if errorlevel 1 (
        echo ERROR: Failed to send start command
        if exist "%TEMP%\qs_start_output.tmp" (
            echo AWS Output:
            type "%TEMP%\qs_start_output.tmp"
        )
        del "%TEMP%\qs_start_output.tmp" 2>nul
        pause
        exit /b 1
    )
    echo SUCCESS: Start command sent to AWS
    del "%TEMP%\qs_start_output.tmp" 2>nul
    echo.
    echo [3/4] Waiting for server to become running...
    echo This usually takes 30-60 seconds...
    set WAIT_COUNT=0
    :WAIT_LOOP
    echo Checking status... (attempt %WAIT_COUNT%)
    timeout /t 12 /nobreak >nul
    set /a WAIT_COUNT+=1
    call "%SCRIPT_DIR%lib_ec2.bat" :GET_STATE >nul 2>&1
    set CURRENT_STATUS=%STATE%
    echo Status: [%CURRENT_STATUS%]
    if /i "%CURRENT_STATUS%"=="running" (
        echo.
        echo SUCCESS: Server is now running!
        echo.
        echo Getting new IP address...
        set NEWIP_TRIES=0
        :GET_NEW_IP
        call "%SCRIPT_DIR%lib_ec2.bat" :GET_PUBLIC_IP >nul 2>&1
        if errorlevel 1 (
          if !NEWIP_TRIES! lss 4 (
            set /a NEWIP_TRIES+=1
            echo Failed to get IP (attempt !NEWIP_TRIES!/4). Retrying...
            timeout /t 5 /nobreak >nul
            goto :GET_NEW_IP
          ) else (
            echo ERROR: Could not obtain public IP after multiple attempts.
            pause
            exit /b 1
          )
        )
        set NEW_IP=%PUBLIC_IP%
        if /i "%NEW_IP%"=="None" (
            if !NEWIP_TRIES! lss 6 (
                set /a NEWIP_TRIES+=1
                echo IP not assigned yet. Retrying (!NEWIP_TRIES!/6)...
                timeout /t 5 /nobreak >nul
                goto :GET_NEW_IP
            ) else (
                echo Server running but IP not assigned yet
                echo Ensure the instance has a public IP or associate an Elastic IP
            )
        ) else (
            echo New server IP: %NEW_IP%
            echo SSH command: ssh -i "%KEY_FILE%" %SERVER_USER@%NEW_IP%
            echo.
            echo Updating configuration with new IP...
            call "%SCRIPT_DIR%lib_update_config.bat" :UPDATE_CONFIG "%NEW_IP%"
            call "%SCRIPT_DIR%config.bat" >nul 2>&1
            echo Configuration updated successfully!
            echo.
            echo All scripts will now use the new IP automatically
        )
        echo.
        echo [4/4] Server is ready for use!
        pause
        exit /b 0
    )
    if %WAIT_COUNT% geq 10 (
        echo.
        echo WARNING: Server taking longer than expected to start
        echo Current status: [%CURRENT_STATUS%]
        echo Check AWS Console for more details
        pause
        exit /b 1
    )
    goto :WAIT_LOOP
)

REM Handle pending state
if /i "%SERVER_STATUS%"=="pending" (
    echo.
    echo INFO: Server is currently starting up
    echo Please wait for it to reach running state
    pause
    exit /b 0
)

REM Handle other states
echo.
echo WARNING: Unexpected server status: [%SERVER_STATUS%]
echo Please check AWS Console for details
pause
exit /b 0
