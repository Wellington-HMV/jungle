<#
  Jungle Watchdog - mantem o jiggle-gui vivo sem admin / sem Task Scheduler.
  Loop leve: a cada N segundos, se o app nao estiver rodando, relanca.
  Sobe no logon (atalho em shell:startup). Single-instance via mutex.

  Liveness via MUTEX (Global\JungleJiggler que o app segura), nao por
  command-line - imune a falso positivo de outro processo citar o nome.
#>
param([int]$CheckSeconds = 300)

# single instance do watchdog
$createdNew = $false
$mutex = New-Object System.Threading.Mutex($true, "Global\JungleWatchdog", [ref]$createdNew)
if (-not $createdNew) { return }

$app = Join-Path $PSScriptRoot 'jiggle-gui.ps1'
$ps  = (Get-Process -Id $PID).Path

function App-Alive {
    try {
        $m = [System.Threading.Mutex]::OpenExisting("Global\JungleJiggler")
        $m.Dispose()
        return $true
    } catch { return $false }
}

while ($true) {
    if (-not (App-Alive)) {
        Start-Process -FilePath $ps -ArgumentList @('-NoProfile','-WindowStyle','Minimized','-File',$app,'-Tray') | Out-Null
    }
    Start-Sleep -Seconds $CheckSeconds
}
