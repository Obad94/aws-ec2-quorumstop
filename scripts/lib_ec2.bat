@echo off
REM ============================================
REM AWS EC2 QuorumStop - Shared EC2 Helper Library
REM Provides reusable routines for instance state & public IP retrieval.
REM Usage examples (after config.bat loaded):
REM   call "%~dp0lib_ec2.bat" :GET_STATE || echo Failed
REM   echo State: %STATE%
REM   call "%~dp0lib_ec2.bat" :GET_PUBLIC_IP || echo Failed
REM   echo IP: %PUBLIC_IP%
REM ============================================

if /i "%1"==":GET_STATE" goto GET_STATE
if /i "%1"==":GET_PUBLIC_IP" goto GET_PUBLIC_IP
goto :eof

:__TRIM
REM %1 = var name to trim (by reference)
for /f "tokens=* delims= " %%A in ("!%~1!") do set "%~1=%%A"
for /l %%A in (1,1,40) do if "!%~1:~-1!"==" " set "%~1=!%~1:~0,-1!"
exit /b 0

:GET_STATE
shift
setlocal EnableDelayedExpansion
if not defined INSTANCE_ID (echo [lib_ec2] ERROR: INSTANCE_ID undefined & endlocal & exit /b 1)
if not defined AWS_REGION (echo [lib_ec2] ERROR: AWS_REGION undefined & endlocal & exit /b 1)
set "AWS_PAGER="
for /f "usebackq tokens=*" %%S in (`aws ec2 describe-instances --region %AWS_REGION% --instance-ids %INSTANCE_ID% --query "Reservations[0].Instances[0].State.Name" --output text 2^>^&1`) do set "_RAW_STATE=%%S"
if not defined _RAW_STATE (echo [lib_ec2] ERROR: Unable to retrieve instance state & endlocal & exit /b 2)
call set "STATE=!_RAW_STATE!"
call :__TRIM STATE
endlocal & set "STATE=%STATE%"
exit /b 0

:GET_PUBLIC_IP
shift
setlocal EnableDelayedExpansion
if not defined INSTANCE_ID (echo [lib_ec2] ERROR: INSTANCE_ID undefined & endlocal & exit /b 1)
if not defined AWS_REGION (echo [lib_ec2] ERROR: AWS_REGION undefined & endlocal & exit /b 1)
set "AWS_PAGER="
for /f "usebackq tokens=*" %%I in (`aws ec2 describe-instances --region %AWS_REGION% --instance-ids %INSTANCE_ID% --query "Reservations[0].Instances[0].PublicIpAddress" --output text 2^>^&1`) do set "_RAW_IP=%%I"
if not defined _RAW_IP (echo [lib_ec2] ERROR: Unable to retrieve public IP & endlocal & exit /b 2)
call set "PUBLIC_IP=!_RAW_IP!"
call :__TRIM PUBLIC_IP
endlocal & set "PUBLIC_IP=%PUBLIC_IP%"
exit /b 0
