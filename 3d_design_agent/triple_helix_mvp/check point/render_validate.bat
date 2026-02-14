@echo off
REM Triple Helix MVP — Compile + Validate + Render
REM Usage: render_validate.bat [scad_file] [--render]
REM Default: hex_frame_v4.scad

setlocal
set SCAD=%1
if "%SCAD%"=="" set SCAD=hex_frame_v4.scad
set RENDER=%2

echo ============================================
echo  Triple Helix MVP Pipeline
echo  File: %SCAD%
echo ============================================

echo.
echo [1/3] Compiling...
"C:\Program Files\OpenSCAD\openscad.com" -o "%~n1.test.csg" "%SCAD%" 2>&1 | findstr /i "error warning"
if errorlevel 1 (
    echo    Compile errors detected!
) else (
    echo    Compile OK
)

echo.
echo [2/3] Validating geometry constraints...
python validate_geometry.py %RENDER% "%SCAD%"

echo.
echo [3/3] Done.
echo ============================================
