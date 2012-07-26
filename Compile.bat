for /f "delims=" %%a IN ('dir /b /s "*_DT.mq4"') do "%CD%\metalang.exe" "%%a"
pause