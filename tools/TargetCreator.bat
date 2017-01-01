::author "Zaratusa"
::Script to create a file list of the files in the directory above this one

@echo off
setlocal enabledelayedexpansion

set TARGETSFOLDER=%CD%\targets
if not exist "%TARGETSFOLDER%" mkdir %TARGETSFOLDER%
cd ..

:start
set /p TARGET="How should the new file be named?: "

for /r %%i in (*) do call :process %%i

echo Finished creating %TARGET%.txt...
goto :start

:process
	set INPUT=%1
	call set INPUT=%%INPUT:!CD!\=%%
	echo %INPUT% | findstr /v ".txt .bat .git LICENSE README" >> %TARGETSFOLDER%\%TARGET%.txt
