@echo off
set "OUTPUT_DIR=C:\Program Files (x86)\ossec-agent\active-response"
if not exist "%OUTPUT_DIR%" mkdir "%OUTPUT_DIR%"

powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$rawJson = [Console]::In.ReadLine(); if ($rawJson) { try { $json = $rawJson | ConvertFrom-Json; $evData = $json.parameters.alert.data.win.eventdata; $pidVal = $evData.newProcessId; if (-not $pidVal) { $pidVal = $evData.processId }; if ($pidVal -match '^0x') { $parsedPid = [Convert]::ToInt32($pidVal, 16) } else { $parsedPid = [int]$pidVal }; $proc = $evData.image; if (-not $proc) { $proc = $evData.newProcessName }; if (-not $proc) { $proc = 'Unknown' }; if ($parsedPid -gt 0) { $kErr = (taskkill /PID $parsedPid /F 2>&1) -join ' '; $res = 'SUCCESS: ' + $kErr } else { $res = 'FAILED: Invalid PID' } } catch { $parsedPid = 'UNKNOWN'; $proc = 'Unknown'; $res = 'ERROR: ' + $_.Exception.Message }; $ts = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'; $msg = $ts + ' | PID: ' + $parsedPid + ' | Process: ' + $proc + ' | Output: ' + $res; [System.IO.File]::AppendAllText('C:\Program Files (x86)\ossec-agent\active-response\kill-process.log', $msg + [Environment]::NewLine) }"

exit /b 0
