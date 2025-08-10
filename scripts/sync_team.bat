@echo off
setlocal ENABLEDELAYEDEXPANSION
REM ============================================
REM AWS EC2 QuorumStop - Team Map Sync Utility
REM Generates a team.map from config.bat DEVn entries and uploads to server.
REM Called automatically by shutdown_server.bat before initiating vote.
REM ============================================

set "SCRIPT_DIR=%~dp0"
if not exist "%SCRIPT_DIR%config.bat" (
  echo [sync_team] ERROR: config.bat not found in scripts folder.
  exit /b 1
)

call "%SCRIPT_DIR%config.bat" >nul 2>&1

REM Basic validation
for %%V in (SERVER_USER SERVER_IP KEY_FILE TEAM_COUNT) do (
  call if "%%%V%%"=="" echo [sync_team] ERROR: %%V not set in config.bat & set _ERR=1
)
if defined _ERR exit /b 1
if not exist "%KEY_FILE%" (
  echo [sync_team] WARNING: KEY_FILE not found: %KEY_FILE%
)
if "%SERVER_IP%"=="0.0.0.0" (
  echo [sync_team] INFO: Placeholder IP 0.0.0.0; skipping team sync.
  exit /b 0
)
if "%SERVER_IP%"=="None" (
  echo [sync_team] INFO: Server IP is None; skipping team sync.
  exit /b 0
)

set TMP_FILE=%TEMP%\team_map_%RANDOM%.tmp
(
  echo # Auto-generated team map - Do NOT edit on server
  echo # Generated: %date% %time%
  for /L %%n in (1,1,%TEAM_COUNT%) do (
    set "_IP="
    set "_NM="
    call set "_IP=%%DEV%%n_IP%%"
    call set "_NM=%%DEV%%n_NAME%%"
    if defined _IP if not defined _NM set "_NM=Dev%%n"
    if defined _IP echo !_IP! !_NM!
  )
) > "%TMP_FILE%"

REM Create directory and upload file using stdin redirection to avoid temp scp dependency
set REMOTE_DIR=.quorumstop
set REMOTE_PATH=~/%REMOTE_DIR%/team.map

echo [sync_team] Uploading team map to %SERVER_USER%@%SERVER_IP%:%REMOTE_PATH%
ssh -o StrictHostKeyChecking=no -i "%KEY_FILE%" %SERVER_USER%@%SERVER_IP% "mkdir -p ~/%REMOTE_DIR% && cat > %REMOTE_PATH%" < "%TMP_FILE%"
if errorlevel 1 (
  echo [sync_team] ERROR: Failed to upload team map.
  del "%TMP_FILE%" 2>nul
  exit /b 1
)

del "%TMP_FILE%" 2>nul

echo [sync_team] Team map sync complete.
exit /b 0
