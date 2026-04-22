@echo off
cd /d "C:\opencode projects\project1\markitdown app"
start python run.py
timeout /t 5 /nobreak >nul
start http://localhost:5000
pause