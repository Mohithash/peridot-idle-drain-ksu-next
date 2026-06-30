#!/system/bin/sh

MODDIR="${MODDIR:-$(cd "$(dirname "$0")/.." 2>/dev/null && pwd)}"
CONFIG_FILE="$MODDIR/config.conf"
LOG_FILE="/data/local/tmp/peridot_idle_drain.log"
BACKUP_FILE="/data/local/tmp/peridot_idle_drain_backup.txt"
DIAG_FILE="/data/local/tmp/peridot_idle_drain_diagnose.txt"
SAFETY_FILE="/data/local/tmp/peridot_safety_check.txt"
BASELINE_FILE="/data/local/tmp/peridot_idle_baseline.txt"
OVERNIGHT_FILE="/data/local/tmp/peridot_overnight_report.txt"
THANOX_FILE_TMP="/data/local/tmp/peridot_thanox_whitelist.txt"
THANOX_FILE_DOWNLOAD="/sdcard/Download/peridot_thanox_whitelist.txt"
APP_POLICY_FILE_TMP="/data/local/tmp/peridot_app_policy.txt"
APP_POLICY_FILE_DOWNLOAD="/sdcard/Download/peridot_app_policy.txt"
HAIL_FILE_TMP="/data/local/tmp/peridot_hail_freeze_candidates.txt"
HAIL_FILE_DOWNLOAD="/sdcard/Download/peridot_hail_freeze_candidates.txt"
HAIL_PROTECTED_FILE_TMP="/data/local/tmp/peridot_hail_protected_packages.txt"
HAIL_PROTECTED_FILE_DOWNLOAD="/sdcard/Download/peridot_hail_protected_packages.txt"
THANOX_RULES_FILE_TMP="/data/local/tmp/peridot_thanox_rules.txt"
THANOX_RULES_FILE_DOWNLOAD="/sdcard/Download/peridot_thanox_rules.txt"
NOTIFICATION_FILE_TMP="/data/local/tmp/peridot_notification_review.txt"
NOTIFICATION_FILE_DOWNLOAD="/sdcard/Download/peridot_notification_review.txt"
MODULE_BACKUP_FILE_TMP="/data/local/tmp/peridot_idle_module_backup.txt"
MODULE_BACKUP_FILE_DOWNLOAD="/sdcard/Download/peridot_idle_module_backup.txt"
FULL_ANALYSIS_FILE_TMP="/data/local/tmp/peridot_full_analysis.txt"
FULL_ANALYSIS_FILE_DOWNLOAD="/sdcard/Download/peridot_full_analysis.txt"
INSTALLED_APPS_SNAPSHOT="/data/local/tmp/peridot_installed_apps_snapshot.txt"
RESTORE_PACK_FILE_TMP="/data/local/tmp/peridot_idle_restore_pack.txt"
RESTORE_PACK_FILE_DOWNLOAD="/sdcard/Download/peridot_idle_restore_pack.txt"
BLACK_WALLPAPER="/data/local/tmp/peridot_black_wallpaper.png"
DEFAULT_PROTECTED_PACKAGES="com.android.dialer,com.google.android.dialer,com.android.phone,com.android.server.telecom,com.android.providers.telephony,com.android.contacts,com.android.messaging,com.google.android.apps.messaging,com.android.deskclock,com.google.android.deskclock,com.google.android.gms,com.google.android.gsf,com.google.android.ims,com.google.android.euicc,com.android.systemui,com.android.settings,com.android.permissioncontroller,me.weishu.kernelsu,com.rifsxd.ksunext,com.topjohnwu.magisk,org.lsposed.manager"
MY_TEMPLATE_PACKAGES="peridot_my_template_overview.txt peridot_thanox_my_rules.txt peridot_hail_my_lists.txt peridot_notification_my_plan.txt peridot_maps_temp_mode.txt peridot_payment_foreground_only.txt peridot_telegram_private_only.txt"
MY_DEFAULT_WHITELIST_PACKAGES="com.android.dialer,com.google.android.dialer,com.android.phone,com.android.server.telecom,com.android.providers.telephony,com.android.contacts,com.android.messaging,com.google.android.apps.messaging,com.android.deskclock,com.google.android.deskclock,com.google.android.gms,com.google.android.gsf,com.google.android.ims,com.google.android.euicc,com.android.systemui,com.android.settings,com.android.permissioncontroller,com.google.android.inputmethod.latin,com.android.inputmethod.latin,me.weishu.kernelsu,com.rifsxd.ksunext,com.topjohnwu.magisk,org.lsposed.manager,org.telegram.messenger,org.telegram.messenger.web,org.thunderdog.challegram,com.whatsapp"
RECOMMENDED_OPTIONAL_PACKAGES="com.whatsapp,org.telegram.messenger,org.telegram.messenger.web,org.thunderdog.challegram,com.google.android.apps.authenticator2,com.google.android.calendar"

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
            echo "MY_SETUP=0"
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
    MY_SETUP=0
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
    MY_SETUP="$(bool_or_zero "$MY_SETUP")"
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
        echo "MY_SETUP=$MY_SETUP"
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

installed_user_packages_not_protected() {
    installed_user_packages | while read -r pkg; do
        [ -n "$pkg" ] || continue
        protected_contains "$pkg" && continue
        echo "$pkg"
    done
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

write_dual_file() {
    tmp_target="$1"
    download_target="$2"
    writer="$3"
    mkdir -p "$(dirname "$tmp_target")" 2>/dev/null
    wrote=""
    if "$writer" "$tmp_target"; then
        chmod 0644 "$tmp_target" 2>/dev/null
        wrote="$tmp_target"
    fi
    if [ -d /sdcard/Download ] || mkdir -p /sdcard/Download 2>/dev/null; then
        if "$writer" "$download_target"; then
            chmod 0644 "$download_target" 2>/dev/null
            if [ -n "$wrote" ]; then
                wrote="$wrote
$download_target"
            else
                wrote="$download_target"
            fi
        fi
    fi
    [ -n "$wrote" ] && printf '%s\n' "$wrote"
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

protected_add_pkg_no_exit() {
    pkg="$1"
    package_valid "$pkg" || return 1
    protected_contains "$pkg" && return 0
    if [ -n "$PROTECTED_PACKAGES" ]; then
        PROTECTED_PACKAGES="$PROTECTED_PACKAGES,$pkg"
    else
        PROTECTED_PACKAGES="$pkg"
    fi
    return 0
}

cmd_set_my_whitelist_defaults() {
    load_config
    added=0
    old_ifs="$IFS"
    IFS=,
    for pkg in $MY_DEFAULT_WHITELIST_PACKAGES; do
        IFS="$old_ifs"
        [ -n "$pkg" ] || { IFS=,; continue; }
        if ! protected_contains "$pkg"; then
            if protected_add_pkg_no_exit "$pkg"; then
                added=$((added + 1))
            fi
        fi
        IFS=,
    done
    IFS="$old_ifs"
    save_config
    log "my whitelist defaults added: $added"
    echo "Added recommended protected defaults without duplicates: $added"
    echo
    echo "Protected packages now:"
    protected_print_lines
    echo
    echo "Maps is intentionally not added as always-protected. Use the Maps temporary mode template."
    echo "Paytm/payment apps are intentionally not protected. Use the payment foreground-only template."
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

write_hail_candidates() {
    target="$1"
    {
        echo "Peridot Idle Drain - Hail Freeze Candidates"
        date
        echo
        echo "Use in Hail manually. This module does not freeze, suspend, or disable packages."
        echo "Freeze candidates are installed user apps that are not in the protected package list."
        echo
        echo "Protected packages to exclude from Hail freeze:"
        protected_print_lines | sed 's/^/- /'
        echo
        echo "Freeze candidates:"
        installed_user_packages_not_protected | sed 's/^/- /'
        echo
        echo "Manual guidance:"
        echo "- Select these candidates in Hail only if you do not need their instant alerts."
        echo "- Keep Phone, Telecom, Telephony Provider, Clock, GMS, GSF, IMS, SystemUI, root, LSPosed, SMS, and chosen messenger apps unfrozen."
        echo "- For apps such as Paytm, shopping, food, social, video, news and games, freeze after exit/screen off if you only open them manually."
        echo "- Test banking/payment apps before relying on alerts or OTP flows."
    } > "$target" 2>/dev/null
}

write_hail_protected() {
    target="$1"
    {
        echo "Peridot Idle Drain - Protected Packages"
        date
        echo
        echo "Do not freeze these in Hail/Thanox:"
        protected_print_lines
    } > "$target" 2>/dev/null
}

cmd_export_hail() {
    load_config
    wrote="$(write_dual_file "$HAIL_FILE_TMP" "$HAIL_FILE_DOWNLOAD" write_hail_candidates)"
    protected_wrote="$(write_dual_file "$HAIL_PROTECTED_FILE_TMP" "$HAIL_PROTECTED_FILE_DOWNLOAD" write_hail_protected)"
    log "hail candidates exported"
    if [ -n "$wrote$protected_wrote" ]; then
        echo "Exported Hail freeze candidates:"
        [ -n "$wrote" ] && echo "$wrote"
        echo
        echo "Exported protected package list:"
        [ -n "$protected_wrote" ] && echo "$protected_wrote"
    else
        echo "Could not write Hail files. Try again after storage is mounted."
    fi
}

write_thanox_rules() {
    target="$1"
    {
        echo "Peridot Idle Drain - Thanox Rules Pack"
        date
        echo
        echo "These are copy/paste conceptual rules. This module does not edit Thanox databases."
        echo
        echo "Protected whitelist:"
        protected_print_lines | sed 's/^/- /'
        echo
        echo "Rule concept: screen off ultra"
        echo "- Trigger: screen off"
        echo "- Target: user apps not in protected whitelist"
        echo "- Action: prevent background start"
        echo "- Action: restrict receivers/wakeups where safe"
        echo "- Action: hibernate/freeze after a delay"
        echo "- Exclude: Phone, Telecom, Telephony Provider, Clock, GMS, GSF, IMS, SystemUI, root, LSPosed, SMS, chosen messenger"
        echo
        echo "Rule concept: manual launch"
        echo "- Trigger: app launched by user"
        echo "- Action: allow/unfreeze the launched app"
        echo "- Trigger: app exit or screen off"
        echo "- Action: refreeze noisy non-whitelist apps"
        echo
        echo "Rule concept: notification cleanup"
        echo "- Disable notification categories in Android/app settings for non-whitelist apps."
        echo "- Keep notification access only for calls, Clock/alarm, SMS, and chosen personal messengers."
        echo "- Do not globally block notifications for protected packages."
        echo
        echo "Rule concept: charging relax"
        echo "- Trigger: charging connected"
        echo "- Action: optionally relax app freezing for apps you are actively using."
        echo "- Trigger: charging disconnected or screen off"
        echo "- Action: return to ultra screen-off policy."
        echo
        echo "Rule concept: night ultra"
        echo "- Trigger: night window, e.g. 23:00-07:00"
        echo "- Action: freeze/restrict all non-whitelist user apps after screen off."
        echo "- Keep exact alarms and Clock safe."
        echo
        echo "Telegram personal-only note:"
        echo "- Thanox/KernelSU cannot reliably keep only personal Telegram chats while muting groups/channels/bots."
        echo "- Configure Telegram in-app: Private Chats on; Groups off; Channels off; mute bots/other chats manually."
    } > "$target" 2>/dev/null
}

cmd_export_thanox_rules() {
    load_config
    wrote="$(write_dual_file "$THANOX_RULES_FILE_TMP" "$THANOX_RULES_FILE_DOWNLOAD" write_thanox_rules)"
    log "thanox rules exported"
    if [ -n "$wrote" ]; then
        echo "Exported Thanox rules:"
        echo "$wrote"
    else
        echo "Could not write Thanox rules. Try again after storage is mounted."
    fi
}

write_notification_report() {
    target="$1"
    {
        echo "Peridot Idle Drain - Notification Review"
        date
        echo
        echo "These installed user apps are not protected and are candidates for manual notification blocking."
        echo "This module does not revoke notification permissions or sweep appops."
        echo
        echo "Keep notifications enabled for:"
        echo "- calls / Phone / Telecom"
        echo "- Clock / alarms"
        echo "- SMS if used"
        echo "- selected personal messenger apps"
        echo "- any banking/payment app only if you truly need alerts"
        echo
        echo "Notification-block candidates:"
        installed_user_packages_not_protected | sed 's/^/- /'
    } > "$target" 2>/dev/null
}

cmd_notification_report() {
    load_config
    wrote="$(write_dual_file "$NOTIFICATION_FILE_TMP" "$NOTIFICATION_FILE_DOWNLOAD" write_notification_report)"
    log "notification report exported"
    if [ -n "$wrote" ]; then
        echo "Exported notification review:"
        echo "$wrote"
    else
        echo "Could not write notification report. Try again after storage is mounted."
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

remove_exact_file() {
    file="$1"
    [ -f "$file" ] || return
    rm -f "$file" 2>/dev/null \
        && echo "Removed: $file" \
        || echo "Could not remove: $file"
}

reset_config_defaults() {
    rm -f "$CONFIG_FILE" 2>/dev/null
    ensure_files
}

cmd_reset_all() {
    ensure_files
    log "reset-all requested"
    echo "Reset all requested."
    echo
    if [ -f "$BACKUP_FILE" ]; then
        cmd_restore
    else
        echo "No settings backup found; skipping settings restore."
    fi
    echo
    echo "Resetting module config to defaults..."
    reset_config_defaults
    echo "Config reset: $CONFIG_FILE"
    echo
    echo "Removing module-generated reports and exports..."
    for file in \
        "$LOG_FILE" \
        "$BACKUP_FILE" \
        "$DIAG_FILE" \
        "$SAFETY_FILE" \
        "$BASELINE_FILE" \
        "$OVERNIGHT_FILE" \
        "$THANOX_FILE_TMP" \
        "$APP_POLICY_FILE_TMP" \
        "$HAIL_FILE_TMP" \
        "$HAIL_PROTECTED_FILE_TMP" \
        "$THANOX_RULES_FILE_TMP" \
        "$NOTIFICATION_FILE_TMP" \
        "$MODULE_BACKUP_FILE_TMP" \
        "$FULL_ANALYSIS_FILE_TMP" \
        "$INSTALLED_APPS_SNAPSHOT" \
        "$RESTORE_PACK_FILE_TMP" \
        "$BLACK_WALLPAPER" \
        "/data/local/tmp/peridot_installed_apps_current.txt" \
        "/data/local/tmp/peridot_quick_actions.txt" \
        "$THANOX_FILE_DOWNLOAD" \
        "$APP_POLICY_FILE_DOWNLOAD" \
        "$HAIL_FILE_DOWNLOAD" \
        "$HAIL_PROTECTED_FILE_DOWNLOAD" \
        "$THANOX_RULES_FILE_DOWNLOAD" \
        "$NOTIFICATION_FILE_DOWNLOAD" \
        "$MODULE_BACKUP_FILE_DOWNLOAD" \
        "$FULL_ANALYSIS_FILE_DOWNLOAD" \
        "$RESTORE_PACK_FILE_DOWNLOAD" \
        "/sdcard/Download/peridot_quick_actions.txt"; do
        remove_exact_file "$file"
    done
    for name in $MY_TEMPLATE_PACKAGES; do
        remove_exact_file "/sdcard/Download/$name"
    done
    echo "Now disable or uninstall the module from KernelSU Next, then reboot."
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
    echo "My setup: $MY_SETUP"
    echo "Screen-on refresh rate: $SCREEN_ON_REFRESH_RATE"
    echo "Protected packages:"
    protected_print_lines | sed 's/^/  /'
    echo "Config: $CONFIG_FILE"
    echo "Log: $LOG_FILE"
    echo "Backup: $BACKUP_FILE"
    echo "Diagnose: $DIAG_FILE"
    echo "Safety check: $SAFETY_FILE"
    echo "Overnight baseline: $BASELINE_FILE"
    echo "Overnight report: $OVERNIGHT_FILE"
    echo "Thanox helper: $THANOX_FILE_TMP"
    echo "App policy: $APP_POLICY_FILE_TMP"
    echo "Hail candidates: $HAIL_FILE_TMP"
    echo "Thanox rules: $THANOX_RULES_FILE_TMP"
    echo "Notification review: $NOTIFICATION_FILE_TMP"
    echo "Full analysis: $FULL_ANALYSIS_FILE_TMP"
    echo "App snapshot: $INSTALLED_APPS_SNAPSHOT"
    echo "Restore pack: $RESTORE_PACK_FILE_TMP"
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

battery_level() {
    dumpsys battery 2>/dev/null | awk -F: '/^[[:space:]]*level:/ { gsub(/ /, "", $2); print $2; exit }'
}

battery_status() {
    dumpsys battery 2>/dev/null | awk -F: '/^[[:space:]]*status:/ { gsub(/ /, "", $2); print $2; exit }'
}

suspend_value() {
    key="$1"
    stats="$2"
    printf '%s\n' "$stats" | awk -v wanted="$key" '
        BEGIN { wanted=tolower(wanted) }
        {
            name=tolower($1)
            gsub(/:/, "", name)
            if (name ~ wanted) {
                print $NF
                exit
            }
        }' 2>/dev/null
}

wakeup_top_name() {
    read_wakeup_sources | tail -n +2 2>/dev/null | sort -k7 -nr 2>/dev/null | head -n 1 | awk '{print $1}'
}

wakeup_top_count() {
    read_wakeup_sources | tail -n +2 2>/dev/null | sort -k7 -nr 2>/dev/null | head -n 1 | awk '{print $7}'
}

write_selected_settings() {
    for item in \
        "global wifi_scan_always_enabled" \
        "global ble_scan_always_enabled" \
        "global adaptive_connectivity_enabled" \
        "global mobile_data_always_on" \
        "system peak_refresh_rate" \
        "system min_refresh_rate" \
        "system haptic_feedback_enabled" \
        "system vibrate_when_ringing" \
        "secure location_mode" \
        "secure doze_enabled" \
        "secure doze_always_on" \
        "secure ambient_display_enabled" \
        "secure pickup_gesture_enabled" \
        "system screen_off_udfps_enabled"; do
        print_setting ${item}
    done
}

cmd_safety_check() {
    load_config
    {
        echo "Peridot Idle Drain - Safety Check"
        date
        echo
        echo "Purpose: read-only calls + Clock/alarm sanity report."
        echo "This command does not modify packages, appops, telephony, IMS, alarms, or settings."
        echo
        echo "Protected packages:"
        protected_print_lines | sed 's/^/- /'
        echo
        echo "Default dialer role:"
        cmd role holders android.app.role.DIALER 2>/dev/null || echo "cmd role unavailable"
        echo
        echo "Dialer/Phone/Clock package presence:"
        for pkg in \
            com.android.dialer \
            com.google.android.dialer \
            com.android.phone \
            com.android.server.telecom \
            com.android.providers.telephony \
            com.android.deskclock \
            com.google.android.deskclock \
            com.google.android.gms \
            com.google.android.gsf \
            com.google.android.ims \
            com.android.systemui; do
            if pm path "$pkg" >/dev/null 2>&1; then
                echo "$pkg: present"
            else
                echo "$pkg: not found"
            fi
        done
        echo
        echo "Next alarm:"
        echo "secure next_alarm_formatted=$(settings get secure next_alarm_formatted 2>/dev/null)"
        dumpsys alarm 2>/dev/null | grep -i -m 8 -e "next alarm" -e "pending alarm" -e "alarm clock" || echo "dumpsys alarm snippet unavailable"
        echo
        echo "Telephony registry snippet:"
        dumpsys telephony.registry 2>/dev/null | grep -i -m 30 -e "mServiceState" -e "mSignalStrength" -e "mCallState" -e "mDataConnectionState" -e "mMessageWaiting" -e "mCallForwarding" || echo "telephony.registry unavailable"
        echo
        echo "Phone/IMS snippet:"
        dumpsys phone 2>/dev/null | grep -i -m 40 -e "ims" -e "volte" -e "registered" -e "service state" -e "mCi" -e "mPhoneId" || echo "dumpsys phone unavailable"
        echo
        echo "Result guidance:"
        echo "- If at least one dialer, Phone/Telecom/Telephony Provider, Clock, GMS/GSF/IMS and SystemUI are present, the module's protected list is call/clock oriented."
        echo "- Verify by placing one test call and setting one alarm after changing profiles."
    } > "$SAFETY_FILE" 2>&1
    chmod 0600 "$SAFETY_FILE" 2>/dev/null
    log "safety check written: $SAFETY_FILE"
    cat "$SAFETY_FILE"
}

cmd_overnight_start() {
    load_config
    stats="$(read_suspend_stats)"
    {
        echo "PERIDOT_IDLE_BASELINE=1"
        echo "timestamp=$(now_epoch)"
        echo "date=$(date '+%Y-%m-%d %H:%M:%S' 2>/dev/null)"
        echo "battery_level=$(battery_level)"
        echo "battery_status=$(battery_status)"
        echo "suspend_attempts=$(suspend_value attempt "$stats")"
        echo "suspend_success=$(suspend_value success "$stats")"
        echo "suspend_failed=$(suspend_value fail "$stats")"
        echo "suspend_short=$(suspend_value short "$stats")"
        echo "top_wakeup_name=$(wakeup_top_name)"
        echo "top_wakeup_count=$(wakeup_top_count)"
        echo "profile=$PROFILE"
        echo "aggressive=$AGGRESSIVE"
        echo "ultra=$ULTRA_IDLE"
        echo "refresh=$SCREEN_ON_REFRESH_RATE"
        echo
        echo "[deviceidle]"
        dumpsys deviceidle 2>/dev/null | head -n 80
        echo
        echo "[selected_settings]"
        write_selected_settings
        echo
        echo "[suspend_stats]"
        printf '%s\n' "$stats"
        echo
        echo "[wakeup_sources_top_30]"
        read_wakeup_sources | head -n 1 2>/dev/null
        read_wakeup_sources | tail -n +2 2>/dev/null | sort -k7 -nr 2>/dev/null | head -n 30
    } > "$BASELINE_FILE" 2>&1
    chmod 0600 "$BASELINE_FILE" 2>/dev/null
    log "overnight baseline written: $BASELINE_FILE"
    echo "Overnight baseline saved: $BASELINE_FILE"
}

baseline_get() {
    key="$1"
    grep -m 1 "^$key=" "$BASELINE_FILE" 2>/dev/null | sed "s/^$key=//"
}

classify_overnight() {
    drain_per_hour="$1"
    failed_delta="$2"
    short_delta="$3"
    top_name="$4"
    classification="good"
    if [ -n "$drain_per_hour" ]; then
        whole="${drain_per_hour%.*}"
        [ -n "$whole" ] || whole=0
        if [ "$whole" -ge 2 ] 2>/dev/null; then
            classification="bad"
        elif [ "$whole" -ge 1 ] 2>/dev/null; then
            classification="warning"
        fi
    fi
    if [ "$failed_delta" -gt 1000 ] 2>/dev/null || [ "$short_delta" -gt 3000 ] 2>/dev/null; then
        [ "$classification" = "good" ] && classification="warning"
    fi
    echo "$classification|$(suspect_from_name "$top_name")"
}

cmd_overnight_report() {
    if [ ! -f "$BASELINE_FILE" ]; then
        echo "No baseline found. Run overnight-start before sleep first."
        exit 1
    fi
    start_ts="$(baseline_get timestamp)"
    start_level="$(baseline_get battery_level)"
    start_failed="$(baseline_get suspend_failed)"
    start_short="$(baseline_get suspend_short)"
    start_attempts="$(baseline_get suspend_attempts)"
    start_top_name="$(baseline_get top_wakeup_name)"
    start_top_count="$(baseline_get top_wakeup_count)"
    now_ts="$(now_epoch)"
    cur_level="$(battery_level)"
    stats="$(read_suspend_stats)"
    cur_attempts="$(suspend_value attempt "$stats")"
    cur_failed="$(suspend_value fail "$stats")"
    cur_short="$(suspend_value short "$stats")"
    cur_top_name="$(wakeup_top_name)"
    cur_top_count="$(wakeup_top_count)"

    [ -n "$start_ts" ] || start_ts=0
    [ -n "$now_ts" ] || now_ts=0
    elapsed=$((now_ts - start_ts))
    [ "$elapsed" -lt 0 ] 2>/dev/null && elapsed=0
    hours="$(awk -v s="$elapsed" 'BEGIN { if (s > 0) printf "%.2f", s / 3600; else printf "0.00" }' 2>/dev/null)"

    battery_delta="unknown"
    drain_per_hour=""
    if [ -n "$start_level" ] && [ -n "$cur_level" ]; then
        battery_delta=$((start_level - cur_level))
        drain_per_hour="$(awk -v d="$battery_delta" -v s="$elapsed" 'BEGIN { if (s > 0) printf "%.2f", d / (s / 3600); else printf "0.00" }' 2>/dev/null)"
    fi

    [ -n "$start_failed" ] || start_failed=0
    [ -n "$cur_failed" ] || cur_failed=0
    [ -n "$start_short" ] || start_short=0
    [ -n "$cur_short" ] || cur_short=0
    [ -n "$start_attempts" ] || start_attempts=0
    [ -n "$cur_attempts" ] || cur_attempts=0
    failed_delta=$((cur_failed - start_failed))
    short_delta=$((cur_short - start_short))
    attempts_delta=$((cur_attempts - start_attempts))
    [ "$failed_delta" -lt 0 ] 2>/dev/null && failed_delta=0
    [ "$short_delta" -lt 0 ] 2>/dev/null && short_delta=0
    [ "$attempts_delta" -lt 0 ] 2>/dev/null && attempts_delta=0

    [ -n "$cur_top_name" ] || cur_top_name="unavailable"
    class_suspect="$(classify_overnight "$drain_per_hour" "$failed_delta" "$short_delta" "$cur_top_name")"
    classification="${class_suspect%%|*}"
    suspected="${class_suspect#*|}"

    {
        echo "Peridot Idle Drain - Overnight Report"
        date
        echo
        echo "Baseline: $BASELINE_FILE"
        echo "Elapsed seconds: $elapsed"
        echo "Elapsed hours: $hours"
        echo "Battery start: ${start_level:-unknown}%"
        echo "Battery now: ${cur_level:-unknown}%"
        echo "Battery delta: $battery_delta%"
        echo "Drain per hour: ${drain_per_hour:-unknown}%/hr"
        echo
        echo "Suspend delta:"
        echo "- attempts: $attempts_delta"
        echo "- failed: $failed_delta"
        echo "- short: $short_delta"
        echo
        echo "Top wakeup source:"
        echo "- baseline: ${start_top_name:-unknown} count=${start_top_count:-unknown}"
        echo "- current: ${cur_top_name:-unknown} count=${cur_top_count:-unknown}"
        echo
        echo "Classification: $classification"
        echo "Suspected cause: $suspected"
        echo
        echo "Guidance:"
        case "$suspected" in
            modem/radio) echo "- Check signal quality, 5G in weak signal, IMS/radio wakeups. Do not disable modem/IMS if calls matter." ;;
            Wi-Fi/CNSS) echo "- Check Wi-Fi scanning, poor AP, Wi-Fi calling, router multicast/noise and CNSS wakeups." ;;
            alarms/apps|Android*) echo "- Use Thanox/Hail/app notification cleanup for non-whitelist apps. Check app alarms." ;;
            sensors|fingerprint*) echo "- Keep AOD, pickup, tap-to-wake and screen-off fingerprint disabled for overnight tests." ;;
            *) echo "- Cause is unclear. Compare wakeup_sources, dmesg, batterystats, and app alarms." ;;
        esac
        echo "- Good target is under 1%/hr with calls and Clock still working."
        echo
        echo "Current idle score:"
        cmd_idle_score
    } > "$OVERNIGHT_FILE" 2>&1
    chmod 0600 "$OVERNIGHT_FILE" 2>/dev/null
    log "overnight report written: $OVERNIGHT_FILE"
    cat "$OVERNIGHT_FILE"
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

write_both_download_tmp() {
    tmp_target="$1"
    download_target="$2"
    writer="$3"
    wrote="$(write_dual_file "$tmp_target" "$download_target" "$writer")"
    if [ -n "$wrote" ]; then
        echo "$wrote"
        return 0
    fi
    return 1
}

wakeup_sort_top() {
    read_wakeup_sources | awk '
        NR == 1 { next }
        NF > 0 {
            count = 0
            if ($7 ~ /^[0-9]+$/) count = $7
            else if ($2 ~ /^[0-9]+$/) count = $2
            printf "%s %s\n", count, $1
        }
    ' 2>/dev/null | sort -nr | head -n "${1:-20}"
}

baseline_wakeup_count() {
    name="$1"
    awk -v n="$name" '
        found == 1 && $1 == n {
            if ($7 ~ /^[0-9]+$/) { print $7; exit }
            if ($2 ~ /^[0-9]+$/) { print $2; exit }
        }
        /^\[wakeup_sources_top_30\]/ { found = 1; next }
        /^\[/ && found == 1 { exit }
    ' "$BASELINE_FILE" 2>/dev/null
}

cmd_wakelock_report() {
    {
        echo "Peridot Idle Drain - Wakelock Report"
        date
        echo
        echo "This is read-only. It does not block or write wakelocks."
        echo
        if ! read_wakeup_sources >/dev/null 2>&1; then
            echo "wakeup_sources is not readable."
            echo "Try running from root, or check /sys/kernel/debug/wakeup_sources manually."
            return
        fi
        if [ -f "$BASELINE_FILE" ]; then
            echo "Top wake sources, delta against overnight-start baseline when available:"
            wakeup_sort_top 25 | while read -r count name; do
                [ -n "$name" ] || continue
                base="$(baseline_wakeup_count "$name")"
                if [ -n "$base" ]; then
                    delta=$((count - base))
                    [ "$delta" -lt 0 ] 2>/dev/null && delta=0
                    printf '%-36s count=%-10s delta=%-10s cause=%s\n' "$name" "$count" "$delta" "$(suspect_from_name "$name")"
                else
                    printf '%-36s count=%-10s delta=%-10s cause=%s\n' "$name" "$count" "n/a" "$(suspect_from_name "$name")"
                fi
            done
        else
            echo "Top wake sources, current cumulative ranking:"
            wakeup_sort_top 25 | while read -r count name; do
                [ -n "$name" ] || continue
                printf '%-36s count=%-10s cause=%s\n' "$name" "$count" "$(suspect_from_name "$name")"
            done
            echo
            echo "Tip: run overnight-start before sleep, then wakelock-report or overnight-report after waking for deltas."
        fi
        echo
        echo "Common interpretation:"
        echo "- modem/radio: weak signal, 5G standby, IMS/data activity. Keep calls safe; do not kill telephony."
        echo "- Wi-Fi/CNSS: scan/PNO/AP noise/Wi-Fi calling/router multicast."
        echo "- alarms/apps: app alarms, push spam, jobs; restrict non-whitelist apps in Thanox/Hail."
        echo "- sensors/fingerprint/touch: AOD, pickup, tap-to-wake, screen-off UDFPS, pocket/touch sensors."
    }
}

extract_packages() {
    sed -n 's/.*\([A-Za-z0-9_][A-Za-z0-9._-]*\.[A-Za-z0-9._-]*\).*/\1/p' 2>/dev/null |
        grep -v '^\.$' |
        sort |
        uniq -c |
        sort -nr |
        head -n "${1:-20}"
}

cmd_alarm_report() {
    {
        echo "Peridot Idle Drain - Alarm Report"
        date
        echo
        echo "Read-only summary from dumpsys alarm."
        echo
        dump="$(dumpsys alarm 2>/dev/null)"
        if [ -z "$dump" ]; then
            echo "dumpsys alarm unavailable."
            return
        fi
        echo "Alarm/clock snippets:"
        printf '%s\n' "$dump" | grep -i -m 40 -e "alarm clock" -e "next alarm" -e "wakeup" -e "pending alarm" -e "allow while idle" || echo "No concise alarm snippets found."
        echo
        echo "Package-ish alarm candidates:"
        printf '%s\n' "$dump" | grep -i -e "wakeup" -e "allow while idle" -e "alarm" | extract_packages 25
        echo
        echo "Guidance: high non-protected candidates belong in Thanox/Hail restriction review, not direct system killing."
    }
}

cmd_jobs_report() {
    {
        echo "Peridot Idle Drain - JobScheduler Report"
        date
        echo
        echo "Read-only summary from dumpsys jobscheduler."
        echo
        dump="$(dumpsys jobscheduler 2>/dev/null)"
        if [ -z "$dump" ]; then
            echo "dumpsys jobscheduler unavailable."
            return
        fi
        echo "Active/pending job snippets:"
        printf '%s\n' "$dump" | grep -i -m 80 -e "running jobs" -e "pending" -e "active" -e "jobstatus" -e "source:" -e "u0a" || echo "No concise jobs snippets found."
        echo
        echo "Package-ish job candidates:"
        printf '%s\n' "$dump" | grep -i -e "jobstatus" -e "source:" -e "service=" -e "package" | extract_packages 25
        echo
        echo "Guidance: frequent jobs from non-whitelist apps are good Thanox/Hail restriction candidates."
    }
}

cmd_location_report() {
    {
        echo "Peridot Idle Drain - Location Report"
        date
        echo
        echo "Read-only summary from dumpsys location."
        echo
        dump="$(dumpsys location 2>/dev/null)"
        if [ -z "$dump" ]; then
            echo "dumpsys location unavailable."
            return
        fi
        echo "Active request/listener snippets:"
        printf '%s\n' "$dump" | grep -i -m 80 -e "request" -e "listener" -e "provider" -e "foreground" -e "background" -e "gps" -e "fused" || echo "No concise location snippets found."
        echo
        echo "Package-ish location candidates:"
        printf '%s\n' "$dump" | grep -i -e "request" -e "listener" -e "provider" -e "package" | extract_packages 25
        echo
        echo "Guidance: location candidates should be restricted in app permissions or Thanox unless they are protected."
    }
}

cmd_sensor_report() {
    {
        echo "Peridot Idle Drain - Sensor Report"
        date
        echo
        echo "Read-only summary from dumpsys sensorservice."
        echo
        dump="$(dumpsys sensorservice 2>/dev/null)"
        if [ -z "$dump" ]; then
            echo "dumpsys sensorservice unavailable."
            return
        fi
        echo "Active connection/listener snippets:"
        printf '%s\n' "$dump" | grep -i -m 100 -e "active" -e "connection" -e "listener" -e "sensor" -e "uid" -e "package" || echo "No concise sensor snippets found."
        echo
        echo "Package-ish sensor candidates:"
        printf '%s\n' "$dump" | grep -i -e "connection" -e "listener" -e "package" -e "uid" | extract_packages 25
        echo
        echo "Guidance: if sensors dominate, keep AOD/pickup/tap/UDFPS off and review apps using motion/location sensors."
    }
}

cmd_network_report() {
    {
        echo "Peridot Idle Drain - Network Report"
        date
        echo
        echo "Read-only summaries from dumpsys connectivity and netstats."
        echo
        conn="$(dumpsys connectivity 2>/dev/null)"
        stats="$(dumpsys netstats 2>/dev/null)"
        if [ -n "$conn" ]; then
            echo "Connectivity snippets:"
            printf '%s\n' "$conn" | grep -i -m 80 -e "defaultnetwork" -e "networkagent" -e "wifi" -e "cellular" -e "background" -e "metered" -e "validated" || echo "No concise connectivity snippets found."
            echo
        else
            echo "dumpsys connectivity unavailable."
            echo
        fi
        if [ -n "$stats" ]; then
            echo "Netstats package-ish candidates:"
            printf '%s\n' "$stats" | grep -i -e "uid=" -e "iface=" -e "tag=" -e "set=BACKGROUND" -e "background" | head -n 200
        else
            echo "dumpsys netstats unavailable."
        fi
        echo
        echo "Guidance: background network from non-whitelist apps should be restricted in Thanox/app settings."
    }
}

third_party_apps_sorted() {
    installed_user_packages | sort
}

cmd_snapshot_apps() {
    mkdir -p "$(dirname "$INSTALLED_APPS_SNAPSHOT")" 2>/dev/null
    third_party_apps_sorted > "$INSTALLED_APPS_SNAPSHOT" 2>/dev/null
    chmod 0644 "$INSTALLED_APPS_SNAPSHOT" 2>/dev/null
    log "installed apps snapshot updated"
    echo "Snapshot updated: $INSTALLED_APPS_SNAPSHOT"
}

cmd_new_apps_report() {
    load_config
    current="/data/local/tmp/peridot_installed_apps_current.txt"
    third_party_apps_sorted > "$current" 2>/dev/null
    chmod 0644 "$current" 2>/dev/null
    {
        echo "Peridot Idle Drain - New Apps Report"
        date
        echo
        echo "Snapshot: $INSTALLED_APPS_SNAPSHOT"
        if [ ! -f "$INSTALLED_APPS_SNAPSHOT" ]; then
            echo "No previous snapshot found. Creating one now."
            cp "$current" "$INSTALLED_APPS_SNAPSHOT" 2>/dev/null
            echo "Run new-apps-report again after installing apps."
            return
        fi
        echo "New third-party apps since snapshot:"
        new_count=0
        comm -13 "$INSTALLED_APPS_SNAPSHOT" "$current" 2>/dev/null | while read -r pkg; do
            [ -n "$pkg" ] || continue
            new_count=$((new_count + 1))
            if protected_contains "$pkg"; then
                echo "- $pkg protected"
            else
                echo "- $pkg freeze/notification-review candidate"
            fi
        done
        echo
        echo "Guidance: add important new apps to protected-list, otherwise review them in Hail/Thanox."
    }
}

write_restore_pack() {
    target="$1"
    {
        echo "Peridot Idle Drain - Restore Pack"
        date
        echo
        echo "Target: Xiaomi peridot running VoltageOS"
        echo "This is a text backup/helper. It does not auto-import untrusted files."
        echo
        echo "[current config.conf]"
        cat "$CONFIG_FILE" 2>/dev/null
        echo
        echo "[protected packages]"
        protected_print_lines
        echo
        echo "[helper files]"
        for file in \
            "$THANOX_FILE_DOWNLOAD" \
            "$APP_POLICY_FILE_DOWNLOAD" \
            "$HAIL_FILE_DOWNLOAD" \
            "$HAIL_PROTECTED_FILE_DOWNLOAD" \
            "$THANOX_RULES_FILE_DOWNLOAD" \
            "$NOTIFICATION_FILE_DOWNLOAD" \
            "$FULL_ANALYSIS_FILE_DOWNLOAD"; do
            [ -f "$file" ] && echo "$file"
        done
        echo
        echo "[manual restore examples]"
        echo "su -c 'sh /data/adb/modules/peridot_idle_drain/scripts/tune.sh protected-reset'"
        echo "su -c 'sh /data/adb/modules/peridot_idle_drain/scripts/tune.sh protected-add com.whatsapp'"
        echo "su -c 'sh /data/adb/modules/peridot_idle_drain/scripts/tune.sh set-profile ultra'"
        echo "su -c 'sh /data/adb/modules/peridot_idle_drain/scripts/tune.sh set-night-schedule 1'"
        echo "su -c 'sh /data/adb/modules/peridot_idle_drain/scripts/tune.sh set-refresh-rate 60'"
        echo "su -c 'sh /data/adb/modules/peridot_idle_drain/scripts/tune.sh my-setup'"
        echo
        echo "[safe category restore]"
        echo "su -c 'sh /data/adb/modules/peridot_idle_drain/scripts/tune.sh restore-category scanning'"
        echo "su -c 'sh /data/adb/modules/peridot_idle_drain/scripts/tune.sh restore-category display'"
        echo "su -c 'sh /data/adb/modules/peridot_idle_drain/scripts/tune.sh restore-category doze'"
        echo "su -c 'sh /data/adb/modules/peridot_idle_drain/scripts/tune.sh restore-category screen'"
        echo "su -c 'sh /data/adb/modules/peridot_idle_drain/scripts/tune.sh restore-category haptics'"
        echo "su -c 'sh /data/adb/modules/peridot_idle_drain/scripts/tune.sh restore-category dark'"
        echo "su -c 'sh /data/adb/modules/peridot_idle_drain/scripts/tune.sh restore-category all'"
    } > "$target" 2>/dev/null
}

cmd_export_restore_pack() {
    load_config
    cmd_export_thanox >/dev/null 2>&1
    cmd_export_app_policy >/dev/null 2>&1
    cmd_export_hail_lists >/dev/null 2>&1
    cmd_export_thanox_templates >/dev/null 2>&1
    cmd_notification_report >/dev/null 2>&1
    wrote="$(write_both_download_tmp "$RESTORE_PACK_FILE_TMP" "$RESTORE_PACK_FILE_DOWNLOAD" write_restore_pack)"
    log "restore pack exported"
    if [ -n "$wrote" ]; then
        echo "Exported restore pack:"
        echo "$wrote"
    else
        echo "Could not write restore pack. Try again after storage is mounted."
    fi
}

restore_key_if_matches() {
    category="$1"
    namespace="$2"
    key="$3"
    value="$4"
    match=0
    case "$category" in
        scanning)
            case "$namespace|$key" in
                global\|wifi_scan_always_enabled|global\|ble_scan_always_enabled|global\|adaptive_connectivity_enabled|global\|network_recommendations_enabled|global\|wifi_wakeup_enabled|global\|wifi_networks_available_notification_on|global\|mobile_data_always_on|secure\|nearby_scanning_enabled|secure\|nearby_scanning_permission_allowed|global\|nearby_scanning_enabled|global\|bluetooth_sanitized_exposure_notification_supported) match=1 ;;
            esac ;;
        display)
            case "$namespace|$key" in
                secure\|doze_enabled|secure\|doze_always_on|secure\|doze_pulse_on_pick_up|secure\|doze_pulse_on_double_tap|secure\|doze_pulse_on_tap|secure\|doze_wake_screen_gesture|secure\|ambient_display_enabled|secure\|ambient_display_always_on|secure\|pickup_gesture_enabled|secure\|wake_gesture_enabled|secure\|double_tap_to_wake|system\|screen_off_udfps_enabled|system\|dt2w|secure\|screen_off_udfps_enabled|system\|single_tap_to_wake) match=1 ;;
            esac ;;
        doze)
            [ "$namespace|$key" = "device_config|device_idle.constants" ] && match=1 ;;
        screen)
            case "$namespace|$key" in
                system\|peak_refresh_rate|system\|min_refresh_rate|system\|user_refresh_rate|secure\|user_refresh_rate|global\|wifi_verbose_logging_enabled|global\|adaptive_connectivity_enabled|global\|network_recommendations_enabled) match=1 ;;
            esac ;;
        haptics)
            case "$namespace|$key" in
                system\|haptic_feedback_enabled|system\|vibrate_when_ringing|system\|haptic_feedback_intensity|system\|notification_vibration_intensity|system\|media_vibration_intensity|system\|touch_vibration_intensity|secure\|haptic_feedback_enabled) match=1 ;;
            esac ;;
        dark)
            case "$namespace|$key" in
                secure\|ui_night_mode|system\|ui_night_mode) match=1 ;;
            esac ;;
    esac
    [ "$match" = "1" ] || return 0
    if [ "$namespace" = "device_config" ] && [ "$key" = "device_idle.constants" ]; then
        restore_device_config "$value"
    else
        settings_delete_or_null_restore "$namespace" "$key" "$value"
    fi
}

cmd_restore_category() {
    category="$1"
    case "$category" in
        scanning|display|doze|screen|haptics|dark) ;;
        all) cmd_restore; return ;;
        *) echo "Usage: $0 restore-category scanning|display|doze|screen|haptics|dark|all"; exit 2 ;;
    esac
    if [ ! -f "$BACKUP_FILE" ]; then
        echo "No backup found."
        exit 0
    fi
    log "restore category requested: $category"
    while IFS='|' read -r namespace key value; do
        [ -n "$namespace" ] || continue
        [ -n "$key" ] || continue
        restore_key_if_matches "$category" "$namespace" "$key" "$value"
    done < "$BACKUP_FILE"
    echo "Restore category completed: $category"
}

write_thanox_templates() {
    target="$1"
    {
        echo "Peridot Idle Drain - Thanox Templates"
        date
        echo
        echo "Copy these ideas into Thanox manually. Package names and Thanox UI labels can vary."
        echo
        echo "[Never freeze / protected]"
        protected_print_lines | sed 's/^/- /'
        echo
        echo "[Template 1: screen off freeze non-whitelist]"
        echo "Trigger: screen off"
        echo "Condition: app is third-party and not in protected list"
        echo "Actions: prevent background start; restrict wakeups/receivers; hibernate/freeze after delay"
        echo "Exclude: protected packages, active music/navigation/call apps"
        echo
        echo "[Template 2: unlock relax]"
        echo "Trigger: screen unlocked"
        echo "Action: allow user-launched apps to open normally"
        echo "Keep: non-whitelist apps restricted until manually opened"
        echo
        echo "[Template 3: charging relax]"
        echo "Trigger: charging connected"
        echo "Action: optionally relax freeze delay for apps you are using"
        echo "Trigger: charging disconnected or screen off"
        echo "Action: return to screen-off freeze policy"
        echo
        echo "[Template 4: night ultra]"
        echo "Trigger: 23:00-07:00 and screen off"
        echo "Action: freeze/restrict every non-whitelist user app"
        echo "Keep: Phone, Clock, SMS, IMS, GMS, SystemUI, root, LSPosed and chosen messenger"
        echo
        echo "[Template 5: noisy app receivers]"
        echo "Target: freeze candidates such as shopping/payment/social/video/news/games"
        echo "Action: block self-start/background start and noisy receivers where Thanox exposes safe controls"
        echo "Do not apply to protected/core packages."
    } > "$target" 2>/dev/null
}

cmd_export_thanox_templates() {
    load_config
    wrote="$(write_both_download_tmp "$THANOX_RULES_FILE_TMP" "$THANOX_RULES_FILE_DOWNLOAD" write_thanox_templates)"
    log "thanox templates exported"
    if [ -n "$wrote" ]; then
        echo "Exported Thanox templates:"
        echo "$wrote"
    else
        echo "Could not write Thanox templates. Try again after storage is mounted."
    fi
}

cmd_export_hail_lists() {
    load_config
    candidates_wrote="$(write_dual_file "$HAIL_FILE_TMP" "$HAIL_FILE_DOWNLOAD" write_hail_candidates)"
    protected_wrote="$(write_dual_file "$HAIL_PROTECTED_FILE_TMP" "$HAIL_PROTECTED_FILE_DOWNLOAD" write_hail_protected)"
    log "hail lists exported"
    echo "Exported Hail freeze candidates:"
    [ -n "$candidates_wrote" ] && echo "$candidates_wrote" || echo "not written"
    echo
    echo "Exported Hail never-freeze/protected list:"
    [ -n "$protected_wrote" ] && echo "$protected_wrote" || echo "not written"
}

my_template_write_file() {
    name="$1"
    target="$2"
    {
        case "$name" in
            peridot_my_template_overview.txt)
                echo "Peridot Idle Drain - Personal Usage Template"
                date
                echo
                echo "Target: Xiaomi peridot running VoltageOS."
                echo "Goal: calls, SMS, Clock/alarm and selected personal messenger stay normal. Maps works when needed. Everything else can be restricted, dozed, frozen or notification-muted manually through Thanox/Hail."
                echo
                echo "[Always alive]"
                echo "- Phone, Dialer, Telecom, Telephony Provider"
                echo "- SMS/Messages"
                echo "- Clock/alarm"
                echo "- GMS, GSF, IMS/eSIM/carrier basics"
                echo "- SystemUI, Settings, Permission Controller"
                echo "- KernelSU/Magisk and LSPosed"
                echo "- selected messenger: Telegram/WhatsApp only if you need instant messages"
                echo
                echo "[Temporary only]"
                echo "- Maps: unfreeze/allow while navigating, freeze/restrict after navigation or exit"
                echo "- Banking/payment apps: allow while foreground, block notifications/background starts, freeze after exit"
                echo
                echo "[Non-whitelist]"
                echo "- Thanox: screen-off restrict/freeze, block background starts and noisy receivers"
                echo "- Hail: manual freeze list for apps you open only when needed"
                echo "- Android settings: disable notifications for non-whitelist apps"
                echo
                echo "[Current protected packages]"
                protected_print_lines | sed 's/^/- /'
                ;;
            peridot_thanox_my_rules.txt)
                echo "Peridot Idle Drain - Personalized Thanox Rules"
                date
                echo
                echo "Copy these concepts into Thanox manually. UI names vary by Thanox version."
                echo
                echo "[Never restrict/freeze]"
                protected_print_lines | sed 's/^/- /'
                echo
                echo "[Rule 1: screen off ultra]"
                echo "Trigger: screen off"
                echo "Target: third-party apps not in protected list"
                echo "Actions: prevent background start; restrict receivers/wakeups; hibernate/freeze after short delay"
                echo "Exclude: Phone, SMS, Clock, GMS/GSF/IMS, SystemUI, root, LSPosed and selected messenger"
                echo
                echo "[Rule 2: foreground only apps]"
                echo "Target: Paytm, banking, shopping, food, travel, news, video, browser, social apps you do not need instantly"
                echo "When opened manually: allow foreground run"
                echo "When app leaves foreground or screen turns off: block background start/receivers and freeze/hibernate"
                echo "Notifications: off unless you explicitly need them"
                echo
                echo "[Rule 3: Maps temporary]"
                echo "Target: com.google.android.apps.maps"
                echo "When Maps is foreground or navigation is active: allow location, network and background service"
                echo "After navigation ends or Maps exits: return to restricted/frozen state"
                echo
                echo "[Rule 4: night minimal]"
                echo "Trigger: night schedule and screen off"
                echo "Keep: calls, SMS and Clock/alarm"
                echo "Optional: selected personal messenger"
                echo "Freeze/restrict: all other user apps"
                ;;
            peridot_hail_my_lists.txt)
                echo "Peridot Idle Drain - Personalized Hail Lists"
                date
                echo
                echo "[Never freeze]"
                protected_print_lines
                echo
                echo "[Do not protect by default]"
                echo "com.google.android.apps.maps # temporary only; unfreeze when navigating"
                echo "net.one97.paytm # example payment app; foreground only"
                echo
                echo "[Freeze candidates installed on this phone]"
                installed_user_packages_not_protected | sed 's/^/- /'
                echo
                echo "Use Hail manually. This module does not freeze, disable or suspend packages."
                ;;
            peridot_notification_my_plan.txt)
                echo "Peridot Idle Drain - Notification Plan"
                date
                echo
                echo "[Keep notifications]"
                echo "- Phone/calls"
                echo "- SMS/Messages"
                echo "- Clock/alarm"
                echo "- selected personal messenger private chats"
                echo "- Maps only while navigating if you want turn-by-turn alerts"
                echo
                echo "[Disable notifications]"
                echo "- payment apps like Paytm unless a specific security/transaction category is needed"
                echo "- shopping, food, social, games, video, music, browser, travel and news apps"
                echo "- every installed non-protected app that does not need to wake you"
                echo
                echo "[Manual review candidates]"
                installed_user_packages_not_protected | sed 's/^/- /'
                echo
                echo "Do this in Android notification settings or inside each app. This module does not run appops sweeps."
                ;;
            peridot_maps_temp_mode.txt)
                echo "Peridot Idle Drain - Maps Temporary Mode"
                date
                echo
                echo "Maps package: com.google.android.apps.maps"
                echo
                echo "Default state:"
                echo "- not protected always"
                echo "- frozen/restricted when not used"
                echo "- location off or restricted when not needed"
                echo
                echo "When needed:"
                echo "- unfreeze/open Maps manually"
                echo "- allow location and network"
                echo "- do not freeze during active navigation"
                echo "- keep Google Play services protected"
                echo
                echo "After use:"
                echo "- end navigation"
                echo "- close Maps"
                echo "- Thanox/Hail can refreeze/restrict after exit or screen off"
                ;;
            peridot_payment_foreground_only.txt)
                echo "Peridot Idle Drain - Payment/Banking Foreground Only"
                date
                echo
                echo "Examples: Paytm, banking, wallet, shopping and UPI helper apps."
                echo
                echo "Default state:"
                echo "- not protected"
                echo "- notifications off except categories you truly need"
                echo "- background start blocked"
                echo "- receivers/wakeups restricted where Thanox exposes safe controls"
                echo "- frozen/hibernated after exit or screen off"
                echo
                echo "When opened manually:"
                echo "- allow foreground network"
                echo "- allow biometric/OTP flow while app is in front"
                echo "- do not break SMS/Phone/GMS because OTP/calls may rely on them"
                echo
                echo "After exit:"
                echo "- freeze or hibernate again"
                echo "- keep notifications blocked"
                ;;
            peridot_telegram_private_only.txt)
                echo "Peridot Idle Drain - Telegram Private-Only Setup"
                date
                echo
                echo "Packages to protect only if Telegram must be instant:"
                echo "- org.telegram.messenger"
                echo "- org.telegram.messenger.web"
                echo "- org.thunderdog.challegram"
                echo
                echo "Inside Telegram:"
                echo "1. Settings > Notifications and Sounds"
                echo "2. Private chats: enabled"
                echo "3. Groups: disabled or muted by default"
                echo "4. Channels: disabled or muted by default"
                echo "5. Bots/Other: disabled or muted"
                echo "6. Archive/mute noisy chats manually"
                echo
                echo "Android cannot reliably separate Telegram private/group/channel/bot notifications from KernelSU. Configure this inside Telegram."
                ;;
            *)
                return 1
                ;;
        esac
    } > "$target" 2>/dev/null
}

cmd_export_my_template() {
    load_config
    wrote=""
    for name in $MY_TEMPLATE_PACKAGES; do
        tmp="/data/local/tmp/$name"
        down="/sdcard/Download/$name"
        result=""
        mkdir -p "$(dirname "$tmp")" 2>/dev/null
        if my_template_write_file "$name" "$tmp"; then
            chmod 0644 "$tmp" 2>/dev/null
            result="$tmp"
        fi
        if [ -d /sdcard/Download ] || mkdir -p /sdcard/Download 2>/dev/null; then
            if my_template_write_file "$name" "$down"; then
                chmod 0644 "$down" 2>/dev/null
                [ -n "$result" ] && result="$result
$down" || result="$down"
            fi
        fi
        [ -n "$result" ] && wrote="$wrote
$result"
    done
    log "my template exported"
    if [ -n "$wrote" ]; then
        echo "Exported personal template pack:"
        printf '%s\n' "$wrote" | sed '/^$/d'
    else
        echo "Could not write personal template pack. Try again after storage is mounted."
    fi
}

write_quick_actions() {
    target="$1"
    {
        echo "Peridot Idle Drain - Quick Actions"
        date
        echo
        echo "Apply personal ultra setup:"
        echo "su -c 'sh /data/adb/modules/peridot_idle_drain/scripts/tune.sh my-setup'"
        echo
        echo "Set profile:"
        echo "su -c 'sh /data/adb/modules/peridot_idle_drain/scripts/tune.sh set-profile ultra'"
        echo "su -c 'sh /data/adb/modules/peridot_idle_drain/scripts/tune.sh set-profile night'"
        echo
        echo "Safety and analysis:"
        echo "su -c 'sh /data/adb/modules/peridot_idle_drain/scripts/tune.sh safety-check'"
        echo "su -c 'sh /data/adb/modules/peridot_idle_drain/scripts/tune.sh analyze-all'"
        echo
        echo "Overnight test:"
        echo "su -c 'sh /data/adb/modules/peridot_idle_drain/scripts/tune.sh overnight-start'"
        echo "# sleep overnight"
        echo "su -c 'sh /data/adb/modules/peridot_idle_drain/scripts/tune.sh overnight-report'"
        echo
        echo "Personal template pack:"
        echo "su -c 'sh /data/adb/modules/peridot_idle_drain/scripts/tune.sh set-my-whitelist-defaults'"
        echo "su -c 'sh /data/adb/modules/peridot_idle_drain/scripts/tune.sh export-my-template'"
        echo
        echo "Manual app policy exports:"
        echo "su -c 'sh /data/adb/modules/peridot_idle_drain/scripts/tune.sh export-hail-lists'"
        echo "su -c 'sh /data/adb/modules/peridot_idle_drain/scripts/tune.sh export-thanox-templates'"
        echo "su -c 'sh /data/adb/modules/peridot_idle_drain/scripts/tune.sh notification-report'"
    } > "$target" 2>/dev/null
}

cmd_export_quick_actions() {
    load_config
    wrote="$(write_dual_file "/data/local/tmp/peridot_quick_actions.txt" "/sdcard/Download/peridot_quick_actions.txt" write_quick_actions)"
    log "quick actions exported"
    if [ -n "$wrote" ]; then
        echo "Exported quick actions:"
        echo "$wrote"
    else
        echo "Could not write quick actions. Try again after storage is mounted."
    fi
}

write_full_analysis() {
    target="$1"
    {
        echo "Peridot Idle Drain - All-in-One Analysis"
        date
        echo
        echo "Target: Xiaomi peridot running VoltageOS"
        echo "This report is read-only and heuristic. It does not block wakelocks or change apps."
        echo
        echo "===== IDLE SCORE ====="
        cmd_idle_score
        echo
        echo "===== SAFETY CHECK ====="
        cmd_safety_check
        echo
        echo "===== WAKELOCKS ====="
        cmd_wakelock_report
        echo
        echo "===== ALARMS ====="
        cmd_alarm_report
        echo
        echo "===== JOBSCHEDULER ====="
        cmd_jobs_report
        echo
        echo "===== LOCATION ====="
        cmd_location_report
        echo
        echo "===== SENSORS ====="
        cmd_sensor_report
        echo
        echo "===== NETWORK ====="
        cmd_network_report
        echo
        echo "===== NOTIFICATION REVIEW SUMMARY ====="
        echo "Non-protected user apps that may deserve manual notification review:"
        installed_user_packages_not_protected | head -n 60 | sed 's/^/- /'
        echo
        echo "Keep notifications for calls, Clock/alarm, SMS, and selected personal messengers."
        echo
        echo "===== APP POLICY SUMMARY ====="
        echo "Protected packages:"
        protected_print_lines | sed 's/^/- /'
        echo
        echo "Recommended optional whitelist apps:"
        recommended_optional_print_lines | sed 's/^/- /'
        echo
        echo "Freeze candidates:"
        installed_user_packages_not_protected | head -n 80 | sed 's/^/- /'
    } > "$target" 2>&1
}

cmd_analyze_all() {
    load_config
    wrote="$(write_both_download_tmp "$FULL_ANALYSIS_FILE_TMP" "$FULL_ANALYSIS_FILE_DOWNLOAD" write_full_analysis)"
    log "full analysis written"
    if [ -n "$wrote" ]; then
        echo "Wrote full analysis:"
        echo "$wrote"
        echo
        cat "$FULL_ANALYSIS_FILE_TMP" 2>/dev/null || cat "$FULL_ANALYSIS_FILE_DOWNLOAD" 2>/dev/null
    else
        echo "Could not write full analysis. Printing directly:"
        write_full_analysis /dev/stdout
    fi
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

cmd_my_setup() {
    load_config
    ENABLED=1
    PROFILE=ultra
    NIGHT_SCHEDULE=1
    NIGHT_START="${NIGHT_START:-23:00}"
    NIGHT_END="${NIGHT_END:-07:00}"
    AGGRESSIVE=1
    SCANNING_TWEAKS=1
    DISPLAY_IDLE_TWEAKS=1
    DOZE_TUNING=1
    ULTRA_IDLE=1
    SCREEN_ON_SAVER=1
    HAPTICS_OFF=1
    DARK_MODE=1
    DARK_WALLPAPER=1
    EXPORT_APP_POLICY=1
    MY_SETUP=1
    SCREEN_ON_REFRESH_RATE=60
    [ -n "$PROTECTED_PACKAGES" ] || PROTECTED_PACKAGES="$DEFAULT_PROTECTED_PACKAGES"
    save_config
    log "my setup enabled"
    cmd_apply
    echo
    cmd_export_app_policy
    echo
    cmd_export_hail
    echo
    cmd_export_thanox
    echo
    cmd_export_thanox_rules
    echo
    cmd_notification_report
    echo
    cmd_export_backup
    echo
    echo "My Setup applied. KernelSU did not freeze, disable, suspend, or notification-block any package."
    echo "Use Hail/Thanox manually with the exported files."
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
        my-setup) MY_SETUP="$value" ;;
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
    reset-all) cmd_reset_all ;;
    status) cmd_status ;;
    diagnose) cmd_diagnose ;;
    analyze-all) cmd_analyze_all ;;
    wakelock-report) cmd_wakelock_report ;;
    alarm-report) cmd_alarm_report ;;
    jobs-report) cmd_jobs_report ;;
    location-report) cmd_location_report ;;
    sensor-report) cmd_sensor_report ;;
    network-report) cmd_network_report ;;
    new-apps-report) cmd_new_apps_report ;;
    snapshot-apps) cmd_snapshot_apps ;;
    export-restore-pack) cmd_export_restore_pack ;;
    restore-category) cmd_restore_category "$2" ;;
    idle-score) cmd_idle_score ;;
    safety-check) cmd_safety_check ;;
    overnight-start) cmd_overnight_start ;;
    overnight-report) cmd_overnight_report ;;
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
    set-my-setup) set_bool_config my-setup "$2" ;;
    set-refresh-rate) set_refresh_rate "$2" ;;
    protected-list) cmd_protected_list ;;
    protected-add) protected_add_pkg "$2" ;;
    protected-remove) protected_remove_pkg "$2" ;;
    protected-reset) protected_reset ;;
    export-thanox) cmd_export_thanox ;;
    export-app-policy) cmd_export_app_policy ;;
    export-hail) cmd_export_hail ;;
    export-hail-lists) cmd_export_hail_lists ;;
    export-thanox-rules) cmd_export_thanox_rules ;;
    export-thanox-templates) cmd_export_thanox_templates ;;
    export-my-template) cmd_export_my_template ;;
    set-my-whitelist-defaults) cmd_set_my_whitelist_defaults ;;
    export-quick-actions) cmd_export_quick_actions ;;
    notification-report) cmd_notification_report ;;
    my-setup) cmd_my_setup ;;
    logs) cmd_logs ;;
    clear-logs) cmd_clear_logs ;;
    *)
        echo "Usage: $0 {boot|apply|profile-list|set-profile profile|apply-profile [profile]|restore|reset-all|restore-category category|status|diagnose|analyze-all|wakelock-report|alarm-report|jobs-report|location-report|sensor-report|network-report|new-apps-report|snapshot-apps|idle-score|safety-check|overnight-start|overnight-report|set-night-schedule 0|1|set-night-window HH:MM HH:MM|pause-minutes n|resume|export-backup|export-restore-pack|set-enabled 0|1|set-aggressive 0|1|set-scanning 0|1|set-display 0|1|set-doze 0|1|set-ultra 0|1|set-screen-saver 0|1|set-haptics 0|1|set-dark-mode 0|1|set-dark-wallpaper 0|1|set-refresh-rate 60|90|120|protected-list|protected-add pkg|protected-remove pkg|protected-reset|export-thanox|export-app-policy|export-hail|export-hail-lists|export-thanox-rules|export-thanox-templates|export-my-template|set-my-whitelist-defaults|export-quick-actions|notification-report|my-setup|logs|clear-logs}"
        exit 2
        ;;
esac
