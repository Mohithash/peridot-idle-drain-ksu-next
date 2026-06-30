#!/system/bin/sh

MODDIR="${MODDIR:-$(cd "$(dirname "$0")/.." 2>/dev/null && pwd)}"
CONFIG_FILE="$MODDIR/config.conf"
LOG_FILE="/data/local/tmp/peridot_idle_drain.log"
BACKUP_FILE="/data/local/tmp/peridot_idle_drain_backup.txt"
DIAG_FILE="/data/local/tmp/peridot_idle_drain_diagnose.txt"
THANOX_FILE_TMP="/data/local/tmp/peridot_thanox_whitelist.txt"
THANOX_FILE_DOWNLOAD="/sdcard/Download/peridot_thanox_whitelist.txt"
APP_POLICY_FILE_TMP="/data/local/tmp/peridot_app_policy.txt"
APP_POLICY_FILE_DOWNLOAD="/sdcard/Download/peridot_app_policy.txt"
MODULE_BACKUP_FILE_TMP="/data/local/tmp/peridot_idle_module_backup.txt"
MODULE_BACKUP_FILE_DOWNLOAD="/sdcard/Download/peridot_idle_module_backup.txt"
BLACK_WALLPAPER="/data/local/tmp/peridot_black_wallpaper.png"
DEFAULT_PROTECTED_PACKAGES="com.android.dialer,com.google.android.dialer,com.android.phone,com.android.server.telecom,com.android.providers.telephony,com.android.contacts,com.android.messaging,com.google.android.apps.messaging,com.android.deskclock,com.google.android.deskclock,com.google.android.gms,com.google.android.gsf,com.google.android.ims,com.google.android.euicc,com.android.systemui,com.android.settings,com.android.permissioncontroller,me.weishu.kernelsu,com.rifsxd.ksunext,com.topjohnwu.magisk,org.lsposed.manager"
RECOMMENDED_OPTIONAL_PACKAGES="com.whatsapp,org.telegram.messenger,org.thunderdog.challegram,com.google.android.apps.authenticator2,com.google.android.calendar"

ensure_files() {
    mkdir -p "$(dirname "$LOG_FILE")" 2>/dev/null
    touch "$LOG_FILE" 2>/dev/null
    chmod 0600 "$LOG_FILE" 2>/dev/null

    if [ ! -f "$CONFIG_FILE" ]; then
        {
            echo "ENABLED=1"
            echo "PROFILE=idle"
            echo "NIGHT_SCHEDULE=0"
            echo "NIGHT_START=23:00"
            echo "NIGHT_END=07:00"
            echo "PAUSED_UNTIL=0"
            echo "AGGRESSIVE=0"
            echo "SCANNING_TWEAKS=1"
            echo "DISPLAY_IDLE_TWEAKS=1"
            echo "DOZE_TUNING=1"
            echo "ULTRA_IDLE=0"
            echo "SCREEN_ON_SAVER=0"
            echo "HAPTICS_OFF=0"
            echo "DARK_MODE=0"
            echo "DARK_WALLPAPER=0"
            echo "EXPORT_APP_POLICY=1"
            echo "SCREEN_ON_REFRESH_RATE=60"
            echo "PROTECTED_PACKAGES=$DEFAULT_PROTECTED_PACKAGES"
        } > "$CONFIG_FILE"
        chmod 0644 "$CONFIG_FILE" 2>/dev/null
    fi
}

bool_or_zero() {
    [ "$1" = "1" ] && echo 1 || echo 0
}

load_config() {
    ensure_files
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
    PROTECTED_PACKAGES="$DEFAULT_PROTECTED_PACKAGES"
    # shellcheck disable=SC1090
    . "$CONFIG_FILE" 2>/dev/null
    ENABLED="$(bool_or_zero "$ENABLED")"
    case "$PROFILE" in
        balanced|idle|ultra|night|screen) ;;
        *) PROFILE=idle ;;
    esac
    NIGHT_SCHEDULE="$(bool_or_zero "$NIGHT_SCHEDULE")"
    case "$NIGHT_START" in
        [0-2][0-9]:[0-5][0-9]) ;;
        *) NIGHT_START=23:00 ;;
    esac
    case "$NIGHT_END" in
        [0-2][0-9]:[0-5][0-9]) ;;
        *) NIGHT_END=07:00 ;;
    esac
    case "$PAUSED_UNTIL" in
        *[!0-9]*|"") PAUSED_UNTIL=0 ;;
    esac
    AGGRESSIVE="$(bool_or_zero "$AGGRESSIVE")"
    SCANNING_TWEAKS="$(bool_or_zero "$SCANNING_TWEAKS")"
    DISPLAY_IDLE_TWEAKS="$(bool_or_zero "$DISPLAY_IDLE_TWEAKS")"
    DOZE_TUNING="$(bool_or_zero "$DOZE_TUNING")"
    ULTRA_IDLE="$(bool_or_zero "$ULTRA_IDLE")"
    SCREEN_ON_SAVER="$(bool_or_zero "$SCREEN_ON_SAVER")"
    HAPTICS_OFF="$(bool_or_zero "$HAPTICS_OFF")"
    DARK_MODE="$(bool_or_zero "$DARK_MODE")"
    DARK_WALLPAPER="$(bool_or_zero "$DARK_WALLPAPER")"
    EXPORT_APP_POLICY="$(bool_or_zero "$EXPORT_APP_POLICY")"
    case "$SCREEN_ON_REFRESH_RATE" in
        60|90|120) ;;
        *) SCREEN_ON_REFRESH_RATE=60 ;;
    esac
    [ -n "$PROTECTED_PACKAGES" ] || PROTECTED_PACKAGES="$DEFAULT_PROTECTED_PACKAGES"
}

save_config() {
    {
        echo "ENABLED=$ENABLED"
        echo "PROFILE=$PROFILE"
        echo "NIGHT_SCHEDULE=$NIGHT_SCHEDULE"
        echo "NIGHT_START=$NIGHT_START"
        echo "NIGHT_END=$NIGHT_END"
        echo "PAUSED_UNTIL=$PAUSED_UNTIL"
        echo "AGGRESSIVE=$AGGRESSIVE"
        echo "SCANNING_TWEAKS=$SCANNING_TWEAKS"
        echo "DISPLAY_IDLE_TWEAKS=$DISPLAY_IDLE_TWEAKS"
        echo "DOZE_TUNING=$DOZE_TUNING"
        echo "ULTRA_IDLE=$ULTRA_IDLE"
        echo "SCREEN_ON_SAVER=$SCREEN_ON_SAVER"
        echo "HAPTICS_OFF=$HAPTICS_OFF"
        echo "DARK_MODE=$DARK_MODE"
        echo "DARK_WALLPAPER=$DARK_WALLPAPER"
        echo "EXPORT_APP_POLICY=$EXPORT_APP_POLICY"
        echo "SCREEN_ON_REFRESH_RATE=$SCREEN_ON_REFRESH_RATE"
        echo "PROTECTED_PACKAGES=$PROTECTED_PACKAGES"
    } > "$CONFIG_FILE"
    chmod 0644 "$CONFIG_FILE" 2>/dev/null
}

log() {
    ensure_files
    printf '%s %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >> "$LOG_FILE"
}

have_cmd() {
    command -v "$1" >/dev/null 2>&1
}

now_epoch() {
    date +%s 2>/dev/null || echo 0
}

time_to_minutes() {
    hour="${1%:*}"
    minute="${1#*:}"
    echo $((10#$hour * 60 + 10#$minute))
}

inside_night_window() {
    start="$(time_to_minutes "$NIGHT_START")"
    end="$(time_to_minutes "$NIGHT_END")"
    now="$(date +%H:%M 2>/dev/null)"
    case "$now" in
        [0-2][0-9]:[0-5][0-9]) ;;
        *) return 1 ;;
    esac
    cur="$(time_to_minutes "$now")"
    if [ "$start" -le "$end" ]; then
        [ "$cur" -ge "$start" ] && [ "$cur" -lt "$end" ]
    else
        [ "$cur" -ge "$start" ] || [ "$cur" -lt "$end" ]
    fi
}

is_paused() {
    now="$(now_epoch)"
    [ "$PAUSED_UNTIL" -gt "$now" ] 2>/dev/null
}

settings_get() {
    settings get "$1" "$2" 2>/dev/null
}

settings_exists() {
    value="$(settings_get "$1" "$2")"
    [ -n "$value" ] && [ "$value" != "null" ]
}

ensure_backup() {
    if [ ! -f "$BACKUP_FILE" ]; then
        : > "$BACKUP_FILE"
        chmod 0600 "$BACKUP_FILE" 2>/dev/null
        log "created backup file: $BACKUP_FILE"
    fi
}

settings_put() {
    namespace="$1"
    key="$2"
    value="$3"
    mode="$4"

    old_value="$(settings_get "$namespace" "$key")"
    existed=1
    [ -n "$old_value" ] && [ "$old_value" != "null" ] || existed=0

    if [ "$mode" = "existing" ] && [ "$existed" = "0" ]; then
        log "settings skipped missing: $namespace $key"
        return
    fi

    ensure_backup
    if ! grep -q "^${namespace}|${key}|" "$BACKUP_FILE" 2>/dev/null; then
        printf '%s|%s|%s\n' "$namespace" "$key" "$old_value" >> "$BACKUP_FILE"
    fi

    if settings put "$namespace" "$key" "$value" >/dev/null 2>&1; then
        log "settings: $namespace $key=$value old=$old_value existed=$existed"
    else
        log "settings failed: $namespace $key=$value"
    fi
}

settings_delete_or_null_restore() {
    namespace="$1"
    key="$2"
    value="$3"

    if [ "$value" = "null" ] || [ -z "$value" ]; then
        settings delete "$namespace" "$key" >/dev/null 2>&1 \
            && log "restored delete: $namespace $key" \
            || log "restore delete failed: $namespace $key"
    else
        settings put "$namespace" "$key" "$value" >/dev/null 2>&1 \
            && log "restored: $namespace $key=$value" \
            || log "restore failed: $namespace $key=$value"
    fi
}

apply_scanning_settings() {
    [ "$SCANNING_TWEAKS" = "1" ] || { log "scanning tweaks skipped"; return; }
    settings_put global wifi_scan_always_enabled 0 common
    settings_put global ble_scan_always_enabled 0 common
    settings_put global adaptive_connectivity_enabled 0 common
    settings_put global network_recommendations_enabled 0 common
    settings_put global wifi_wakeup_enabled 0 common
    settings_put global wifi_networks_available_notification_on 0 common
    settings_put global mobile_data_always_on 0 common

    settings_put secure nearby_scanning_enabled 0 common
    settings_put secure nearby_scanning_permission_allowed 0 existing
    settings_put global nearby_scanning_enabled 0 existing
    settings_put global bluetooth_sanitized_exposure_notification_supported 0 existing
}

apply_display_idle_settings() {
    [ "$DISPLAY_IDLE_TWEAKS" = "1" ] || { log "display idle tweaks skipped"; return; }
    settings_put secure doze_enabled 0 common
    settings_put secure doze_always_on 0 common
    settings_put secure doze_pulse_on_pick_up 0 common
    settings_put secure doze_pulse_on_double_tap 0 common
    settings_put secure doze_pulse_on_tap 0 common
    settings_put secure doze_wake_screen_gesture 0 common
    settings_put secure ambient_display_enabled 0 common
    settings_put secure ambient_display_always_on 0 common
    settings_put secure pickup_gesture_enabled 0 common
    settings_put secure wake_gesture_enabled 0 common
    settings_put secure double_tap_to_wake 0 common

    # Peridot exposes screen-off UDFPS and Xiaomi tap sensors in the device tree.
    settings_put system screen_off_udfps_enabled 0 common
    settings_put system dt2w 0 existing
    settings_put secure screen_off_udfps_enabled 0 existing
    settings_put system single_tap_to_wake 0 existing
}

apply_deviceidle_constants() {
    [ "$DOZE_TUNING" = "1" ] || { log "deviceidle tuning skipped"; return; }
    if ! have_cmd device_config; then
        log "device_config unavailable"
        return
    fi

    constants="inactive_to=300000,sensing_to=60000,locating_to=60000,location_accuracy=2000,motion_inactive_to=300000,idle_after_inactive_to=900000,idle_pending_to=300000,max_idle_pending_to=600000,idle_pending_factor=2.0,idle_to=1800000,max_idle_to=21600000,idle_factor=2.0,min_time_to_alarm=1800000,max_temp_app_whitelist_duration=60000,mms_temp_app_whitelist_duration=20000,sms_temp_app_whitelist_duration=20000,notification_whitelist_duration=20000"

    old="$(device_config get device_idle constants 2>/dev/null)"
    ensure_backup
    if ! grep -q '^device_config|device_idle.constants|' "$BACKUP_FILE" 2>/dev/null; then
        printf '%s|%s|%s\n' "device_config" "device_idle.constants" "$old" >> "$BACKUP_FILE"
    fi

    device_config put device_idle constants "$constants" >/dev/null 2>&1 \
        && log "device_config: device_idle constants applied" \
        || log "device_config failed: device_idle constants"
}

restore_device_config() {
    value="$1"
    if ! have_cmd device_config; then
        log "device_config unavailable for restore"
        return
    fi

    if [ "$value" = "null" ] || [ -z "$value" ]; then
        device_config delete device_idle constants >/dev/null 2>&1 \
            && log "restored delete: device_config device_idle constants" \
            || log "restore delete failed: device_config device_idle constants"
    else
        device_config put device_idle constants "$value" >/dev/null 2>&1 \
            && log "restored: device_config device_idle constants" \
            || log "restore failed: device_config device_idle constants"
    fi
}

apply_aggressive_settings() {
    [ "$AGGRESSIVE" = "1" ] || return
    log "aggressive mode enabled"
    settings_put global wifi_poor_connection_warning 0 existing
    settings_put global wifi_verbose_logging_enabled 0 common
    settings_put global bluetooth_on_while_driving 0 existing
    settings_put secure assistant 0 existing
    settings_put secure voice_interaction_service 0 existing
}

apply_ultra_idle_settings() {
    [ "$ULTRA_IDLE" = "1" ] || return
    log "ultra idle enabled"

    settings_put global app_standby_enabled 1 common
    settings_put global app_restriction_enabled 1 existing
    settings_put global forced_app_standby_enabled 1 existing
    settings_put global app_auto_restriction_enabled 1 existing
    settings_put global adaptive_battery_management_enabled 1 common
    settings_put global enable_freezer 1 existing
    settings_put global cached_apps_freezer 1 existing
    settings_put global bluetooth_on 0 existing
    settings_put secure location_mode 0 existing
    settings_put secure screensaver_enabled 0 common
    settings_put secure notification_badging 0 existing
    settings_put secure lock_screen_show_notifications 0 existing
    settings_put system accelerometer_rotation 0 existing
    settings_put system haptic_feedback_enabled 0 existing
}

apply_screen_on_saver_settings() {
    [ "$SCREEN_ON_SAVER" = "1" ] || return
    log "screen-on saver enabled refresh=$SCREEN_ON_REFRESH_RATE"
    settings_put system peak_refresh_rate "$SCREEN_ON_REFRESH_RATE" common
    settings_put system min_refresh_rate 60 common
    settings_put system user_refresh_rate "$SCREEN_ON_REFRESH_RATE" existing
    settings_put secure user_refresh_rate "$SCREEN_ON_REFRESH_RATE" existing
    settings_put global wifi_verbose_logging_enabled 0 common
    settings_put global adaptive_connectivity_enabled 0 common
    settings_put global network_recommendations_enabled 0 common
}

apply_haptics_settings() {
    [ "$HAPTICS_OFF" = "1" ] || return
    log "haptics off enabled"
    settings_put system haptic_feedback_enabled 0 common
    settings_put system vibrate_when_ringing 0 common
    settings_put system haptic_feedback_intensity 0 existing
    settings_put system notification_vibration_intensity 0 existing
    settings_put system media_vibration_intensity 0 existing
    settings_put system touch_vibration_intensity 0 existing
    settings_put secure haptic_feedback_enabled 0 existing
}

apply_dark_mode_settings() {
    [ "$DARK_MODE" = "1" ] || return
    log "dark mode enabled"
    settings_put secure ui_night_mode 2 existing
    settings_put system ui_night_mode 2 existing
    cmd uimode night yes >/dev/null 2>&1 \
        && log "cmd uimode night yes applied" \
        || log "cmd uimode night yes unavailable"
}

write_black_wallpaper_png() {
    if [ -f "$BLACK_WALLPAPER" ]; then
        return 0
    fi
    if have_cmd base64; then
        printf '%s\n' 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGOSHzRgAAAAABJRU5ErkJggg==' | base64 -d > "$BLACK_WALLPAPER" 2>/dev/null
        chmod 0644 "$BLACK_WALLPAPER" 2>/dev/null
        [ -s "$BLACK_WALLPAPER" ] && return 0
    fi
    return 1
}

apply_dark_wallpaper_settings() {
    [ "$DARK_WALLPAPER" = "1" ] || return
    log "dark wallpaper requested"
    if ! write_black_wallpaper_png; then
        log "dark wallpaper skipped: could not create png"
        return
    fi
    cmd wallpaper set "$BLACK_WALLPAPER" >/dev/null 2>&1 \
        && log "dark wallpaper applied: $BLACK_WALLPAPER" \
        || log "dark wallpaper unsupported by cmd wallpaper on this ROM"
}

package_valid() {
    case "$1" in
        ""|*[!A-Za-z0-9._-]*|.*|*..*|*.) return 1 ;;
        *.*) return 0 ;;
        *) return 1 ;;
    esac
}

protected_contains() {
    pkg="$1"
    old_ifs="$IFS"
    IFS=,
    for item in $PROTECTED_PACKAGES; do
        IFS="$old_ifs"
        [ "$item" = "$pkg" ] && return 0
        IFS=,
    done
    IFS="$old_ifs"
    return 1
}

protected_print_lines() {
    old_ifs="$IFS"
    IFS=,
    for item in $PROTECTED_PACKAGES; do
        IFS="$old_ifs"
        [ -n "$item" ] && echo "$item"
        IFS=,
    done
    IFS="$old_ifs"
}

installed_user_packages() {
    pm list packages -3 2>/dev/null | sed 's/^package://'
}

recommended_optional_print_lines() {
    old_ifs="$IFS"
    IFS=,
    for item in $RECOMMENDED_OPTIONAL_PACKAGES; do
        IFS="$old_ifs"
        [ -n "$item" ] && echo "$item"
        IFS=,
    done
    IFS="$old_ifs"
}

protected_add_pkg() {
    pkg="$1"
    load_config
    if ! package_valid "$pkg"; then
        echo "Invalid package name: $pkg"
        exit 2
    fi
    if protected_contains "$pkg"; then
        echo "$pkg already protected"
        exit 0
    fi
    if [ -n "$PROTECTED_PACKAGES" ]; then
        PROTECTED_PACKAGES="$PROTECTED_PACKAGES,$pkg"
    else
        PROTECTED_PACKAGES="$pkg"
    fi
    save_config
    log "protected add: $pkg"
    echo "Added protected package: $pkg"
}

protected_remove_pkg() {
    pkg="$1"
    load_config
    if ! package_valid "$pkg"; then
        echo "Invalid package name: $pkg"
        exit 2
    fi
    new_list=""
    old_ifs="$IFS"
    IFS=,
    for item in $PROTECTED_PACKAGES; do
        IFS="$old_ifs"
        if [ "$item" != "$pkg" ] && [ -n "$item" ]; then
            [ -n "$new_list" ] && new_list="$new_list,$item" || new_list="$item"
        fi
        IFS=,
    done
    IFS="$old_ifs"
    PROTECTED_PACKAGES="$new_list"
    save_config
    log "protected remove: $pkg"
    echo "Removed protected package if present: $pkg"
}

protected_reset() {
    load_config
    PROTECTED_PACKAGES="$DEFAULT_PROTECTED_PACKAGES"
    save_config
    log "protected reset"
    echo "Protected packages reset to defaults."
}

cmd_protected_list() {
    load_config
    protected_print_lines
}

write_thanox_helper() {
    target="$1"
    {
        echo "Peridot Idle Drain - Thanox Helper"
        date
        echo
        echo "Recommended target:"
        echo "- Xiaomi peridot running VoltageOS"
        echo "- Calls and Clock/alarm should stay protected"
        echo
        echo "Protected packages:"
        protected_print_lines | sed 's/^/- /'
        echo
        echo "Thanox setup concept:"
        echo "1. Add the protected packages above to your Thanox whitelist/do-not-freeze list."
        echo "2. Add any app that must notify instantly, such as WhatsApp or Telegram."
        echo "3. For all other user apps, use Thanox to restrict background start/wakeup after screen off."
        echo "4. For apps like Paytm/shopping/social/video apps, freeze or hibernate after screen off/exit."
        echo "5. Do not freeze Phone, Telecom, Telephony Provider, Clock, GMS, GSF, IMS, SystemUI, KernelSU, Magisk, or LSPosed."
        echo
        echo "Suggested Thanox policy:"
        echo "- Screen off: restrict background start for non-protected apps"
        echo "- Screen off: hibernate/freeze non-protected apps after a delay"
        echo "- App launch: allow app to unfreeze when manually opened"
        echo "- App exit or screen off: refreeze noisy apps"
        echo "- Notification spam: disable app notification categories first, then restrict wakeups"
        echo
        echo "Notes:"
        echo "- This module does not edit Thanox databases because that is fragile across Thanox versions."
        echo "- Verify installed package names on your phone before adding custom protected apps."
        echo "- Thanox package names seen in the wild can vary; add the actual Thanox package itself if it gets restricted."
    } > "$target" 2>/dev/null
}

write_app_policy() {
    target="$1"
    {
        echo "Peridot Idle Drain - App Policy Helper"
        date
        echo
        echo "Goal:"
        echo "- Lowest practical drain while keeping calls, SMS/telephony, Clock/alarm, GMS/IMS, SystemUI, root, and selected personal messengers working."
        echo "- KernelSU module applies system settings only."
        echo "- Thanox/Hail should handle app freezing and notification control."
        echo
        echo "Protected / whitelist packages:"
        protected_print_lines | sed 's/^/- /'
        echo
        echo "Recommended apps to add if you use them:"
        recommended_optional_print_lines | sed 's/^/- /'
        echo "- your banking app only if you need alerts"
        echo "- your authenticator app if not listed above"
        echo "- your calendar/reminder app if separate from Clock"
        echo
        echo "Installed user apps detected by pm list packages -3:"
        installed_user_packages | sed 's/^/- /'
        echo
        echo "Freeze candidates among installed user apps:"
        installed_user_packages | while read -r pkg; do
            [ -n "$pkg" ] || continue
            if protected_contains "$pkg"; then
                continue
            fi
            echo "- $pkg"
        done
        echo
        echo "Thanox policy:"
        echo "1. Add every protected package above to Thanox whitelist / do-not-freeze."
        echo "2. For non-whitelist user apps: block background start, receivers, wakeups and background network where acceptable."
        echo "3. On screen off: hibernate/freeze non-whitelist apps after a short delay."
        echo "4. On app exit: refreeze noisy apps such as Paytm, shopping, food, video, social, news and games."
        echo "5. Keep Phone, Telecom, Telephony Provider, Clock, GMS, GSF, IMS, SystemUI, KernelSU/Magisk and LSPosed alive."
        echo
        echo "Hail policy:"
        echo "1. Select all non-whitelist user apps for freeze."
        echo "2. Do not freeze protected packages."
        echo "3. Use manual launch/unfreeze for apps you only need while using the phone."
        echo "4. Hail package freeze is stronger than notification blocking; test banking/payment apps before relying on them."
        echo
        echo "Notification policy:"
        echo "- Disable notifications for non-whitelist apps in Android Settings, App Manager, Thanox or app-specific settings."
        echo "- This module intentionally does not run notification appops across all packages because that can break important alerts."
        echo
        echo "Telegram policy:"
        echo "- Android/KernelSU cannot reliably allow only personal messages while globally muting groups/channels/bots."
        echo "- In Telegram: Settings > Notifications and Sounds."
        echo "- Keep Private Chats on."
        echo "- Turn Groups off."
        echo "- Turn Channels off."
        echo "- Mute bots/other chats manually or with Telegram folders/notification exceptions."
        echo "- Keep Telegram whitelisted only if instant personal messages are needed."
    } > "$target" 2>/dev/null
}

cmd_export_thanox() {
    load_config
    mkdir -p "$(dirname "$THANOX_FILE_TMP")" 2>/dev/null
    wrote=""
    if write_thanox_helper "$THANOX_FILE_TMP"; then
        chmod 0644 "$THANOX_FILE_TMP" 2>/dev/null
        wrote="$THANOX_FILE_TMP"
    fi
    if [ -d /sdcard/Download ] || mkdir -p /sdcard/Download 2>/dev/null; then
        if write_thanox_helper "$THANOX_FILE_DOWNLOAD"; then
            chmod 0644 "$THANOX_FILE_DOWNLOAD" 2>/dev/null
            [ -n "$wrote" ] && wrote="$wrote
$THANOX_FILE_DOWNLOAD"
            [ -n "$wrote" ] || wrote="$THANOX_FILE_DOWNLOAD"
        fi
    fi
    log "thanox helper exported"
    if [ -n "$wrote" ]; then
        echo "Exported Thanox helper:"
        echo "$wrote"
    else
        echo "Could not write Thanox helper. Try again on Android after storage is mounted."
    fi
}

cmd_export_app_policy() {
    load_config
    mkdir -p "$(dirname "$APP_POLICY_FILE_TMP")" 2>/dev/null
    wrote=""
    if write_app_policy "$APP_POLICY_FILE_TMP"; then
        chmod 0644 "$APP_POLICY_FILE_TMP" 2>/dev/null
        wrote="$APP_POLICY_FILE_TMP"
    fi
    if [ -d /sdcard/Download ] || mkdir -p /sdcard/Download 2>/dev/null; then
        if write_app_policy "$APP_POLICY_FILE_DOWNLOAD"; then
            chmod 0644 "$APP_POLICY_FILE_DOWNLOAD" 2>/dev/null
            [ -n "$wrote" ] && wrote="$wrote
$APP_POLICY_FILE_DOWNLOAD"
            [ -n "$wrote" ] || wrote="$APP_POLICY_FILE_DOWNLOAD"
        fi
    fi
    log "app policy exported"
    if [ -n "$wrote" ]; then
        echo "Exported app policy:"
        echo "$wrote"
    else
        echo "Could not write app policy. Try again on Android after storage is mounted."
    fi
}

print_setting() {
    printf '%s %-42s %s\n' "$1" "$2" "$(settings_get "$1" "$2")"
}

valid_profile() {
    case "$1" in
        balanced|idle|ultra|night|screen) return 0 ;;
        *) return 1 ;;
    esac
}

profile_list() {
    echo "balanced"
    echo "idle"
    echo "ultra"
    echo "night"
    echo "screen"
}

set_profile_values() {
    profile="$1"
    valid_profile "$profile" || return 1
    ENABLED=1
    PROFILE="$profile"
    case "$profile" in
        balanced)
            AGGRESSIVE=0
            ULTRA_IDLE=0
            SCANNING_TWEAKS=1
            DISPLAY_IDLE_TWEAKS=0
            DOZE_TUNING=1
            SCREEN_ON_SAVER=0
            HAPTICS_OFF=0
            DARK_MODE=0
            DARK_WALLPAPER=0
            SCREEN_ON_REFRESH_RATE=120
            ;;
        idle)
            AGGRESSIVE=0
            ULTRA_IDLE=0
            SCANNING_TWEAKS=1
            DISPLAY_IDLE_TWEAKS=1
            DOZE_TUNING=1
            SCREEN_ON_SAVER=0
            HAPTICS_OFF=0
            DARK_MODE=0
            DARK_WALLPAPER=0
            SCREEN_ON_REFRESH_RATE=60
            ;;
        ultra|night)
            AGGRESSIVE=1
            ULTRA_IDLE=1
            SCANNING_TWEAKS=1
            DISPLAY_IDLE_TWEAKS=1
            DOZE_TUNING=1
            SCREEN_ON_SAVER=1
            HAPTICS_OFF=1
            DARK_MODE=1
            DARK_WALLPAPER=1
            SCREEN_ON_REFRESH_RATE=60
            ;;
        screen)
            AGGRESSIVE=0
            ULTRA_IDLE=0
            SCANNING_TWEAKS=1
            DISPLAY_IDLE_TWEAKS=0
            DOZE_TUNING=0
            SCREEN_ON_SAVER=1
            HAPTICS_OFF=1
            DARK_MODE=1
            DARK_WALLPAPER=1
            SCREEN_ON_REFRESH_RATE=60
            ;;
    esac
}

cmd_set_profile() {
    profile="$1"
    load_config
    if ! valid_profile "$profile"; then
        echo "Usage: $0 set-profile balanced|idle|ultra|night|screen"
        exit 2
    fi
    PROFILE="$profile"
    save_config
    log "config: profile=$profile"
    echo "profile set to $profile"
}

cmd_apply_profile() {
    profile="$1"
    load_config
    [ -n "$profile" ] || profile="$PROFILE"
    if ! set_profile_values "$profile"; then
        echo "Usage: $0 apply-profile [balanced|idle|ultra|night|screen]"
        exit 2
    fi
    save_config
    log "profile values applied: $profile"
    cmd_apply
}

cmd_apply_boot() {
    load_config
    if is_paused; then
        log "boot apply skipped: paused until $PAUSED_UNTIL"
        echo "Peridot Idle Drain Tweaks: paused until $PAUSED_UNTIL"
        exit 0
    fi
    if [ "$NIGHT_SCHEDULE" = "1" ] && inside_night_window; then
        log "boot apply: night schedule active"
        cmd_apply_profile night
    else
        log "boot apply: profile=$PROFILE"
        cmd_apply_profile "$PROFILE"
    fi
}

cmd_apply() {
    load_config
    if is_paused; then
        log "apply skipped: paused until $PAUSED_UNTIL"
        echo "Peridot Idle Drain Tweaks: paused until $PAUSED_UNTIL"
        exit 0
    fi
    if [ "$ENABLED" != "1" ]; then
        log "apply skipped: module disabled"
        echo "Peridot Idle Drain Tweaks: disabled"
        exit 0
    fi

    log "apply start ENABLED=$ENABLED AGGRESSIVE=$AGGRESSIVE SCANNING=$SCANNING_TWEAKS DISPLAY=$DISPLAY_IDLE_TWEAKS DOZE=$DOZE_TUNING ULTRA=$ULTRA_IDLE SCREEN_ON=$SCREEN_ON_SAVER HAPTICS=$HAPTICS_OFF DARK=$DARK_MODE WALLPAPER=$DARK_WALLPAPER"
    apply_scanning_settings
    apply_display_idle_settings
    apply_deviceidle_constants
    apply_aggressive_settings
    apply_ultra_idle_settings
    apply_screen_on_saver_settings
    apply_haptics_settings
    apply_dark_mode_settings
    apply_dark_wallpaper_settings
    [ "$EXPORT_APP_POLICY" = "1" ] && cmd_export_app_policy >/dev/null 2>&1
    log "apply complete"
    echo "Applied idle-drain tweaks."
}

cmd_restore() {
    ensure_files
    log "restore requested"
    if [ ! -f "$BACKUP_FILE" ]; then
        log "no backup found: $BACKUP_FILE"
        echo "No backup found."
        exit 0
    fi

    while IFS='|' read -r namespace key value; do
        [ -n "$namespace" ] || continue
        [ -n "$key" ] || continue
        if [ "$namespace" = "device_config" ] && [ "$key" = "device_idle.constants" ]; then
            restore_device_config "$value"
        else
            settings_delete_or_null_restore "$namespace" "$key" "$value"
        fi
    done < "$BACKUP_FILE"

    log "restore complete"
    echo "Restored backed-up settings."
}

cmd_status() {
    load_config
    echo "Peridot Idle Drain Tweaks"
    echo "Enabled: $ENABLED"
    echo "Profile: $PROFILE"
    echo "Night schedule: $NIGHT_SCHEDULE"
    echo "Night window: $NIGHT_START-$NIGHT_END"
    echo "Paused until: $PAUSED_UNTIL"
    echo "Aggressive: $AGGRESSIVE"
    echo "Scanning tweaks: $SCANNING_TWEAKS"
    echo "Display idle tweaks: $DISPLAY_IDLE_TWEAKS"
    echo "Doze tuning: $DOZE_TUNING"
    echo "Ultra idle: $ULTRA_IDLE"
    echo "Screen-on saver: $SCREEN_ON_SAVER"
    echo "Haptics off: $HAPTICS_OFF"
    echo "Dark mode: $DARK_MODE"
    echo "Dark wallpaper: $DARK_WALLPAPER"
    echo "Export app policy: $EXPORT_APP_POLICY"
    echo "Screen-on refresh rate: $SCREEN_ON_REFRESH_RATE"
    echo "Protected packages:"
    protected_print_lines | sed 's/^/  /'
    echo "Config: $CONFIG_FILE"
    echo "Log: $LOG_FILE"
    echo "Backup: $BACKUP_FILE"
    echo "Diagnose: $DIAG_FILE"
    echo "Thanox helper: $THANOX_FILE_TMP"
    echo "App policy: $APP_POLICY_FILE_TMP"
    [ -f "$BACKUP_FILE" ] && echo "Backup exists: yes" || echo "Backup exists: no"
}

cmd_diagnose() {
    load_config
    {
        echo "Peridot Idle Drain Diagnose"
        date
        echo
        cmd_status
        echo
        echo "Protected package list"
        protected_print_lines
        echo
        echo "Device"
        getprop ro.product.device 2>/dev/null
        getprop ro.build.fingerprint 2>/dev/null
        getprop ro.vendor.build.fingerprint 2>/dev/null
        echo
        echo "Power/display props"
        for prop in \
            ro.surface_flinger.set_idle_timer_ms \
            ro.surface_flinger.set_touch_timer_ms \
            ro.surface_flinger.support_kernel_idle_timer \
            debug.sf.defer_refresh_rate_when_off \
            vendor.display.enable_optimize_refresh \
            vendor.display.override_doze_mode \
            persist.vendor.radio.enableadvancedscan \
            ro.vendor.sensors.xiaomi.double_tap \
            ro.vendor.sensors.xiaomi.single_tap \
            ro.vendor.sensors.xiaomi.udfps; do
            printf '%-48s %s\n' "$prop" "$(getprop "$prop" 2>/dev/null)"
        done
        echo
        echo "Key settings"
        for item in \
            "global wifi_scan_always_enabled" \
            "global ble_scan_always_enabled" \
            "global adaptive_connectivity_enabled" \
            "global network_recommendations_enabled" \
            "global wifi_wakeup_enabled" \
            "global mobile_data_always_on" \
            "global app_standby_enabled" \
            "global app_restriction_enabled" \
            "global forced_app_standby_enabled" \
            "global app_auto_restriction_enabled" \
            "global adaptive_battery_management_enabled" \
            "system peak_refresh_rate" \
            "system min_refresh_rate" \
            "system user_refresh_rate" \
            "system haptic_feedback_enabled" \
            "system vibrate_when_ringing" \
            "system haptic_feedback_intensity" \
            "system notification_vibration_intensity" \
            "secure ui_night_mode" \
            "global enable_freezer" \
            "global cached_apps_freezer" \
            "secure nearby_scanning_enabled" \
            "secure location_mode" \
            "secure doze_enabled" \
            "secure doze_always_on" \
            "secure doze_pulse_on_pick_up" \
            "secure doze_pulse_on_double_tap" \
            "secure doze_pulse_on_tap" \
            "secure ambient_display_enabled" \
            "secure pickup_gesture_enabled" \
            "system screen_off_udfps_enabled"; do
            print_setting ${item}
        done
        echo
        echo "Device idle"
        dumpsys deviceidle 2>/dev/null | head -n 120
        echo
        echo "Suspend stats"
        if [ -r /sys/kernel/debug/suspend_stats ]; then
            cat /sys/kernel/debug/suspend_stats
        elif [ -r /d/suspend_stats ]; then
            cat /d/suspend_stats
        else
            echo "suspend_stats not readable"
        fi
        echo
        echo "Top wakeup_sources"
        if [ -r /sys/kernel/debug/wakeup_sources ]; then
            head -n 1 /sys/kernel/debug/wakeup_sources
            tail -n +2 /sys/kernel/debug/wakeup_sources | sort -k7 -nr | head -n 30
        elif [ -r /d/wakeup_sources ]; then
            head -n 1 /d/wakeup_sources
            tail -n +2 /d/wakeup_sources | sort -k7 -nr | head -n 30
        else
            echo "wakeup_sources not readable"
        fi
    } > "$DIAG_FILE" 2>&1
    chmod 0600 "$DIAG_FILE" 2>/dev/null
    log "diagnose written: $DIAG_FILE"
    cat "$DIAG_FILE"
}

cmd_logs() {
    ensure_files
    cat "$LOG_FILE" 2>/dev/null
}

cmd_clear_logs() {
    ensure_files
    : > "$LOG_FILE"
    chmod 0600 "$LOG_FILE" 2>/dev/null
    echo "Logs cleared."
}

cmd_set_night_schedule() {
    load_config
    case "$1" in
        0|1) NIGHT_SCHEDULE="$1" ;;
        *) echo "Usage: $0 set-night-schedule 0|1"; exit 2 ;;
    esac
    save_config
    log "config: night-schedule=$NIGHT_SCHEDULE"
    echo "night schedule set to $NIGHT_SCHEDULE"
}

cmd_set_night_window() {
    load_config
    case "$1" in
        [0-2][0-9]:[0-5][0-9]) ;;
        *) echo "Usage: $0 set-night-window HH:MM HH:MM"; exit 2 ;;
    esac
    case "$2" in
        [0-2][0-9]:[0-5][0-9]) ;;
        *) echo "Usage: $0 set-night-window HH:MM HH:MM"; exit 2 ;;
    esac
    NIGHT_START="$1"
    NIGHT_END="$2"
    save_config
    log "config: night-window=$NIGHT_START-$NIGHT_END"
    echo "night window set to $NIGHT_START-$NIGHT_END"
}

cmd_pause_minutes() {
    load_config
    minutes="$1"
    case "$minutes" in
        *[!0-9]*|"") echo "Usage: $0 pause-minutes <minutes>"; exit 2 ;;
    esac
    now="$(now_epoch)"
    PAUSED_UNTIL=$((now + minutes * 60))
    save_config
    log "paused for $minutes minutes until $PAUSED_UNTIL"
    echo "paused until epoch $PAUSED_UNTIL"
}

cmd_resume() {
    load_config
    PAUSED_UNTIL=0
    save_config
    log "resumed"
    echo "module resumed"
}

read_suspend_stats() {
    if [ -r /sys/kernel/debug/suspend_stats ]; then
        cat /sys/kernel/debug/suspend_stats
    elif [ -r /d/suspend_stats ]; then
        cat /d/suspend_stats
    fi
}

read_wakeup_sources() {
    if [ -r /sys/kernel/debug/wakeup_sources ]; then
        cat /sys/kernel/debug/wakeup_sources
    elif [ -r /d/wakeup_sources ]; then
        cat /d/wakeup_sources
    fi
}

suspect_from_name() {
    case "$1" in
        *qcom_rx*|*IPA*|*rmnet*|*modem*|*qmi*|*smd*) echo "modem/radio" ;;
        *wlan*|*cnss*|*wifi*) echo "Wi-Fi/CNSS" ;;
        *alarm*|*timerfd*) echo "alarms/apps" ;;
        *sensor*|*ssc*|*sns*) echo "sensors" ;;
        *fingerprint*|*fp*|*touch*) echo "fingerprint/touch" ;;
        *PowerManagerService*) echo "Android wakelocks/apps" ;;
        *) echo "unknown/kernel" ;;
    esac
}

cmd_idle_score() {
    stats="$(read_suspend_stats)"
    attempts="$(printf '%s\n' "$stats" | awk 'tolower($1) ~ /attempt/ { print $NF; exit }' 2>/dev/null)"
    success="$(printf '%s\n' "$stats" | awk 'tolower($1) ~ /success/ { print $NF; exit }' 2>/dev/null)"
    failed="$(printf '%s\n' "$stats" | awk 'tolower($1) ~ /fail/ { print $NF; exit }' 2>/dev/null)"
    short="$(printf '%s\n' "$stats" | awk 'tolower($1) ~ /short/ { print $NF; exit }' 2>/dev/null)"
    [ -n "$attempts" ] || attempts=0
    [ -n "$success" ] || success=0
    [ -n "$failed" ] || failed=0
    [ -n "$short" ] || short=0
    if [ "$attempts" -eq 0 ] 2>/dev/null; then
        attempts=$((success + failed + short))
    fi

    top_line="$(read_wakeup_sources | tail -n +2 2>/dev/null | sort -k7 -nr 2>/dev/null | head -n 1)"
    top_name="$(printf '%s\n' "$top_line" | awk '{print $1}' 2>/dev/null)"
    [ -n "$top_name" ] || top_name="unavailable"
    suspect="$(suspect_from_name "$top_name")"

    score=100
    classification="good"
    if [ "$attempts" -gt 0 ] 2>/dev/null; then
        failed_pct=$((failed * 100 / attempts))
        short_pct=$((short * 100 / attempts))
        score=$((100 - failed_pct - short_pct / 2))
        [ "$score" -lt 0 ] && score=0
        if [ "$score" -lt 50 ]; then
            classification="bad"
        elif [ "$score" -lt 75 ]; then
            classification="warning"
        else
            classification="good"
        fi
    else
        classification="warning"
    fi

    {
        echo "Idle score: $score/100"
        echo "Classification: $classification"
        echo "Suspend attempts: $attempts"
        echo "Successful/long-ish suspends: $success"
        echo "Failed suspends: $failed"
        echo "Short suspends: $short"
        echo "Top suspected source: $top_name ($suspect)"
        echo
        echo "Interpretation:"
        case "$classification" in
            good) echo "- Suspend stats look acceptable from this simple heuristic." ;;
            warning) echo "- Some suspend failures/short wakes are present. Check wakeup_sources and app alarms." ;;
            bad) echo "- Suspend is likely unhealthy. Check modem/Wi-Fi/app/sensor wakeups before adding more tweaks." ;;
        esac
        echo "- This is a heuristic score, not a replacement for overnight drain testing."
    }
}

write_module_backup() {
    target="$1"
    {
        echo "Peridot Idle Drain Module Backup"
        date
        echo
        echo "[config.conf]"
        cat "$CONFIG_FILE" 2>/dev/null
        echo
        echo "[protected packages]"
        protected_print_lines
    } > "$target" 2>/dev/null
}

cmd_export_backup() {
    load_config
    mkdir -p "$(dirname "$MODULE_BACKUP_FILE_TMP")" 2>/dev/null
    wrote=""
    if write_module_backup "$MODULE_BACKUP_FILE_TMP"; then
        chmod 0644 "$MODULE_BACKUP_FILE_TMP" 2>/dev/null
        wrote="$MODULE_BACKUP_FILE_TMP"
    fi
    if [ -d /sdcard/Download ] || mkdir -p /sdcard/Download 2>/dev/null; then
        if write_module_backup "$MODULE_BACKUP_FILE_DOWNLOAD"; then
            chmod 0644 "$MODULE_BACKUP_FILE_DOWNLOAD" 2>/dev/null
            [ -n "$wrote" ] && wrote="$wrote
$MODULE_BACKUP_FILE_DOWNLOAD" || wrote="$MODULE_BACKUP_FILE_DOWNLOAD"
        fi
    fi
    log "module backup exported"
    if [ -n "$wrote" ]; then
        echo "Exported module backup:"
        echo "$wrote"
    else
        echo "Could not write module backup. Try again after storage is mounted."
    fi
}

set_bool_config() {
    var="$1"
    value="$2"
    load_config
    case "$value" in
        0|1) ;;
        *) echo "Usage: $0 set-$var 0|1"; exit 2 ;;
    esac
    case "$var" in
        enabled) ENABLED="$value" ;;
        aggressive) AGGRESSIVE="$value" ;;
        scanning) SCANNING_TWEAKS="$value" ;;
        display) DISPLAY_IDLE_TWEAKS="$value" ;;
        doze) DOZE_TUNING="$value" ;;
        ultra)
            ULTRA_IDLE="$value"
            if [ "$value" = "1" ]; then
                AGGRESSIVE=1
                SCANNING_TWEAKS=1
                DISPLAY_IDLE_TWEAKS=1
                DOZE_TUNING=1
            fi
            ;;
        screen-saver) SCREEN_ON_SAVER="$value" ;;
        haptics) HAPTICS_OFF="$value" ;;
        dark-mode) DARK_MODE="$value" ;;
        dark-wallpaper) DARK_WALLPAPER="$value" ;;
        app-policy) EXPORT_APP_POLICY="$value" ;;
        *) echo "Unknown config: $var"; exit 2 ;;
    esac
    save_config
    log "config: $var=$value"
    echo "$var set to $value"
}

set_refresh_rate() {
    value="$1"
    load_config
    case "$value" in
        60|90|120) ;;
        *) echo "Usage: $0 set-refresh-rate 60|90|120"; exit 2 ;;
    esac
    SCREEN_ON_REFRESH_RATE="$value"
    save_config
    log "config: refresh-rate=$value"
    echo "screen-on refresh rate set to $value"
}

case "$1" in
    boot) cmd_apply_boot ;;
    apply) cmd_apply ;;
    profile-list) profile_list ;;
    set-profile) cmd_set_profile "$2" ;;
    apply-profile) cmd_apply_profile "$2" ;;
    restore) cmd_restore ;;
    status) cmd_status ;;
    diagnose) cmd_diagnose ;;
    idle-score) cmd_idle_score ;;
    set-night-schedule) cmd_set_night_schedule "$2" ;;
    set-night-window) cmd_set_night_window "$2" "$3" ;;
    pause-minutes) cmd_pause_minutes "$2" ;;
    resume) cmd_resume ;;
    export-backup) cmd_export_backup ;;
    set-enabled) set_bool_config enabled "$2" ;;
    set-aggressive) set_bool_config aggressive "$2" ;;
    set-scanning) set_bool_config scanning "$2" ;;
    set-display) set_bool_config display "$2" ;;
    set-doze) set_bool_config doze "$2" ;;
    set-ultra) set_bool_config ultra "$2" ;;
    set-screen-saver) set_bool_config screen-saver "$2" ;;
    set-haptics) set_bool_config haptics "$2" ;;
    set-dark-mode) set_bool_config dark-mode "$2" ;;
    set-dark-wallpaper) set_bool_config dark-wallpaper "$2" ;;
    set-export-app-policy) set_bool_config app-policy "$2" ;;
    set-refresh-rate) set_refresh_rate "$2" ;;
    protected-list) cmd_protected_list ;;
    protected-add) protected_add_pkg "$2" ;;
    protected-remove) protected_remove_pkg "$2" ;;
    protected-reset) protected_reset ;;
    export-thanox) cmd_export_thanox ;;
    export-app-policy) cmd_export_app_policy ;;
    logs) cmd_logs ;;
    clear-logs) cmd_clear_logs ;;
    *)
        echo "Usage: $0 {boot|apply|profile-list|set-profile profile|apply-profile [profile]|restore|status|diagnose|idle-score|set-night-schedule 0|1|set-night-window HH:MM HH:MM|pause-minutes n|resume|export-backup|set-enabled 0|1|set-aggressive 0|1|set-scanning 0|1|set-display 0|1|set-doze 0|1|set-ultra 0|1|set-screen-saver 0|1|set-haptics 0|1|set-dark-mode 0|1|set-dark-wallpaper 0|1|set-refresh-rate 60|90|120|protected-list|protected-add pkg|protected-remove pkg|protected-reset|export-thanox|export-app-policy|logs|clear-logs}"
        exit 2
        ;;
esac
