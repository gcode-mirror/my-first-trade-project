TortoiseProc.exe /command:update /path:"%CD%\profiles\DEX\"

sleep 10

START wperl notify.pl
terminal.exe

sleep 3

TortoiseProc.exe /command:commit /path:"%CD%\profiles\DEX\"