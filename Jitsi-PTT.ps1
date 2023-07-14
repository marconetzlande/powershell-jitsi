Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

public class Keyboard
{
    [DllImport("user32.dll")]
    public static extern short GetAsyncKeyState(int vKey);
    
    [DllImport("user32.dll")]
    public static extern bool SetForegroundWindow(IntPtr hWnd);
    
    [DllImport("user32.dll")]
    public static extern IntPtr GetForegroundWindow();
}
"@

function GetProcessMainWindowHandle($processName) {
    $process = Get-Process | Where-Object { $_.MainWindowTitle -eq $processName }
    if ($process) {
        return $process.MainWindowHandle
    }
    return $null
}

function Mute {
    $global:muted = $true
    [Keyboard]::SetForegroundWindow($jH)
    Start-Sleep -Milliseconds 100
    [System.Windows.Forms.SendKeys]::SendWait(' ')
    [System.Windows.Forms.SendKeys]::Flush()
    Write-Host("Mute()")
    [Keyboard]::SetForegroundWindow($cH)
}

function Unmute {
    $cH = [Keyboard]::GetForegroundWindow()
    $global:muted = $false
    [Keyboard]::SetForegroundWindow($jH)
    Start-Sleep -Milliseconds 100
    [System.Windows.Forms.SendKeys]::SendWait('m')
    [System.Windows.Forms.SendKeys]::Flush()
    Write-Host("Unute()")
}

function CheckCtrlHoldDuration {
    $ctrlKeyState = [Keyboard]::GetAsyncKeyState(0x11) -band 0x8000

    if ($ctrlKeyState) {
        if (-not $global:ctrlPressed) {
            $global:ctrlPressed = $true
            $global:startTime = (Get-Date).Ticks
        }
        elseif ((Get-Date).Ticks - $global:startTime -ge 5000000) {
            if ($global:muted) {
                Unmute
            }
            $global:ctrlPressed = $false
            $global:startTime = 0
        }
    }
    else {
        if (-not $global:muted) {
            Mute
        }
        $global:ctrlPressed = $false
        $global:startTime = 0
    }
}


$global:ctrlPressed = $false
$global:startTime = 0

$jH = GetProcessMainWindowHandle("Jitsi Meet - Pushtotalktest | Jitsi Meet")
$cH = [Keyboard]::GetForegroundWindow()

$global:muted = $true


while ($true) {
    # Continue with your script logic here
    Start-Sleep -Milliseconds 10
    CheckCtrlHoldDuration
}