$channelname = "xxx"
$windowtitle = "Jitsi Meet - ${channelname} | Jitsi Meet"

#https://learn.microsoft.com/en-us/windows/win32/inputdev/virtual-key-codes
$activationKey = 0x11

$holdDuration = 1000 #
$doubleTapDuration = 50  # Maximum duration between two Ctrl key presses for double-tap detection
$maxDuration = 300  # Maximum duration to wait for the second Ctrl key press


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
    public static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);

    [DllImport("user32.dll")]
    public static extern IntPtr GetForegroundWindow();
}
"@

function GetProcessMainWindowHandle($windowTitle) {
    $jitsi_edge = (Get-Process -Name msedge |Where-Object MainWindowTitle -eq $windowTitle)[0]
    $jitsi_edge_hwnd = $jitsi_edge.MainWindowHandle
    if ($jitsi_edge_hwnd) {
        return $jitsi_edge_hwnd
    }
    Exit 1
    return $null
}

function Mute {
    $global:muted = $true
    [Keyboard]::SetForegroundWindow($jH)
    Start-Sleep -Milliseconds 100
    [System.Windows.Forms.SendKeys]::SendWait(' ')
    [System.Windows.Forms.SendKeys]::Flush()
    Write-Host("Mute()")
    [Keyboard]::ShowWindowAsync($jH, 6) #Minimize Window
    #[Keyboard]::SetForegroundWindow($cH)
}

function Unmute {
    $global:cH = [Keyboard]::GetForegroundWindow()
    $global:muted = $false
    [Keyboard]::ShowWindowAsync($jH, 9) #Restore Window
    [Keyboard]::SetForegroundWindow($jH)
    Start-Sleep -Milliseconds 100
    [System.Windows.Forms.SendKeys]::SendWait('m')
    [System.Windows.Forms.SendKeys]::Flush()
    Write-Host("Unute()")
}

$global:ctrlPressed = $false
$global:ctrlPressTime = $null
$global:ctrlUpTime = $null

function CheckCtrlHoldDuration {
    $ctrlKeyState = [Keyboard]::GetAsyncKeyState($acticationKey) -band 0x8000

    if ($ctrlKeyState) {
        if (-not $global:ctrlPressed) {
            $global:ctrlPressed = $true
            $global:ctrlPressTime = (Get-Date).Ticks
        }
        elseif ((Get-Date).Ticks - $global:ctrlPressTime -ge ($holdDuration * 10000)) {
            if ($global:muted) {
                Unmute
            }
            $global:ctrlPressed = $false
            $global:ctrlPressTime = 0
        }
    }
    else {
        if (-not $global:muted) {
            Mute
        }
        $global:ctrlPressed = $false
        $global:ctrlPressTime = 0
    }
}

function CheckCtrlDoubleTap {
    $ctrlKeyState = [Keyboard]::GetAsyncKeyState($activationKey) -band 0x8000

    if ($ctrlKeyState) {
        if ($global:ctrlPressTime -and $global:ctrlUpTime -and ((Get-Date) - $global:ctrlPressTime).TotalMilliseconds -gt $doubleTapDuration -and ((Get-Date) - $global:ctrlPressTime).TotalMilliseconds -lt $maxDuration) {
            Write-Host("Ctrl 2nd")
            # Double-tap detected
            if ($global:muted) {
                Unmute
            } else {
                Mute
            }
            $global:ctrlPressTime = $null
            $global:ctrlUpTime = $null
        } else {
            if (-not $global:ctrlPressTime) {
                #safe time of first press
                Write-Host("Ctrl 1st")
                $global:ctrlPressTime = Get-Date
            }
        }
    } else {
        #reset if it takes to long
        if ($global:ctrlPressTime -and ((Get-Date) - $global:ctrlPressTime).TotalMilliseconds -gt $maxDuration) {
            Write-Host("Ctrl reset")
            $global:ctrlPressTime = $null
            $global:ctrlUpTime = $null
        }

        #
        if ($global:ctrlPressTime) {
            $global:ctrlUpTime = Get-Date
        }

    }
}

$jH = GetProcessMainWindowHandle($windowtitle)
$global:cH = [Keyboard]::GetForegroundWindow()

$global:muted = $true


while ($true) {
    # Continue with your script logic here
    Start-Sleep -Milliseconds 10
    #CheckCtrlHoldDuration
    CheckCtrlDoubleTap
}
