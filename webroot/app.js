(() => {
  // node_modules/kernelsu/index.js
  var callbackCounter = 0;
  function getUniqueCallbackName(prefix) {
    return `${prefix}_callback_${Date.now()}_${callbackCounter++}`;
  }
  function exec(command, options) {
    if (typeof options === "undefined") {
      options = {};
    }
    return new Promise((resolve, reject) => {
      const callbackFuncName = getUniqueCallbackName("exec");
      window[callbackFuncName] = (errno, stdout, stderr) => {
        resolve({ errno, stdout, stderr });
        cleanup(callbackFuncName);
      };
      function cleanup(successName) {
        delete window[successName];
      }
      try {
        ksu.exec(command, JSON.stringify(options), callbackFuncName);
      } catch (error) {
        reject(error);
        cleanup(callbackFuncName);
      }
    });
  }
  function Stdio() {
    this.listeners = {};
  }
  Stdio.prototype.on = function(event, listener) {
    if (!this.listeners[event]) {
      this.listeners[event] = [];
    }
    this.listeners[event].push(listener);
  };
  Stdio.prototype.emit = function(event, ...args) {
    if (this.listeners[event]) {
      this.listeners[event].forEach((listener) => listener(...args));
    }
  };
  function ChildProcess() {
    this.listeners = {};
    this.stdin = new Stdio();
    this.stdout = new Stdio();
    this.stderr = new Stdio();
  }
  ChildProcess.prototype.on = function(event, listener) {
    if (!this.listeners[event]) {
      this.listeners[event] = [];
    }
    this.listeners[event].push(listener);
  };
  ChildProcess.prototype.emit = function(event, ...args) {
    if (this.listeners[event]) {
      this.listeners[event].forEach((listener) => listener(...args));
    }
  };

  // webroot-src/app.js
  var output = document.getElementById("output");
  var apiError = document.getElementById("apiError");
  var tune = "/data/adb/modules/peridot_idle_drain/scripts/tune.sh";
  var HAS_KERNELSU_API = typeof window !== "undefined" && window.ksu && typeof window.ksu.exec === "function";
  var execFn = null;
  var profileInfo = {
    balanced: {
      title: "Balanced",
      affects: "scanning reduction, moderate Doze, 120 Hz available",
      safe: "does not change AOD/tap/pickup, calls, SMS, Clock, IMS, modem, GMS, SystemUI or root"
    },
    idle: {
      title: "Idle saver",
      affects: "scanning, display idle, AOD/tap/pickup/screen-off UDFPS, Doze",
      safe: "does not stop calls, SMS, Clock, IMS, modem, GMS, SystemUI or root"
    },
    ultra: {
      title: "Ultra idle",
      affects: "scanning, display idle, Doze, app standby hints, screen saver, haptics, dark mode, 60 Hz",
      safe: "does not freeze apps directly and does not stop calls, SMS, Clock, IMS, modem, GMS, SystemUI or root"
    },
    night: {
      title: "Night profile",
      affects: "same safe aggressive direction as Ultra for overnight idle",
      safe: "keeps calls, SMS and Clock/alarm path protected; does not stop telephony, IMS, GMS, SystemUI or root"
    },
    screen: {
      title: "Screen-on saver",
      affects: "60 Hz, dark mode, haptics off, screen-on discovery reductions",
      safe: "does not force display idle/Doze and does not stop calls, SMS, Clock, Maps, IMS, GMS or SystemUI"
    }
  };
  var ids = [
    "enabled",
    "profile",
    "nightSchedule",
    "nightStart",
    "nightEnd",
    "aggressive",
    "scanning",
    "display",
    "doze",
    "ultra",
    "screenSaver",
    "haptics",
    "darkMode",
    "darkWallpaper",
    "refreshRate",
    "packageName"
  ];
  var el = {};
  ids.forEach((id) => {
    el[id] = document.getElementById(id);
  });
  function show(text) {
    output.textContent = text || "";
  }
  function showError(error) {
    const message = error && error.message ? error.message : String(error || "Unknown error");
    apiError.style.display = "block";
    show(`WebUI error: ${message}

Manual fallback:
su -c 'sh ${tune} status'
su -c 'sh ${tune} my-setup'
su -c 'sh ${tune} reset-all'`);
  }
  window.addEventListener("error", (event) => {
    showError(event.error || event.message);
  });
  window.addEventListener("unhandledrejection", (event) => {
    showError(event.reason);
  });
  function explainProfile(name) {
    const info = profileInfo[name] || profileInfo.idle;
    document.getElementById("profileExplain").innerHTML = `<strong>${info.title}</strong><span>Affects: ${info.affects}.</span><span>Safe areas: ${info.safe}.</span>`;
  }
  async function run(args) {
    if (!execFn) throw new Error("KernelSU API unavailable");
    const result = await execFn(`sh ${tune} ${args}`);
    return result.stdout || result.stderr || "";
  }
  async function refresh() {
    const text = await run("status");
    show(text);
    el.enabled.checked = /Enabled:\s*1/.test(text);
    const profileMatch = text.match(/Profile:\s*(balanced|idle|ultra|night|screen)/);
    if (profileMatch) el.profile.value = profileMatch[1];
    explainProfile(el.profile.value);
    el.nightSchedule.checked = /Night schedule:\s*1/.test(text);
    const nightMatch = text.match(/Night window:\s*([0-2][0-9]:[0-5][0-9])-([0-2][0-9]:[0-5][0-9])/);
    if (nightMatch) {
      el.nightStart.value = nightMatch[1];
      el.nightEnd.value = nightMatch[2];
    }
    el.aggressive.checked = /Aggressive:\s*1/.test(text);
    el.scanning.checked = /Scanning tweaks:\s*1/.test(text);
    el.display.checked = /Display idle tweaks:\s*1/.test(text);
    el.doze.checked = /Doze tuning:\s*1/.test(text);
    el.ultra.checked = /Ultra idle:\s*1/.test(text);
    el.screenSaver.checked = /Screen-on saver:\s*1/.test(text);
    el.haptics.checked = /Haptics off:\s*1/.test(text);
    el.darkMode.checked = /Dark mode:\s*1/.test(text);
    el.darkWallpaper.checked = /Dark wallpaper:\s*1/.test(text);
    const rate = text.match(/Screen-on refresh rate:\s*(60|90|120)/);
    if (rate) el.refreshRate.value = rate[1];
  }
  function validPackageName(pkg) {
    return /^[A-Za-z0-9_][A-Za-z0-9._-]*\.[A-Za-z0-9._-]+$/.test(pkg) && !pkg.includes("..") && !pkg.endsWith(".");
  }
  async function bindButton(id, command, shouldRefresh = false) {
    document.getElementById(id).addEventListener("click", async () => {
      try {
        show(await run(typeof command === "function" ? command() : command));
        if (shouldRefresh) await refresh();
      } catch (error) {
        showError(error);
      }
    });
  }
  function loadKernelSuApi() {
    if (HAS_KERNELSU_API) {
      execFn = exec;
      return true;
    }
    apiError.style.display = "block";
    explainProfile("idle");
    show([
      "KernelSU WebUI API unavailable.",
      "",
      "Open this module from KernelSU Next / KernelSU Manager module WebUI.",
      "If you are already there, your manager WebView/API bridge may be incompatible.",
      "",
      "Manual command examples:",
      "su -c 'sh /data/adb/modules/peridot_idle_drain/scripts/tune.sh status'",
      "su -c 'sh /data/adb/modules/peridot_idle_drain/scripts/tune.sh my-setup'",
      "su -c 'sh /data/adb/modules/peridot_idle_drain/scripts/tune.sh reset-all'"
    ].join("\n"));
    return false;
  }
  async function main() {
    explainProfile("idle");
    el.profile.addEventListener("change", async () => {
      explainProfile(el.profile.value);
      show(await run(`set-profile ${el.profile.value}`));
      await refresh();
    });
    el.enabled.addEventListener("change", async () => {
      show(await run(`set-enabled ${el.enabled.checked ? 1 : 0}`));
      await refresh();
    });
    el.nightSchedule.addEventListener("change", async () => {
      show(await run(`set-night-schedule ${el.nightSchedule.checked ? 1 : 0}`));
      await refresh();
    });
    el.aggressive.addEventListener("change", async () => {
      show(await run(`set-aggressive ${el.aggressive.checked ? 1 : 0}`));
      await refresh();
    });
    el.scanning.addEventListener("change", async () => {
      show(await run(`set-scanning ${el.scanning.checked ? 1 : 0}`));
      await refresh();
    });
    el.display.addEventListener("change", async () => {
      show(await run(`set-display ${el.display.checked ? 1 : 0}`));
      await refresh();
    });
    el.doze.addEventListener("change", async () => {
      show(await run(`set-doze ${el.doze.checked ? 1 : 0}`));
      await refresh();
    });
    el.ultra.addEventListener("change", async () => {
      show(await run(`set-ultra ${el.ultra.checked ? 1 : 0}`));
      await refresh();
    });
    el.screenSaver.addEventListener("change", async () => {
      show(await run(`set-screen-saver ${el.screenSaver.checked ? 1 : 0}`));
      await refresh();
    });
    el.haptics.addEventListener("change", async () => {
      show(await run(`set-haptics ${el.haptics.checked ? 1 : 0}`));
      await refresh();
    });
    el.darkMode.addEventListener("change", async () => {
      show(await run(`set-dark-mode ${el.darkMode.checked ? 1 : 0}`));
      await refresh();
    });
    el.darkWallpaper.addEventListener("change", async () => {
      show(await run(`set-dark-wallpaper ${el.darkWallpaper.checked ? 1 : 0}`));
      await refresh();
    });
    el.refreshRate.addEventListener("change", async () => {
      show(await run(`set-refresh-rate ${el.refreshRate.value}`));
      await refresh();
    });
    bindButton("mySetup", "my-setup", true);
    bindButton("apply", "apply", true);
    bindButton("safetyCheck", "safety-check");
    bindButton("exportMyTemplate", "export-my-template");
    bindButton("applyProfile", () => `apply-profile ${el.profile.value}`, true);
    bindButton("idleScore", "idle-score");
    bindButton("overnightStart", "overnight-start");
    bindButton("overnightReport", "overnight-report");
    bindButton("analyzeAll", "analyze-all");
    bindButton("diagnose", "diagnose");
    bindButton("wakelockReport", "wakelock-report");
    bindButton("alarmReport", "alarm-report");
    bindButton("jobsReport", "jobs-report");
    bindButton("locationReport", "location-report");
    bindButton("sensorReport", "sensor-report");
    bindButton("networkReport", "network-report");
    bindButton("listPackages", "protected-list");
    bindButton("whitelistDefaults", "set-my-whitelist-defaults", true);
    bindButton("exportHailLists", "export-hail-lists");
    bindButton("exportThanoxTemplates", "export-thanox-templates");
    bindButton("notificationReport", "notification-report");
    bindButton("newAppsReport", "new-apps-report");
    bindButton("pause30", "pause-minutes 30", true);
    bindButton("resume", "resume", true);
    bindButton("exportRestorePack", "export-restore-pack");
    bindButton("exportBackup", "export-backup");
    bindButton("restore", "restore");
    bindButton("viewLogs", "logs");
    bindButton("clearLogs", "clear-logs");
    bindButton("snapshotApps", "snapshot-apps");
    document.getElementById("saveNightWindow").addEventListener("click", async () => {
      if (!el.nightStart.value || !el.nightEnd.value) {
        show("Select both night start and end times.");
        return;
      }
      show(await run(`set-night-window ${el.nightStart.value} ${el.nightEnd.value}`));
      await refresh();
    });
    document.getElementById("addPackage").addEventListener("click", async () => {
      const pkg = el.packageName.value.trim();
      if (!validPackageName(pkg)) {
        show("Enter a valid package name first.");
        return;
      }
      show(await run(`protected-add ${pkg}`));
      el.packageName.value = "";
      await refresh();
    });
    document.getElementById("removePackage").addEventListener("click", async () => {
      const pkg = el.packageName.value.trim();
      if (!validPackageName(pkg)) {
        show("Enter a valid package name first.");
        return;
      }
      show(await run(`protected-remove ${pkg}`));
      el.packageName.value = "";
      await refresh();
    });
    document.querySelectorAll("[data-restore-category]").forEach((button) => {
      button.addEventListener("click", async () => {
        show(await run(`restore-category ${button.dataset.restoreCategory}`));
      });
    });
    document.getElementById("resetAll").addEventListener("click", async () => {
      if (!confirm("Reset all module settings and generated files before uninstall?")) return;
      show(await run("reset-all"));
      await refresh();
    });
    if (await loadKernelSuApi()) {
      await refresh();
    }
  }
  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", main);
  } else {
    main();
  }
})();
