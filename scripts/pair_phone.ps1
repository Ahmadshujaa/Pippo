# ============================================================================
#  pair_phone.ps1  -  ONE-TIME pairing of your phone for Wireless Debugging
#
#  Run this once. After a successful pairing you never need it again:
#  just toggle "Wireless debugging" on the phone and start
#  wireless_watch.ps1 (or the .bat) - the phone is found automatically.
#
#  Notes:
#   - Restarts the adb server first: a stale server is the usual cause of
#     "error: protocol fault (couldn't read status message)" while pairing.
#   - Success/failure is detected from adb's OUTPUT TEXT, because some adb
#     versions return exit code 0 even when pairing fails.
#   - Retries up to 3 times; each attempt needs a FRESH popup on the phone.
# ============================================================================

$ErrorActionPreference = 'Continue'
$Adb = Join-Path $env:LOCALAPPDATA 'Android\Sdk\platform-tools\adb.exe'

if (-not (Test-Path $Adb)) {
    Write-Host "ERROR: adb.exe not found at $Adb" -ForegroundColor Red
    Read-Host 'Press Enter to exit'
    exit 1
}

Write-Host ''
Write-Host '================ ONE-TIME PAIRING ================' -ForegroundColor Cyan
Write-Host 'On your PHONE:'
Write-Host '  1. Settings > Developer options > Wireless debugging > turn ON'
Write-Host '  2. Tap  "Pair device with pairing code"'
Write-Host '  3. A popup shows:  Wi-Fi pairing code (6 digits)'
Write-Host '     and            IP address & Port  (e.g. 192.168.1.42:37845)'
Write-Host '     -> keep that popup OPEN while you type below.'
Write-Host '===================================================' -ForegroundColor Cyan
Write-Host ''

# A stale/corrupted adb server causes "protocol fault (couldn't read status
# message)" - always start pairing from a freshly restarted server.
Write-Host 'Restarting the adb server (clears stale pairing state)...' -ForegroundColor DarkGray
& $Adb kill-server 2>$null | Out-Null
& $Adb start-server 2>$null | Out-Null
Write-Host ''

# Show this PC's IPs: the popup IP on the phone must live in the same
# network/subnet as one of these, otherwise the two devices cannot talk.
Write-Host "This PC's IP addresses (the phone popup IP should be in the same network):" -ForegroundColor DarkGray
Get-NetIPAddress -AddressFamily IPv4 |
    Where-Object { $_.IPAddress -ne '127.0.0.1' -and $_.IPAddress -notlike '169.254.*' } |
    ForEach-Object { Write-Host ("  {0}  ({1})" -f $_.IPAddress, $_.InterfaceAlias) -ForegroundColor DarkGray }
Write-Host ''

$MaxAttempts = 3
$Paired      = $false

for ($attempt = 1; $attempt -le $MaxAttempts -and -not $Paired; $attempt++) {
    if ($attempt -gt 1) {
        Write-Host ''
        Write-Host "Attempt $attempt of $MaxAttempts" -ForegroundColor Cyan
        Write-Host 'IMPORTANT: on the phone, CLOSE and re-open "Pair device with pairing code"' -ForegroundColor Yellow
        Write-Host '           to get a FRESH port and code, then keep the popup OPEN.' -ForegroundColor Yellow
        Write-Host ''
    }

    $PairAddr = (Read-Host 'Enter the PAIRING IP:PORT (from the popup)').Trim()
    $Code     = (Read-Host 'Enter the 6-digit Wi-Fi pairing code').Trim()

    if (-not $PairAddr -or -not $Code) {
        Write-Host 'Pairing address and code are required.' -ForegroundColor Red
        continue
    }

    # Normalize input: remove spaces (some phone UIs print the code grouped).
    $Code = ($Code -replace '\s', '')

    Write-Host ''
    Write-Host "Pairing with $PairAddr ..." -ForegroundColor Yellow
    $pairOutput = & $Adb pair $PairAddr $Code 2>&1
    $pairText   = ($pairOutput | Out-String).Trim()
    Write-Host $pairText

    if ($pairText -match '(?i)success') {
        $Paired = $true
        break
    }

    # Classify the failure so the user knows exactly what to fix.
    Write-Host ''
    if ($pairText -match 'code mismatch|(?i)failed to pair') {
        Write-Host 'The pairing CODE was rejected. Re-open the popup for a fresh code and retry.' -ForegroundColor Red
    }
    elseif ($pairText -match 'protocol fault') {
        # "protocol fault" is adb's vague wrapper for whatever went wrong inside
        # the server's pairing client - most often the PC could not reach the
        # phone at all. Probe the pairing port to tell the two cases apart.
        $probe = $PairAddr -split ':'
        $reachable = $false
        $tcp = New-Object System.Net.Sockets.TcpClient
        try {
            $iar = $tcp.BeginConnect($probe[0], [int]$probe[1], $null, $null)
            if ($iar.AsyncWaitHandle.WaitOne(4000)) {
                try { $null = $tcp.EndConnect($iar); $reachable = $true } catch { $reachable = $false }
            }
        } finally { $tcp.Close() }

        if ($reachable) {
            Write-Host 'The phone dropped the pairing connection mid-handshake.' -ForegroundColor Red
            Write-Host 'The pairing popup most likely closed/expired - re-open it and retry' -ForegroundColor Red
            Write-Host 'with the NEW port and code.' -ForegroundColor Red
        }
        else {
            Write-Host "The PC could NOT reach the phone at $PairAddr (connection timed out)." -ForegroundColor Red
            Write-Host 'Even though both devices are on the same Wi-Fi, the network is BLOCKING' -ForegroundColor Red
            Write-Host 'device-to-device traffic ("AP/client isolation" - common on campus,' -ForegroundColor Red
            Write-Host 'office, hotel and guest Wi-Fi networks).' -ForegroundColor Red
            Write-Host 'Fix: on a home router disable "AP/client isolation" in its settings;' -ForegroundColor Red
            Write-Host 'on a managed network, connect the PC to your PHONE''s hotspot instead' -ForegroundColor Red
            Write-Host 'and run this script again (the popup IP will be a 192.168.x.x one).' -ForegroundColor Red
        }
    }
    elseif ($pairText -match '(?i)failed to connect|timed out|refused|unreachable|cannot resolve') {
        Write-Host "The PC could not reach $PairAddr." -ForegroundColor Red
        Write-Host 'Check: phone and PC on the SAME Wi-Fi network, the popup IP in the same' -ForegroundColor Red
        Write-Host 'subnet as one of the PC IPs shown above, router AP/client isolation,' -ForegroundColor Red
        Write-Host 'and no VPN active on either device.' -ForegroundColor Red
    }
    else {
        Write-Host 'Pairing FAILED. Common causes:' -ForegroundColor Red
        Write-Host '  - The pairing popup timed out (it expires ~1 min). Tap "Pair device with pairing code" again for a fresh port/code.'
        Write-Host '  - Typo in the IP:PORT (that port is the PAIRING port, different from the port on the main screen).'
    }
}

if (-not $Paired) {
    Write-Host ''
    Write-Host "Pairing did not succeed after $MaxAttempts attempts." -ForegroundColor Red
    Read-Host 'Press Enter to exit'
    exit 1
}

Write-Host ''
Write-Host 'Paired! Now looking for the phone on the network...' -ForegroundColor Green
Write-Host '(Make sure the main "Wireless debugging" screen is still open on the phone.)'

$Deadline  = (Get-Date).AddSeconds(60)
$Connected = $false
while ((Get-Date) -lt $Deadline -and -not $Connected) {
    $services = & $Adb mdns services 2>$null
    foreach ($line in $services) {
        if ($line -match '_adb-tls-connect\._tcp' -and
            $line -match '(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}):(\d{1,5})') {
            $Target = "$($Matches[1]):$($Matches[2])"
            Write-Host "Found device at $Target - connecting..." -ForegroundColor Yellow
            & $Adb connect $Target
            $Connected = $true
            break
        }
    }
    if (-not $Connected) { Start-Sleep -Seconds 2 }
}

if (-not $Connected) {
    # mDNS discovery is often blocked by the Windows firewall even though
    # pairing worked - offer a manual connect using the phone's main screen.
    Write-Host ''
    Write-Host 'The phone was not discovered automatically. mDNS discovery is often' -ForegroundColor Yellow
    Write-Host 'blocked by the Windows firewall (run scripts\fix_firewall.ps1 as admin).' -ForegroundColor Yellow
    Write-Host ''
    $Manual = (Read-Host 'To connect manually, enter the IP:PORT from the phone''s main "Wireless debugging" screen (Enter to skip)').Trim()
    if ($Manual -match '^\d{1,3}(\.\d{1,3}){3}:\d{1,5}$') {
        Write-Host "Connecting to $Manual ..." -ForegroundColor Yellow
        $connectOutput = & $Adb connect $Manual 2>&1
        $connectText   = ($connectOutput | Out-String).Trim()
        Write-Host $connectText
        if ($connectText -match '(?i)(already )?connected to') {
            $Connected = $true
        }
    }
}

Write-Host ''
if ($Connected) {
    Write-Host 'SUCCESS - phone connected over Wi-Fi:' -ForegroundColor Green
    & $Adb devices -l
    Write-Host ''
    Write-Host 'From now on: toggle Wireless debugging on the phone, then run' -ForegroundColor Green
    Write-Host '  scripts\start_wireless_watch.bat' -ForegroundColor Green
    Write-Host 'and Pippo will build & launch automatically.' -ForegroundColor Green
} else {
    Write-Host 'Pairing succeeded, but no connection could be established yet.' -ForegroundColor Yellow
    Write-Host 'Toggle Wireless debugging off/on and run scripts\wireless_watch.ps1 -' -ForegroundColor Yellow
    Write-Host 'if the phone still never appears, run scripts\fix_firewall.ps1 as admin.' -ForegroundColor Yellow
}

Write-Host ''
Read-Host 'Press Enter to close'

