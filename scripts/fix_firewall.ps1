# ============================================================================
#  fix_firewall.ps1  -  Run in an ADMIN PowerShell (right-click > Run as...)
#
#  Windows Firewall commonly blocks adb's mDNS discovery (UDP 5353), which is
#  why the phone may never appear even with Wireless debugging turned ON.
#  This adds an allow rule for adb.exe inbound UDP traffic.
# ============================================================================

$Adb = Join-Path $env:LOCALAPPDATA 'Android\Sdk\platform-tools\adb.exe'

if (-not (Test-Path $Adb)) {
    Write-Host "ERROR: adb.exe not found at $Adb" -ForegroundColor Red
    exit 1
}

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
           ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host 'This script must be run as Administrator. Re-run it elevated.' -ForegroundColor Red
    exit 1
}

Write-Host "Adding firewall rule for: $Adb" -ForegroundColor Yellow
Remove-NetFirewallRule -DisplayName 'ADB mDNS Wireless Debugging' -ErrorAction SilentlyContinue
New-NetFirewallRule -DisplayName 'ADB mDNS Wireless Debugging' `
    -Description 'Allow adb to discover phones advertising Wireless debugging (mDNS/UDP 5353)' `
    -Direction Inbound -Action Allow -Program $Adb -Protocol UDP | Out-Null
New-NetFirewallRule -DisplayName 'ADB mDNS Wireless Debugging (TCP)' `
    -Description 'Allow inbound TCP replies for adb wireless connections' `
    -Direction Inbound -Action Allow -Program $Adb -Protocol TCP | Out-Null

Write-Host 'Done. Restart the watcher and toggle Wireless debugging on the phone.' -ForegroundColor Green
Read-Host 'Press Enter to close'
