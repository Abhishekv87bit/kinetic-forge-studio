@echo off
REM Extract path coordinates from SVG file
type %1 | findstr /R "d=\"[^\"]*\""
