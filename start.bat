TortoiseProc.exe /command:update /path:"%CD%\profiles\DEX\"

sleep 10

terminal.exe

sleep 3

TortoiseProc.exe /command:commit /path:"%CD%\profiles\DEX\"
