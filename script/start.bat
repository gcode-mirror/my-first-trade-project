pushd ..
TortoiseProc.exe /command:update /path:"%CD%\profiles\"
START wperl notify.pl
terminal.exe
TortoiseProc.exe /command:commit /path:"%CD%\profiles\"