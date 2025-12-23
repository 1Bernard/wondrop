export const Session = {
  mounted() {
    // 1. Restore from LocalStorage
    const deviceId = localStorage.getItem("aether_device_id");
    const deviceName = localStorage.getItem("aether_device_name");
    const stealthMode = localStorage.getItem("aether_stealth_mode") === "true";
    const quickSave = localStorage.getItem("aether_quick_save") === "true";
    const bridgeMode = localStorage.getItem("aether_bridge_mode") === "true";

    if (deviceId && deviceName) {
      console.log("Restoring session...", { deviceId, deviceName, bridgeMode });
      this.pushEvent("session:restore", {
        id: deviceId,
        name: deviceName,
        stealth_mode: stealthMode,
        quick_save: quickSave,
        bridge_mode: bridgeMode
      });
    } else {
      // 2. Request new session initialization if nothing stored
      console.log("No session found, requesting init...");
      this.pushEvent("session:request_init", {});
    }

    // 3. Listen for Save Events from Server
    // Persistent Offline ID
    let offlineId = localStorage.getItem("wondrop_offline_id");
    if (!offlineId) {
        offlineId = "offline-" + Math.random().toString(36).substr(2, 9);
        localStorage.setItem("wondrop_offline_id", offlineId);
    }
    this.pushEvent("manual:set_offline_id", { id: offlineId });

    // Global Offline Detection
    const updateStatus = () => {
        const isOffline = !navigator.onLine;
        this.pushEvent("manual:set_offline_mode", { offline: isOffline });
        document.body.classList.toggle("is-offline", isOffline);
    };

    window.addEventListener("online", updateStatus);
    window.addEventListener("offline", updateStatus);
    updateStatus();

    this.handleEvent("session:save", (payload) => {
      console.log("Saving session...", payload);
      localStorage.setItem("aether_device_id", payload.id);
      localStorage.setItem("aether_device_name", payload.name);
      localStorage.setItem("aether_stealth_mode", payload.stealth_mode);
      localStorage.setItem("aether_quick_save", payload.quick_save);
      localStorage.setItem("aether_bridge_mode", payload.bridge_mode);
    });
  }
};
