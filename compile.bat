for /f "delims=" %%a IN ('dir /b /s "DT_*.mq4"') do "%CD%\metalang.exe" "%%a"
pause