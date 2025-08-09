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
  for /f "tokens=*" %%A in ("%%V") do if "!%%A!"=="" echo [deploy] ERROR: %%V not set & set _CFGERR=1
)
if defined _CFGERR exit /b 1
if not exist "%KEY_FILE%" (
  echo [deploy] ERROR: SSH key missing: %KEY_FILE%
  exit /b 1
)

REM Local vote script path
set "LOCAL_VOTE=%ROOT_DIR%server\vote_shutdown.sh"
if not exist "%LOCAL_VOTE%" (
  echo [deploy] ERROR: Local server\vote_shutdown.sh not found.
  exit /b 1
)

REM Quick sanity on IP
if "%SERVER_IP%"=="0.0.0.0" echo [deploy] ERROR: SERVER_IP placeholder. Run start_server first. & exit /b 1
if /i "%SERVER_IP%"=="None" echo [deploy] ERROR: SERVER_IP None. Start/refresh instance. & exit /b 1

REM Optional state check
if exist "%SCRIPT_DIR%lib_ec2.bat" (
  call "%SCRIPT_DIR%lib_ec2.bat" :GET_STATE >nul 2>&1
  if not errorlevel 1 (
    if /i not "%STATE%"=="running" (
      echo [deploy] ERROR: Instance state %STATE% (must be running for SSH)
      exit /b 1
    )
  )
)

REM Compute local hash (certutil)
set "LOCAL_HASH="
for /f "skip=1 tokens=1" %%H in ('certutil -hashfile "%LOCAL_VOTE%" SHA256 ^| findstr /R /I "^[0-9A-F]"') do (
  set LOCAL_HASH=%%H
  goto :gotLocalHash
)
:gotLocalHash
if not defined LOCAL_HASH echo [deploy] WARNING: Could not compute local hash.

set "REMOTE_PATH=/home/%SERVER_USER%/vote_shutdown.sh"
set "REMOTE_HASH="
ssh -o BatchMode=yes -o StrictHostKeyChecking=no -i "%KEY_FILE%" %SERVER_USER%@%SERVER_IP% "if [ -f '%REMOTE_PATH%' ]; then sha256sum '%REMOTE_PATH%' 2>/dev/null | awk '{print \$1}'; fi" > "%TEMP%\qs_rhash.tmp" 2>nul
if exist "%TEMP%\qs_rhash.tmp" (
  set /p REMOTE_HASH=<"%TEMP%\qs_rhash.tmp"
  del "%TEMP%\qs_rhash.tmp" >nul 2>&1
)
if defined REMOTE_HASH echo [deploy] Remote hash: %REMOTE_HASH%
if defined LOCAL_HASH  echo [deploy] Local  hash: %LOCAL_HASH%

if defined REMOTE_HASH if defined LOCAL_HASH if /i "%REMOTE_HASH%"=="%LOCAL_HASH%" if /i not "%1"=="/force" (
  echo [deploy] No changes (use /force to re-upload).
  goto :postSetup
)

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
  ssh -o StrictHostKeyChecking=no -i "%KEY_FILE%" %SERVER_USER%@%SERVER_IP% "sha256sum '%REMOTE_PATH%' 2>/dev/null | awk '{print \$1}'" > "%TEMP%\qs_new_rhash.tmp" 2>nul
  if exist "%TEMP%\qs_new_rhash.tmp" (
    set /p NEW_RHASH=<"%TEMP%\qs_new_rhash.tmp"
    del "%TEMP%\qs_new_rhash.tmp" >nul 2>&1
    echo [deploy] New Remote Hash: %NEW_RHASH%
  )
)

echo.
echo Deployment complete. Test with:
echo   ssh -i "%KEY_FILE%" %SERVER_USER%@%SERVER_IP% "vote_shutdown help"

echo.
exit /b 0
