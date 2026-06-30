#!/system/bin/sh

MODDIR="${0%/*}"

chmod 0755 "$MODDIR/scripts/tune.sh" 2>/dev/null
sh "$MODDIR/scripts/tune.sh" apply
echo
sh "$MODDIR/scripts/tune.sh" status
echo
echo "Recent log:"
sh "$MODDIR/scripts/tune.sh" logs
