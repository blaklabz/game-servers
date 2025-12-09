@echo off
setlocal

rem ============================
rem EDIT THESE VALUES
rem ============================
set "STEAMCMD_DIR=C:\Users\enshrouded\Downloads\steamcmd"
set "SERVER_DIR=C:\Users\enshrouded\Downloads\steamcmd\enshrouded_server"
set "APPID=2278520"
set "WEBHOOK_URL=""
rem ============================

rem ---- Notify Discord: update starting ----
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$wh = '%WEBHOOK_URL%';" ^
  "$body = '{\"content\":\"Enshrouded update starting at %date% %time%.\"}';" ^
  "Invoke-RestMethod -Uri $wh -Method Post -ContentType 'application/json' -Body $body"

echo Requesting graceful shutdown of Enshrouded server...

rem Try soft kill first (no /F)
taskkill /IM enshrouded_server.exe >nul 2>&1

rem Wait up to 20 seconds for it to exit cleanly
timeout /t 20 /nobreak >nul

rem Check if it's still running
tasklist /FI "IMAGENAME eq enshrouded_server.exe" | find /I "enshrouded_server.exe" >nul
if %ERRORLEVEL%==0 (
    echo Server still running, forcing shutdown...
    taskkill /IM enshrouded_server.exe /F >nul 2>&1
) else (
    echo Server exited cleanly.
)

echo Running SteamCMD update...
"%STEAMCMD_DIR%\steamcmd.exe" ^
  +force_install_dir "%SERVER_DIR%" ^
  +login anonymous ^
  +app_update %APPID% validate ^
  +quit

echo Starting Enshrouded server...
start "" "%SERVER_DIR%\enshrouded_server.exe"

rem ---- Notify Discord: update finished ----
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$wh = '%WEBHOOK_URL%';" ^
  "$body = '{\"content\":\"Enshrouded update finished at %date% %time%.\"}';" ^
  "Invoke-RestMethod -Uri $wh -Method Post -ContentType 'application/json' -Body $body"

endlocal
