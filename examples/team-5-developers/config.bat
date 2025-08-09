@echo off
REM Example configuration for a team of 5 developers
REM Copy needed lines into scripts\config.bat and adjust values.

REM AWS Configuration
set INSTANCE_ID=i-0EXAMPLEABCDEF1234
set AWS_REGION=us-west-2

REM Server Connection (dynamic)
set SERVER_IP=0.0.0.0
set KEY_FILE=C:\Users\%USERNAME%\path\to\team-key.pem

REM Team IP Mappings (extendable list)
set DEV1_IP=203.0.113.10
set DEV2_IP=203.0.113.11
set DEV3_IP=203.0.113.12
set DEV4_IP=203.0.113.13
set DEV5_IP=203.0.113.14

REM Current User (example for Developer3)
set YOUR_NAME=Dev3
set YOUR_IP=%DEV3_IP%

REM Server Configuration
set SERVER_VOTE_SCRIPT=/home/ubuntu/vote_shutdown.sh
set SERVER_USER=ubuntu
