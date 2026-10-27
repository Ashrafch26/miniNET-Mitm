@echo off
setlocal EnableExtensions EnableDelayedExpansion
title miniNET-Mitm ARP table override (Windows lab)

rem arp_spoof.bat - ARP cache override for the miniNET-Mitm CTF lab (Windows).
rem
rem Uses only the built-in arp.exe command. It can only change THIS machine's
rem ARP cache. Windows has no stock CLI that sends forged ARP frames to another
rem host, so remote victim poisoning is not possible with arp.exe alone.
rem
rem Use only on hosts/networks you own or are authorized to test.
rem
rem Usage (Administrator Command Prompt):
rem   set IFACE=Ethernet
rem   set VICTIM_IP=192.168.50.2
rem   set GATEWAY_IP=192.168.50.254
rem   arp_spoof.bat
rem
rem   set SPOOF_MAC=aa-bb-cc-dd-ee-ff   override the detected interface MAC
rem   set BIDIR=1                       also override the victim entry
rem   set CONFIRM=1                     skip the confirmation prompt

if not defined IFACE set "IFACE=Ethernet"
if not defined VICTIM_IP set "VICTIM_IP=192.168.50.2"
if not defined GATEWAY_IP set "GATEWAY_IP=192.168.50.254"
if not defined BIDIR set "BIDIR=0"
if not defined CONFIRM set "CONFIRM=0"

net session >nul 2>&1
if errorlevel 1 (
    echo [-] Run this script as Administrator.
    exit /b 1
)

echo %VICTIM_IP%| findstr /R /C:"^10\." /C:"^192\.168\." /C:"^172\.1[6-9]\." /C:"^172\.2[0-9]\." /C:"^172\.3[01]\." >nul
if errorlevel 1 (
    echo [-] VICTIM_IP must be a private IPv4 address ^(got: %VICTIM_IP%^).
    exit /b 1
)

echo %GATEWAY_IP%| findstr /R /C:"^10\." /C:"^192\.168\." /C:"^172\.1[6-9]\." /C:"^172\.2[0-9]\." /C:"^172\.3[01]\." >nul
if errorlevel 1 (
    echo [-] GATEWAY_IP must be a private IPv4 address ^(got: %GATEWAY_IP%^).
    exit /b 1
)

if not "%BIDIR%"=="0" if not "%BIDIR%"=="1" (
    echo [-] BIDIR must be 0 or 1.
    exit /b 1
)

if not defined SPOOF_MAC (
    for /f "usebackq delims=" %%A in (`powershell -NoProfile -Command "(Get-NetAdapter -Name '%IFACE%' -ErrorAction Stop).MacAddress"`) do set "SPOOF_MAC=%%A"
)

if not defined SPOOF_MAC (
    echo [-] Could not detect the MAC for interface "%IFACE%".
    echo     Pass it explicitly: set SPOOF_MAC=aa-bb-cc-dd-ee-ff
    exit /b 1
)

echo [*] interface : %IFACE%
echo [*] victim    : %VICTIM_IP%
echo [*] gateway   : %GATEWAY_IP%
echo [*] spoof MAC : %SPOOF_MAC%
if "%BIDIR%"=="1" (
    echo [*] scope     : gateway + victim entries in the LOCAL ARP cache
) else (
    echo [*] scope     : gateway entry in the LOCAL ARP cache
)
echo [!] arp.exe only edits this machine's cache; it does not poison the victim.

if not "%CONFIRM%"=="1" (
    echo [!] This changes the local ARP cache and can disrupt lab traffic.
    set /p "ANSWER=Type YES if you are authorized to run this: "
    if /I not "!ANSWER!"=="YES" (
        echo [-] aborted
        exit /b 1
    )
)

arp -s %GATEWAY_IP% %SPOOF_MAC%
if errorlevel 1 (
    echo [-] arp -s failed for %GATEWAY_IP%.
    exit /b 1
)

if "%BIDIR%"=="1" (
    arp -s %VICTIM_IP% %SPOOF_MAC%
    if errorlevel 1 echo [!] arp -s failed for %VICTIM_IP%.
)

echo [*] local ARP cache updated:
arp -a

echo [*] press any key to remove the static entries...
pause >nul

arp -d %GATEWAY_IP%
if "%BIDIR%"=="1" arp -d %VICTIM_IP%
echo [*] static entries removed
exit /b 0
