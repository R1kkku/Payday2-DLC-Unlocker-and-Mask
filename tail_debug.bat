@echo off
title UltimateDLC Debug Console
color 0A
echo ============================================================
echo   UltimateDLC Debug Console - Live Output
echo   Log: C:\Program Files (x86)\Steam\steamapps\common\PAYDAY 2\mods\Payday2-DLC-Unlocker-and-Mask\debug_log.txt
echo ============================================================
echo.
powershell -NoProfile -Command "Get-Content -Path 'C:\Program Files (x86)\Steam\steamapps\common\PAYDAY 2\mods\Payday2-DLC-Unlocker-and-Mask\debug_log.txt' -Wait -Tail 200"
pause
