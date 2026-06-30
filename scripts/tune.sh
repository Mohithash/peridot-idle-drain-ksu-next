#!/system/bin/sh
M="${0%/*}/.."
O=/data/local/tmp/peridot_idle_full.sh
P="$M/payload/tune"
rm -f "$O"
for f in "$P"/*;do [ -f "$f" ]&&cat "$f">>"$O";done
if [ ! -s "$O" ];then
 echo "Peridot Idle: payload missing";exit 1
fi
chmod 0755 "$O" 2>/dev/null
exec sh "$O" "$@"
