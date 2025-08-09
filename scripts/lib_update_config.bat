@echo off
REM ============================================
REM Shared helper: lib_update_config.bat
REM Provides :UPDATE_CONFIG routine to rewrite config.bat with new SERVER_IP
REM Usage: call "%~dp0lib_update_config.bat" :UPDATE_CONFIG NEW_IP
REM ============================================

if /i "%1"==":UPDATE_CONFIG" goto UPDATE_CONFIG
goto :eof

:UPDATE_CONFIG
shift
set NEW_IP_ADDRESS=%~1
if not defined NEW_IP_ADDRESS goto :eof
for /f "tokens=* delims= " %%a in ("%NEW_IP_ADDRESS%") do set NEW_IP_ADDRESS=%%a
for /l %%a in (1,1,100) do if "%NEW_IP_ADDRESS:~-1%"==" " set NEW_IP_ADDRESS=%NEW_IP_ADDRESS:~0,-1%

REM Load current config to preserve variables
set "SCRIPT_DIR=%~dp0"
if exist "%SCRIPT_DIR%config.bat" call "%SCRIPT_DIR%config.bat"

if /i "%NEW_IP_ADDRESS%"=="%SERVER_IP%" (
  echo (No change in IP; config not rewritten)
  goto :eof
)

set TIMESTAMP=%date% %time%
(
echo @echo off
echo REM ============================================
echo REM AWS EC2 QuorumStop - Configuration
echo REM This file is automatically updated by scripts
echo REM Last updated: %TIMESTAMP%
echo REM ============================================
echo.
echo REM =============================
echo REM AWS Configuration
echo REM =============================
echo set INSTANCE_ID=%INSTANCE_ID%
echo set AWS_REGION=%AWS_REGION%
echo.
echo REM =============================
echo REM Server Connection ^(Dynamic^)
echo REM =============================
echo set SERVER_IP=%NEW_IP_ADDRESS%
echo set KEY_FILE=%KEY_FILE%
echo.
echo REM =============================
echo REM Team IP Mappings (dynamic list)
echo REM =============================
for /f "tokens=1,2 delims==" %%A in ('set DEV[0-9]_IP 2^>nul') do echo set %%A=%%B
for /f "tokens=1,2 delims==" %%A in ('set DEV[0-9][0-9]_IP 2^>nul') do echo set %%A=%%B
echo.
echo REM =============================
echo REM Current User Configuration
echo REM =============================
echo set YOUR_NAME=%YOUR_NAME%
echo set YOUR_IP=%YOUR_IP%
echo.
echo REM =============================
echo REM Server Configuration
echo REM =============================
echo set SERVER_VOTE_SCRIPT=%SERVER_VOTE_SCRIPT%
echo set SERVER_USER=%SERVER_USER%
echo.
echo REM =============================
echo REM Display Configuration
echo REM =============================
echo if "%%1"=="show" ^(
echo   echo ============================================
echo   echo AWS EC2 QuorumStop - Configuration
echo   echo ============================================
echo   echo.
echo   echo AWS Settings:
echo   echo   Instance ID: %%INSTANCE_ID%%
echo   echo   Region: %%AWS_REGION%%
echo   echo.
echo   echo Server Connection:
echo   echo   IP Address: %%SERVER_IP%%
echo   echo   SSH Key: %%KEY_FILE%%
echo   echo   User: %%SERVER_USER%%
echo   echo.
echo   echo Team IP Mappings:
for /f "tokens=1,2 delims==" %%A in ('set DEV[0-9]_IP 2^>nul') do echo   echo   %%A: %%%%A%%
for /f "tokens=1,2 delims==" %%A in ('set DEV[0-9][0-9]_IP 2^>nul') do echo   echo   %%A: %%%%A%%
echo   echo.
echo   echo Current User:
echo   echo   Name: %%YOUR_NAME%%
echo   echo   IP: %%YOUR_IP%%
echo   echo.
echo   echo Server Paths:
echo   echo   Vote Script: %%SERVER_VOTE_SCRIPT%%
echo   echo.
echo   echo Configuration Status:
echo   if exist "%%KEY_FILE%%" ^(
echo     echo   SSH Key: ✓ Found
echo   ^) else ^(
echo     echo   SSH Key: ✗ Not found - Update KEY_FILE path
echo   ^)
echo   echo.
echo   echo Last Updated: %%date%% %%time%%
echo   echo ============================================
echo ^)
) > "%SCRIPT_DIR%config_temp.bat"

move /y "%SCRIPT_DIR%config_temp.bat" "%SCRIPT_DIR%config.bat" >nul
echo Updated config.bat with new IP %NEW_IP_ADDRESS%
goto :eof
