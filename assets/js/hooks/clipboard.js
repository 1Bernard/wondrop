export const Clipboard = {
  mounted() {
    // Helper to update UI and system clipboard
    this.updateClipboard = (content) => {
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
    };

    // Handle incoming P2P clipboard pushes
    this.handleEvent("clipboard:received", ({ content }) => {
        this.updateClipboard(content);
    });

    // Listen for server push to update local clipboard
    this.handleEvent("clipboard:sync", ({ content }) => {
      this.updateClipboard(content);
    });

    // Intercept Push form for P2P broadcast
    const form = this.el.closest("form");
    if (form) {
      form.addEventListener("submit", (e) => {
        const textarea = document.getElementById("clipboard-input");
        if (textarea) {
          const content = textarea.value.trim();
          if (content !== "") {
            window.dispatchEvent(new CustomEvent("p2p:broadcast", { 
              detail: { type: "clipboard", content: content } 
            }));
          }
        }
      });
    }

    // Listen for custom "copy-current-url" event from buttons
    this.el.addEventListener("copy-current-url", () => {
        const url = window.location.href;
        if (navigator.clipboard && navigator.clipboard.writeText) {
            navigator.clipboard.writeText(url).then(() => {
                alert("Link copied!");
            }).catch(() => {
                prompt("Copy this link manually:", url);
            });
        } else {
            prompt("Copy this link manually:", url);
        }
    });
  }
};
