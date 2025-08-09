@echo off
setlocal enabledelayedexpansion

echo === AWS EC2 QuorumStop - Sync IP Utility ===

set "SCRIPT_DIR=%~dp0..\scripts\"
if not exist "%SCRIPT_DIR%config.bat" (
  echo ERROR: config.bat not found in scripts directory.
  exit /b 1
)

call "%SCRIPT_DIR%config.bat"
echo Instance: %INSTANCE_ID% (%AWS_REGION%)
echo Previous IP: %SERVER_IP%

set "AWS_PAGER="
aws --version >nul 2>&1 || (echo ERROR: AWS CLI not installed & exit /b 1)

echo Querying current public IP from AWS...
for /f "usebackq tokens=*" %%I in (`aws ec2 describe-instances --region %AWS_REGION% --instance-ids %INSTANCE_ID% --query "Reservations[0].Instances[0].PublicIpAddress" --output text 2^>nul`) do set NEW_IP=%%I

if not defined NEW_IP (
  echo ERROR: Could not retrieve IP. Check instance ID/region or instance state.
  exit /b 1
)

for /f "tokens=* delims= " %%a in ("%NEW_IP%") do set NEW_IP=%%a
for /l %%a in (1,1,100) do if "%NEW_IP:~-1%"==" " set NEW_IP=%NEW_IP:~0,-1%

echo Current AWS IP: %NEW_IP%

if /i "%NEW_IP%"=="None" (
  echo WARNING: Instance has no public IP (maybe stopped or no public interface).
  exit /b 2
)

if /i "%NEW_IP%"=="%SERVER_IP%" (
  echo No change detected. config.bat not modified.
  exit /b 0
)

echo Updating config.bat...
call "%SCRIPT_DIR%lib_update_config.bat" :UPDATE_CONFIG "%NEW_IP%" >nul

echo Done. New IP stored: %NEW_IP%
exit /b 0
