#  Copyright (c) 2014-present, Facebook, Inc.
#  All rights reserved.
#
#  This source code is licensed in accordance with the terms specified in
#  the LICENSE file found in the root directory of this source tree.
$progData = [System.Environment]::GetEnvironmentVariable('ProgramData')
$targetFolder = Join-Path $progData "osquery"
$serviceName = 'osqueryd'

# Remove the osquery path from the System PATH variable. Note: Here
# we don't make use of our local vars, as Regex requires escaping the '\'
$oldPath = [System.Environment]::GetEnvironmentVariable('Path', 'Machine')
if ($oldPath -imatch [regex]::escape($targetFolder)) {
  $newPath = $oldPath -replace [regex]::escape($targetFolder), $NULL
  [System.Environment]::SetEnvironmentVariable('Path', $newPath, 'Machine')
}

if ((Get-Service $serviceName -ErrorAction SilentlyContinue)) {
  Stop-Service $serviceName
  
  # If we find zombie processes, ensure they're termintated
  $proc = Get-Process | Where-Object { $_.ProcessName -eq 'osqueryd' }
  if ($proc -ne $null) {
    Stop-Process -Force $proc -ErrorAction SilentlyContinue
  }

  Set-Service $serviceName -startuptype 'manual'
  Get-CimInstance -ClassName Win32_Service -Filter "Name='osqueryd'" | Invoke-CimMethod -methodName Delete
}

if (Test-Path $targetFolder) {
  Remove-Item -Force -Recurse $targetFolder
} else {
  Write-Debug 'osquery was not found on the system. Nothing to do.'
}
