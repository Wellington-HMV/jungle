<#
  Jungle - Mouse Jiggler (bandeja) com janela de horario.
  Pulsa input (mouse_event MOVE 0,0) -> Teams/Slack verde, SEM mover cursor.
  Tambem segura display/sistema acordado (SetThreadExecutionState).
  Janela padrao: SEG-SEX, 09h-18h. Fora disso fica AGUARDANDO (nao pulsa).

  - Janela visual: status + botao ativar/desativar.
  - Fechar janela = esconde na bandeja. Reabrir = duplo-clique no icone.
  - Single-instance. -Tray inicia minimizado (boot).
#>
param(
    [int]$Seconds   = 60,
    [int]$StartHour = 9,
    [int]$EndHour   = 18,
    [switch]$AllDays,   # se passado, roda todo dia (default: so seg-sex)
    [switch]$Tray
)

# ---- single instance ----
$mutexName = "Global\JungleJiggler"
$createdNew = $false
$mutex = New-Object System.Threading.Mutex($true, $mutexName, [ref]$createdNew)
if (-not $createdNew) {
    $ev = [System.Threading.EventWaitHandle]::new($false, 'AutoReset', 'Global\JungleShowWindow')
    $ev.Set() | Out-Null
    return
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

Add-Type @"
using System;
using System.Runtime.InteropServices;
public class Nat {
    [DllImport("user32.dll")] public static extern void mouse_event(uint f, uint dx, uint dy, uint d, IntPtr e);
    [DllImport("kernel32.dll")] public static extern uint SetThreadExecutionState(uint esFlags);
}
"@
$MOUSEEVENTF_MOVE = [uint32]1
$ES_KEEP    = [uint32]"0x80000003"
$ES_RELEASE = [uint32]"0x80000000"

$script:active = $false   # toggle do usuario (mestre)

# dentro da janela de horario (dias + faixa)?
function In-Window {
    $now = Get-Date
    if (-not $AllDays -and ($now.DayOfWeek -eq 'Saturday' -or $now.DayOfWeek -eq 'Sunday')) { return $false }
    return ($now.Hour -ge $StartHour -and $now.Hour -lt $EndHour)
}

function New-StatusIcon([string]$state) {
    $bmp = New-Object System.Drawing.Bitmap 16,16
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = 'AntiAlias'
    $color = switch ($state) {
        'on'   { [System.Drawing.Color]::LimeGreen }
        'wait' { [System.Drawing.Color]::Goldenrod }
        default{ [System.Drawing.Color]::Gray }
    }
    $brush = New-Object System.Drawing.SolidBrush $color
    $g.FillEllipse($brush, 1,1,14,14)
    $g.Dispose()
    return [System.Drawing.Icon]::FromHandle($bmp.GetHicon())
}

$startupLnk = Join-Path ([Environment]::GetFolderPath('Startup')) 'JungleJiggler.lnk'
$watchdog   = Join-Path $PSScriptRoot 'watchdog.ps1'
$psExe      = (Get-Process -Id $PID).Path

function Test-Autostart { Test-Path $startupLnk }
function Set-Autostart([bool]$enable) {
    if ($enable) {
        # boot aponta pro watchdog (logon + self-heal). Watchdog relanca o app se morrer.
        $ws = New-Object -ComObject WScript.Shell
        $lnk = $ws.CreateShortcut($startupLnk)
        $lnk.TargetPath = $psExe
        $lnk.Arguments  = "-NoProfile -WindowStyle Minimized -File ""$watchdog"""
        $lnk.WorkingDirectory = $PSScriptRoot
        $lnk.Description = "Jungle Watchdog (mantem o jiggler vivo)"
        $lnk.Save()
    } elseif (Test-Path $startupLnk) {
        Remove-Item $startupLnk -Force
    }
}

# ---- form ----
$form = New-Object System.Windows.Forms.Form
$form.Text = "Jungle Jiggler"
$form.Size = New-Object System.Drawing.Size(300,240)
$form.FormBorderStyle = 'FixedSingle'
$form.MaximizeBox = $false
$form.StartPosition = 'CenterScreen'

$lblStatus = New-Object System.Windows.Forms.Label
$lblStatus.AutoSize = $false
$lblStatus.Size = New-Object System.Drawing.Size(260,40)
$lblStatus.Location = New-Object System.Drawing.Point(16,14)
$lblStatus.TextAlign = 'MiddleCenter'
$lblStatus.Font = New-Object System.Drawing.Font("Segoe UI",14,[System.Drawing.FontStyle]::Bold)
$form.Controls.Add($lblStatus)

$btn = New-Object System.Windows.Forms.Button
$btn.Size = New-Object System.Drawing.Size(260,46)
$btn.Location = New-Object System.Drawing.Point(16,60)
$btn.Font = New-Object System.Drawing.Font("Segoe UI",12,[System.Drawing.FontStyle]::Bold)
$form.Controls.Add($btn)

$chkBoot = New-Object System.Windows.Forms.CheckBox
$chkBoot.Text = "Iniciar com o Windows"
$chkBoot.Location = New-Object System.Drawing.Point(20,118)
$chkBoot.AutoSize = $true
$chkBoot.Checked = Test-Autostart
$form.Controls.Add($chkBoot)

$dias = if ($AllDays) { "Todo dia" } else { "Seg-Sex" }
$lblWin = New-Object System.Windows.Forms.Label
$lblWin.Text = "Janela: $dias  ${StartHour}h-${EndHour}h"
$lblWin.Location = New-Object System.Drawing.Point(20,144)
$lblWin.AutoSize = $true
$lblWin.Font = New-Object System.Drawing.Font("Segoe UI",9,[System.Drawing.FontStyle]::Bold)
$form.Controls.Add($lblWin)

$lblInfo = New-Object System.Windows.Forms.Label
$lblInfo.Text = "Pulso a cada ${Seconds}s - fecha = bandeja"
$lblInfo.Location = New-Object System.Drawing.Point(20,166)
$lblInfo.AutoSize = $true
$lblInfo.ForeColor = [System.Drawing.Color]::Gray
$form.Controls.Add($lblInfo)

# ---- tray ----
$trayIcon = New-Object System.Windows.Forms.NotifyIcon
$trayIcon.Visible = $true

function Update-UI {
    if (-not $script:active) {
        $lblStatus.Text = "PARADO"; $lblStatus.ForeColor = [System.Drawing.Color]::Gray
        $btn.Text = "Ativar"; $trayIcon.Text = "Jungle - parado"
        $trayIcon.Icon = New-StatusIcon 'off'
    } elseif (In-Window) {
        $lblStatus.Text = "ATIVO"; $lblStatus.ForeColor = [System.Drawing.Color]::LimeGreen
        $btn.Text = "Desativar"; $trayIcon.Text = "Jungle - ATIVO (na janela)"
        $trayIcon.Icon = New-StatusIcon 'on'
    } else {
        $lblStatus.Text = "AGUARDANDO"; $lblStatus.ForeColor = [System.Drawing.Color]::Goldenrod
        $btn.Text = "Desativar"; $trayIcon.Text = "Jungle - aguardando janela ${StartHour}h-${EndHour}h"
        $trayIcon.Icon = New-StatusIcon 'wait'
    }
}

# ---- timer do pulso (so pulsa dentro da janela) ----
$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = $Seconds * 1000
$timer.Add_Tick({
    if ($script:active -and (In-Window)) {
        [Nat]::SetThreadExecutionState($ES_KEEP) | Out-Null
        [Nat]::mouse_event($MOUSEEVENTF_MOVE, 0, 0, 0, [IntPtr]::Zero) | Out-Null
    } else {
        [Nat]::SetThreadExecutionState($ES_RELEASE) | Out-Null
    }
})

# ---- timer do relogio: atualiza status ao cruzar a janela ----
$clock = New-Object System.Windows.Forms.Timer
$clock.Interval = 20000
$clock.Add_Tick({ Update-UI })

function Set-Active([bool]$on) {
    $script:active = $on
    if ($on) {
        $timer.Start(); $clock.Start()
        if (In-Window) {
            [Nat]::SetThreadExecutionState($ES_KEEP) | Out-Null
            [Nat]::mouse_event($MOUSEEVENTF_MOVE, 0, 0, 0, [IntPtr]::Zero) | Out-Null
        }
    } else {
        $timer.Stop(); $clock.Stop()
        [Nat]::SetThreadExecutionState($ES_RELEASE) | Out-Null
    }
    Update-UI
}

$btn.Add_Click({ Set-Active (-not $script:active) })
$chkBoot.Add_CheckedChanged({ Set-Autostart $chkBoot.Checked })

$menu = New-Object System.Windows.Forms.ContextMenuStrip
$miOpen = $menu.Items.Add("Abrir")
$miToggle = $menu.Items.Add("Ativar / Desativar")
$null = $menu.Items.Add("-")
$miExit = $menu.Items.Add("Sair")
$trayIcon.ContextMenuStrip = $menu

function Show-Window {
    $form.Show(); $form.WindowState = 'Normal'; $form.Activate(); $form.BringToFront()
}
$miOpen.Add_Click({ Show-Window })
$miToggle.Add_Click({ Set-Active (-not $script:active) })
$miExit.Add_Click({
    $timer.Stop(); $clock.Stop()
    [Nat]::SetThreadExecutionState($ES_RELEASE) | Out-Null
    $trayIcon.Visible = $false
    $form.Dispose()
    [System.Windows.Forms.Application]::Exit()
})
$trayIcon.Add_DoubleClick({ Show-Window })

$form.Add_FormClosing({
    param($s,$e)
    if ($e.CloseReason -eq 'UserClosing') {
        $e.Cancel = $true
        $form.Hide()
        $trayIcon.ShowBalloonTip(1500, "Jungle Jiggler", "Rodando na bandeja.", 'Info')
    }
})

$showEv = [System.Threading.EventWaitHandle]::new($false, 'AutoReset', 'Global\JungleShowWindow')
$evTimer = New-Object System.Windows.Forms.Timer
$evTimer.Interval = 700
$evTimer.Add_Tick({ if ($showEv.WaitOne(0)) { Show-Window } })
$evTimer.Start()

# ---- start ----
Set-Active $true
if ($Tray) { $form.WindowState = 'Minimized'; $form.ShowInTaskbar = $false }
else { Show-Window }

[System.Windows.Forms.Application]::Run()
$mutex.ReleaseMutex()
