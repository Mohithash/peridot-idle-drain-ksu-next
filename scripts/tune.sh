#!/system/bin/sh
M=${0%/*}/..
L=/data/local/tmp/peridot_idle.log
B=/data/local/tmp/peridot_idle.bak
bk(){ [ -f $B ]||:>$B; grep -q "^$1|$2|" $B 2>/dev/null||echo "$1|$2|$(settings get $1 $2 2>/dev/null)" >>$B; }
put(){ bk $1 $2; settings put $1 $2 $3 >/dev/null 2>&1; echo "$1.$2=$3" >>$L; }
apply(){
put global wifi_scan_always_enabled 0;put global ble_scan_always_enabled 0;put global wifi_wakeup_enabled 0;put global adaptive_connectivity_enabled 0;put global mobile_data_always_on 0
put secure nearby_scanning_enabled 0;put secure doze_enabled 0;put secure doze_always_on 0;put secure doze_pulse_on_pick_up 0;put secure doze_pulse_on_double_tap 0;put secure doze_pulse_on_tap 0;put secure ambient_display_enabled 0;put secure wake_gesture_enabled 0;put secure pickup_gesture_enabled 0
put system haptic_feedback_enabled 0;put system peak_refresh_rate 60;put system min_refresh_rate 60
cmd uimode night yes >/dev/null 2>&1;echo applied
}
reset(){ [ -f $B ]&&while IFS='|' read n k v;do [ "$v" = null ]&&settings delete $n $k||settings put $n $k "$v";done<$B;rm -f $L;echo reset; }
case "$1" in status)echo "Peridot Idle v1.7.7 by Mohithash";;apply|my-setup|set-profile|apply-profile)apply;;safety-check)echo "Calls/SMS/Clock untouched. Test once.";;overnight-start)date > /data/local/tmp/peridot_start.txt;dumpsys battery|grep level >> /data/local/tmp/peridot_start.txt;;overnight-report)dumpsys battery|grep level;cat /data/local/tmp/peridot_start.txt 2>/dev/null;;analyze-all)cat /sys/kernel/debug/wakeup_sources 2>/dev/null|head -20;dumpsys alarm 2>/dev/null|head -40;;reset-all|restore)reset;;logs)cat $L 2>/dev/null;;clear-logs):>$L;;*)echo "status apply my-setup safety-check overnight-start overnight-report analyze-all reset-all logs";;esac
