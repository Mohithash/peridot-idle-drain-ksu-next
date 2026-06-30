#!/system/bin/sh

MODDIR="${MODDIR:-$(cd "$(dirname "$0")/.." 2>/dev/null && pwd)}"
CONFIG_FILE="$MODDIR/config.conf"
LOG_FILE="/data/local/tmp/peridot_idle_drain.log"
BACKUP_FILE="/data/local/tmp/peridot_idle_drain_backup.txt"
DIAG_FILE="/data/local/tmp/peridot_idle_drain_diagnose.txt"

ensure_files() {
    mkdir -p "$(dirname "$LOG_FILE")" 2>/dev/null
    touch "$LOG_FILE" 2>/dev/null
    chmod 0600 "$LOG_FILE" 2>/dev/null

    if [ ! -f "$CONFIG_FILE" ]; then
        {
            echo "ENABLED=1"
            echo "AGGRESSIVE=0"
            echo "SCANNING_TWEAKS=1"
            echo "DISPLAY_IDLE_TWEAKS=1"
            echo "DOZE_TUNING=1"
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
    AGGRESSIVE=0
    SCANNING_TWEAKS=1
    DISPLAY_IDLE_TWEAKS=1
    DOZE_TUNING=1
    # shellcheck disable=SC1090
    . "$CONFIG_FILE" 2>/dev/null
    ENABLED="$(bool_or_zero "$ENABLED")"
    AGGRESSIVE="$(bool_or_zero "$AGGRESSIVE")"
    SCANNING_TWEAKS="$(bool_or_zero "$SCANNING_TWEAKS")"
    DISPLAY_IDLE_TWEAKS="$(bool_or_zero "$DISPLAY_IDLE_TWEAKS")"
    DOZE_TUNING="$(bool_or_zero "$DOZE_TUNING")"
}

save_config() {
    {
        echo "ENABLED=$ENABLED"
        echo "AGGRESSIVE=$AGGRESSIVE"
        echo "SCANNING_TWEAKS=$SCANNING_TWEAKS"
        echo "DISPLAY_IDLE_TWEAKS=$DISPLAY_IDLE_TWEAKS"
        echo "DOZE_TUNING=$DOZE_TUNING"
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

print_setting() {
    printf '%s %-42s %s\n' "$1" "$2" "$(settings_get "$1" "$2")"
}

cmd_apply() {
    load_config
    if [ "$ENABLED" != "1" ]; then
        log "apply skipped: module disabled"
        echo "Peridot Idle Drain Tweaks: disabled"
        exit 0
    fi

    log "apply start ENABLED=$ENABLED AGGRESSIVE=$AGGRESSIVE SCANNING=$SCANNING_TWEAKS DISPLAY=$DISPLAY_IDLE_TWEAKS DOZE=$DOZE_TUNING"
    apply_scanning_settings
    apply_display_idle_settings
    apply_deviceidle_constants
    apply_aggressive_settings
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
    echo "Aggressive: $AGGRESSIVE"
    echo "Scanning tweaks: $SCANNING_TWEAKS"
    echo "Display idle tweaks: $DISPLAY_IDLE_TWEAKS"
    echo "Doze tuning: $DOZE_TUNING"
    echo "Config: $CONFIG_FILE"
    echo "Log: $LOG_FILE"
    echo "Backup: $BACKUP_FILE"
    echo "Diagnose: $DIAG_FILE"
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
            "secure nearby_scanning_enabled" \
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
        *) echo "Unknown config: $var"; exit 2 ;;
    esac
    save_config
    log "config: $var=$value"
    echo "$var set to $value"
}

case "$1" in
    apply) cmd_apply ;;
    restore) cmd_restore ;;
    status) cmd_status ;;
    diagnose) cmd_diagnose ;;
    set-enabled) set_bool_config enabled "$2" ;;
    set-aggressive) set_bool_config aggressive "$2" ;;
    set-scanning) set_bool_config scanning "$2" ;;
    set-display) set_bool_config display "$2" ;;
    set-doze) set_bool_config doze "$2" ;;
    logs) cmd_logs ;;
    clear-logs) cmd_clear_logs ;;
    *)
        echo "Usage: $0 {apply|restore|status|diagnose|set-enabled 0|1|set-aggressive 0|1|set-scanning 0|1|set-display 0|1|set-doze 0|1|logs|clear-logs}"
        exit 2
        ;;
esac
