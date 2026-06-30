#!/system/bin/sh

MODDIR="${MODDIR:-$(cd "$(dirname "$0")/.." 2>/dev/null && pwd)}"
CONFIG_FILE="$MODDIR/config.conf"
LOG_FILE="/data/local/tmp/peridot_idle_drain.log"
BACKUP_FILE="/data/local/tmp/peridot_idle_drain_backup.txt"

ensure_files() {
    mkdir -p "$(dirname "$LOG_FILE")" 2>/dev/null
    touch "$LOG_FILE" 2>/dev/null
    chmod 0600 "$LOG_FILE" 2>/dev/null

    if [ ! -f "$CONFIG_FILE" ]; then
        {
            echo "ENABLED=1"
            echo "AGGRESSIVE=0"
        } > "$CONFIG_FILE"
        chmod 0644 "$CONFIG_FILE" 2>/dev/null
    fi
}

load_config() {
    ensure_files
    ENABLED=1
    AGGRESSIVE=0
    # shellcheck disable=SC1090
    . "$CONFIG_FILE" 2>/dev/null
    [ "$ENABLED" = "1" ] || ENABLED=0
    [ "$AGGRESSIVE" = "1" ] || AGGRESSIVE=0
}

save_config() {
    {
        echo "ENABLED=$ENABLED"
        echo "AGGRESSIVE=$AGGRESSIVE"
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

    old_value="$(settings_get "$namespace" "$key")"
    ensure_backup

    if ! grep -q "^${namespace}|${key}|" "$BACKUP_FILE" 2>/dev/null; then
        printf '%s|%s|%s\n' "$namespace" "$key" "$old_value" >> "$BACKUP_FILE"
    fi

    if settings put "$namespace" "$key" "$value" >/dev/null 2>&1; then
        log "settings: $namespace $key=$value old=$old_value"
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

apply_deviceidle_constants() {
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

apply_safe_settings() {
    settings_put global wifi_scan_always_enabled 0
    settings_put global ble_scan_always_enabled 0
    settings_put global bluetooth_sanitized_exposure_notification_supported 0
    settings_put global adaptive_connectivity_enabled 0
    settings_put global network_recommendations_enabled 0
    settings_put global wifi_wakeup_enabled 0

    settings_put secure nearby_scanning_enabled 0
    settings_put secure nearby_scanning_permission_allowed 0
    settings_put global nearby_scanning_enabled 0

    settings_put secure doze_enabled 0
    settings_put secure doze_always_on 0
    settings_put secure doze_pulse_on_pick_up 0
    settings_put secure doze_pulse_on_double_tap 0
    settings_put secure doze_pulse_on_tap 0
    settings_put secure doze_wake_screen_gesture 0
    settings_put secure ambient_display_enabled 0
    settings_put secure ambient_display_always_on 0
    settings_put secure pickup_gesture_enabled 0
    settings_put secure wake_gesture_enabled 0
    settings_put secure double_tap_to_wake 0
    settings_put system screen_off_udfps_enabled 0
    settings_put system dt2w 0

    settings_put global wifi_networks_available_notification_on 0
    settings_put global mobile_data_always_on 0
}

apply_aggressive_settings() {
    [ "$AGGRESSIVE" = "1" ] || return
    log "aggressive mode enabled"

    settings_put global wifi_poor_connection_warning 0
    settings_put global wifi_verbose_logging_enabled 0
    settings_put global bluetooth_on_while_driving 0
    settings_put secure assistant 0
    settings_put secure voice_interaction_service 0
}

cmd_apply() {
    load_config
    if [ "$ENABLED" != "1" ]; then
        log "apply skipped: module disabled"
        echo "Peridot Idle Drain Tweaks: disabled"
        exit 0
    fi

    log "apply start ENABLED=$ENABLED AGGRESSIVE=$AGGRESSIVE"
    apply_safe_settings
    apply_deviceidle_constants
    apply_aggressive_settings
    log "apply complete"
    echo "Applied idle-drain tweaks. Aggressive=$AGGRESSIVE"
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
    echo "Config: $CONFIG_FILE"
    echo "Log: $LOG_FILE"
    echo "Backup: $BACKUP_FILE"
    if [ -f "$BACKUP_FILE" ]; then
        echo "Backup exists: yes"
    else
        echo "Backup exists: no"
    fi
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

cmd_set_enabled() {
    load_config
    case "$1" in
        0|1) ENABLED="$1" ;;
        *) echo "Usage: $0 set-enabled 0|1"; exit 2 ;;
    esac
    save_config
    log "config: ENABLED=$ENABLED"
    echo "Enabled set to $ENABLED"
}

cmd_set_aggressive() {
    load_config
    case "$1" in
        0|1) AGGRESSIVE="$1" ;;
        *) echo "Usage: $0 set-aggressive 0|1"; exit 2 ;;
    esac
    save_config
    log "config: AGGRESSIVE=$AGGRESSIVE"
    echo "Aggressive set to $AGGRESSIVE"
}

case "$1" in
    apply) cmd_apply ;;
    restore) cmd_restore ;;
    status) cmd_status ;;
    set-enabled) cmd_set_enabled "$2" ;;
    set-aggressive) cmd_set_aggressive "$2" ;;
    logs) cmd_logs ;;
    clear-logs) cmd_clear_logs ;;
    *)
        echo "Usage: $0 {apply|restore|status|set-enabled 0|1|set-aggressive 0|1|logs|clear-logs}"
        exit 2
        ;;
esac
