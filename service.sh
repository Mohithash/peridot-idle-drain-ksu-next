#!/system/bin/sh

MODDIR="${0%/*}"

[ -x "$MODDIR/scripts/tune.sh" ] || chmod 0755 "$MODDIR/scripts/tune.sh" 2>/dev/null

i=0
while [ "$(getprop sys.boot_completed 2>/dev/null)" != "1" ] && [ "$i" -lt 90 ]; do
    sleep 2
    i=$((i + 1))
done

sleep 20

sh "$MODDIR/scripts/tune.sh" boot
