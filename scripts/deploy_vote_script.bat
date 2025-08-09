@echo off
setlocal ENABLEDELAYEDEXPANSION
REM =============================================================
REM AWS EC2 QuorumStop - deploy_vote_script.bat
REM Purpose: Automatically deploy / update the server-side vote_shutdown.sh
REM          script to the EC2 instance using existing configuration.
REM
REM Requirements:
REM   - scripts\config.bat populated (INSTANCE_ID, AWS_REGION, SERVER_IP, SERVER_USER, KEY_FILE)
REM   - Instance must be in running state (for SSH). Use scripts\start_server.bat first if needed.
REM   - AWS CLI required only if we auto-check state; scp/ssh must be in PATH.
REM
REM Behavior:
REM   1. Loads config and validates required variables.
REM   2. Verifies instance is running (via lib_ec2.bat); warns / aborts otherwise.
REM   3. Computes local SHA256 hash of server\vote_shutdown.sh.
REM   4. Retrieves remote hash if file already exists.
REM   5. Skips upload if hashes match (unless /force passed).
REM   6. Uploads file (prefers scp; falls back to type + ssh cat) and sets permissions.
REM   7. Creates symlink /usr/local/bin/vote_shutdown for convenience.
REM   8. Ensures log file & team map directory exist.
REM   9. Reports final status and remote version header.
REM
REM Usage:
REM   scripts\deploy_vote_script.bat              (normal idempotent deploy)
REM   scripts\deploy_vote_script.bat /force       (force re-upload regardless of hash)
REM
REM Exit Codes:
REM   0 = success (deployed or already up to date)
REM   1 = configuration / validation error
REM   2 = upload / permission error
REM =============================================================

set "SCRIPT_DIR=%~dp0"
set "ROOT_DIR=%SCRIPT_DIR%..\"

REM Load config
if not exist "%SCRIPT_DIR%config.bat" (
  echo [deploy] ERROR: config.bat not found in scripts folder.
  exit /b 1
)
call "%SCRIPT_DIR%config.bat" >nul 2>&1

REM Validate core variables
for %%V in (INSTANCE_ID AWS_REGION SERVER_IP SERVER_USER KEY_FILE SERVER_VOTE_SCRIPT) do (
  call if "%%%V%%"=="" echo [deploy] ERROR: %%V not set in config.bat & set _CFGERR=1
)
if defined _CFGERR exit /b 1
if not exist "%KEY_FILE%" (
  echo [deploy] ERROR: SSH key missing: %KEY_FILE%
  exit /b 1
)

REM Ensure target vote script exists locally
set "LOCAL_VOTE=%ROOT_DIR%server\vote_shutdown.sh"
if not exist "%LOCAL_VOTE%" (
  echo [deploy] ERROR: Local file not found: %LOCAL_VOTE%
  exit /b 1
)

REM Quick state check (optional, only if helper present)
if exist "%SCRIPT_DIR%lib_ec2.bat" (
  call "%SCRIPT_DIR%lib_ec2.bat" :GET_STATE >nul 2>&1
  if errorlevel 1 (
    echo [deploy] WARNING: Could not determine instance state (continuing).
  ) else (
    if /i not "%STATE%"=="running" (
      echo [deploy] ERROR: Instance state is %STATE% (needs to be running for SSH).
      echo          Start it with scripts\start_server.bat and retry.
      exit /b 1
    )
  )
) else (
  echo [deploy] NOTE: lib_ec2.bat missing; skipping state validation.
)

REM Basic IP sanity
if "%SERVER_IP%"=="0.0.0.0" (
  echo [deploy] ERROR: SERVER_IP is placeholder (0.0.0.0). Run scripts\start_server.bat to refresh.
  exit /b 1
)
if /i "%SERVER_IP%"=="None" (
  echo [deploy] ERROR: SERVER_IP is 'None'. Start/refresh instance first.
  exit /b 1
)

REM Compute local SHA256 hash (using certutil)
for /f "skip=1 tokens=1" %%H in ('certutil -hashfile "%LOCAL_VOTE%" SHA256 ^| findstr /R /I "^[0-9A-F]"') do set LOCAL_HASH=%%H & goto :HAVE_LOCAL_HASH
:HERE2
:HAV E_LOCAL_HASH
if not defined LOCAL_HASH (
  echo [deploy] WARNING: Could not compute local hash (certutil output unexpected). Continuing.
)

REM Fetch remote hash if file exists
set "REMOTE_PATH=/home/%SERVER_USER%/vote_shutdown.sh"
set "REMOTE_HASH="
ssh -o BatchMode=yes -o StrictHostKeyChecking=no -i "%KEY_FILE%" %SERVER_USER%@%SERVER_IP% "if [ -f '%REMOTE_PATH%' ]; then sha256sum '%REMOTE_PATH%' 2>/dev/null | awk '{print \$1}'; fi" > "%TEMP%\qs_remote_hash.tmp" 2>nul
if exist "%TEMP%\qs_remote_hash.tmp" (
  set /p REMOTE_HASH=<"%TEMP%\qs_remote_hash.tmp"
  del "%TEMP%\qs_remote_hash.tmp" >nul 2>&1
)

if defined REMOTE_HASH echo [deploy] Remote hash: %REMOTE_HASH%
if defined LOCAL_HASH  echo [deploy] Local  hash: %LOCAL_HASH%

if /i "%REMOTE_HASH%"=="%LOCAL_HASH%" if /i not "%1"=="/force" (
  echo [deploy] No changes detected (use /force to re-upload). Up to date.
  goto :POST_SETUP
)

REM Attempt upload with scp first
where scp >nul 2>&1
if not errorlevel 1 (
  echo [deploy] Uploading via scp...
  scp -o StrictHostKeyChecking=no -i "%KEY_FILE%" "%LOCAL_VOTE%" %SERVER_USER%@%SERVER_IP%:"%REMOTE_PATH%" >nul 2>&1
  if errorlevel 1 (
    echo [deploy] WARNING: scp failed. Falling back to stdin method.
    goto :FALLBACK_UPLOAD
  ) else (
    goto :POST_UPLOAD
  )
) else (
  echo [deploy] scp not found; using fallback stream upload.
  goto :FALLBACK_UPLOAD
)

:FALLBACK_UPLOAD
(Type "%LOCAL_VOTE%" | ssh -o StrictHostKeyChecking=no -i "%KEY_FILE%" %SERVER_USER%@%SERVER_IP% "cat > '%REMOTE_PATH%'" ) >nul 2>&1
if errorlevel 1 (
  echo [deploy] ERROR: Fallback upload failed.
  exit /b 2
)

:POST_UPLOAD
ssh -o StrictHostKeyChecking=no -i "%KEY_FILE%" %SERVER_USER%@%SERVER_IP% "chmod +x '%REMOTE_PATH%' && sudo ln -sf '%REMOTE_PATH%' /usr/local/bin/vote_shutdown && mkdir -p ~/.quorumstop && (sudo touch /var/log/quorumstop-votes.log 2>/dev/null || true) && (sudo chmod 640 /var/log/quorumstop-votes.log 2>/dev/null || true)" >nul 2>&1
if errorlevel 1 (
  echo [deploy] ERROR: Permission / post-upload setup failed.
  exit /b 2
)

echo [deploy] Upload & permission steps complete.

:POST_SETUP
REM Show first identifying line of remote script
ssh -o StrictHostKeyChecking=no -i "%KEY_FILE%" %SERVER_USER%@%SERVER_IP% "head -n 5 '%REMOTE_PATH%' | grep -m1 'Server-side Vote Handler'" 2>nul

REM Display final status summary
if defined LOCAL_HASH echo [deploy] Local Hash : %LOCAL_HASH%
if defined REMOTE_HASH echo [deploy] Previous Remote Hash: %REMOTE_HASH%
if defined LOCAL_HASH (
  ssh -o StrictHostKeyChecking=no -i "%KEY_FILE%" %SERVER_USER%@%SERVER_IP% "sha256sum '%REMOTE_PATH%' 2>/dev/null | awk '{print \$1}'" > "%TEMP%\qs_new_remote_hash.tmp" 2>nul
  if exist "%TEMP%\qs_new_remote_hash.tmp" (
    set /p NEW_RHASH=<"%TEMP%\qs_new_remote_hash.tmp"
    del "%TEMP%\qs_new_remote_hash.tmp" >nul 2>&1
    echo [deploy] New Remote Hash : %NEW_RHASH%
  )
)

echo.
echo Deployment complete.
echo You can test with: ssh -i "%KEY_FILE%" %SERVER_USER%@%SERVER_IP% "vote_shutdown help"

echo.
exit /b 0
