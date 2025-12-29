@echo off
setlocal enabledelayedexpansion

cd /d C:\Users\wodyd\Project\Dolphin

set "ROJO=%USERPROFILE%\.rokit\bin\rojo.exe"

:menu
echo.
echo ==============================
echo   Rojo Serve Launcher (7.6.1)
echo ==============================
echo  1) Hub
echo  2) Lobby
echo  3) Stage1
echo  4) Stage2
echo  5) Stage3
echo  6) Stage4
echo  7) Stage5
echo  0) Exit
echo.
set /p CHOICE=Select (0-7): 

if "%CHOICE%"=="1" set "PLACE=Hub"
if "%CHOICE%"=="2" set "PLACE=Lobby"
if "%CHOICE%"=="3" set "PLACE=Stage1"
if "%CHOICE%"=="4" set "PLACE=Stage2"
if "%CHOICE%"=="5" set "PLACE=Stage3"
if "%CHOICE%"=="6" set "PLACE=Stage4"
if "%CHOICE%"=="7" set "PLACE=Stage5"
if "%CHOICE%"=="0" goto :eof

if not defined PLACE (
  echo [ERROR] Invalid choice.
  goto :menu
)

set "PROJ=places\%PLACE%\%PLACE%.project.json"

echo.
echo [INFO] Using: %ROJO%
echo [INFO] Project: %PROJ%

if not exist "%ROJO%" (
  echo [ERROR] Rojo not found: %ROJO%
  pause
  goto :menu
)

if not exist "%PROJ%" (
  echo [ERROR] Project file not found: %PROJ%
  pause
  set "PLACE="
  goto :menu
)

echo.
echo [RUN] %ROJO% serve %PROJ%
echo (Close this window or press Ctrl+C to stop serve.)
echo.

"%ROJO%" serve "%PROJ%"

echo.
echo [INFO] Rojo serve exited.
set "PLACE="
pause
goto :menu
