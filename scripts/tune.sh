#!/system/bin/sh
v=1.7.8
g(){ settings get "$1" "$2" 2>/dev/null; }
p(){ settings put "$1" "$2" "$3" >/dev/null 2>&1; }
show(){
echo "Peridot Idle v$v by Mohithash"
echo "wifi_scan=$(g global wifi_scan_always_enabled)"
echo "ble_scan=$(g global ble_scan_always_enabled)"
echo "mobile_data_always_on=$(g global mobile_data_always_on)"
echo "nearby=$(g secure nearby_scanning_enabled)"
echo "doze=$(g secure doze_enabled)"
echo "aod=$(g secure doze_always_on)"
echo "ambient=$(g secure ambient_display_enabled)"
echo "haptics=$(g system haptic_feedback_enabled)"
echo "peak_hz=$(g system peak_refresh_rate)"
echo "min_hz=$(g system min_refresh_rate)"
echo "night_mode=$(g secure ui_night_mode)"
}
apply(){
p global wifi_scan_always_enabled 0
p global ble_scan_always_enabled 0
p global wifi_wakeup_enabled 0
p global adaptive_connectivity_enabled 0
p global mobile_data_always_on 0
p secure nearby_scanning_enabled 0
p secure doze_enabled 0
p secure doze_always_on 0
p secure doze_pulse_on_pick_up 0
p secure doze_pulse_on_double_tap 0
p secure doze_pulse_on_tap 0
p secure ambient_display_enabled 0
p secure wake_gesture_enabled 0
p secure pickup_gesture_enabled 0
p system haptic_feedback_enabled 0
p system peak_refresh_rate 60
p system min_refresh_rate 60
cmd uimode night yes >/dev/null 2>&1
echo "Applied. Current values:"
show
}
reset(){
p global wifi_scan_always_enabled 1
p global ble_scan_always_enabled 1
p global mobile_data_always_on 1
p secure doze_enabled 1
p secure doze_always_on 0
p secure ambient_display_enabled 0
p system haptic_feedback_enabled 1
settings delete system peak_refresh_rate >/dev/null 2>&1
settings delete system min_refresh_rate >/dev/null 2>&1
cmd uimode night no >/dev/null 2>&1
echo "Reset basic values. Reboot after uninstall."
show
}
case "$1" in
status)show;;
apply|my-setup|set-profile|apply-profile)apply;;
safety-check)echo "Safe: this script does not stop Phone/SMS/Clock/IMS/modem/GMS/SystemUI.";;
overnight-start)date>/sdcard/Download/peridot_start.txt;dumpsys battery|grep level>>/sdcard/Download/peridot_start.txt;echo "Started. Sleep, then run report.";;
overnight-report)echo "Start:";cat /sdcard/Download/peridot_start.txt 2>/dev/null;echo "Now:";dumpsys battery|grep level;;
analyze-all)dumpsys deviceidle|head -60;echo "---wakeup---";cat /sys/kernel/debug/wakeup_sources 2>/dev/null|head -20;;
reset-all|restore)reset;;
logs)show;;
clear-logs)echo "No private log in v$v";;
*)echo "Commands: status apply my-setup safety-check overnight-start overnight-report analyze-all reset-all";;
esac
