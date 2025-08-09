@echo off
REM AWS EC2 QuorumStop - Shared EC2 Helper Library (refined)
REM Functions:
REM   :GET_STATE      -> Sets STATE env var to instance state (running/stopped/etc)
REM   :GET_PUBLIC_IP  -> Sets PUBLIC_IP env var to public IPv4 address
REM Options (2nd argument):
REM   /quiet   Suppress log noise (only final value on success)
REM   /value   Same as /quiet (prints only raw value) - handy for FOR /F capture
REM Exit Codes:
REM   0 success
REM   1 missing required env vars (INSTANCE_ID / AWS_REGION)
REM   2 AWS CLI failure or empty result
REM   3 unknown action

set "ACTION=%~1"
set "MODE=%~2"
if /i "%MODE%"=="/quiet" set "QUIET=1"
if /i "%MODE%"=="/value" set "QUIET=1"

if not defined ACTION goto :HELP

if /i "%ACTION%"==":GET_STATE"      goto GET_STATE
if /i "%ACTION%"==":GET_PUBLIC_IP"  goto GET_PUBLIC_IP
if /i "%ACTION%"==":TEST_STATE"     goto TEST_STATE

if not defined QUIET echo [lib_ec2] No matching parameter found: %ACTION%
exit /b 3

:REQUIRE_VARS
if not defined INSTANCE_ID (
  if not defined QUIET echo [lib_ec2] ERROR: INSTANCE_ID undefined
  exit /b 1
)
if not defined AWS_REGION (
  if not defined QUIET echo [lib_ec2] ERROR: AWS_REGION undefined
  exit /b 1
)
exit /b 0

:GET_STATE
call :REQUIRE_VARS || exit /b %errorlevel%
if not defined QUIET echo [lib_ec2] GET_STATE start
set "STATE="
set "AWS_PAGER="
for /f usebackq^ tokens^=* %%S in (`aws ec2 describe-instances --region "%AWS_REGION%" --instance-ids "%INSTANCE_ID%" --query "Reservations[0].Instances[0].State.Name" --output text 2^>nul`) do set "STATE=%%S"
if not defined STATE (
  if not defined QUIET echo [lib_ec2] ERROR: Unable to retrieve instance state
  exit /b 2
)
if defined QUIET (
  echo %STATE%
) else (
  echo [lib_ec2] Instance state: %STATE%
)
exit /b 0

:GET_PUBLIC_IP
call :REQUIRE_VARS || exit /b %errorlevel%
if not defined QUIET echo [lib_ec2] GET_PUBLIC_IP start
set "PUBLIC_IP="
set "AWS_PAGER="
for /f usebackq^ tokens^=* %%I in (`aws ec2 describe-instances --region "%AWS_REGION%" --instance-ids "%INSTANCE_ID%" --query "Reservations[0].Instances[0].PublicIpAddress" --output text 2^>nul`) do set "PUBLIC_IP=%%I"
if not defined PUBLIC_IP (
  if not defined QUIET echo [lib_ec2] ERROR: Unable to retrieve public IP
  exit /b 2
)
if defined QUIET (
  echo %PUBLIC_IP%
) else (
  echo [lib_ec2] Public IP: %PUBLIC_IP%
)
exit /b 0

:TEST_STATE
if not defined QUIET echo [lib_ec2] TEST_STATE start
call "%~dp0config.bat" >nul 2>&1
call "%~dp0lib_ec2.bat" :GET_STATE /quiet > "%TEMP%\_qs_state.tmp" 2>nul
set "STATE="
if exist "%TEMP%\_qs_state.tmp" for /f "usebackq tokens=*" %%S in ("%TEMP%\_qs_state.tmp") do set "STATE=%%S"
if exist "%TEMP%\_qs_state.tmp" del "%TEMP%\_qs_state.tmp" >nul 2>&1
if defined STATE (
  if not defined QUIET echo [TEST] Instance state: %STATE%
  if defined QUIET echo %STATE%
  exit /b 0
) else (
  if not defined QUIET echo [TEST] Failed to retrieve instance state
  exit /b 2
)

:HELP
if defined QUIET exit /b 3
echo [lib_ec2] Usage: call lib_ec2.bat :GET_STATE ^| :GET_PUBLIC_IP [ /quiet ^| /value ]
echo             call lib_ec2.bat :TEST_STATE
echo Requires env vars: INSTANCE_ID AWS_REGION (and AWS CLI configured)
exit /b 3
