@echo off
REM ============================================
REM AWS EC2 QuorumStop - Sample Configuration
REM Copy this file to scripts\config.bat and edit values. Do NOT commit real config.bat.
REM ============================================

REM AWS Configuration
set INSTANCE_ID=i-0EXAMPLE123456789
set AWS_REGION=us-west-2

REM Server Connection (Dynamic; SERVER_IP updated automatically by scripts)
set SERVER_IP=0.0.0.0
set KEY_FILE=C:\Users\%USERNAME%\path\to\your-key.pem

REM Team Count (number of DEVn entries you define below)
set TEAM_COUNT=2

REM Team IP Mappings and Names (extend as needed: DEV3_IP, DEV3_NAME, ...)
set DEV1_IP=203.0.113.10
set DEV1_NAME=Dev1
set DEV2_IP=203.0.113.11
set DEV2_NAME=Dev2

REM Current User Configuration
set YOUR_NAME=Dev1
set YOUR_IP=%DEV1_IP%

REM Server Configuration
set SERVER_VOTE_SCRIPT=/home/ubuntu/vote_shutdown.sh
set SERVER_USER=ubuntu

REM Display Configuration (lists team entries)
if "%1"=="show" (
  echo ============================================
  echo AWS EC2 QuorumStop - Configuration (Sample)
  echo ============================================
  echo Instance ID: %INSTANCE_ID%
  echo Region: %AWS_REGION%
  echo Server IP: %SERVER_IP%
  echo SSH Key: %KEY_FILE%
  echo User: %SERVER_USER%
  echo.
  echo Team Entries:
  for /L %%n in (1,1,%TEAM_COUNT%) do (
    call echo     DEV%%n_IP=%%DEV%%n_IP%% (%%DEV%%n_NAME%%)
  )
  echo.
  echo Current User: %YOUR_NAME% (%YOUR_IP%)
)
