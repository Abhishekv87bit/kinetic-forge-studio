@echo off
REM Export SVG from OpenSCAD
openscad -o %2 --camera=0,0,0,0,0,0,500 -D "$t=0.5" %1
