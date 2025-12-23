import SimplePeer from "simple-peer";

export const ManualSignaling = {
  mounted() {
    this.handleEvent("manual:initiate", () => {
      this.initiateManualPeer();
    });

    this.handleEvent("manual:process_answer", ({ answer }) => {
      if (this.initiatorPeer) {
        this.initiatorPeer.signal(JSON.parse(answer));
      }
    });

    this.handleEvent("manual:process_offer", ({ offer }) => {
      this.respondToManualOffer(offer);
    });
  },

  initiateManualPeer() {
    console.log("[Manual] Initiating Manual Handshake...");
    const peer = new SimplePeer({
      initiator: true,
      trickle: false, // Must be false for a single QR code handshake
      config: { iceServers: [] } // No STUN for true offline
    });

    peer.on('signal', data => {
      const sdpJson = JSON.stringify(data);
      console.log("[Manual] Offer generated.");
      this.pushEvent("manual:offer_ready", { offer: sdpJson });
    });

    peer.on('connect', () => {
      console.log("[Manual] P2P Connected via Manual Handshake!");
      window.dispatchEvent(new CustomEvent("manual-peer-connected", { 
        detail: { peer: peer, peerId: "manual-peer-" + Math.random().toString(36).substr(2, 5) }
      }));
      this.pushEvent("manual:connected", {});
    });

    peer.on('error', err => console.error("[Manual] Peer Error:", err));
    
    this.initiatorPeer = peer;
  },

  respondToManualOffer(offerSdp) {
    console.log("[Manual] Responding to Manual Offer...");
    const peer = new SimplePeer({
      initiator: false,
      trickle: false,
      config: { iceServers: [] }
    });

    peer.on('signal', data => {
      const sdpJson = JSON.stringify(data);
      console.log("[Manual] Answer generated.");
      this.pushEvent("manual:answer_ready", { answer: sdpJson });
    });

    peer.on('connect', () => {
      console.log("[Manual] P2P Connected as Receiver!");
      window.dispatchEvent(new CustomEvent("manual-peer-connected", { 
        detail: { peer: peer, peerId: "manual-peer-remote" }
      }));
      this.pushEvent("manual:connected", {});
    });

    peer.on('error', err => console.error("[Manual] Peer Error:", err));

    peer.signal(JSON.parse(offerSdp));
    this.receiverPeer = peer;
  }
};
