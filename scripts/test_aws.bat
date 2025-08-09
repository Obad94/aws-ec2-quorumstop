@echo off
setlocal ENABLEDELAYEDEXPANSION
REM ============================================
REM AWS EC2 QuorumStop - AWS Debug Test (robust ASCII version)
REM ============================================

REM Resolve script directory so paths work from anywhere
set "SCRIPT_DIR=%~dp0"

echo === AWS EC2 QuorumStop - AWS Debug Test ===

REM --------------------------------------------
REM [1/3] AWS CLI presence
REM --------------------------------------------
echo [1/3] Testing AWS CLI installation...
aws --version >nul 2>&1
if errorlevel 1 (
  echo ERROR: AWS CLI not installed or not in PATH
  echo(
  echo Installation steps:
  echo 1. Download from: https://aws.amazon.com/cli/
  echo 2. Run the installer as administrator
  echo 3. Restart Command Prompt
  pause
  exit /b 1
)
for /f "delims=" %%A in ('aws --version 2^>^&1') do echo %%A

REM --------------------------------------------
REM [2/3] Credentials / Identity
REM --------------------------------------------
echo(
echo [2/3] Testing AWS credentials...
for /f "delims=" %%A in ('aws sts get-caller-identity 2^>^&1') do echo %%A
set "STS_EXIT=%ERRORLEVEL%"
echo AWS STS command exit code: %STS_EXIT%
if not "%STS_EXIT%"=="0" goto :creds_error

REM Root credential warning (robust detection)
for /f "delims=" %%A in ('aws sts get-caller-identity --query Arn --output text 2^>^&1') do set "CALLER_ARN=%%A"
echo Caller ARN: !CALLER_ARN!
echo !CALLER_ARN! | findstr /i /r ":root$" >nul && set "USING_ROOT=1"
if defined USING_ROOT call :warn_root

REM --------------------------------------------
REM [3/3] EC2 Describe Instance
REM --------------------------------------------
echo(
echo [3/3] Testing EC2 access...
if not exist "%SCRIPT_DIR%config.bat" (
  echo ERROR: scripts\config.bat not found!
  echo Cannot test EC2 instance access without configuration
  pause
  exit /b 1
)

call "%SCRIPT_DIR%config.bat"

REM Basic validation of required vars
if "%INSTANCE_ID%"=="" echo ERROR: INSTANCE_ID not set in config.bat & goto :fail
if "%AWS_REGION%"=="" echo ERROR: AWS_REGION not set in config.bat & goto :fail

echo Using Instance ID: %INSTANCE_ID% (Region: %AWS_REGION%)

REM Run describe-instances capturing exact exit code
set "_DESC_FILE=%TEMP%\qs_ec2_desc_%RANDOM%.log"
aws ec2 describe-instances --region %AWS_REGION% --instance-ids %INSTANCE_ID% --output table >"%_DESC_FILE%" 2>&1
set "EC2_EXIT=%ERRORLEVEL%"
 type "%_DESC_FILE%"
 echo EC2 describe exit code: %EC2_EXIT%
 del "%_DESC_FILE%" >nul 2>&1
if not "%EC2_EXIT%"=="0" goto :ec2_error

REM Condensed summary (optional quick view)
echo(
echo Instance summary:
for /f "delims=" %%A in ('aws ec2 describe-instances --region %AWS_REGION% --instance-ids %INSTANCE_ID% --query "Reservations[0].Instances[0].{Name:Tags[?Key=='Name']|[0].Value,State:State.Name,Type:InstanceType,PubIP:PublicIpAddress,PrivIP:PrivateIpAddress}" --output table 2^>^&1') do echo %%A

REM Success section
set "CRED_STATUS=OK (valid and configured)"
if defined USING_ROOT set "CRED_STATUS=WARNING: USING ROOT (replace with IAM user)"

echo(
echo ========================================
echo SUCCESS: All AWS commands working!
echo ========================================
echo(
echo Your configuration status:
echo - AWS CLI: OK (installed and working)
echo - Credentials: %CRED_STATUS%
echo - EC2 Access: OK (instance reachable)
echo - Instance ID: %INSTANCE_ID%
echo - Region: %AWS_REGION%
echo(
echo You are ready to use AWS EC2 QuorumStop.
echo(
echo Next steps:
echo 1. Run: scripts\start_server.bat (start your server)
echo 2. Run: scripts\view_config.bat (view full configuration)
echo 3. Run: scripts\shutdown_server.bat (test democratic shutdown)
echo(
pause
exit /b 0

:warn_root
echo WARNING: Detected use of ROOT account credentials: !CALLER_ARN!
echo WARNING: Create an IAM user/role with least privileges (EC2 describe/stop/start) and remove root access keys.
echo WARNING: Enable MFA on the root account and delete/disable any root keys.
exit /b 0

:creds_error
echo(
echo ERROR: AWS credentials not configured OR command failed (exit code %STS_EXIT%).
echo(
echo Troubleshooting:
echo - Run: aws configure
echo - Ensure Access Key / Secret Key are correct
echo - Set default region (e.g., us-west-2)
echo - Set default output format (json)
echo(
echo Get credentials from AWS Console:
echo Your Name (top right) -> Security Credentials -> Access Keys
echo Remove any old/unused root access keys.
pause
exit /b 1

:ec2_error
echo(
echo ERROR: Cannot access EC2 instance (exit code %EC2_EXIT%).
echo Output above may contain the AWS error message.
echo Check:
echo - Instance ID: %INSTANCE_ID%
echo - Region: %AWS_REGION%
echo - Permissions: ec2:DescribeInstances, ec2:DescribeInstanceStatus
echo - Instance exists and you have rights
echo(
pause
exit /b 1

:fail
echo(
echo One or more required configuration values missing. Fix config.bat and re-run.
pause
exit /b 1
