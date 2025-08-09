@echo off
REM AWS EC2 QuorumStop - Shared EC2 Helper Library
echo [lib_ec2] Script started with parameters: %*

if /i "%1"==":GET_STATE" goto GET_STATE
if /i "%1"==":GET_PUBLIC_IP" goto GET_PUBLIC_IP  
if /i "%1"==":TEST_STATE" goto TEST_STATE
echo [lib_ec2] No matching parameter found
goto :eof

:GET_STATE
echo [lib_ec2] Starting GET_STATE function
if not defined INSTANCE_ID (echo [lib_ec2] ERROR: INSTANCE_ID undefined & exit /b 1)
if not defined AWS_REGION (echo [lib_ec2] ERROR: AWS_REGION undefined & exit /b 1)
set "AWS_PAGER="
aws ec2 describe-instances --region "%AWS_REGION%" --instance-ids "%INSTANCE_ID%" --query "Reservations[0].Instances[0].State.Name" --output text > "%TEMP%\state.txt" 2>&1
set "STATE="
for /f "tokens=*" %%S in ('type "%TEMP%\state.txt"') do set "STATE=%%S"
echo [lib_ec2] Instance state: %STATE%
if not defined STATE (echo [lib_ec2] ERROR: Unable to retrieve instance state & exit /b 2)
exit /b 0

:GET_PUBLIC_IP
echo [lib_ec2] Starting GET_PUBLIC_IP function
if not defined INSTANCE_ID (echo [lib_ec2] ERROR: INSTANCE_ID undefined & exit /b 1)
if not defined AWS_REGION (echo [lib_ec2] ERROR: AWS_REGION undefined & exit /b 1)
set "AWS_PAGER="
aws ec2 describe-instances --region "%AWS_REGION%" --instance-ids "%INSTANCE_ID%" --query "Reservations[0].Instances[0].PublicIpAddress" --output text > "%TEMP%\ip.txt" 2>&1
set "PUBLIC_IP="
for /f "tokens=*" %%I in ('type "%TEMP%\ip.txt"') do set "PUBLIC_IP=%%I"
if not defined PUBLIC_IP (echo [lib_ec2] ERROR: Unable to retrieve public IP & exit /b 2)
exit /b 0

:TEST_STATE
echo [lib_ec2] TEST_STATE function called
call "%~dp0config.bat"
call "%~dp0lib_ec2.bat" :GET_STATE
if defined STATE (
  echo [TEST] Instance state: %STATE%
) else (
  echo [TEST] Failed to retrieve instance state.
)
exit /b 0
