@echo off
setlocal enabledelayedexpansion

:: -------------------------------------------------------------------
:: CONFIGURATION
:: Set your Wazuh Manager IP here so agent communication remains open.
:: -------------------------------------------------------------------
set WAZUH_MANAGER_IP=192.168.1.30

:: Read JSON payload from STDIN passed by Wazuh
set /p INPUT_JSON=

:: Check if the payload contains "add" or "delete"
echo %INPUT_JSON% | findstr /C:"\"command\":\"add\"" >nul
if %errorlevel% equ 0 (
    goto ISOLATE
)

echo %INPUT_JSON% | findstr /C:"\"command\":\"delete\"" >nul
if %errorlevel% equ 0 (
    goto UNISOLATE
)

:: If neither, exit cleanly
goto RESPOND

:ISOLATE
:: 1. Block all inbound and outbound traffic across all profiles
netsh advfirewall set allprofiles firewallpolicy blockinbound,blockoutbound >nul

:: 2. Delete existing rules if previously set to avoid duplicates
netsh advfirewall firewall delete rule name="Wazuh_Manager_Outbound_UDP" >nul 2>&1
netsh advfirewall firewall delete rule name="Wazuh_Manager_Outbound_TCP" >nul 2>&1

:: 3. Explicitly allow outbound communication to Wazuh Manager ports (1514 UDP / 1515 TCP)
netsh advfirewall firewall add rule name="Wazuh_Manager_Outbound_UDP" dir=out action=allow protocol=UDP remoteip=%WAZUH_MANAGER_IP% remoteport=1514 >nul
netsh advfirewall firewall add rule name="Wazuh_Manager_Outbound_TCP" dir=out action=allow protocol=TCP remoteip=%WAZUH_MANAGER_IP% remoteport=1515 >nul

goto RESPOND

:UNISOLATE
:: 1. Revert default outbound policy to allow
netsh advfirewall set allprofiles firewallpolicy blockinbound,allowoutbound >nul

:: 2. Cleanup isolated rules
netsh advfirewall firewall delete rule name="Wazuh_Manager_Outbound_UDP" >nul 2>&1
netsh advfirewall firewall delete rule name="Wazuh_Manager_Outbound_TCP" >nul 2>&1

goto RESPOND

:RESPOND
:: Write JSON acknowledgment back to Wazuh engine
echo {"version":1,"origin":{"name":"win-isolate.cmd","module":"active-response"},"command":"continue","parameters":{}}
exit /b 0
