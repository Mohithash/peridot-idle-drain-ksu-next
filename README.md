# Peridot Idle Drain Tweaks

KernelSU Next module for Xiaomi peridot on VoltageOS.

Author: Mohithash
Repo: https://github.com/Mohithash/peridot-idle-drain-ksu-next

v1.7.5 is a compact compatibility build for KernelSU Next installs that zero
large module files. Runtime ZIP entries are intentionally small.

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

For uninstall, run `reset-all`, remove the module in KernelSU Next, then reboot.
