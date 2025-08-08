@echo off
REM ============================================
REM EC2 Democratic Shutdown - Configuration
REM This file is automatically updated by scripts
REM Last updated: [AUTO-GENERATED TIMESTAMP]
REM ============================================

REM =============================
REM AWS Configuration
REM =============================
REM Your EC2 instance details
set INSTANCE_ID=i-0123456789abcdef0
set AWS_REGION=us-west-2

REM =============================
REM Server Connection (Dynamic)  
REM =============================
REM These are updated automatically by start_server.bat
set SERVER_IP=1.2.3.4
set KEY_FILE=C:\Users\%USERNAME%\Downloads\your-aws-key.pem

REM =============================
REM Team IP Mappings
REM =============================
REM Each team member's public IP address
REM Get your IP from: https://whatismyipaddress.com
set DEV1_IP=203.0.113.1
set DEV2_IP=203.0.113.2
set DEV3_IP=203.0.113.3

REM =============================
REM Current User Configuration
REM =============================
REM IMPORTANT: Each team member should set their own values here
set YOUR_NAME=Developer1
set YOUR_IP=%DEV1_IP%

REM =============================
REM Server Configuration
REM =============================
REM Server paths and settings
set SERVER_VOTE_SCRIPT=/home/ubuntu/vote_shutdown.sh
set SERVER_USER=ubuntu

REM =============================
REM Display Configuration
REM =============================
REM Show current configuration when called with "show" parameter
if "%1"=="show" (
    echo ============================================
    echo EC2 Democratic Shutdown - Configuration
    echo ============================================
    echo.
    echo AWS Settings:
    echo   Instance ID: %INSTANCE_ID%
    echo   Region: %AWS_REGION%
    echo.
    echo Server Connection:
    echo   IP Address: %SERVER_IP%
    echo   SSH Key: %KEY_FILE%
    echo   User: %SERVER_USER%
    echo.
    echo Team IP Mappings:
    echo   Developer 1: %DEV1_IP%
    echo   Developer 2: %DEV2_IP%
    echo   Developer 3: %DEV3_IP%
    echo.
    echo Current User:
    echo   Name: %YOUR_NAME%
    echo   IP: %YOUR_IP%
    echo.
    echo Server Paths:
    echo   Vote Script: %SERVER_VOTE_SCRIPT%
    echo.
    echo Configuration Status:
    if exist "%KEY_FILE%" (
        echo   SSH Key: ✓ Found
    ) else (
        echo   SSH Key: ✗ Not found - Update KEY_FILE path
    )
    echo.
    echo Last Updated: %date% %time%
    echo ============================================
)