export const FileUpload = {
  mounted() {
    this.el.addEventListener("change", (e) => {
      const files = e.target.files;
      if (files && files.length > 0) {
        this.handleFiles(files);
      }
    });

    // Drag and drop support on the container
    const dropZone = this.el.closest("#section-files");
    if (dropZone) {
      dropZone.addEventListener("dragover", (e) => {
        e.preventDefault();
        dropZone.classList.add("border-sky-400", "bg-sky-50");
      });

      dropZone.addEventListener("dragleave", (e) => {
        e.preventDefault();
        dropZone.classList.remove("border-sky-400", "bg-sky-50");
      });

      dropZone.addEventListener("drop", (e) => {
        e.preventDefault();
        dropZone.classList.remove("border-sky-400", "bg-sky-50");
        if (e.dataTransfer.files && e.dataTransfer.files.length > 0) {
          this.handleFiles(e.dataTransfer.files);
        }
      });
    }
  },

  handleFiles(files) {
    const file = files[0]; // Single file for prototype
    if (!file) return;

    // Polyfill ID generation for non-secure contexts
    const transferId = typeof crypto !== 'undefined' && crypto.randomUUID 
        ? crypto.randomUUID() 
        : 'transfer_' + Math.random().toString(36).substr(2, 9);

    // 1. Notify Server of File Offer
    this.pushEvent("file:offer", {
      id: transferId,
      filename: file.name,
      size: file.size,
      type: file.type
    });
    
    // 2. Trigger P2P transfer via WebRTC hook
    window.dispatchEvent(new CustomEvent("start-transfer", { detail: { file, transferId } }));
  }
};
