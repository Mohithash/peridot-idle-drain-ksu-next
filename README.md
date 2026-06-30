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
PROFILE=idle
NIGHT_SCHEDULE=0
NIGHT_START=23:00
NIGHT_END=07:00
PAUSED_UNTIL=0
AGGRESSIVE=0
SCANNING_TWEAKS=1
DISPLAY_IDLE_TWEAKS=1
DOZE_TUNING=1
ULTRA_IDLE=0
SCREEN_ON_SAVER=0
HAPTICS_OFF=0
DARK_MODE=0
DARK_WALLPAPER=0
EXPORT_APP_POLICY=1
SCREEN_ON_REFRESH_RATE=60
PROTECTED_PACKAGES=com.android.dialer,com.android.phone,com.android.server.telecom,...
```

## Profiles and Schedule

Version 1.4.0 adds profile presets:

- `balanced`: scanning and Doze tuning, keeps display convenience and 120 Hz
- `idle`: default idle saver, scanning plus display idle plus Doze
- `ultra`: strongest safe settings, 60 Hz, dark mode, haptics off, Ultra Idle on
- `night`: same safe aggressive direction as Ultra, intended for overnight use
- `screen`: screen-on saver, 60 Hz, dark mode, haptics off, without forcing display idle/Doze

Night schedule can apply the `night` profile automatically during a chosen window, for example `23:00-07:00`. Calls, Clock/alarm, telephony, GMS/IMS, SystemUI, root and LSPosed remain protected by design.

You can pause the module temporarily for gaming, navigation, banking, camera, or any situation where you want normal behavior:

```sh
su -c 'sh /data/adb/modules/peridot_idle_drain/scripts/tune.sh pause-minutes 30'
su -c 'sh /data/adb/modules/peridot_idle_drain/scripts/tune.sh resume'
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

## Screen-On Saver and UI Reductions

Version 1.3.0 adds optional screen-on battery helpers:

- refresh-rate cap: `60`, `90`, or `120`
- haptics/vibration off where Android exposes settings keys
- Android dark mode request
- best-effort black wallpaper command
- app policy export for Thanox and Hail

The screen-on saver is intentionally simple. Display brightness, gaming, camera, 5G in weak signal, and heavy apps dominate screen-on drain, so the module caps refresh rate and reduces extra discovery behavior without forcing brightness or breaking calls.

Dark wallpaper uses Android's `cmd wallpaper` when available. Android does not expose a reliable universal wallpaper backup/restore command, so restore your previous wallpaper manually if you use this option.

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

Recommended optional whitelist apps:

- `com.whatsapp` if you need instant WhatsApp messages
- `org.telegram.messenger` for Telegram stable
- `org.thunderdog.challegram` for Telegram X
- your authenticator app
- your calendar/reminder app if separate from Clock
- banking or payment apps only if you truly need alerts

Suggested Thanox concept:

- whitelist the protected packages
- whitelist any messenger that must notify instantly
- restrict background start/wakeup for all other user apps after screen off
- freeze or hibernate noisy apps such as shopping, payment, social, video, or food apps after screen off/exit
- do not freeze Phone, Telecom, Telephony Provider, Clock, GMS, GSF, IMS, SystemUI, KernelSU, Magisk, or LSPosed

## Hail, Notifications, and Telegram

The module exports an app policy helper instead of editing Hail/Thanox private data or blindly changing appops for every package.

Suggested Hail concept:

- select all non-whitelist user apps for freeze
- do not freeze protected packages
- use manual launch/unfreeze for apps you only need while using the phone
- test banking/payment apps before relying on them, because freezing can delay security prompts or transaction alerts

Suggested notification concept:

- disable notifications for non-whitelist apps from Android Settings, App Manager, Thanox, or each app's settings
- keep notifications only for calls, Clock/alarm, SMS, and your chosen personal messenger
- avoid global notification appops scripts unless you are ready to recover manually

Telegram limitation:

Android/KernelSU cannot reliably allow only personal messages while globally muting groups, channels, and bots. Configure Telegram itself:

- Telegram > Settings > Notifications and Sounds
- Private Chats: on
- Groups: off
- Channels: off
- mute bots/other chats manually or through Telegram folders/notification exceptions
- keep Telegram whitelisted only if instant personal messages matter

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
dist/peridot-idle-drain-ksu-next-v1.4.0.zip
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
- Select and apply profiles
- Configure night schedule and night window
- Pause/resume tweaks temporarily
- Enable / disable aggressive mode
- Enable / disable scanning tweaks
- Enable / disable display idle tweaks
- Enable / disable Doze tuning
- Enable / disable screen-on saver
- Select refresh cap
- Enable / disable haptics off
- Enable / disable dark mode
- Enable / disable dark wallpaper
- Apply now
- Diagnose
- Idle score
- Export module backup
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

Profiles:

```sh
su -c 'sh /data/adb/modules/peridot_idle_drain/scripts/tune.sh profile-list'
su -c 'sh /data/adb/modules/peridot_idle_drain/scripts/tune.sh set-profile ultra'
su -c 'sh /data/adb/modules/peridot_idle_drain/scripts/tune.sh apply-profile ultra'
```

Night schedule:

```sh
su -c 'sh /data/adb/modules/peridot_idle_drain/scripts/tune.sh set-night-schedule 1'
su -c 'sh /data/adb/modules/peridot_idle_drain/scripts/tune.sh set-night-window 23:00 07:00'
```

Pause and resume:

```sh
su -c 'sh /data/adb/modules/peridot_idle_drain/scripts/tune.sh pause-minutes 30'
su -c 'sh /data/adb/modules/peridot_idle_drain/scripts/tune.sh resume'
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

Screen-on saver and UI reductions:

```sh
su -c 'sh /data/adb/modules/peridot_idle_drain/scripts/tune.sh set-screen-saver 1'
su -c 'sh /data/adb/modules/peridot_idle_drain/scripts/tune.sh set-refresh-rate 60'
su -c 'sh /data/adb/modules/peridot_idle_drain/scripts/tune.sh set-haptics 1'
su -c 'sh /data/adb/modules/peridot_idle_drain/scripts/tune.sh set-dark-mode 1'
su -c 'sh /data/adb/modules/peridot_idle_drain/scripts/tune.sh set-dark-wallpaper 1'
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

Export the full Thanox/Hail/app policy helper:

```sh
su -c 'sh /data/adb/modules/peridot_idle_drain/scripts/tune.sh export-app-policy'
```

The helper is written to:

```txt
/data/local/tmp/peridot_app_policy.txt
/sdcard/Download/peridot_app_policy.txt
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

Generate a simple idle score:

```sh
su -c 'sh /data/adb/modules/peridot_idle_drain/scripts/tune.sh idle-score'
```

The score reads suspend and wakeup-source diagnostics when available and classifies the current state as `good`, `warning`, or `bad`. It is only a heuristic; overnight drain testing is still the real proof.

Export module config and protected package backup:

```sh
su -c 'sh /data/adb/modules/peridot_idle_drain/scripts/tune.sh export-backup'
```

Backup paths:

```txt
/data/local/tmp/peridot_idle_module_backup.txt
/sdcard/Download/peridot_idle_module_backup.txt
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
- Hail/Thanox freezing can delay or block notifications for frozen apps. Keep only the apps you truly need whitelisted.
- VoltageOS, Android, and device trees can change. Re-test after ROM updates.
- This module is not an official VoltageOS project.

## Credits

- Created for Xiaomi peridot / VoltageOS idle-drain testing.
- Maintained by Mohithash with Codex assistance.
- Thanks to the VoltageOS and peridot maintainers for the base ROM/device work.
