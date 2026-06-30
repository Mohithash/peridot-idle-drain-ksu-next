# Peridot Idle Drain Tweaks

KernelSU Next module for Xiaomi peridot on VoltageOS.

Author: Mohithash
Repo: https://github.com/Mohithash/peridot-idle-drain-ksu-next

v1.8.0 is the full chunked compatibility build. KernelSU Next on the test phone
zero-filled larger installed files, so the module ships tiny payload chunks and
rebuilds the full backend script at runtime.

The module applies reversible Android settings for idle battery and exports
Thanox/Hail helper files. It does not directly freeze apps.

Safety: no modem/IMS/telephony/GMS/SystemUI stopping, no package disabling,
no appops sweep, no remounts, no thermal/governor/wakelock writes.

Useful commands:

```sh
su -c 'sh /data/adb/modules/peridot_idle_drain/scripts/tune.sh status'
su -c 'sh /data/adb/modules/peridot_idle_drain/scripts/tune.sh my-setup'
su -c 'sh /data/adb/modules/peridot_idle_drain/scripts/tune.sh safety-check'
su -c 'sh /data/adb/modules/peridot_idle_drain/scripts/tune.sh analyze-all'
su -c 'sh /data/adb/modules/peridot_idle_drain/scripts/tune.sh reset-all'
```

Features include profiles, safe ultra apply, call/alarm safety check, overnight
report, wakelock/alarm/job/location/sensor/network analyzers, protected-package
whitelist commands, and Thanox/Hail/export templates. Calls, SMS, Clock, IMS,
modem, GMS, SystemUI, root, and LSPosed are not stopped or frozen.

For uninstall, run `reset-all`, remove the module in KernelSU Next, then reboot.
