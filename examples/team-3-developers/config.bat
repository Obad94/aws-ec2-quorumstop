@echo off
REM Example configuration for a team of 3 developers (PLANNED SAMPLE)
REM Do not use in production; copy fields into scripts\config.bat and edit.

REM AWS Configuration
set INSTANCE_ID=i-0EXAMPLE123456789
set AWS_REGION=us-west-2

REM Server Connection (dynamic)
set SERVER_IP=0.0.0.0
set KEY_FILE=C:\Users\%USERNAME%\path\to\your-key.pem

REM Team IP Mappings
set DEV1_IP=203.0.113.1
set DEV2_IP=203.0.113.2
set DEV3_IP=203.0.113.3

REM Current User
set YOUR_NAME=Developer1
set YOUR_IP=%DEV1_IP%

REM Server Configuration
set SERVER_VOTE_SCRIPT=/home/ubuntu/vote_shutdown.sh
set SERVER_USER=ubuntu
