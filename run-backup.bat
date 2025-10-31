@echo off
REM ROSS Carbonite FTP Backup - Batch Launcher
REM This script launches the PowerShell backup script

REM Get the directory where this batch file is located
set SCRIPT_DIR=%~dp0

REM Change to script directory
cd /d "%SCRIPT_DIR%"

REM Run PowerShell script with execution policy bypass
PowerShell.exe -ExecutionPolicy Bypass -File "%SCRIPT_DIR%Backup-CarboniteFiles.ps1"

REM Exit with the same error code as PowerShell
exit /b %ERRORLEVEL%
