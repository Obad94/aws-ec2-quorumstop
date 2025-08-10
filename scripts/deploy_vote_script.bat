@echo off
setlocal EnableDelayedExpansion
REM =============================================================
REM AWS EC2 QuorumStop - deploy_vote_script.bat (Cleaned)
REM =============================================================
set "SCRIPT_DIR=%~dp0"
set "ROOT_DIR=%SCRIPT_DIR%..\\"
if not exist "%SCRIPT_DIR%config.bat" (echo [deploy] ERROR: scripts\config.bat not found.& exit /b 1)
call "%SCRIPT_DIR%config.bat" >nul 2>&1
REM Validate required vars
for %%V in (INSTANCE_ID AWS_REGION SERVER_IP SERVER_USER KEY_FILE SERVER_VOTE_SCRIPT) do (
  if not defined %%V (
    echo [deploy] ERROR: %%V not set
    set _CFGERR=1
  ) else (
    call echo [deploy] %%V=%%%V%%
  )
)
if defined _CFGERR (echo [deploy] Configuration errors.& exit /b 1)
if not exist "%KEY_FILE%" (echo [deploy] ERROR: SSH key missing: %KEY_FILE% & exit /b 1)
set "LOCAL_VOTE=%ROOT_DIR%server\vote_shutdown.sh"
if not exist "%LOCAL_VOTE%" (echo [deploy] ERROR: Local vote_shutdown.sh missing.& exit /b 1)
if "%SERVER_IP%"=="0.0.0.0" (echo [deploy] ERROR: Placeholder SERVER_IP. Start server first.& exit /b 1)
if /i "%SERVER_IP%"=="None" (echo [deploy] ERROR: SERVER_IP None. Start instance.& exit /b 1)
set "AWS_PAGER="
aws ec2 describe-instances --region "%AWS_REGION%" --instance-ids "%INSTANCE_ID%" --query "Reservations[0].Instances[0].State.Name" --output text >"%TEMP%\deploy_state.txt" 2>&1
set "INSTANCE_STATE="
for /f "tokens=*" %%S in ('type "%TEMP%\deploy_state.txt"') do set "INSTANCE_STATE=%%S"
if /i not "%INSTANCE_STATE%"=="running" (echo [deploy] ERROR: Instance state %INSTANCE_STATE% (must be running). & exit /b 1)
set "LOCAL_HASH="
for /f "tokens=*" %%H in ('powershell -Command "Get-FileHash '%LOCAL_VOTE%' -Algorithm SHA256 | Select -Expand Hash"') do set "LOCAL_HASH=%%H"
set "REMOTE_PATH=/home/%SERVER_USER%/vote_shutdown.sh"
set "REMOTE_HASH="
ssh -o BatchMode=yes -o StrictHostKeyChecking=no -i "%KEY_FILE%" %SERVER_USER%@%SERVER_IP% "sha256sum '%REMOTE_PATH%' 2>/dev/null | cut -d' ' -f1" >"%TEMP%\qs_rhash.tmp" 2>nul
if exist "%TEMP%\qs_rhash.tmp" (set /p REMOTE_HASH=<"%TEMP%\qs_rhash.tmp" & del "%TEMP%\qs_rhash.tmp" 2>nul)
if defined REMOTE_HASH if defined LOCAL_HASH if /i "%REMOTE_HASH%"=="%LOCAL_HASH%" if /i not "%1"=="/force" (
  echo [deploy] No changes (hash match). Use /force to re-upload.
  goto :POST
)
where scp >nul 2>&1 && (
  scp -q -o StrictHostKeyChecking=no -i "%KEY_FILE%" "%LOCAL_VOTE%" %SERVER_USER%@%SERVER_IP%:"%REMOTE_PATH%" || goto :FALLBACK
  goto :AFTER
)
:FALLBACK
type "%LOCAL_VOTE%" | ssh -o StrictHostKeyChecking=no -i "%KEY_FILE%" %SERVER_USER%@%SERVER_IP% "cat > '%REMOTE_PATH%'" || (echo [deploy] ERROR: Upload failed.& exit /b 2)
:AFTER
ssh -o StrictHostKeyChecking=no -i "%KEY_FILE%" %SERVER_USER%@%SERVER_IP% "chmod +x '%REMOTE_PATH%' && sudo ln -sf '%REMOTE_PATH%' /usr/local/bin/vote_shutdown && mkdir -p ~/.quorumstop && { sudo touch /var/log/quorumstop-votes.log; sudo chown ubuntu:ubuntu /var/log/quorumstop-votes.log 2>/dev/null; sudo chmod 660 /var/log/quorumstop-votes.log 2>/dev/null; }" || (echo [deploy] ERROR: Post-upload setup failed.& exit /b 2)
echo [deploy] Upload ^& setup complete.
:POST
if defined LOCAL_HASH ssh -o StrictHostKeyChecking=no -i "%KEY_FILE%" %SERVER_USER%@%SERVER_IP% "sha256sum '%REMOTE_PATH%' 2>/dev/null | cut -d' ' -f1" >"%TEMP%\qs_new_rhash.tmp" 2>nul & if exist "%TEMP%\qs_new_rhash.tmp" (set /p NEW_RHASH=<"%TEMP%\qs_new_rhash.tmp" & del "%TEMP%\qs_new_rhash.tmp" 2>nul & if defined NEW_RHASH echo [deploy] New Remote Hash: %NEW_RHASH%)
exit /b 0
