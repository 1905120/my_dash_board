@echo off
title My Dashboard Server

echo ========================================
echo    Starting My Dashboard Server...
echo ========================================
echo.

:: Change to the Flask app directory
cd /d "%~dp0my_dash_board"

:: Start the browser after a short delay (to allow server to start)
start "" cmd /c "timeout /t 2 /nobreak >nul && start http://127.0.0.1:5000/"

:: Start the Flask server
:: python dash_board.py

:: Start the server using Waitress (production-ready, no debug console)
python -m waitress --host=127.0.0.1 --port=5000 dash_board:app

pass
 
