<#
.SYNOPSIS
  Anti-Lock CLI - mantem display ligado + sistema acordado via
  SetThreadExecutionState. NAO sintetiza input de mouse (Defender ignora).

.EXAMPLE
  .\jiggle.ps1
#>
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class Power {
    [DllImport("kernel32.dll")] public static extern uint SetThreadExecutionState(uint esFlags);
}
"@

$ES_KEEP    = [uint32]"0x80000003"  # continuous | system | display
$ES_RELEASE = [uint32]"0x80000000"

Write-Host "Anti-Lock ON - tela acesa / sem sleep. Ctrl+C para parar."
try {
    while ($true) {
        [Power]::SetThreadExecutionState($ES_KEEP) | Out-Null
        Start-Sleep -Seconds 50
    }
}
finally {
    [Power]::SetThreadExecutionState($ES_RELEASE) | Out-Null
    Write-Host "`nAnti-Lock OFF."
}
