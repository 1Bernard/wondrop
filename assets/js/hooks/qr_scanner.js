import { Html5QrcodeScanner } from "html5-qrcode";

export const QRScanner = {
  mounted() {
    this.scanner = null;

    this.handleEvent("scanner:start", () => {
      this.startScanner();
    });

    this.handleEvent("scanner:stop", () => {
      this.stopScanner();
    });
  },

  startScanner() {
    if (this.scanner) return;

    this.scanner = new Html5QrcodeScanner("reader", { 
        fps: 10, 
        qrbox: { width: 250, height: 250 },
        aspectRatio: 1.0
    });

    this.scanner.render((decodedText) => {
      console.log("[Scanner] QR Code detected!");
      this.pushEvent("scanner:detected", { data: decodedText });
      this.stopScanner();
    }, (error) => {
      // Ignore scan errors as they occur frequently when no QR is in view
    });
  },

  stopScanner() {
    if (this.scanner) {
      this.scanner.clear().then(() => {
        this.scanner = null;
        console.log("[Scanner] Stopped.");
      }).catch(err => {
        console.error("[Scanner] Failed to stop:", err);
      });
    }
  },

  destroyed() {
    this.stopScanner();
  }
};
