@echo off
REM lib_update_config.bat - SERVER_IP updater with dedupe
REM Usage: call lib_update_config.bat :SET_IP 1.2.3.4 [/quiet] [/debug]
if /i "%1"==":SET_IP" shift & goto DO_SET
if /i "%1"==":UPDATE_CONFIG" shift & goto DO_SET
goto :eof

:DO_SET
setlocal EnableDelayedExpansion
set "NEW_IP=%~1"
shift
:FLAGS
if "%~1"=="" goto GOT_FLAGS
if /i "%~1"=="/quiet"  (set QUIET=1 & shift & goto FLAGS)
if /i "%~1"=="/silent" (set QUIET=1 & shift & goto FLAGS)
if /i "%~1"=="/debug"  (set DEBUG=1 & shift & goto FLAGS)
shift & goto FLAGS
:GOT_FLAGS
if not defined NEW_IP (if not defined QUIET echo [update] ERROR: Missing IP & endlocal & exit /b 1)
for %%Z in ("%~dp0") do set "_RAW_DIR=%%~fZ"
if exist "%CD%\scripts\config.bat" (
  set "SCRIPT_DIR=%CD%\scripts\"
) else (
  set "SCRIPT_DIR=%_RAW_DIR%"
)
if /i "%SCRIPT_DIR%"=="C:\" if exist "%CD%\scripts\config.bat" set "SCRIPT_DIR=%CD%\scripts\"
set "TARGET=%SCRIPT_DIR%config.bat"
if defined DEBUG echo [update][debug] SCRIPT_DIR=%SCRIPT_DIR% TARGET=%TARGET% NEW_IP=%NEW_IP%
if not exist "%TARGET%" (if not defined QUIET echo [update] ERROR: config.bat not found & endlocal & exit /b 2)
set "TMP=%TARGET%.tmp__"
set "UPDATED="

REM First, create a clean version by removing all SERVER_IP lines
(
  for /f "usebackq delims=" %%L in ("%TARGET%") do (
    echo %%L | findstr /i /b /c:"set SERVER_IP=" >nul
    if !errorlevel! NEQ 0 (
      echo %%L
    )
  )
)>"%TMP%.clean" || (if not defined QUIET echo [update] ERROR: Clean temp write failed & del "%TMP%.clean" 2>nul & endlocal & exit /b 3)

REM Then, add the SERVER_IP line back in the right place
set "FOUND_COMMENT="
(
  for /f "usebackq delims=" %%L in ("%TMP%.clean") do (
    echo %%L
    echo %%L | findstr /i /c:"Server Connection (Dynamic)" >nul
    if !errorlevel! EQU 0 (
      echo set SERVER_IP=%NEW_IP%
      set "FOUND_COMMENT=1"
    )
  )
)>"%TMP%" || (if not defined QUIET echo [update] ERROR: Final temp write failed & del "%TMP%" 2>nul & del "%TMP%.clean" 2>nul & endlocal & exit /b 3)

del "%TMP%.clean" 2>nul
if not defined FOUND_COMMENT (if not defined QUIET echo [update] ERROR: Comment marker not found & del "%TMP%" 2>nul & endlocal & exit /b 5)
set "UPDATED=1"
move /y "%TMP%" "%TARGET%" >nul 2>&1 || (if not defined QUIET echo [update] ERROR: Replace failed & del "%TMP%" 2>nul & endlocal & exit /b 4)
if not defined UPDATED (if not defined QUIET echo [update] WARNING: SERVER_IP line not found - no change & endlocal & exit /b 5)
if not defined QUIET echo [update] SERVER_IP updated to %NEW_IP%
if defined DEBUG for /f "tokens=1,* delims==" %%A in ('findstr /i /b /c:"set SERVER_IP=" "%TARGET%"') do echo [update][debug] Verified SERVER_IP=%%B
endlocal & exit /b 0
