# Wireless Debugging - auto-detect & auto-launch Pippo

Goal: flip **Wireless debugging** ON on your phone and the app launches on it,
no cable, no manual `adb connect`.

## How it works

- Android 11+ advertises the "Wireless debugging" switch over **mDNS**
  (`_adb-tls-connect._tcp`).
- The watcher (`scripts/wireless_watch.ps1`) polls ADB's mDNS discovery every
  ~2 s. When your phone appears it runs `adb connect`, then launches the app:
  - `-Mode flutter` (default): `flutter run -d <phone>` from `Mobile\`
    (build + install + launch + **hot reload**).
  - `-Mode app`: `am start` on the already-installed app (instant, no rebuild).

## One-time setup (do this once)

1. Make sure your **phone and PC are on the same Wi-Fi network**.
2. On the phone: **Settings > Developer options > Wireless debugging > ON**.
3. Run `scripts\pair_phone.ps1` and follow the prompts:
   - On the phone tap **"Pair device with pairing code"**.
   - Type the shown `IP:PORT` and the 6-digit code into the script.
   - After pairing, the script auto-connects the phone.
   - (Pairing survives reboots - you only do this once, or again only if you
     toggle "Revoke wireless debugging authorizations" / reinstall the OS.)
4. If the phone was not discovered in step 3, run `scripts\fix_firewall.ps1`
   in an **admin** PowerShell (Windows Firewall usually blocks UDP 5353),
   then re-run `pair_phone.ps1`.

## Everyday use

Toggle Wireless debugging ON on the phone, then pick one:

| Action | How |
|---|---|
| Build + run with hot reload | Double-click `scripts\start_wireless_watch.bat` |
| Quick-launch installed app | Double-click `scripts\start_wireless_quicklaunch.bat` |
| From VS Code (open `Mobile\`) | Terminal > Run Task > "Wireless: ..." |
| From a terminal | `powershell -NoProfile -ExecutionPolicy Bypass -File scripts\wireless_watch.ps1` |

The watcher stays open: toggle Wireless debugging **off**, and the device is
forgotten; toggle it **on** again later and Pippo launches again automatically.
`Ctrl+C` stops the watcher (or press `q` inside a `flutter run` session).

## Troubleshooting

- **`adb pair` fails with "protocol fault (couldn't read status message)"**:
  the script probes the pairing port to tell these apart:
  - *Port unreachable (timed out)* - the network blocks device-to-device
    traffic (**AP/client isolation**, typical on campus/office/hotel/guest
    Wi-Fi). Disable isolation on a home router, or connect the PC to the
    **phone's hotspot** and pair over that network.
  - *Port reachable but pairing still failed* - the pairing popup had
    closed/expired; re-open it and use the NEW port + code within ~1 min.
- **Phone never appears**: phone/PC on different networks or a guest Wi-Fi
  (client isolation) - use the same network; or run `fix_firewall.ps1` as admin.
- **Connects but shows `offline`**: toggle Wireless debugging off/on; the
  watcher clears stale transports on start.
- **`flutter run` needs no Node.js backend**: the mobile app uses its local
  `atlas_core` package; the watcher only handles the device side.
