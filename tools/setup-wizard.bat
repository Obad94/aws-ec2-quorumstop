@echo off
setlocal EnableExtensions EnableDelayedExpansion

REM Updated AWS EC2 QuorumStop - Setup Wizard (team info + correct YOUR_IP mapping)

set "SCRIPT_DIR=%~dp0..\scripts\"
set "CONFIG_FILE=%SCRIPT_DIR%config.bat"

echo ============================================
echo AWS EC2 QuorumStop - Setup Wizard
echo ============================================
echo This wizard will create or update scripts\config.bat
echo Press Ctrl+C at any time to abort.
echo.

aws --version >nul 2>&1 && echo (AWS CLI detected) || echo (AWS CLI not detected - you can still proceed)
echo.

if /i "%~1"=="--auto" goto AUTO_MODE

if exist "%CONFIG_FILE%" (
  echo Existing config.bat found. Creating backup...
  copy /y "%CONFIG_FILE%" "%CONFIG_FILE%.bak" >nul
  echo Backup: config.bat.bak
  call "%CONFIG_FILE%" >nul 2>&1
  echo.
  echo Current values shown in brackets. Press Enter to keep.
)

set /p INSTANCE_ID_IN=EC2 Instance ID [%INSTANCE_ID%]: 
if not defined INSTANCE_ID_IN set INSTANCE_ID_IN=%INSTANCE_ID%
:CHK_IID
if not defined INSTANCE_ID_IN (
  echo Instance ID required.
  set /p INSTANCE_ID_IN=EC2 Instance ID: 
  goto CHK_IID
)

set /p AWS_REGION_IN=AWS Region [%AWS_REGION%]: 
if not defined AWS_REGION_IN set AWS_REGION_IN=%AWS_REGION%
if not defined AWS_REGION_IN set AWS_REGION_IN=us-west-2

set /p KEY_FILE_IN=SSH private key path [%KEY_FILE%]: 
if not defined KEY_FILE_IN set KEY_FILE_IN=%KEY_FILE%
if not exist "%KEY_FILE_IN%" echo WARNING: Key file not found now.

set /p SERVER_USER_IN=SSH user (ubuntu/ec2-user) [%SERVER_USER%]: 
if not defined SERVER_USER_IN set SERVER_USER_IN=%SERVER_USER%
if not defined SERVER_USER_IN set SERVER_USER_IN=ubuntu

set /p VOTE_SCRIPT_IN=Vote script path [/home/%SERVER_USER_IN%/vote_shutdown.sh]: 
if not defined VOTE_SCRIPT_IN set VOTE_SCRIPT_IN=/home/%SERVER_USER_IN%/vote_shutdown.sh

echo.
echo Enter team member IPs (blank to finish). After each IP you can enter a name.
set COUNT=0
for /l %%n in (1,1,50) do (
  set "TMP_IP="
  set "TMP_NAME="
  set /p TMP_IP=DEV%%n_IP: 
  set "_TRIM=!TMP_IP: =!"
  if "!TMP_IP!"=="" goto END_IP_LOOP
  if "!_TRIM!"=="" goto END_IP_LOOP
  set "DEV%%n_IP=!TMP_IP: =!"
  set /p TMP_NAME=  Name for %%n (^default Dev%%n^): 
  if not defined TMP_NAME set "TMP_NAME=Dev%%n"
  set "DEV%%n_NAME=!TMP_NAME!"
  set /a COUNT+=1
)
:END_IP_LOOP
if %COUNT%==0 echo (No team IPs entered)

echo.
set /p YOUR_NAME_IN=Your display name [%YOUR_NAME%]: 
if not defined YOUR_NAME_IN set YOUR_NAME_IN=%YOUR_NAME%
if not defined YOUR_NAME_IN set YOUR_NAME_IN=Developer1

:CHOOSE_YOUR_IP
echo Select your IP (enter number, full IP, or DEVn / DEVn_IP label):
echo   Examples: 1   203.0.113.42   DEV1   DEV1_IP
set IDX=0
for /L %%n in (1,1,%COUNT%) do (
  set CUR_NAME=
  set "CUR_IP=!DEV%%n_IP!"
  set "CUR_NAME=!DEV%%n_NAME!"
  if not defined CUR_NAME set CUR_NAME=Dev%%n
  echo   %%n. !CUR_IP! (!CUR_NAME!^)
)
set /p SEL=Your IP: 
set "SEL=%SEL: =%"
set "YOUR_IP_IN="
set "YOUR_NAME_SELECTED="
if not defined SEL goto CHOOSE_YOUR_IP

REM 1) Numeric index selection
set "NONNUM="
for /f "delims=0123456789" %%c in ("!SEL!") do set NONNUM=1
if not defined NONNUM (
  for /f "tokens=*" %%i in ("!SEL!") do set /a IDX_TEST=%%i
  if !IDX_TEST! GEQ 1 if !IDX_TEST! LEQ !COUNT! (
    call set "YOUR_IP_IN=%%DEV!IDX_TEST!_IP%%"
    call set "YOUR_NAME_SELECTED=%%DEV!IDX_TEST!_NAME%%"
  )
)

REM 2) DEVn / DEVn_IP label
if not defined YOUR_IP_IN (
  set "TMP=!SEL:_IP=!"
  if /i "!TMP:~0,3!"=="DEV" (
    set "NUM=!TMP:~3!"
    set "NONNUM2="
    for /f "delims=0123456789" %%c in ("!NUM!") do set NONNUM2=1
    if not defined NONNUM2 (
      call set "YOUR_IP_IN=%%DEV!NUM!_IP%%"
      call set "YOUR_NAME_SELECTED=%%DEV!NUM!_NAME%%"
    )
  )
)

REM 3) Full IP match
if not defined YOUR_IP_IN (
  for /L %%n in (1,1,!COUNT!) do (
    call if /i "!SEL!"=="%%DEV%%n_IP%%" (
      set "YOUR_IP_IN=!SEL!"
      call set "YOUR_NAME_SELECTED=%%DEV%%n_NAME%%"
    )
  )
)

REM 4) Fallback: treat as custom IP
if not defined YOUR_IP_IN set "YOUR_IP_IN=!SEL!"

if not defined YOUR_IP_IN goto CHOOSE_YOUR_IP
if defined YOUR_NAME_SELECTED set "YOUR_NAME_IN=%YOUR_NAME_SELECTED%"

echo Selected IP: !YOUR_IP_IN!  (Name: !YOUR_NAME_IN!)

call :WRITE_CONFIG "%INSTANCE_ID_IN%" "%AWS_REGION_IN%" "%KEY_FILE_IN%" "%SERVER_USER_IN%" "%VOTE_SCRIPT_IN%" "%YOUR_NAME_IN%" "%YOUR_IP_IN%" "%COUNT%"
echo.
echo SUCCESS: config.bat created/updated.
echo Next:
echo   scripts\test_aws.bat
echo   scripts\start_server.bat
echo   Install server vote script (add IP->Name mappings there)
exit /b 0

:AUTO_MODE
if not defined QS_INSTANCE_ID echo ERROR: --auto requires QS_INSTANCE_ID & exit /b 1
if not defined QS_REGION set QS_REGION=us-west-2
if not defined QS_SSH_USER set QS_SSH_USER=ubuntu
if not defined QS_VOTE_SCRIPT set QS_VOTE_SCRIPT=/home/%QS_SSH_USER%/vote_shutdown.sh
if not defined QS_NAME set QS_NAME=Developer1
if not defined QS_YOUR_IP set QS_YOUR_IP=0.0.0.0
call :WRITE_CONFIG "%QS_INSTANCE_ID%" "%QS_REGION%" "%QS_KEY_FILE%" "%QS_SSH_USER%" "%QS_VOTE_SCRIPT%" "%QS_NAME%" "%QS_YOUR_IP%" "%QS_TEAM_IPS%"
echo Auto mode completed.
exit /b 0

:WRITE_CONFIG
set "W_INSTANCE_ID=%~1"
set "W_REGION=%~2"
set "W_KEY=%~3"
set "W_SSH_USER=%~4"
set "W_VOTE=%~5"
set "W_NAME=%~6"
set "W_YOUR_IP=%~7"
set "W_TEAM_COUNT=%~8"
echo Writing config...
>"%CONFIG_FILE%" echo @echo off
>>"%CONFIG_FILE%" echo REM ============================================
>>"%CONFIG_FILE%" echo REM AWS EC2 QuorumStop - Configuration
>>"%CONFIG_FILE%" echo REM Generated by setup-wizard.bat on %date% %time%
>>"%CONFIG_FILE%" echo REM This file may be auto-updated by scripts\lib_update_config.bat (SERVER_IP changes)
>>"%CONFIG_FILE%" echo REM ============================================
>>"%CONFIG_FILE%" echo.
>>"%CONFIG_FILE%" echo REM AWS Configuration
>>"%CONFIG_FILE%" echo set INSTANCE_ID=%W_INSTANCE_ID: =%
>>"%CONFIG_FILE%" echo set AWS_REGION=%W_REGION%
>>"%CONFIG_FILE%" echo.
>>"%CONFIG_FILE%" echo REM Server Connection ^(Dynamic^)
>>"%CONFIG_FILE%" echo set SERVER_IP=0.0.0.0
>>"%CONFIG_FILE%" echo set KEY_FILE=%W_KEY%
>>"%CONFIG_FILE%" echo.
>>"%CONFIG_FILE%" echo REM Team Count
>>"%CONFIG_FILE%" echo set TEAM_COUNT=%W_TEAM_COUNT%
>>"%CONFIG_FILE%" echo.
>>"%CONFIG_FILE%" echo REM Team IP Mappings and Names
for /L %%n in (1,1,%W_TEAM_COUNT%) do if defined DEV%%n_IP (
  call >>"%CONFIG_FILE%" echo set DEV%%n_IP=%%DEV%%n_IP%%
  call >>"%CONFIG_FILE%" echo set DEV%%n_NAME=%%DEV%%n_NAME%%
)
>>"%CONFIG_FILE%" echo.
>>"%CONFIG_FILE%" echo REM Current User Configuration
>>"%CONFIG_FILE%" echo set YOUR_NAME=%W_NAME%
>>"%CONFIG_FILE%" echo set YOUR_IP=%W_YOUR_IP%
>>"%CONFIG_FILE%" echo.
>>"%CONFIG_FILE%" echo REM Server Configuration
>>"%CONFIG_FILE%" echo set SERVER_VOTE_SCRIPT=%W_VOTE%
>>"%CONFIG_FILE%" echo set SERVER_USER=%W_SSH_USER%
>>"%CONFIG_FILE%" echo.
>>"%CONFIG_FILE%" echo REM Display Configuration ^(lists team entries^)
>>"%CONFIG_FILE%" echo if "%%1"=="show" ^(
>>"%CONFIG_FILE%" echo   echo ============================================
>>"%CONFIG_FILE%" echo   echo AWS EC2 QuorumStop - Configuration
>>"%CONFIG_FILE%" echo   echo ============================================
>>"%CONFIG_FILE%" echo   echo Instance ID: %%INSTANCE_ID%%
>>"%CONFIG_FILE%" echo   echo Region: %%AWS_REGION%%
>>"%CONFIG_FILE%" echo   echo Server IP: %%SERVER_IP%%
>>"%CONFIG_FILE%" echo   echo SSH Key: %%KEY_FILE%%
>>"%CONFIG_FILE%" echo   echo User: %%SERVER_USER%%
>>"%CONFIG_FILE%" echo   echo.
>>"%CONFIG_FILE%" echo   echo Team Entries:
>>"%CONFIG_FILE%" echo   for /L %%%%n in (1,1,%%TEAM_COUNT%%) do ^(
>>"%CONFIG_FILE%" echo     call echo     DEV%%%%n_IP=%%DEV%%%%n_IP%% ^(%%DEV%%%%n_NAME%%^)
>>"%CONFIG_FILE%" echo   ^)
>>"%CONFIG_FILE%" echo   echo.
>>"%CONFIG_FILE%" echo   echo Current User: %%YOUR_NAME%% (%%YOUR_IP%%)
>>"%CONFIG_FILE%" echo ^)
exit /b 0
