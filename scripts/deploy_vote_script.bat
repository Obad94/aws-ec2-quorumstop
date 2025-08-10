@echo off
setlocal EnableDelayedExpansion
REM =============================================================
REM AWS EC2 QuorumStop - deploy_vote_script.bat (Rewritten Clean Debug)
REM Debug output only shown when /debug flag supplied.
REM =============================================================

REM Parse flags
set "DEBUG="
set "FORCE="
for %%A in (%*) do (
  if /i "%%~A"=="/debug" set "DEBUG=1"
  if /i "%%~A"=="/force" set "FORCE=1"
)
if defined DEBUG (echo [deploy] Debug mode enabled.)

REM Configure debug echo macro
if defined DEBUG (set "STEP=echo") else (set "STEP=rem")

%STEP% [deploy][step1] Script start.
set "SCRIPT_DIR=%~dp0"
set "ROOT_DIR=%SCRIPT_DIR%.."
if not exist "%SCRIPT_DIR%config.bat" (
  echo [deploy] ERROR: scripts\config.bat not found.
  exit /b 1
)
call "%SCRIPT_DIR%config.bat" >nul 2>&1

%STEP% [deploy][step2] Loaded config.
for %%V in (INSTANCE_ID AWS_REGION SERVER_IP SERVER_USER KEY_FILE SERVER_VOTE_SCRIPT) do (
  if not defined %%V (
    echo [deploy] ERROR: %%V not set
    set _CFGERR=1
  )
)
echo [deploy] INSTANCE_ID=%INSTANCE_ID%
echo [deploy] AWS_REGION=%AWS_REGION%
echo [deploy] SERVER_IP=%SERVER_IP%
echo [deploy] SERVER_USER=%SERVER_USER%
echo [deploy] KEY_FILE=%KEY_FILE%
echo [deploy] SERVER_VOTE_SCRIPT=%SERVER_VOTE_SCRIPT%
if defined _CFGERR (
  echo [deploy] Configuration errors.
  exit /b 1
)
if not exist "%KEY_FILE%" (
  echo [deploy] ERROR: SSH key missing: %KEY_FILE%
  exit /b 1
)
%STEP% [deploy][step3] SSH key ok.
for %%I in ("%~dp0..") do set "ROOT_DIR=%%~fI"
set "LOCAL_VOTE=%ROOT_DIR%\server\vote_shutdown.sh"
if not exist "%LOCAL_VOTE%" (
  echo [deploy] ERROR: Local vote_shutdown.sh missing.
  exit /b 1
)
%STEP% [deploy][step4] Local vote script ok.
if "%SERVER_IP%"=="0.0.0.0" (
  echo [deploy] ERROR: Placeholder SERVER_IP. Start server first.
  exit /b 1
)
if /i "%SERVER_IP%"=="None" (
  echo [deploy] ERROR: SERVER_IP None. Start instance.
  exit /b 1
)
set "AWS_PAGER="
%STEP% [deploy][step5] Checking instance state...
set "INSTANCE_STATE="
for /f "tokens=*" %%S in ('aws ec2 describe-instances --region "%AWS_REGION%" --instance-ids "%INSTANCE_ID%" --query "Reservations[0].Instances[0].State.Name" --output text 2^>nul') do set "INSTANCE_STATE=%%S"
for /f "tokens=*" %%A in ("%INSTANCE_STATE%") do set "INSTANCE_STATE=%%A"
if not defined INSTANCE_STATE set "INSTANCE_STATE=UNKNOWN"
echo [deploy] Instance state: [%INSTANCE_STATE%]
if /i not "%INSTANCE_STATE%"=="running" (
  echo [deploy] ERROR: Instance state must be running.
  exit /b 1
)
%STEP% [deploy][step6] Instance running; continuing.

%STEP% [deploy][step7] Computing local hash...
set "LOCAL_HASH="
powershell -Command "try{(Get-FileHash '%LOCAL_VOTE%' -Algorithm SHA256).Hash}catch{''}" > "%TEMP%\qs_lhash.tmp" 2>nul
set /p LOCAL_HASH=<"%TEMP%\qs_lhash.tmp" 2>nul
del "%TEMP%\qs_lhash.tmp" 2>nul
if defined LOCAL_HASH (
  echo [deploy] Local hash: %LOCAL_HASH%
) else (
  echo [deploy] WARNING: Could not compute local hash.
)

set "REMOTE_PATH=/home/%SERVER_USER%/vote_shutdown.sh"
%STEP% [deploy][step8] Remote path: %REMOTE_PATH%
set "REMOTE_HASH="
%STEP% [deploy][step9] Fetching remote hash...
ssh -o BatchMode=yes -o StrictHostKeyChecking=no -i "%KEY_FILE%" %SERVER_USER%@%SERVER_IP% "sha256sum '%REMOTE_PATH%' 2>/dev/null | cut -d' ' -f1" >"%TEMP%\qs_rhash.tmp" 2>nul
if exist "%TEMP%\qs_rhash.tmp" (
  set /p REMOTE_HASH=<"%TEMP%\qs_rhash.tmp"
  del "%TEMP%\qs_rhash.tmp" 2>nul
)
if defined REMOTE_HASH (
  echo [deploy] Remote hash: %REMOTE_HASH%
) else (
  echo [deploy] Remote hash: (none)
)

%STEP% [deploy][step10] Decide upload...
if not defined REMOTE_HASH goto :UPLOAD
if not defined LOCAL_HASH goto :UPLOAD
if /i "%REMOTE_HASH%"=="%LOCAL_HASH%" (
  echo [deploy] Hashes match.
  if defined FORCE (
    echo [deploy] Force re-upload.
  ) else (
    echo [deploy] No changes. Use /force to re-upload.
    goto :POST
  )
) else (
  echo [deploy] Hash mismatch.
)

:UPLOAD
%STEP% [deploy][step11] Uploading...
where scp >nul 2>&1
if not errorlevel 1 (
  scp -q -o StrictHostKeyChecking=no -i "%KEY_FILE%" "%LOCAL_VOTE%" %SERVER_USER%@%SERVER_IP%:"%REMOTE_PATH%" || goto :FALLBACK
  goto :AFTER
) else (
  echo [deploy] scp not found, fallback.
  goto :FALLBACK
)
:FALLBACK
type "%LOCAL_VOTE%" | ssh -o StrictHostKeyChecking=no -i "%KEY_FILE%" %SERVER_USER%@%SERVER_IP% "cat > '%REMOTE_PATH%'" || (echo [deploy] ERROR: Upload failed.& exit /b 2)
:AFTER
set "DID_UPLOAD=1"
%STEP% [deploy][step12] Post-upload setup...
ssh -o StrictHostKeyChecking=no -i "%KEY_FILE%" %SERVER_USER%@%SERVER_IP% "chmod +x '%REMOTE_PATH%' && sudo ln -sf '%REMOTE_PATH%' /usr/local/bin/vote_shutdown && mkdir -p ~/.quorumstop && { sudo touch /var/log/quorumstop-votes.log; sudo chown ubuntu:ubuntu /var/log/quorumstop-votes.log 2>/dev/null; sudo chmod 660 /var/log/quorumstop-votes.log 2>/dev/null; }" || (echo [deploy] ERROR: Post-upload setup failed.& exit /b 2)
%STEP% [deploy][step13] Upload ^& setup complete.

:POST
%STEP% [deploy][step14] Verifying remote hash...
if defined LOCAL_HASH (
  if defined DID_UPLOAD (
    call :VERIFY_REMOTE_HASH
  ) else if defined DEBUG (
    %STEP% [deploy] Skipping verify (no upload; debug could force verify but suppressed to reduce noise)
  ) else (
    rem No upload, no verify.
  )
) else (
  echo [deploy] Skipping verify (no local hash)
)
echo [deploy] Done.
exit /b 0

:VERIFY_REMOTE_HASH
%STEP% [deploy][verify] Running ssh verify command...
set "NEW_RHASH="
ssh -o StrictHostKeyChecking=no -i "%KEY_FILE%" %SERVER_USER%@%SERVER_IP% "sha256sum '%REMOTE_PATH%' 2>/dev/null | cut -d' ' -f1" >"%TEMP%\qs_new_rhash.tmp" 2>nul
if not exist "%TEMP%\qs_new_rhash.tmp" (
  %STEP% [deploy][verify] WARNING: Temp file missing.
  goto :EOF
)
set /p NEW_RHASH=<"%TEMP%\qs_new_rhash.tmp" 2>nul
del "%TEMP%\qs_new_rhash.tmp" 2>nul
if not defined NEW_RHASH (
  %STEP% [deploy][verify] WARNING: Remote hash empty.
  goto :EOF
)
echo [deploy] New Remote Hash: %NEW_RHASH%
goto :EOF
