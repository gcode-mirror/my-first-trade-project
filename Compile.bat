for /f "delims=" %%a IN ('dir /b /s "*DT*.mq4"') do "%CD%\metalang.exe" "%%a"
pause