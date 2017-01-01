::author "Zaratusa"
::Script to update the thumbnail on GMod Workshop items,
::it uses image.jpg in the current directory as the new thumbnail

@echo off
for /f "tokens=1,2*" %%E in ('reg query HKEY_CURRENT_USER\Software\Valve\Steam') do if %%E==SteamExe call :save %%G
:save
	set STEAMPATH=%1
	call set STEAMPATH=%%STEAMPATH:%~nx1=%%

:start
set /p ID="On which Workshop ID do you want to update the thumbnail?: "

%STEAMPATH%steamapps/common/GarrysMod/bin/gmpublish.exe update -icon ""%CD%\image.jpg"" -id "%ID%"

echo.
goto :start
