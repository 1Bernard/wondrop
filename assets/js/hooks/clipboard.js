export const Clipboard = {
  mounted() {
    // Listen for server push to update local clipboard
    this.handleEvent("clipboard:sync", ({ content }) => {
      // Update local textarea if it exists (might be in another tab, so check)
      const textarea = document.getElementById("clipboard-input");
      if (textarea) {
        textarea.value = content;
      }
      

      
      // Try to write to system clipboard if allowed (Secure Context only)
      if (navigator.clipboard && navigator.clipboard.writeText) {
          navigator.clipboard.writeText(content).catch(err => {
            console.warn("Clipboard write failed:", err);
            prompt("Copy this link manually:", content);
          });
      } else {
          // Fallback for non-secure contexts (HTTP)
          prompt("Copy this link manually:", content);
      }
    });

    // Listen for custom "copy-current-url" event from buttons
    this.el.addEventListener("copy-current-url", () => {
        const url = window.location.href;
        if (navigator.clipboard && navigator.clipboard.writeText) {
            navigator.clipboard.writeText(url).then(() => {
                // Optional: Flash success message?
                alert("Link copied!");
            }).catch(() => {
                prompt("Copy this link manually:", url);
            });
        } else {
            prompt("Copy this link manually:", url);
        }
    });
  },

  updated() {
      // If the element value was updated by LiveView, we might want to sync? 
      // Probably not needed if we rely on explicit events.
  }
};
