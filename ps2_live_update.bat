@echo off

rem Configurable Directories
rem This Batch file should work across most of SOE's games.
rem Tested on Planetside 2 and H1Z1.
set gameDir=C:\Program Files (x86)\Steam\SteamApps\common\PlanetSide 2
set gameDataDir=C:\Users\Jhett\My Projects\SOE Version Tracker\Repos\Planetside 2 Live\gamedata
set toolDataDir=C:\Users\Jhett\My Projects\SOE Version Tracker\Repos\Planetside 2 Live\tooldata

set toolsDir=C:\Users\Jhett\My Projects\SOE Version Tracker\Tools

rem Things below here should not need to be edited.
rem --------------------------------------------------------------

set assetSource=%gameDataDir%\Resources\Assets
set localeSource=%gameDataDir%\Locale
set luaSource=%gameDataDir%\UI

rem Tool Dirs
set soePackDir=%toolsDir%\soe-pack
set soeLocaleDir=%toolsDir%\soe-locale
set unluacDir=%toolsDir%\unluac

rem Asset Dirs
set manifestOutput=%toolDataDir%\manifests
set assetOutput=%toolDataDir%\assets
set diffOutput=%toolDataDir%\assets\diff

rem Locale Dir
set localeOutput=%toolDataDir%\locale

rem Special Files Dir
set luaOutput=%toolDataDir%\lua
set exeOutput=%toolDataDir%\exe

rem Make Required Dirs
if not exist "%gameDataDir%" mklink /j "%gameDataDir%" "%gameDir%"
if not exist "%toolDataDir%" mkdir "%toolDataDir%"

	rem Assets
if not exist "%manifestOutput%" mkdir "%manifestOutput%"

if not exist "%assetOutput%" (
	mkdir "%assetOutput%

	echo ---------------------------------------------------------
	echo Assets have not been extracted yet.
	echo The tool will now extract all assets.
	echo This is a first time process and may take some time...
	echo ---------------------------------------------------------

	node "%soePackDir%\packer.js" extractall "%assetSource%" "%assetOutput%"
)

if exist "%diffOutput%" rmdir "%diffOutput%" /s/q
mkdir "%diffOutput%"

	rem Locale
if exist "%localeOutput%" rmdir "%localeOutput%" /s/q
mkdir "%localeOutput%"

	rem Special Files
if exist "%luaOutput%" rmdir "%luaOutput%" /s/q
mkdir "%luaOutput%"
if exist "%exeOutput%" rmdir "%exeOutput%" /s/q
mkdir "%exeOutput%"

echo ---------------------------------------------------------
echo Started Game Data Analysis.
echo Updating Manifests...
echo ---------------------------------------------------------

	if exist "%manifestOutput%\manifest_latest.txt" (
		echo Moving 'latest' manifest to 'previous'
		move "%manifestOutput%\manifest_latest.txt" "%manifestOutput%\manifest_previous.txt"
	)
	
	if exist "%manifestOutput%\diff_latest.json" (
		echo Moving 'latest' diff to 'previous'
		move "%manifestOutput%\diff_latest.json" "%manifestOutput%\diff_previous.json"
	)
	
	echo Generating new manifest
	node "%soePackDir%\packer.js" manifest "%assetSource%" "%manifestOutput%\manifest_latest.txt"
	
	if exist "%manifestOutput%\manifest_latest.txt" (
		echo Generating new diff from 'previous' to 'latest'
		node "%soePackDir%\packer.js" diff "%manifestOutput%\manifest_previous.txt" "%manifestOutput%\manifest_latest.txt" "%manifestOutput%\diff_latest.json"
	)

echo ---------------------------------------------------------
echo Manifest Update Complete!
echo Extracting Diff Files...
echo ---------------------------------------------------------

	node "%soePackDir%\packer.js" extractdiff "%manifestOutput%\diff_latest.json" "%assetSource%" "%diffOutput%"
	xcopy "%diffOutput%" "%assetOutput%" /y

echo ---------------------------------------------------------
echo Diff Extraction Complete!
echo Converting Locale Files...
echo ---------------------------------------------------------

	for %%f in ("%localeSource%\*.dat") do (
		node "%soeLocaleDir%\locale.js" parse "%localeSource%\%%~nf.dat" "%localeSource%\%%~nf.dir" "%localeOutput%\%%~nf.json"
	)

echo ---------------------------------------------------------
echo Locale Conversion Complete!
echo Converting LUA Scripts...
echo ---------------------------------------------------------

	java -jar "%unluacDir%\unluac.jar" "%luaSource%\ScriptsBase.bin" > "%luaOutput%\ScriptsBase.lua"
	java -jar "%unluacDir%\unluac.jar" "%luaSource%\ScriptsBase_x64.bin" > "%luaOutput%\ScriptsBase_x64.lua"
	
echo ---------------------------------------------------------
echo LUA Conversion Complete!
echo Converting exe's...
echo ---------------------------------------------------------

	for %%f in ("%gameDataDir%\*.exe") do (
		if exist "%exeOutput%\%%~nf.txt" del "%exeOutput%\%%~nf.txt"
		"%toolsDir%\strings.exe" -a -q -n 6 "%gameDataDir%\%%~nf.exe" >> "%exeOutput%\%%~nf.txt"
	)

echo ---------------------------------------------------------
echo Exe Conversion Complete!
echo Game Analysis Complete!
echo ---------------------------------------------------------

PAUSE