@echo off
REM Example configuration for a team of 5 developers
REM Copy needed lines into scripts\config.bat and adjust values.

REM AWS Configuration
set INSTANCE_ID=i-0EXAMPLEABCDEF1234
set AWS_REGION=us-west-2

REM Server Connection (dynamic)
set SERVER_IP=0.0.0.0
set KEY_FILE=C:\Users\%USERNAME%\path\to\team-key.pem

REM Team Count
set TEAM_COUNT=5

REM Team IP Mappings (extendable list)
set DEV1_IP=203.0.113.10
set DEV1_NAME=Dev1
set DEV2_IP=203.0.113.11
set DEV2_NAME=Dev2
set DEV3_IP=203.0.113.12
set DEV3_NAME=Dev3
set DEV4_IP=203.0.113.13
set DEV4_NAME=Dev4
set DEV5_IP=203.0.113.14
set DEV5_NAME=Dev5

REM Current User (example for Developer3)
set YOUR_NAME=Dev3
set YOUR_IP=%DEV3_IP%

REM Server Configuration
set SERVER_VOTE_SCRIPT=/home/ubuntu/vote_shutdown.sh
set SERVER_USER=ubuntu

REM Display (sample)
if "%1"=="show" (
  echo ============================================
  echo Sample Config - 5 Developers
  echo ============================================
  echo Instance ID: %INSTANCE_ID%
  echo Region: %AWS_REGION%
  echo Server IP: %SERVER_IP%
  echo SSH Key: %KEY_FILE%
  echo User: %SERVER_USER%
  echo.
  echo Team Entries:
  for /L %%n in (1,1,%TEAM_COUNT%) do (
    call echo     DEV%%%%n_IP=%%DEV%%%%n_IP%% (%%DEV%%%%n_NAME%%)
  )
  echo.
  echo Current User: %YOUR_NAME% (%YOUR_IP%)
)
