@echo off

rem Title: Wifi logging
rem Version: V1
rem Date: 2023-05-01
rem Created by: Matthias Rommel


setlocal enableextensions enabledelayedexpansion

rem set the global wifi settings
set WLAN_SSID=ip-net_v2
set FILE_DIRECTORY=.\Logs
set FILE_NAME=WifiLog
set LOGGING_INTERNVAL_IN_SEC=10
set CSV_SEPERATOR=;

rem Check if Logs folder exists, create it if it doesn't
if not exist "%FILE_DIRECTORY%" (
    echo Creating Logs folder...
    mkdir "%FILE_DIRECTORY%"
)

echo Drücke Ctrl+C um Programm zu beenden

rem Set log file path
set LOG_FILE=%FILE_DIRECTORY%\%FILE_NAME%.csv




:LOOP
rem get current timestamp
for /f "tokens=2 delims==" %%a in ('wmic os get localdatetime /value') do set "dt=%%a"
set "datetime=%dt:~0,4%-%dt:~4,2%-%dt:~6,2% %dt:~8,2%:%dt:~10,2%:%dt:~12,2%"

rem Run netsh command to get WLAN interface info
echo Running netsh command to get WLAN interface info...
set Connected=Disconnected
for /f "tokens=1,2,3,4,5,6,7,8,9,10,11,12 delims=:" %%a in ('netsh wlan show interfaces ^| findstr /c:"Status" /c:"BSSID" /c:"Band" /c:"Kanal" /c:"Signal" /c:"Profil" ') do (
    set VAR=%%a:%%b:%%c:%%d:%%e:%%f
    set VAR=!VAR: =!
    if "!VAR:~0,4!" == "BSSI" (
        set BSSID=!VAR:~6!
    ) else if "!VAR:~0,4!" == "Band" (
        set Band=!VAR:~5!
		set Band=!Band::=!
    ) else if "!VAR:~0,4!" == "Kana" (
        set Kanal=!VAR:~6!
		set Kanal=!Kanal::=!
    ) else if "!VAR:~0,4!" == "Sign" (
        set Signal=!VAR:~6!
		set Signal=!Signal::=!
    ) else if "!VAR:~0,4!" == "Prof" (
        set Profil=!VAR:~7!
		set Profil=!Profil::=!
    ) else if "!VAR:~0,7!" == "Status:" (
        set Status=!VAR:~6!
		set Status=!Status::=!
    )

    rem Check if WLAN connection is to the desired SSID
    if "!Profil!" == "%WLAN_SSID%" (
        set Connected="!Status!"
    ) 	
)

if %WLAN_SSID% == !Profil! (
	rem Write results to log file if WLAN connection is lost  getrennt/Verbunden
	if "%Status%" == "getrennt" (
		echo WLAN connection lost
		rem write the last know state
		IF EXIST "%LOG_FILE%" (
	 
			echo %datetime%%CSV_SEPERATOR%%Profil%%CSV_SEPERATOR%%BSSID%%CSV_SEPERATOR%%Band%%CSV_SEPERATOR%%Kanal%%CSV_SEPERATOR%%Signal%%CSV_SEPERATOR%%Status% >> "%LOG_FILE%"
			
			REM Rename current file with timestamp
			echo rename the existing logfile with timestamp
			set LOG_FILE_NEW="%datetime::=%"_"%FILE_NAME%".csv
			ren "%LOG_FILE%" !LOG_FILE_NEW!
		)
	) else (
		IF NOT EXIST "%LOG_FILE%" (
			echo Zeitstempel%CSV_SEPERATOR%Profil%CSV_SEPERATOR%BSSID%CSV_SEPERATOR%Band%CSV_SEPERATOR%Kanal%CSV_SEPERATOR%Signal%CSV_SEPERATOR%Status  > "%LOG_FILE%"
		) 
		echo %datetime%%CSV_SEPERATOR%%Profil%%CSV_SEPERATOR%%BSSID%%CSV_SEPERATOR%%Band%%CSV_SEPERATOR%%Kanal%%CSV_SEPERATOR%%Signal%%CSV_SEPERATOR%%Status% >> "%LOG_FILE%"
	)
) else (
	echo not connected to desired SSID: %WLAN_SSID%
)

rem Wait for 30 seconds before repeating
echo Waiting for %LOGGING_INTERNVAL_IN_SEC% seconds before repeating...
ping -n %LOGGING_INTERNVAL_IN_SEC% 127.0.0.1 > nul
goto LOOP
