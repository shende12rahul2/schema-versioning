@echo off
REM Simple wrapper around the Flyway command line (Windows).
REM Run from anywhere:  tools\db <command> [args]
REM Type "tools\db help" for the list of commands.
setlocal EnableDelayedExpansion

cd /d "%~dp0.."

set "CMD=%~1"
if "%CMD%"=="" set "CMD=help"

if /i "%CMD%"=="new"      goto :new
if /i "%CMD%"=="migrate"  goto :simple
if /i "%CMD%"=="info"     goto :simple
if /i "%CMD%"=="validate" goto :simple
if /i "%CMD%"=="reset"    goto :reset
if /i "%CMD%"=="baseline" goto :baseline
if /i "%CMD%"=="repair"   goto :repair
goto :help

:new
if "%~3"=="" (
  echo Usage: tools\db new ^<TICKET^> ^<description^>
  exit /b 1
)
set "TICKET=%~2"
set "TICKET=!TICKET:-=!"
set "DESC="
shift
shift
:descloop
if "%~1"=="" goto :descdone
if defined DESC (set "DESC=!DESC!_%~1") else (set "DESC=%~1")
shift
goto :descloop
:descdone
for /f %%i in ('powershell -NoProfile -Command "Get-Date -Format yyyyMMddHHmmss"') do set "TS=%%i"
set "FILE=db\migrations\versioned\V!TS!__!TICKET!_!DESC!.sql"
(
  echo -- Ticket : !TICKET!
  echo -- Purpose: !DESC!
  echo -- V file: runs ONCE. Never edit after merge - create a new V file instead.
  echo.
) > "!FILE!"
echo Created !FILE!
exit /b 0

:simple
if "%~2"=="" (
  echo Usage: tools\db %CMD% ^<env^>
  exit /b 1
)
call :flyway %~2 %CMD%
exit /b %ERRORLEVEL%

:reset
echo This WIPES your personal schema and rebuilds it from Git.
call :flyway personal clean || exit /b 1
call :flyway personal migrate
exit /b %ERRORLEVEL%

:baseline
if "%~2"=="" (
  echo Usage: tools\db baseline ^<env^>
  exit /b 1
)
call :flyway %~2 baseline -baselineVersion=1 "-baselineDescription=initial schema"
exit /b %ERRORLEVEL%

:repair
if "%~2"=="" (
  echo Usage: tools\db repair ^<env^>
  exit /b 1
)
echo repair only fixes Flyway's history table. It does NOT undo SQL.
set /p "OK=Have you undone any partial changes by hand? (yes/no) "
if /i not "!OK!"=="yes" (
  echo Cancelled.
  exit /b 1
)
call :flyway %~2 repair
exit /b %ERRORLEVEL%

:flyway
set "ENVNAME=%~1"
set "CONF=conf\env\%ENVNAME%.conf"
if not exist "%CONF%" (
  echo ERROR: %CONF% not found.
  if /i "%ENVNAME%"=="personal" echo Copy conf\env\personal.conf.example to conf\env\personal.conf first.
  exit /b 1
)
echo ^>^> Environment: %ENVNAME%
shift
call flyway "-configFiles=conf/flyway.conf,%CONF:\=/%" %1 %2 %3
exit /b %ERRORLEVEL%

:help
echo Usage: tools\db ^<command^> [args]
echo.
echo   new ^<TICKET^> ^<description^>   Create a new versioned (V) file with a timestamp
echo   migrate ^<env^>                Apply pending changes (env = personal ^| dev ^| ...)
echo   info ^<env^>                   Show what has run and what is pending
echo   validate ^<env^>               Check Git files against what already ran
echo   reset                        PERSONAL schema only: wipe it and rebuild from Git
echo   baseline ^<env^>               ONE TIME, existing database: mark it as "already at V1"
echo   repair ^<env^>                 Fix the history table after a failed run (see docs)
echo.
echo Password: set FLYWAY_PASSWORD before running. It is never stored in Git.
exit /b 0
