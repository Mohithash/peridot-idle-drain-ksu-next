# Peridot Idle Drain Tweaks

KernelSU Next module with WebUI for reducing idle battery drain on Xiaomi peridot running VoltageOS.

This module applies conservative Android settings that commonly affect overnight drain. It is designed to be reversible, visible through logs, and safe for daily use.

## Overview

Peridot Idle Drain Tweaks runs after boot through KernelSU Next and applies a small set of idle-focused settings. The goal is to reduce background wakeups from scanning, ambient display, network recommendation, and device-idle behavior without disabling core phone features.

The module includes:

- KernelSU Next module metadata
- boot-time `service.sh`
- WebUI in `webroot/index.html`
- command-line control script at `scripts/tune.sh`
- backup and restore support
- log output for troubleshooting

Default configuration:

```txt
ENABLED=1
AGGRESSIVE=0
SCANNING_TWEAKS=1
DISPLAY_IDLE_TWEAKS=1
DOZE_TUNING=1
ULTRA_IDLE=0
PROTECTED_PACKAGES=com.android.dialer,com.android.phone,com.android.server.telecom,...
```

## Compatibility

Recommended:

- Xiaomi peridot
- VoltageOS
- KernelSU Next

May work, but untested:

- Other AOSP-based peridot ROMs

Not recommended:

- MIUI
- HyperOS
- other devices
- non-peridot ROM/device ports

The module uses mostly standard Android settings, but defaults and ROM behavior can vary. Treat it as a VoltageOS peridot module first.

## What It Changes

Normal mode disables or reduces common idle wake sources:

- Wi-Fi scanning always available
- BLE scanning always available
- nearby scanning settings
- adaptive connectivity
- network recommendations
- Wi-Fi wake / network notification behavior
- AOD / ambient display settings
- pickup wake
- tap-to-wake / double-tap-to-wake style settings where exposed through Android settings
- screen-off UDFPS setting where exposed
- `mobile_data_always_on`

It also applies moderate `device_idle` constants through `device_config` to encourage deeper idle without using extreme values.

The 1.1.0 tuning pass was informed by the available VoltageOS peridot device tree:

- peridot exposes AOD/doze, pickup pulse, single-tap/double-tap, and screen-off UDFPS support
- peridot enables Wi-Fi background scanning support
- peridot exposes SurfaceFlinger/kernel idle timer related properties
- peridot carries radio advanced-scan defaults and Qualcomm diagnostic/debug components that should be observed, not forcibly disabled by a user module

Aggressive mode additionally changes discovery/assistant/voice-interaction style settings:

- Wi-Fi poor connection warning
- Wi-Fi verbose logging setting
- Bluetooth while driving setting
- assistant setting
- voice interaction service setting

Aggressive mode is disabled by default.

## Ultra Idle Mode

Version 1.2.0 adds an optional Ultra Idle profile for users who care mainly about:

- incoming/outgoing calls
- SMS/telephony basics
- Clock/alarm reliability
- root/KernelSU/LSPosed availability
- lowest possible idle drain from settings-level tuning

Ultra mode automatically enables the existing scanning, display-idle, Doze, and aggressive categories. It also enables Android-level app standby/restriction/freezer toggles where the ROM exposes them through settings. It does not force-stop, disable, or freeze any package directly.

Ultra mode may reduce convenience features such as location background behavior, Bluetooth background behavior, notification badges, lock-screen notification display, haptics, and screen rotation settings if those keys exist on the ROM. It is intended for users who use Thanox Pro, App Manager, or another app-control tool to decide which apps remain alive.

Calls and Clock should remain safe because the default protected list includes common telephony, Telecom, Dialer, telephony provider, Clock, GMS/GSF/IMS, SystemUI, KernelSU/Magisk, and LSPosed packages. Still, package names vary by ROM, so verify your installed Clock, SMS, and dialer package names.

## Protected Packages and Thanox

The module keeps a protected package list for Thanox guidance. It does not edit Thanox databases because that would be fragile across Thanox versions.

Default protected packages include:

- `com.android.dialer`
- `com.android.phone`
- `com.android.server.telecom`
- `com.android.providers.telephony`
- `com.android.contacts`
- `com.android.messaging`
- `com.google.android.apps.messaging`
- `com.android.deskclock`
- `com.google.android.deskclock`
- `com.google.android.gms`
- `com.google.android.gsf`
- `com.google.android.ims`
- `com.android.systemui`
- `me.weishu.kernelsu`
- `com.topjohnwu.magisk`
- `org.lsposed.manager`

Add your own must-stay-awake apps, for example WhatsApp or Telegram, before making Thanox aggressively freeze apps after screen off.

Suggested Thanox concept:

- whitelist the protected packages
- whitelist any messenger that must notify instantly
- restrict background start/wakeup for all other user apps after screen off
- freeze or hibernate noisy apps such as shopping, payment, social, video, or food apps after screen off/exit
- do not freeze Phone, Telecom, Telephony Provider, Clock, GMS, GSF, IMS, SystemUI, KernelSU, Magisk, or LSPosed

## What It Does Not Touch

This module intentionally does not:

- disable packages
- freeze apps
- stop Google Play services
- stop SystemUI
- stop IMS, modem, radio, or telephony services
- remount system/vendor/product partitions
- edit thermal configuration
- edit CPU or GPU governors
- blindly disable kernel wakelocks
- change SELinux
- remove root, LSPosed, or module functionality

It is a settings-level idle tuning module, not a kernel undervolt, debloat, thermal, or app freezer module.

## Install

Install the release ZIP from KernelSU Next:

```txt
dist/peridot-idle-drain-ksu-next-v1.2.0.zip
```

Steps:

1. Open KernelSU Next.
2. Go to Modules.
3. Install the ZIP.
4. Reboot.
5. Open the module WebUI from KernelSU Next.

## WebUI Usage

The WebUI provides:

- Enable / disable module
- Enable / disable aggressive mode
- Enable / disable scanning tweaks
- Enable / disable display idle tweaks
- Enable / disable Doze tuning
- Apply now
- Diagnose
- Restore backed-up settings
- View logs
- Clear logs

Changes are stored in:

```txt
/data/adb/modules/peridot_idle_drain/config.conf
```

## Manual Commands

Check status:

```sh
su -c 'sh /data/adb/modules/peridot_idle_drain/scripts/tune.sh status'
```

Apply tweaks:

```sh
su -c 'sh /data/adb/modules/peridot_idle_drain/scripts/tune.sh apply'
```

Restore backed-up settings:

```sh
su -c 'sh /data/adb/modules/peridot_idle_drain/scripts/tune.sh restore'
```

Enable or disable the module:

```sh
su -c 'sh /data/adb/modules/peridot_idle_drain/scripts/tune.sh set-enabled 1'
su -c 'sh /data/adb/modules/peridot_idle_drain/scripts/tune.sh set-enabled 0'
```

Enable or disable aggressive mode:

```sh
su -c 'sh /data/adb/modules/peridot_idle_drain/scripts/tune.sh set-aggressive 1'
su -c 'sh /data/adb/modules/peridot_idle_drain/scripts/tune.sh set-aggressive 0'
```

Enable or disable Ultra Idle mode:

```sh
su -c 'sh /data/adb/modules/peridot_idle_drain/scripts/tune.sh set-ultra 1'
su -c 'sh /data/adb/modules/peridot_idle_drain/scripts/tune.sh set-ultra 0'
```

Show or edit protected packages:

```sh
su -c 'sh /data/adb/modules/peridot_idle_drain/scripts/tune.sh protected-list'
su -c 'sh /data/adb/modules/peridot_idle_drain/scripts/tune.sh protected-add com.whatsapp'
su -c 'sh /data/adb/modules/peridot_idle_drain/scripts/tune.sh protected-remove com.example.app'
su -c 'sh /data/adb/modules/peridot_idle_drain/scripts/tune.sh protected-reset'
```

Export the Thanox helper file:

```sh
su -c 'sh /data/adb/modules/peridot_idle_drain/scripts/tune.sh export-thanox'
```

The helper is written to:

```txt
/data/local/tmp/peridot_thanox_whitelist.txt
/sdcard/Download/peridot_thanox_whitelist.txt
```

Enable or disable tweak categories:

```sh
su -c 'sh /data/adb/modules/peridot_idle_drain/scripts/tune.sh set-scanning 1'
su -c 'sh /data/adb/modules/peridot_idle_drain/scripts/tune.sh set-display 1'
su -c 'sh /data/adb/modules/peridot_idle_drain/scripts/tune.sh set-doze 1'
```

Collect a read-only diagnosis report:

```sh
su -c 'sh /data/adb/modules/peridot_idle_drain/scripts/tune.sh diagnose'
```

View or clear logs:

```sh
su -c 'sh /data/adb/modules/peridot_idle_drain/scripts/tune.sh logs'
su -c 'sh /data/adb/modules/peridot_idle_drain/scripts/tune.sh clear-logs'
```

## Restore/Uninstall

The first apply creates a backup file:

```txt
/data/local/tmp/peridot_idle_drain_backup.txt
```

Logs are written to:

```txt
/data/local/tmp/peridot_idle_drain.log
```

Diagnosis reports are written to:

```txt
/data/local/tmp/peridot_idle_drain_diagnose.txt
```

To restore original settings:

```sh
su -c 'sh /data/adb/modules/peridot_idle_drain/scripts/tune.sh restore'
```

Then disable or uninstall the module from KernelSU Next and reboot.

If you uninstall without restoring first, Android may keep the changed settings because they are stored in the system settings database. Restore first if you want to go back to previous values.

## Idle Drain Testing

For a fair before/after test:

1. Charge to 90-100%.
2. Reboot.
3. Wait 5 minutes after unlock.
4. Turn the screen off.
5. Leave the phone untouched for 6-8 hours, ideally overnight.
6. Keep SIM, Wi-Fi, Bluetooth, NFC, and location in your normal daily state.
7. Compare battery drop per hour.

Rough guide:

- `0.3-0.8%/hour`: good
- around `1%/hour`: acceptable
- `2%+/hour`: likely a real wakelock, modem, app, or suspend issue

Useful logs for deeper diagnosis:

```sh
adb shell dumpsys batterystats > batterystats.txt
adb shell dumpsys deviceidle > deviceidle.txt
adb shell su -c 'cat /sys/kernel/debug/wakeup_sources' > wakeup_sources.txt
adb shell su -c 'cat /sys/kernel/debug/suspend_stats' > suspend_stats.txt
adb shell dmesg > dmesg.txt
adb logcat -d > logcat.txt
```

## Risks/Notes

- Some features may feel less automatic after applying the module, especially nearby discovery, Wi-Fi suggestions, ambient display, pickup wake, or assistant behavior in aggressive mode.
- If you rely on AOD, pickup wake, tap-to-wake, or smart connectivity features, keep aggressive mode off and restore if needed.
- This module does not guarantee low drain if the real cause is modem, IMS, poor signal, a third-party app, kernel wakelock, broken suspend, or vendor firmware behavior.
- VoltageOS, Android, and device trees can change. Re-test after ROM updates.
- This module is not an official VoltageOS project.

## Credits

- Created for Xiaomi peridot / VoltageOS idle-drain testing.
- Maintained by Mohithash with Codex assistance.
- Thanks to the VoltageOS and peridot maintainers for the base ROM/device work.
