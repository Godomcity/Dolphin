@echo off
setlocal

cd /d C:\Users\wodyd\Project\Dolphin

for %%P in (Hub Lobby Stage1 Stage2 Stage3 Stage4 Stage5) do (
  echo.
  echo ===== [%%P] write project.json + delete _port =====

  if not exist "places\%%P" mkdir "places\%%P"

  > "places\%%P\%%P.project.json" (
    echo {
    echo   "name": "%%P",
    echo   "tree": {
    echo     "$className": "DataModel",
    echo     "ReplicatedStorage": { "$path": "src/ReplicatedStorage" },
    echo     "ServerScriptService": { "$path": "src/ServerScriptService" },
    echo     "StarterPlayer": { "$path": "src/StarterPlayer" },
    echo     "StarterGui": { "$path": "src/StarterGui" }
    echo   }
    echo }
  )

  echo [OK] places\%%P\%%P.project.json

  if exist "places\%%P\_port" (
    rmdir /S /Q "places\%%P\_port"
    echo [DEL] places\%%P\_port
  ) else (
    echo [SKIP] places\%%P\_port 없음
  )
)

echo.
echo All done.
endlocal
