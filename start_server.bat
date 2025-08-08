@echo off
setlocal enabledelayedexpansion

REM ============================================
REM EC2 Democratic Shutdown - Server Startup
REM Starts EC2 instance and updates configuration
REM ============================================

REM Load configuration
if not exist config.bat (
    echo ERROR: config.bat not found!
    echo Please ensure config.bat is in the same directory
    pause
    exit /b 1
)

call config.bat
echo Loaded configuration for user: %YOUR_NAME%

echo === EC2 Democratic Shutdown - Server Startup ===
echo.

echo [1/3] Checking current server status...
echo Instance ID: %INSTANCE_ID%
echo Current config IP: %SERVER_IP%

REM Get server status
aws ec2 describe-instances --region %AWS_REGION% --instance-ids %INSTANCE_ID% --query "Reservations[0].Instances[0].State.Name" --output text > status.tmp
if errorlevel 1 (
    echo ERROR: Failed to check server status
    echo Please check your AWS configuration and credentials
    del status.tmp 2>nul
    pause
    exit /b 1
)

if not exist status.tmp (
    echo ERROR: No response from AWS
    echo Please verify AWS CLI is properly configured
    pause
    exit /b 1
)

set /p SERVER_STATUS=<status.tmp
del status.tmp
REM Trim spaces from status
for /f "tokens=* delims= " %%a in ("%SERVER_STATUS%") do set SERVER_STATUS=%%a
for /l %%a in (1,1,100) do if "%SERVER_STATUS:~-1%"==" " set SERVER_STATUS=%SERVER_STATUS:~0,-1%

if "%SERVER_STATUS%"=="" (
    echo ERROR: Empty response from AWS
    echo Please check your INSTANCE_ID and AWS_REGION in config.bat
    pause
    exit /b 1
)

echo Current server status: [%SERVER_STATUS%]

REM Handle stopping state FIRST (before any other checks)
if "%SERVER_STATUS%"=="stopping" (
    echo.
    echo INFO: Server is currently stopping
    echo Waiting for it to reach stopped state, then will start it...
    
    set STOP_WAIT_COUNT=0
    :STOP_WAIT_LOOP
    echo Waiting for stop to complete... (attempt %STOP_WAIT_COUNT%)
    
    timeout /t 10 /nobreak >nul
    set /a STOP_WAIT_COUNT+=1
    
    aws ec2 describe-instances --region %AWS_REGION% --instance-ids %INSTANCE_ID% --query "Reservations[0].Instances[0].State.Name" --output text > stop_status.tmp
    if errorlevel 1 (
        echo ERROR: Cannot check status during stop wait
        del stop_status.tmp 2>nul
        pause
        exit /b 1
    )
    
    set /p STOP_STATUS=<stop_status.tmp
    del stop_status.tmp
    REM Trim spaces from status
    for /f "tokens=* delims= " %%a in ("%STOP_STATUS%") do set STOP_STATUS=%%a
    for /l %%a in (1,1,100) do if "%STOP_STATUS:~-1%"==" " set STOP_STATUS=%STOP_STATUS:~0,-1%
    
    echo Status: [%STOP_STATUS%]
    
    if "%STOP_STATUS%"=="stopped" (
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
if "%SERVER_STATUS%"=="running" (
    echo.
    echo SUCCESS: Server is already running!
    echo Getting current IP address...
    
    aws ec2 describe-instances --region %AWS_REGION% --instance-ids %INSTANCE_ID% --query "Reservations[0].Instances[0].PublicIpAddress" --output text > ip.tmp
    if exist ip.tmp (
        set /p CURRENT_IP=<ip.tmp
        REM Trim spaces from IP
        for /f "tokens=* delims= " %%a in ("!CURRENT_IP!") do set CURRENT_IP=%%a
        for /l %%a in (1,1,100) do if "!CURRENT_IP:~-1!"==" " set CURRENT_IP=!CURRENT_IP:~0,-1%
        
        if not "!CURRENT_IP!"=="None" (
            echo Server IP: !CURRENT_IP!
            echo SSH command: ssh -i "%KEY_FILE%" %SERVER_USER%@!CURRENT_IP!
            
            REM Update config if IP changed
            if not "!CURRENT_IP!"=="%SERVER_IP%" (
                echo.
                echo IP has changed from %SERVER_IP% to !CURRENT_IP!
                echo Updating configuration...
                call :UPDATE_CONFIG "!CURRENT_IP!"
                echo Configuration updated successfully
            ) else (
                echo IP unchanged - configuration is current
            )
        ) else (
            echo Server is running but no public IP assigned yet
        )
        del ip.tmp
    )
    echo.
    echo Server is ready for use!
    pause
    exit /b 0
)

REM Handle stopped state
if "%SERVER_STATUS%"=="stopped" (
    :START_SERVER
    echo.
    echo [2/3] Server is stopped. Starting now...
    
    aws ec2 start-instances --region %AWS_REGION% --instance-ids %INSTANCE_ID% > start_output.tmp
    if errorlevel 1 (
        echo ERROR: Failed to send start command
        if exist start_output.tmp (
            echo AWS Output:
            type start_output.tmp
        )
        del start_output.tmp 2>nul
        pause
        exit /b 1
    )
    
    echo SUCCESS: Start command sent to AWS
    del start_output.tmp 2>nul
    
    echo.
    echo [3/3] Waiting for server to become running...
    echo This usually takes 30-60 seconds...
    
    set WAIT_COUNT=0
    :WAIT_LOOP
    echo Checking status... (attempt %WAIT_COUNT%)
    
    timeout /t 15 /nobreak >nul
    set /a WAIT_COUNT+=1
    
    aws ec2 describe-instances --region %AWS_REGION% --instance-ids %INSTANCE_ID% --query "Reservations[0].Instances[0].State.Name" --output text > current_status.tmp
    if errorlevel 1 (
        echo ERROR: Cannot check status during startup
        del current_status.tmp 2>nul
        pause
        exit /b 1
    )
    
    set /p CURRENT_STATUS=<current_status.tmp
    del current_status.tmp
    REM Trim spaces from status
    for /f "tokens=* delims= " %%a in ("%CURRENT_STATUS%") do set CURRENT_STATUS=%%a
    for /l %%a in (1,1,100) do if "%CURRENT_STATUS:~-1%"==" " set CURRENT_STATUS=%CURRENT_STATUS:~0,-1%
    
    echo Status: [%CURRENT_STATUS%]
    
    if "%CURRENT_STATUS%"=="running" (
        echo.
        echo SUCCESS: Server is now running!
        
        echo Getting new IP address...
        aws ec2 describe-instances --region %AWS_REGION% --instance-ids %INSTANCE_ID% --query "Reservations[0].Instances[0].PublicIpAddress" --output text > new_ip.tmp
        if exist new_ip.tmp (
            set /p NEW_IP=<new_ip.tmp
            REM Trim spaces from IP
            for /f "tokens=* delims= " %%a in ("!NEW_IP!") do set NEW_IP=%%a
            for /l %%a in (1,1,100) do if "!NEW_IP:~-1!"==" " set NEW_IP=!NEW_IP:~0,-1%
            
            if not "!NEW_IP!"=="None" (
                echo.
                echo New server IP: !NEW_IP!
                echo SSH command: ssh -i "%KEY_FILE%" %SERVER_USER%@!NEW_IP!
                echo.
                echo Updating configuration with new IP...
                call :UPDATE_CONFIG "!NEW_IP!"
                echo Configuration updated successfully!
                echo.
                echo All scripts will now use the new IP automatically
            ) else (
                echo Server running but IP not assigned yet
            )
            del new_ip.tmp
        )
        echo.
        echo Server is ready for use!
        pause
        exit /b 0
    )
    
    if %WAIT_COUNT% geq 12 (
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
if "%SERVER_STATUS%"=="pending" (
    echo.
    echo INFO: Server is already starting up
    echo Please wait for it to reach running state
    pause
    exit /b 0
)

REM Handle other states
echo.
echo WARNING: Unexpected server status: [%SERVER_STATUS%]
echo Please check AWS Console for details
echo.
echo Cost reminder: Server charges resume when running
pause
exit /b 0

REM ============================================
REM Function to update configuration file
REM ============================================
:UPDATE_CONFIG
set NEW_IP_ADDRESS=%~1
REM Trim any spaces from the IP address
for /f "tokens=* delims= " %%a in ("%NEW_IP_ADDRESS%") do set NEW_IP_ADDRESS=%%a
for /l %%a in (1,1,100) do if "%NEW_IP_ADDRESS:~-1%"==" " set NEW_IP_ADDRESS=%NEW_IP_ADDRESS:~0,-1%

set TIMESTAMP=%date% %time%

REM Create temporary file with updated configuration
(
echo @echo off
echo REM ============================================
echo REM EC2 Democratic Shutdown - Configuration
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
echo     echo EC2 Democratic Shutdown - Configuration
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
) > config_temp.bat

REM Replace original config file
move config_temp.bat config.bat >nul
goto :eof