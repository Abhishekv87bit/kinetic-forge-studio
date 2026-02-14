@echo off
echo ══════════════════════════════════════════════════════════════
echo   FUSION 360 SCRIPT INSTALLER
echo ══════════════════════════════════════════════════════════════
echo.

set FUSION_SCRIPTS=%appdata%\Autodesk\Autodesk Fusion 360\API\Scripts

echo Fusion Scripts folder: %FUSION_SCRIPTS%
echo.

if not exist "%FUSION_SCRIPTS%" (
    echo ERROR: Fusion 360 scripts folder not found!
    echo Please ensure Fusion 360 is installed.
    pause
    exit /b 1
)

echo Creating script folders...

:: SpurGear
if not exist "%FUSION_SCRIPTS%\SpurGear" mkdir "%FUSION_SCRIPTS%\SpurGear"
copy /Y "fusion_spur_gear.py" "%FUSION_SCRIPTS%\SpurGear\SpurGear.py"
echo   [OK] SpurGear

:: Rack (flat)
if not exist "%FUSION_SCRIPTS%\Rack" mkdir "%FUSION_SCRIPTS%\Rack"
copy /Y "fusion_rack.py" "%FUSION_SCRIPTS%\Rack\Rack.py"
echo   [OK] Rack (flat)

:: WavyRack (sinusoidal - with teeth)
if not exist "%FUSION_SCRIPTS%\WavyRack" mkdir "%FUSION_SCRIPTS%\WavyRack"
copy /Y "fusion_wavy_rack.py" "%FUSION_SCRIPTS%\WavyRack\WavyRack.py"
echo   [OK] WavyRack (with teeth)

:: WavyRackBase (sinusoidal - NO teeth, add manually)
if not exist "%FUSION_SCRIPTS%\WavyRackBase" mkdir "%FUSION_SCRIPTS%\WavyRackBase"
copy /Y "fusion_wavy_rack_base.py" "%FUSION_SCRIPTS%\WavyRackBase\WavyRackBase.py"
echo   [OK] WavyRackBase (no teeth - add manually)

:: RodEndBearing
if not exist "%FUSION_SCRIPTS%\RodEndBearing" mkdir "%FUSION_SCRIPTS%\RodEndBearing"
copy /Y "fusion_rod_end_bearing.py" "%FUSION_SCRIPTS%\RodEndBearing\RodEndBearing.py"
echo   [OK] RodEndBearing

:: ConnectingRod
if not exist "%FUSION_SCRIPTS%\ConnectingRod" mkdir "%FUSION_SCRIPTS%\ConnectingRod"
copy /Y "fusion_connecting_rod.py" "%FUSION_SCRIPTS%\ConnectingRod\ConnectingRod.py"
echo   [OK] ConnectingRod

:: RockerBar
if not exist "%FUSION_SCRIPTS%\RockerBar" mkdir "%FUSION_SCRIPTS%\RockerBar"
copy /Y "fusion_rocker_bar.py" "%FUSION_SCRIPTS%\RockerBar\RockerBar.py"
echo   [OK] RockerBar

:: WaveAssembly
if not exist "%FUSION_SCRIPTS%\WaveAssembly" mkdir "%FUSION_SCRIPTS%\WaveAssembly"
copy /Y "fusion_wave_assembly.py" "%FUSION_SCRIPTS%\WaveAssembly\WaveAssembly.py"
echo   [OK] WaveAssembly

echo.
echo ══════════════════════════════════════════════════════════════
echo   INSTALLATION COMPLETE
echo ══════════════════════════════════════════════════════════════
echo.
echo Scripts installed to: %FUSION_SCRIPTS%
echo.
echo Next steps:
echo   1. Open Fusion 360
echo   2. Go to Tools ^> Add-Ins ^> Scripts and Add-Ins
echo   3. Your scripts will appear in the list
echo   4. Select one and click "Run"
echo.
pause
