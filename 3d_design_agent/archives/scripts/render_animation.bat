@echo off
REM Render animation frames from OpenSCAD file
REM Usage: render_animation.bat <file.scad> <output_dir> <frames>
openscad -o %2\frame_%%04d.png --animate=%3 --camera=0,0,0,0,0,0,500 %1
