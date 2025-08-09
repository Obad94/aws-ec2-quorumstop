@echo off
setlocal EnableDelayedExpansion
REM =============================================================
REM AWS EC2 QuorumStop - deploy_vote_script.bat (Simplified Stable Version)
REM =============================================================

REM Determine directories
set "SCRIPT_DIR=%~dp0"
for %%~ in (.) do rem noop
set "ROOT_DIR=%SCRIPT_DIR%..\"

REM Load config
if not exist "%SCRIPT_DIR%config.bat" (
  echo [deploy] ERROR: scripts\config.bat not found.
  exit /b 1
)
call "%SCRIPT_DIR%config.bat" >nul 2>&1

REM Validate required vars
for %%V in (INSTANCE_ID AWS_REGION SERVER_IP SERVER_USER KEY_FILE SERVER_VOTE_SCRIPT) do (
  for /f "tokens=*" %%A in ("%%V") do if "!%%A!"=="" (
    echo [deploy] ERROR: %%V not set 
    set _CFGERR=1
  ) else (
    echo [deploy] %%V = !%%A!
  )
)
if defined _CFGERR (
  echo [deploy] Configuration errors found. Exiting.
  exit /b 1
)

echo [deploy] Configuration validation passed.

if not exist "%KEY_FILE%" (
  echo [deploy] ERROR: SSH key missing: %KEY_FILE%
  exit /b 1
)

echo [deploy] SSH key file exists: %KEY_FILE%

REM Local vote script path
set "LOCAL_VOTE=%ROOT_DIR%server\vote_shutdown.sh"
echo [deploy] Looking for local vote script: %LOCAL_VOTE%
if not exist "%LOCAL_VOTE%" (
  echo [deploy] ERROR: Local server\vote_shutdown.sh not found.
  exit /b 1
)
echo [deploy] Local vote script found.

REM Quick sanity on IP
if "%SERVER_IP%"=="0.0.0.0" (
  echo [deploy] ERROR: SERVER_IP placeholder. Run start_server first. 
  exit /b 1
)
if /i "%SERVER_IP%"=="None" (
  echo [deploy] ERROR: SERVER_IP None. Start/refresh instance. 
  exit /b 1
)
echo [deploy] SERVER_IP validation passed: %SERVER_IP%

REM Optional state check - Direct AWS CLI call
echo [deploy] Checking instance state...
set "AWS_PAGER="
aws ec2 describe-instances --region "%AWS_REGION%" --instance-ids "%INSTANCE_ID%" --query "Reservations[0].Instances[0].State.Name" --output text > "%TEMP%\deploy_state.txt" 2>&1
set "INSTANCE_STATE="
for /f "tokens=*" %%S in ('type "%TEMP%\deploy_state.txt"') do set "INSTANCE_STATE=%%S"
echo [deploy] Instance state: %INSTANCE_STATE%
if /i not "%INSTANCE_STATE%"=="running" (
  echo [deploy] ERROR: Instance state %INSTANCE_STATE% ^(must be running for SSH^)
  exit /b 1
)

REM Compute local hash (PowerShell Get-FileHash)
set "LOCAL_HASH="
echo [deploy] Computing local file hash...
echo [deploy] File path: "%LOCAL_VOTE%"
REM Use PowerShell Get-FileHash which is more reliable
for /f "tokens=*" %%H in ('powershell -Command "Get-FileHash '%LOCAL_VOTE%' -Algorithm SHA256 | Select-Object -ExpandProperty Hash"') do (
  set "LOCAL_HASH=%%H"
)
if not defined LOCAL_HASH (
  echo [deploy] WARNING: Could not compute local hash.
) else (
  echo [deploy] Local hash computed successfully
)

set "REMOTE_PATH=/home/%SERVER_USER%/vote_shutdown.sh"
set "REMOTE_HASH="
echo [deploy] Checking for remote file hash...
ssh -o BatchMode=yes -o StrictHostKeyChecking=no -i "%KEY_FILE%" %SERVER_USER%@%SERVER_IP% "sha256sum /home/ubuntu/vote_shutdown.sh 2>/dev/null | cut -d' ' -f1" > "%TEMP%\qs_rhash.tmp" 2>nul
if exist "%TEMP%\qs_rhash.tmp" (
  set /p REMOTE_HASH=<"%TEMP%\qs_rhash.tmp"
  del "%TEMP%\qs_rhash.tmp" >nul 2>&1
  echo [deploy] REMOTE_HASH read: [!REMOTE_HASH!]
) else (
  echo [deploy] Remote hash temp file not found
)
if defined REMOTE_HASH echo [deploy] Remote hash: !REMOTE_HASH!
if defined LOCAL_HASH (
  set "HASH_DISPLAY=!LOCAL_HASH:~0,12!...!LOCAL_HASH:~-12!"
  echo [deploy] Local hash: !HASH_DISPLAY!
)

echo [deploy] Starting remote hash check...

REM Check if we should skip upload due to matching hashes
if defined REMOTE_HASH (
  if defined LOCAL_HASH (
    if /i "!REMOTE_HASH!"=="!LOCAL_HASH!" (
      if /i not "%1"=="/force" (
        echo [deploy] No changes detected, hashes match ^(use /force to re-upload^).
        goto :postSetup
      )
    )
  )
)
echo [deploy] Proceeding with upload...

REM Upload (scp preferred)
where scp >nul 2>&1
if not errorlevel 1 (
  echo [deploy] Uploading via scp...
  scp -q -o StrictHostKeyChecking=no -i "%KEY_FILE%" "%LOCAL_VOTE%" %SERVER_USER%@%SERVER_IP%:"%REMOTE_PATH%"
  if errorlevel 1 (
    echo [deploy] scp failed, trying fallback...
    goto :fallbackUpload
  ) else goto :afterUpload
) else (
  echo [deploy] scp not found, using fallback...
  goto :fallbackUpload
)

:fallbackUpload
type "%LOCAL_VOTE%" | ssh -o StrictHostKeyChecking=no -i "%KEY_FILE%" %SERVER_USER%@%SERVER_IP% "cat > '%REMOTE_PATH%'" || (
  echo [deploy] ERROR: Fallback upload failed.
  exit /b 2
)

:afterUpload
ssh -o StrictHostKeyChecking=no -i "%KEY_FILE%" %SERVER_USER%@%SERVER_IP% "chmod +x '%REMOTE_PATH%' && sudo ln -sf '%REMOTE_PATH%' /usr/local/bin/vote_shutdown && mkdir -p ~/.quorumstop && (sudo touch /var/log/quorumstop-votes.log 2>/dev/null || true) && (sudo chmod 640 /var/log/quorumstop-votes.log 2>/dev/null || true)" || (
  echo [deploy] ERROR: Post-upload setup failed.
  exit /b 2
)
echo [deploy] Upload & setup complete.

:postSetup
if defined LOCAL_HASH (
  ssh -o StrictHostKeyChecking=no -i "%KEY_FILE%" %SERVER_USER%@%SERVER_IP% "sha256sum '%REMOTE_PATH%' 2>/dev/null | cut -d' ' -f1" > "%TEMP%\qs_new_rhash.tmp" 2>nul
  if exist "%TEMP%\qs_new_rhash.tmp" (
    set /p NEW_RHASH=<"%TEMP%\qs_new_rhash.tmp"
    del "%TEMP%\qs_new_rhash.tmp" >nul 2>&1
    if defined NEW_RHASH echo [deploy] New Remote Hash: !NEW_RHASH!
  )
)

echo.
echo Deployment complete. Test with:
echo   ssh -i "%KEY_FILE%" %SERVER_USER%@%SERVER_IP% "vote_shutdown help"

echo.
exit /b 0
