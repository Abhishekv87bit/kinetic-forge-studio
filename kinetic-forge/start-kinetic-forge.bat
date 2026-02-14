@echo off
title KineticForge
cd /d "D:\Claude local\kinetic-forge"
echo Starting KineticForge...
echo Frontend: http://localhost:5173
echo API:      http://localhost:3001
echo.
echo Close this window to stop the server.
echo.
start "" http://localhost:5173
npm run dev
