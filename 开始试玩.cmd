@echo off
cd /d "%~dp0"
".tools\godot\Godot_v4.7.2-stable_win64.exe" --path "."
if errorlevel 1 pause

