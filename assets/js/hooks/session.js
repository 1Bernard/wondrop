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
