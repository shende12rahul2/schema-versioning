@echo off
REM Local practice lab helper (Windows). See local\README.md.
REM   local\lab up | down | status | sql <schema> [file] | compare | apply <NN> [fix] | restore
setlocal EnableDelayedExpansion

cd /d "%~dp0.."
set "COMPOSE=docker compose -f local/docker-compose.yml"
set "CONTAINER=schema-lab"
set "PW=Lab_Passw0rd"
set "CONN=//localhost:1521/FREEPDB1"

set "CMD=%~1"
if "%CMD%"=="" goto :help
if /i "%CMD%"=="up"      goto :up
if /i "%CMD%"=="down"    goto :down
if /i "%CMD%"=="status"  goto :status
if /i "%CMD%"=="sql"     goto :sql
if /i "%CMD%"=="compare" goto :compare
if /i "%CMD%"=="apply"   goto :apply
if /i "%CMD%"=="restore" goto :restore
goto :help

:up
%COMPOSE% up -d || exit /b 1
echo Waiting for the database (first start: a few minutes)...
:waitloop
docker logs %CONTAINER% 2>&1 | findstr /C:"DATABASE IS READY TO USE" >nul && goto :ready
docker logs %CONTAINER% 2>&1 | findstr /B /C:"ORA-" /C:"SP2-" >nul && (
  echo Setup error - check: docker logs %CONTAINER%
  exit /b 1
)
timeout /t 5 /nobreak >nul
goto :waitloop
:ready
REM After a restart the old "ready" line is still in the log: also wait for a real connection.
echo SELECT 'DB_UP' FROM dual; | docker exec -i %CONTAINER% sqlplus -s -L system/%PW%@%CONN% 2>nul | findstr /C:"DB_UP" >nul && goto :connected
timeout /t 3 /nobreak >nul
goto :ready
:connected
echo Lab is ready. LEGACY_DEV has the legacy schema, DEVELOPER_DB is empty.
exit /b 0

:down
%COMPOSE% down -v
exit /b %ERRORLEVEL%

:status
%COMPOSE% ps
exit /b %ERRORLEVEL%

:sql
if "%~2"=="" (
  echo Usage: local\lab sql ^<legacy_dev^|developer_db^|system^> [file]
  exit /b 1
)
if "%~3"=="" (
  docker exec -it %CONTAINER% sqlplus -L %~2/%PW%@%CONN%
) else (
  docker exec -i %CONTAINER% sqlplus -s -L %~2/%PW%@%CONN% < "%~3"
)
exit /b %ERRORLEVEL%

:compare
docker exec -i %CONTAINER% sqlplus -s -L system/%PW%@%CONN% < local\sql\compare_schemas.sql
exit /b %ERRORLEVEL%

:apply
if "%~2"=="" (
  echo Usage: local\lab apply ^<NN^> [fix]
  exit /b 1
)
set "SC="
for /d %%D in ("local\scenarios\%~2_*") do set "SC=local\scenarios\%%~nxD"
if not defined SC (
  echo No scenario %~2 in local\scenarios\
  exit /b 1
)
set "SRC=!SC!\migrations"
if /i "%~3"=="fix" set "SRC=!SC!\fix\migrations"
if exist "!SRC!" xcopy /E /Y /I "!SRC!" db\migrations >nul
if exist "!SRC!" echo Copied files from !SRC!
if /i not "%~3"=="fix" if exist "!SC!\delete.txt" (
  for /f "usebackq delims=" %%F in ("!SC!\delete.txt") do (
    set "P=%%F"
    set "P=!P:/=\!"
    if exist "!P!" del "!P!" && echo Deleted !P!
  )
)
echo Applied !SC! %~3
exit /b 0

:restore
echo This removes ALL uncommitted changes and new files under db\migrations\.
set /p "OK=Continue? (yes/no) "
if /i not "!OK!"=="yes" (
  echo Cancelled.
  exit /b 1
)
git checkout -- db/migrations
git clean -fd -- db/migrations
exit /b %ERRORLEVEL%

:help
echo Usage: local\lab ^<command^>
echo.
echo   up                    Start the lab database (first start loads db\legacy, 2-5 min)
echo   down                  Stop the lab and DELETE its data (next "up" starts fresh)
echo   status                Show whether the lab database is running
echo   sql ^<schema^> [file]   Open SQL*Plus as legacy_dev ^| developer_db ^| system (or run a file)
echo   compare               Compare LEGACY_DEV ("shared Dev") with DEVELOPER_DB ("fresh install")
echo   apply ^<NN^> [fix]      Copy scenario NN's files into db\migrations (see local\README.md)
echo   restore               Put db\migrations back exactly as it is in Git
echo.
echo For Flyway commands use tools\db with env local-dev or local-developer,
echo after: set FLYWAY_PASSWORD=Lab_Passw0rd
exit /b 0
