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

Aggressive mode additionally changes discovery/assistant/voice-interaction style settings:

- Wi-Fi poor connection warning
- Wi-Fi verbose logging setting
- Bluetooth while driving setting
- assistant setting
- voice interaction service setting

Aggressive mode is disabled by default.

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
dist/peridot-idle-drain-ksu-next-v1.0.0.zip
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
- Apply now
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
