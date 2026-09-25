@echo off
title UltimateDLC Debug Console
color 0A
echo ============================================================
echo   UltimateDLC Debug Console - Live Output
echo   Session ID:  2026-09-25_08-44-46
echo   Session Log: C:\Program Files (x86)\Steam\steamapps\common\PAYDAY 2\mods\Payday2-DLC-Unlocker-and-Mask\logs\debug_log_2026-09-25_08-44-46.txt
echo   Latest Log:  C:\Program Files (x86)\Steam\steamapps\common\PAYDAY 2\mods\Payday2-DLC-Unlocker-and-Mask\debug_log.txt
echo ============================================================
echo.
powershell -NoProfile -Command "Get-Content -Path 'C:\Program Files (x86)\Steam\steamapps\common\PAYDAY 2\mods\Payday2-DLC-Unlocker-and-Mask\logs\debug_log_2026-09-25_08-44-46.txt' -Wait -Tail 200"
pause
