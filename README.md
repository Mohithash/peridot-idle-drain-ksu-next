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
MY_SETUP=0
SCREEN_ON_REFRESH_RATE=60
PROTECTED_PACKAGES=com.android.dialer,com.android.phone,com.android.server.telecom,...
```

## Profiles and Schedule

Profile presets:

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

## Personal Usage Template

Version 1.7.0 adds a template pack tailored for this VoltageOS peridot workflow:

- always alive: Phone, calls, SMS, Clock/alarm, telephony, IMS, GMS/GSF, SystemUI, root/KernelSU, LSPosed and selected messenger
- temporary only: Maps, enabled while navigating and restricted/frozen again after navigation or app exit
- foreground only: Paytm, banking, shopping and payment apps, allowed when opened manually, then restricted/frozen after exit
- all other user apps: Thanox screen-off restrict/freeze plus Hail manual freeze
- notifications: keep only calls, SMS, Clock/alarm and chosen personal messenger; disable non-whitelist notification spam manually

The template pack is text-only. It does not directly freeze apps, disable packages, suspend packages, revoke notifications, or edit Thanox/Hail private databases.

Recommended first run:

```sh
su -c 'sh /data/adb/modules/peridot_idle_drain/scripts/tune.sh set-my-whitelist-defaults'
su -c 'sh /data/adb/modules/peridot_idle_drain/scripts/tune.sh export-my-template'
su -c 'sh /data/adb/modules/peridot_idle_drain/scripts/tune.sh export-quick-actions'
```

The template pack writes these files to `/data/local/tmp/` and, when storage is mounted, `/sdcard/Download/`:

```txt
peridot_my_template_overview.txt
peridot_thanox_my_rules.txt
peridot_hail_my_lists.txt
peridot_notification_my_plan.txt
peridot_maps_temp_mode.txt
peridot_payment_foreground_only.txt
peridot_telegram_private_only.txt
peridot_quick_actions.txt
```

`set-my-whitelist-defaults` adds recommended protected packages without duplicates. It includes common phone/SMS/Clock/GMS/IMS/SystemUI/root/LSPosed packages, common keyboards, Telegram variants and WhatsApp. Maps is intentionally not protected by default because the intended behavior is temporary navigation mode. Paytm/payment apps are intentionally not protected because the intended behavior is foreground-only usage with notifications muted.

Telegram private-only behavior must be configured inside Telegram itself:

- Private chats: on
- Groups: off or muted
- Channels: off or muted
- Bots/other: muted manually

## Battery-Neutral Module Design

The module itself is designed to avoid becoming a battery drain source:

- `service.sh` is one-shot after boot: it waits for boot completion, applies the selected profile, then exits.
- There is no persistent daemon, no resident loop, and no periodic background polling.
- The WebUI runs commands only when you open it or tap a button.
- The WebUI does not use `setInterval` polling or network/CDN assets.
- The module does not hold wakelocks, block wakelocks, or run a background scheduler.

For ongoing app control, use Thanox/Hail rules manually. The module only exports templates and package lists.

## v1.7.0 Personal Template Workflow

Version 1.7.0 is the personal workflow release for Xiaomi peridot running VoltageOS. It keeps the module in the safe lane: KernelSU applies reversible system settings and generates reports/templates, while Thanox/Hail remain responsible for manual app restriction.

After this release, more improvement needs your real overnight reports rather than more generic tweaks. The module can tell you whether drain looks more like modem/radio, Wi-Fi/CNSS, alarms/apps, jobs, location, sensors, background network, or notification/app spam.

Recommended flow:

1. Install the ZIP and reboot.
2. Run **My Setup** from WebUI or shell.
3. Open the exported Hail candidate list and manually select apps you want Hail to freeze.
4. Open the exported Thanox rules and manually recreate the rules in Thanox Pro.
5. Run `safety-check` after changing profiles or protected packages.
6. Before sleep, run `overnight-start`.
7. After waking, run `overnight-report`.
8. Run `analyze-all` if drain is still above your target.

My Setup enables profile `ultra`, night schedule, aggressive mode, scanning/display/Doze tuning, Ultra Idle, screen-on saver, haptics off, dark mode, best-effort dark wallpaper, 60 Hz refresh cap, and all helper exports.

My Setup does not freeze, disable, suspend, force-stop, block wakelocks, or notification-block packages. Hail and Thanox remain manual because package freezing is personal and can break alerts if applied blindly.

All-in-one analyzer commands:

```sh
su -c 'sh /data/adb/modules/peridot_idle_drain/scripts/tune.sh analyze-all'
su -c 'sh /data/adb/modules/peridot_idle_drain/scripts/tune.sh wakelock-report'
su -c 'sh /data/adb/modules/peridot_idle_drain/scripts/tune.sh alarm-report'
su -c 'sh /data/adb/modules/peridot_idle_drain/scripts/tune.sh jobs-report'
su -c 'sh /data/adb/modules/peridot_idle_drain/scripts/tune.sh location-report'
su -c 'sh /data/adb/modules/peridot_idle_drain/scripts/tune.sh sensor-report'
su -c 'sh /data/adb/modules/peridot_idle_drain/scripts/tune.sh network-report'
su -c 'sh /data/adb/modules/peridot_idle_drain/scripts/tune.sh new-apps-report'
su -c 'sh /data/adb/modules/peridot_idle_drain/scripts/tune.sh snapshot-apps'
```

Analyzer outputs:

```txt
/data/local/tmp/peridot_safety_check.txt
/data/local/tmp/peridot_idle_baseline.txt
/data/local/tmp/peridot_overnight_report.txt
/data/local/tmp/peridot_full_analysis.txt
/sdcard/Download/peridot_full_analysis.txt
/data/local/tmp/peridot_installed_apps_snapshot.txt
/data/local/tmp/peridot_hail_freeze_candidates.txt
/sdcard/Download/peridot_hail_freeze_candidates.txt
/data/local/tmp/peridot_hail_protected_packages.txt
/sdcard/Download/peridot_hail_protected_packages.txt
/data/local/tmp/peridot_thanox_rules.txt
/sdcard/Download/peridot_thanox_rules.txt
/data/local/tmp/peridot_notification_review.txt
/sdcard/Download/peridot_notification_review.txt
/data/local/tmp/peridot_idle_restore_pack.txt
/sdcard/Download/peridot_idle_restore_pack.txt
```

Extra exports:

```sh
su -c 'sh /data/adb/modules/peridot_idle_drain/scripts/tune.sh export-thanox-templates'
su -c 'sh /data/adb/modules/peridot_idle_drain/scripts/tune.sh export-hail-lists'
su -c 'sh /data/adb/modules/peridot_idle_drain/scripts/tune.sh export-restore-pack'
```

Category restore:

```sh
su -c 'sh /data/adb/modules/peridot_idle_drain/scripts/tune.sh restore-category scanning'
su -c 'sh /data/adb/modules/peridot_idle_drain/scripts/tune.sh restore-category display'
su -c 'sh /data/adb/modules/peridot_idle_drain/scripts/tune.sh restore-category doze'
su -c 'sh /data/adb/modules/peridot_idle_drain/scripts/tune.sh restore-category screen'
su -c 'sh /data/adb/modules/peridot_idle_drain/scripts/tune.sh restore-category haptics'
su -c 'sh /data/adb/modules/peridot_idle_drain/scripts/tune.sh restore-category dark'
su -c 'sh /data/adb/modules/peridot_idle_drain/scripts/tune.sh restore-category all'
```

The reports are heuristic and intentionally cautious. They classify likely causes but do not block kernel wakelocks or make irreversible changes.

Telegram personal-only limitation remains in-app only. Keep Telegram whitelisted if you need personal messages, then configure Telegram itself: Private Chats on, Groups off, Channels off, and mute bots/other chats manually.

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
dist/peridot-idle-drain-ksu-next-v1.7.0.zip
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
- My Setup
- Safety Check
- Overnight Start
- Overnight Report
- Diagnose
- Analyze All
- Wakelocks / Alarms / Jobs / Location / Sensors / Network reports
- New Apps report and app snapshot
- Idle score
- Export module backup
- Export restore pack
- Export Hail candidates
- Export Hail lists
- Export Thanox rules
- Export Thanox templates
- My Template
- Whitelist Defaults
- Quick Actions
- Notification report
- Restore by category
- Restore backed-up settings
- View logs
- Clear logs

Changes are stored in:

```txt
/data/adb/modules/peridot_idle_drain/config.conf
```

Open the WebUI from KernelSU Next / KernelSU Manager's module screen. It will not work if `webroot/index.html` is opened from a browser or file manager because the `kernelsu` WebUI API is only injected by the manager.

For ADB command testing, grant root to shell in your root manager first. Otherwise `adb shell su -c ...` may fail even though the module itself is installed.

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

Safety check for calls and Clock:

```sh
su -c 'sh /data/adb/modules/peridot_idle_drain/scripts/tune.sh safety-check'
```

It reads default dialer role where available, package presence, next alarm, telephony registry snippets and phone/IMS snippets. It is read-only and tolerant of missing ROM commands.

Overnight analyzer:

```sh
su -c 'sh /data/adb/modules/peridot_idle_drain/scripts/tune.sh overnight-start'
# leave phone idle overnight
su -c 'sh /data/adb/modules/peridot_idle_drain/scripts/tune.sh overnight-report'
```

The report compares battery level, elapsed time, suspend failed/short deltas and top wakeup source where readable. It classifies the result as `good`, `warning`, or `bad`, with suspected cause buckets such as modem/radio, Wi-Fi/CNSS, alarms/apps, sensors, fingerprint/touch, or unknown.

Export Hail candidates:

```sh
su -c 'sh /data/adb/modules/peridot_idle_drain/scripts/tune.sh export-hail'
```

Export the personalized template pack:

```sh
su -c 'sh /data/adb/modules/peridot_idle_drain/scripts/tune.sh set-my-whitelist-defaults'
su -c 'sh /data/adb/modules/peridot_idle_drain/scripts/tune.sh export-my-template'
su -c 'sh /data/adb/modules/peridot_idle_drain/scripts/tune.sh export-quick-actions'
```

Export Thanox rules:

```sh
su -c 'sh /data/adb/modules/peridot_idle_drain/scripts/tune.sh export-thanox-rules'
```

Export notification review candidates:

```sh
su -c 'sh /data/adb/modules/peridot_idle_drain/scripts/tune.sh notification-report'
```

Apply the personal ultra setup and generate all app-control helper files:

```sh
su -c 'sh /data/adb/modules/peridot_idle_drain/scripts/tune.sh my-setup'
```

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
