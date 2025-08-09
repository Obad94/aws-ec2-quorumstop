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
setlocal EnableDelayedExpansion
set NEW_IP_ADDRESS=%~1
if not defined NEW_IP_ADDRESS goto :eof
for /f "tokens=* delims= " %%a in ("%NEW_IP_ADDRESS%") do set NEW_IP_ADDRESS=%%a
for /l %%a in (1,1,100) do if "!NEW_IP_ADDRESS:~-1!"==" " set NEW_IP_ADDRESS=!NEW_IP_ADDRESS:~0,-1!

REM Load current config to preserve variables
set "SCRIPT_DIR=%~dp0"
if exist "%SCRIPT_DIR%config.bat" call "%SCRIPT_DIR%config.bat" >nul 2>&1

REM If IP unchanged, exit silently
if /i "!NEW_IP_ADDRESS!"=="%SERVER_IP%" (
  echo (No change in IP; config not rewritten)
  endlocal & goto :eof
)

REM Determine TEAM_COUNT (preserve if defined, else infer from highest DEVn_IP)
set "_TEAM_COUNT=%TEAM_COUNT%"
if not defined _TEAM_COUNT (
  set /a _HI=0
  for /L %%n in (1,1,99) do (
    call if defined DEV%%n_IP set /a _HI=%%n
  )
  if !_HI! gtr 0 set _TEAM_COUNT=!_HI!
)
if not defined _TEAM_COUNT set _TEAM_COUNT=0

REM Build temp file
set TIMESTAMP=%date% %time%
(
  echo @echo off
  echo REM ============================================
  echo REM AWS EC2 QuorumStop - Configuration
  echo REM This file is automatically updated by scripts\lib_update_config.bat
  echo REM Last updated: !TIMESTAMP!
  echo REM ============================================
  echo.
  echo REM AWS Configuration
  echo set INSTANCE_ID=%INSTANCE_ID%
  echo set AWS_REGION=%AWS_REGION%
  echo.
  echo REM Server Connection ^(Dynamic^)
  echo set SERVER_IP=!NEW_IP_ADDRESS!
  echo set KEY_FILE=%KEY_FILE%
  echo.
  echo REM Team Count (highest indexed DEVn_IP preserved)
  echo set TEAM_COUNT=!_TEAM_COUNT!
  echo.
  echo REM Team IP Mappings and Names
  if not "!_TEAM_COUNT!"=="0" (
    for /L %%n in (1,1,!_TEAM_COUNT!) do (
      call set "_IP=%%DEV%%n_IP%%"
      call set "_NM=%%DEV%%n_NAME%%"
      if defined _IP echo set DEV%%n_IP=!_IP!
      if defined _NM (
        echo set DEV%%n_NAME=!_NM!
      ) else (
        echo set DEV%%n_NAME=Dev%%n
      )
    )
  ) else (
    echo REM (No team members defined)
  )
  echo.
  echo REM Current User Configuration
  echo set YOUR_NAME=%YOUR_NAME%
  echo set YOUR_IP=%YOUR_IP%
  echo.
  echo REM Server Configuration
  echo set SERVER_VOTE_SCRIPT=%SERVER_VOTE_SCRIPT%
  echo set SERVER_USER=%SERVER_USER%
  echo.
  echo REM Display Configuration (lists team entries)
  echo if "%%1"=="show" ^(
  echo   echo ============================================
  echo   echo AWS EC2 QuorumStop - Configuration
  echo   echo ============================================
  echo   echo Instance ID: %%INSTANCE_ID%%
  echo   echo Region: %%AWS_REGION%%
  echo   echo Server IP: %%SERVER_IP%%
  echo   echo SSH Key: %%KEY_FILE%%
  echo   echo User: %%SERVER_USER%%
  echo   echo.
  echo   echo Team Entries:
  echo   for /L %%%%n in (1,1,%%TEAM_COUNT%%) do ^(
  echo     call echo     DEV%%%%n_IP=%%DEV%%%%n_IP%% ^(%%DEV%%%%n_NAME%%^)
  echo   ^)
  echo   echo.
  echo   echo Current User: %%YOUR_NAME%% ^(%%YOUR_IP%%^)
  echo ^)
) > "%SCRIPT_DIR%config_temp.bat"

move /y "%SCRIPT_DIR%config_temp.bat" "%SCRIPT_DIR%config.bat" >nul
endlocal & echo Updated config.bat with new IP %NEW_IP_ADDRESS%
goto :eof
