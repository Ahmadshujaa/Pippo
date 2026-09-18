# ============================================================================
#  wireless_watch.ps1  -  Auto-detect phone via Wireless Debugging and launch
#
#  Watches ADB's mDNS discovery. The moment you toggle "Wireless debugging"
#  ON on your phone (previously paired with pair_phone.ps1), the phone is
#  connected over Wi-Fi and the app is launched.
#
#  Modes:
#    -Mode flutter   (default)  runs  "flutter run -d <phone>"  from Mobile\
#                               -> build + install + launch + hot reload.
#                               Press 'q' in this window to end the session.
#    -Mode app                  just starts the already-installed app via
#                               "am start" (instant, no rebuild). Falls back
#                               to a flutter run if the app is not installed.
#
#  Usage:
#    powershell -NoProfile -ExecutionPolicy Bypass -File wireless_watch.ps1
#    powershell ... -File wireless_watch.ps1 -Mode app
# ============================================================================

param(
    [ValidateSet('flutter', 'app')]
    [string]$Mode = 'flutter',
    [int]$PollSeconds = 2
)

$ErrorActionPreference = 'Continue'
$Adb      = Join-Path $env:LOCALAPPDATA 'Android\Sdk\platform-tools\adb.exe'
$MobileDir = Split-Path -Parent $PSScriptRoot
$Package  = 'com.example.tactics'
$Activity = "$Package/.MainActivity"

if (-not (Test-Path $Adb)) {
    Write-Host "ERROR: adb.exe not found at $Adb" -ForegroundColor Red
    exit 1
}
if (-not (Test-Path (Join-Path $MobileDir 'pubspec.yaml'))) {
    Write-Host "ERROR: Flutter project not found at $MobileDir" -ForegroundColor Red
    exit 1
}

function Get-WirelessTargets {
    # Returns "ip:port" entries discovered via mDNS (_adb-tls-connect._tcp),
    # which is exactly what the phone's "Wireless debugging" switch advertises.
    $targets = @()
    $services = & $Adb mdns services 2>$null
    foreach ($line in $services) {
        if ($line -match '_adb-tls-connect\._tcp' -and
            $line -match '(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}):(\d{1,5})') {
            $t = "$($Matches[1]):$($Matches[2])"
            if ($targets -notcontains $t) { $targets += $t }
        }
    }
    return $targets
}

function Get-OnlineWirelessDevices {
    # Wireless devices (serial "ip:port") currently in "device" (online) state.
    $devices = @()
    foreach ($line in (& $Adb devices 2>$null)) {
        if ($line -match '^(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}:\d{1,5})\s+device\b') {
            $devices += $Matches[1]
        }
    }
    return $devices
}

function Start-AppOnDevice([string]$Serial) {
    if ($Mode -eq 'flutter') {
        Write-Host ">>> Launching Pippo on $Serial (flutter run - hot reload ready)..." -ForegroundColor Green
        Write-Host ">>> Press 'q' in this window to end the session." -ForegroundColor DarkGray
        Push-Location $MobileDir
        try { & flutter run -d $Serial } finally { Pop-Location }
    }
    else {
        $installed = & $Adb -s $Serial shell pm path $Package 2>$null
        if ($installed) {
            Write-Host ">>> Starting installed Pippo app on $Serial..." -ForegroundColor Green
            & $Adb -s $Serial shell am start -n $Activity | Out-Null
            Write-Host '>>> App launched.' -ForegroundColor Green
        }
        else {
            Write-Host ">>> App not installed on $Serial - installing via flutter run..." -ForegroundColor Yellow
            Push-Location $MobileDir
            try { & flutter run -d $Serial } finally { Pop-Location }
        }
    }
}

# Clear any stale/offline transports left over from previous sessions by
# restarting the adb server (it restarts automatically on next use).
& $Adb kill-server 2>$null | Out-Null


Write-Host '==============================================' -ForegroundColor Cyan
Write-Host ' Pippo - Wireless Debugging Watcher' -ForegroundColor Cyan
Write-Host " Mode      : $Mode"
Write-Host " Project   : $MobileDir"
Write-Host " Poll every : $PollSeconds s"
Write-Host '==============================================' -ForegroundColor Cyan
Write-Host ''
if ($Mode -eq 'app') {
    Write-Host 'Waiting for Wireless Debugging to be turned on the phone...' -ForegroundColor Yellow
    Write-Host "(Toggle: Settings > Developer options > Wireless debugging)" -ForegroundColor DarkGray
} else {
    Write-Host 'Waiting for Wireless Debugging to be turned on the phone...' -ForegroundColor Yellow
    Write-Host '(Toggle: Settings > Developer options > Wireless debugging)' -ForegroundColor DarkGray
}
Write-Host 'Once detected, the app launches automatically. Ctrl+C to quit.'
Write-Host ''

# $seen tracks devices that are currently online so each device launches once
# per "toggle on". When the phone disconnects it is forgotten and will launch
# again the next time you toggle Wireless debugging (or it comes back).
$seen = @{}

while ($true) {
    # 1. Discover advertised wireless-debug services and connect to new ones.
    $targets = Get-WirelessTargets
    foreach ($t in $targets) {
        if (-not $seen.ContainsKey($t)) {
            Write-Host "Discovered wireless device: $t - connecting..." -ForegroundColor Yellow
            & $Adb connect $t | Out-Null
        }
    }

    Start-Sleep -Milliseconds 800

    # 2. Launch the app for every newly-online wireless device.
    $online = Get-OnlineWirelessDevices
    foreach ($dev in $online) {
        if (-not $seen.ContainsKey($dev)) {
            $seen[$dev] = $true
            Start-AppOnDevice -Serial $dev
        }
    }

    # 3. Forget devices that disappeared so a later toggle re-launches them.
    foreach ($key in @($seen.Keys)) {
        if ($online -notcontains $key) {
            $seen.Remove($key)
            Write-Host "Device $key disconnected." -ForegroundColor DarkGray
        }
    }

    Start-Sleep -Seconds $PollSeconds
}
