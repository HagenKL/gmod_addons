::author "Zaratusa"
::Script to copy files from the current directory to a gmod_addons folder on the desktop
::using a recipe with a given name, use TargetCreator.bat to create the recipe

@echo off
setlocal enabledelayedexpansion

:start
set /p TARGET="Which addon files do you want to collect next?: "

for /f "tokens=1,2" %%i in (%CD%\targets\%TARGET%.txt) do (
	if "%%j"=="" (call :process %%i %%i) else (call :process %%i %%j)
)

echo Finished collecting files from %TARGET%.txt...
goto :start

:process
	set SOURCE=%1
	set DESTINATION=%2
	call set DESTINATION=%%DESTINATION:%~nx2=%%
	xcopy /s /v /y /q %CD%\..\%SOURCE% %UserProfile%\Desktop\gmod_addons\%TARGET%\%DESTINATION% >> nul
