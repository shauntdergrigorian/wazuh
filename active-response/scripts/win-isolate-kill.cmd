@echo off
setlocal enabledelayedexpansion

:: ===================================================================
:: SECTION 1: CONFIGURATION & DIRECTORY INITIALIZATION
:: ===================================================================
:: Set your Wazuh Manager IP so the agent maintains server communication
set WAZUH_MANAGER_IP=192.168.1.100

:: Active Response logging output location
set "LOG_DIR=C:\Program Files (x86)\ossec-agent\active-response"
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"

:: ===================================================================
:: SECTION 2: READ AND PARSE WAZUH STDIN PAYLOAD
:: ===================================================================
:: Capture the JSON string sent via standard input by the Wazuh Agent daemon
set /p INPUT_JSON=

:: Verify if Wazuh issued an "add" execution request
echo %INPUT_JSON% | findstr /C:"\"command\":\"add\"" >nul
if %errorlevel% neq 0 (
    :: If command is not "add" (or if it receives a "delete" command), exit without doing anything
    goto RESPOND
)

:: ===================================================================
:: SECTION 3: PROCESS TERMINATION (POWERHELL INLINE EXECUTION)
:: ===================================================================
:: Pass the captured JSON string into an inline PowerShell snippet to safely parse
:: nested JSON fields across Sysmon and native Windows Event IDs (Hex or Decimal PIDs).
echo %INPUT_JSON% | powershell.exe -NoProfile -ExecutionPolicy Bypass -Command ^
  "$rawJson = [Console]::In.ReadLine(); " ^
  "if ($rawJson) { " ^
  "  try { " ^
  "    $json = $rawJson | ConvertFrom-Json; " ^
  "    $evData = $json.parameters.alert.data.win.eventdata; " ^
  "    $pidVal = $evData.newProcessId; " ^
  "    if (-not $pidVal) { $pidVal = $evData.processId }; " ^
  "    if ($pidVal -match '^0x') { $parsedPid = [Convert]::ToInt32($pidVal, 16) } else { $parsedPid = [int]$pidVal }; " ^
  "    $proc = $evData.image; " ^
  "    if (-not $proc) { $proc = $evData.newProcessName }; " ^
  "    if (-not $proc) { $proc = 'Unknown' }; " ^
  "    if ($parsedPid -gt 0) { " ^
  "      $kErr = (taskkill /PID $parsedPid /F 2>&1) -join ' '; " ^
  "      $res = 'SUCCESS: ' + $kErr " ^
  "    } else { $res = 'FAILED: Invalid PID' } " ^
  "  } catch { " ^
  "    $parsedPid = 'UNKNOWN'; $proc = 'Unknown'; $res = 'ERROR: ' + $_.Exception.Message " ^
  "  }; " ^
  "  $ts = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'; " ^
  "  $msg = $ts + ' | PID: ' + $parsedPid + ' | Process: ' + $proc + ' | Output: ' + $res; " ^
  "  [System.IO.File]::AppendAllText('C:\Program Files (x86)\ossec-agent\active-response\kill-process.log', $msg + [Environment]::NewLine) " ^
  "}"

:: ===================================================================
:: SECTION 4: ENDPOINT NETWORK ISOLATION (NETSH FIREWALL)
:: ===================================================================
:: 1. Set default policies across all profiles (Domain, Private, Public) to block all traffic
netsh advfirewall set allprofiles firewallpolicy blockinbound,blockoutbound >nul

:: 2. Remove any pre-existing Wazuh manager rules to prevent duplicate entry errors
netsh advfirewall firewall delete rule name="Wazuh_Manager_Outbound_UDP" >nul 2>&1
netsh advfirewall firewall delete rule name="Wazuh_Manager_Outbound_TCP" >nul 2>&1

:: 3. Create outbound explicit bypass rules to preserve agent-to-manager connectivity
netsh advfirewall firewall add rule name="Wazuh_Manager_Outbound_UDP" dir=out action=allow protocol=UDP remoteip=%WAZUH_MANAGER_IP% remoteport=1514 >nul
netsh advfirewall firewall add rule name="Wazuh_Manager_Outbound_TCP" dir=out action=allow protocol=TCP remoteip=%WAZUH_MANAGER_IP% remoteport=1515 >nul

:: ===================================================================
:: SECTION 5: ACKNOWLEDGMENT & EXIT
:: ===================================================================
:RESPOND
:: Send standard JSON response back to the Wazuh Active Response engine
echo {"version":1,"origin":{"name":"win-isolate-kill.cmd","module":"active-response"},"command":"continue","parameters":{}}
exit /b 0
