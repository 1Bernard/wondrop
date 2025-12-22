import SimplePeer from "simple-peer";

export const WebRTC = {
  mounted() {
    this.peers = {}; // peer_id -> SimplePeer instance
    this.chunks = {}; // peer_id -> [chunks]
    this.pendingFiles = [];
    this.canceledTransfers = new Set();
    this.bridgeMode = this.el.dataset.bridgeMode === "true";
    this.offers = {}; // transferId -> { file, bridgeMode }

    // Identity
    this.currentId = this.el.dataset.device;
    const deviceId = this.currentId;
    const roomId = this.el.dataset.room;
    
    console.log(`WebRTC Hook Mounted: ${deviceId} in ${roomId}`);
    console.log("Secure Context:", window.isSecureContext ? "Yes" : "No (P2P may be restricted)");

    if (!window.isSecureContext && window.location.hostname !== 'localhost') {
        this.pushEvent("insecure_context_detected", {});
        this.pushEvent("peer_error", { error: "Insecure Context detected. P2P is disabled by your browser. Bridge Mode will be used automatically." });
    }

    // Listen for Signal from Server (Relay)
    this.handleEvent("phx-p2p-signal", ({ sender_id, signal }) => {
      // If we don't have a peer for this sender, create one (we are receiver)
      if (!this.peers[sender_id]) {
        this.createPeer(sender_id, false);
      }
      // Pass signal to peer
      this.peers[sender_id].signal(signal);
    });

    // Listen for "Initiate" command (We are initiator)
    this.handleEvent("initiate_peer", ({ peer_id }) => {
      if (this.peers[peer_id]) return; // Already connected
      console.log(`Initiating connection to ${peer_id}`);
      const peer = this.createPeer(peer_id, true); 
      
      // Automatic Failure Detection
      const timeout = setTimeout(() => {
          if (!peer.connected) {
              console.warn(`Connection to ${peer_id} timed out. Switching to Bridge Mode...`);
              this.pushEvent("bridge:auto_switch", { reason: "timeout" });
          }
      }, 7000); // 7 seconds timeout

      peer.on('connect', () => {
          clearTimeout(timeout);
          console.log(`Connected to peer ${peer_id}`);
          this.pushEvent("peer_connected", { peer_id: peer_id });
          
          // Flush pending files
          if (this.pendingFiles.length > 0) {
              console.log(`Sending ${this.pendingFiles.length} pending files to ${peer_id}`);
              this.pendingFiles.forEach(({ file, transferId }) => {
                  this.sendFile(peer, file, transferId);
              });
              this.pendingFiles = [];
          }
      });
    });
    
    // Listen for Save File trigger
    this.handleEvent("trigger_save", ({ id }) => {
        if (this.chunks[id]) {
            const data = this.chunks[id];
            const blob = new Blob(data.chunks, { type: data.meta.mime });
            const url = URL.createObjectURL(blob);
            const a = document.createElement("a");
            a.href = url;
            a.download = data.meta.filename;
            document.body.appendChild(a);
            a.click();
            document.body.removeChild(a);
            URL.revokeObjectURL(url);
        } else {
            console.error("File data not found for ID:", id);
        }
    });

    // Listen for Approval to start sending
    this.handleEvent("file:approved", ({ id, receiver_id }) => {
        if (this.offers[id]) {
            const { file } = this.offers[id];
            const bridgeMode = this.el.dataset.bridgeMode === "true";

            console.log(`[Approval] File ${id} approved by ${receiver_id}. Starting stream...`);

            if (bridgeMode) {
                // If in Bridge Mode, we only need to start the stream once
                this.sendViaBridge(file, id);
                delete this.offers[id]; // Don't start multiple bridge streams
            } else {
                // If P2P, send to the specific peer who approved
                const peer = this.peers[receiver_id];
                if (peer && peer.connected) {
                    this.sendFile(peer, file, id);
                    // We keep the offer in case other peers approve too!
                } else {
                    console.warn(`[Approval] Peer ${receiver_id} not connected. Cannot send P2P.`);
                }
            }
        }
    });

    // Listen for local file upload event
    window.addEventListener("start-transfer", (e) => {
        const file = e.detail.file;
        const transferId = e.detail.transferId;
        const bridgeMode = this.el.dataset.bridgeMode === "true";

        console.log(`[Flow] Offer created for ${file.name}. Waiting for receiver approval...`);
        this.offers[transferId] = { file, bridgeMode };
        
        // We only trigger feedback here
        this.pushEvent("peer_error", { error: "Awaiting receiver approval..." });
        
        // Auto-switch reminder logic (can stay or go, but let's keep it for unreachable peers)
        const delay = window.isSecureContext ? 3000 : 500;
        setTimeout(() => {
            const isStillPending = !!this.offers[transferId];
            const hasConnectedPeers = Object.values(this.peers).some(p => p.connected);
            
            if (isStillPending && !hasConnectedPeers && !this.bridgeMode) {
                this.pushEvent("bridge:auto_switch", { reason: "no_peers" });
            }
        }, delay);
    });
    
    // Listen for relayed bridge chunks
    this.handleEvent("file:bridge_chunk", (payload) => {
        // payload: { sender_id, data (base64 or similar?) }
        // Actually, for simplicity, let's assume we receive the same structure handleData expects
        // But handleData expects ArrayBuffer. 
        // Phoenix pushes JSON. so 'data' will be B64 string.
        const { sender_id, chunk, metadata } = payload;
        
        if (sender_id === this.currentId) return; // Ignore self
        console.log(`[Bridge] Received chunk from ${sender_id}`);

        if (metadata) {
            // It's a start/end metadata packet
            const msg = JSON.parse(metadata);
            if (msg.type === 'file-start') {
                 this.currentTransfer = this.currentTransfer || {};
                 this.currentTransfer[sender_id] = msg.id;
                 this.chunks[msg.id] = { chunks: [], meta: msg };
                 console.log("Receiving Bridged File:", msg.filename);
            } else if (msg.type === 'file-end') {
                 console.log("Bridged File Complete");
            }
        } else if (chunk) {
            // It's a binary chunk (base64 encoded)
            // Convert B64 to Uint8Array/ArrayBuffer
            const binary = Uint8Array.from(atob(chunk), c => c.charCodeAt(0));
            const transferId = this.currentTransfer && this.currentTransfer[sender_id];
            if(transferId && this.chunks[transferId]) {
               this.chunks[transferId].chunks.push(binary);
            }
        }
    });

    // Listen for Cancellation
    this.handleEvent("file:cancel", ({ id }) => {
        console.log(`[Transfer] Canceling ${id}`);
        this.canceledTransfers.add(id);
        
        // Cleanup receiver buffers
        if (this.chunks[id]) {
            delete this.chunks[id];
        }
        if (this.offers[id]) {
            delete this.offers[id];
        }
        // Cleanup transfer tracking
        if (this.currentTransfer) {
            Object.keys(this.currentTransfer).forEach(peerId => {
                if (this.currentTransfer[peerId] === id) delete this.currentTransfer[peerId];
            });
        }
    });
  },

  updated() {
      const wasBridge = this.bridgeMode;
      this.bridgeMode = this.el.dataset.bridgeMode === "true";

      // If we just entered Bridge Mode and have pending files, flush them!
      if (this.bridgeMode && !wasBridge && this.pendingFiles && this.pendingFiles.length > 0) {
          console.log(`Bridge Mode activated. Flushing ${this.pendingFiles.length} pending files via relay.`);
          this.pendingFiles.forEach(({ file, transferId }) => {
              this.sendViaBridge(file, transferId);
          });
          this.pendingFiles = [];
      }
  },

  sendViaBridge(file, transferId) {
      // 1. Send Start Metadata
      const metadata = JSON.stringify({ 
          type: 'file-start',
          id: transferId,
          filename: file.name, 
          size: file.size, 
          mime: file.type 
      });
      // Push metadata
      this.pushEvent("file:bridge_chunk", { metadata: metadata, chunk: null });

      // Update state to sending
      this.pushEvent("file:progress", { id: transferId, progress: 0, state: "sending" });

      // 2. Chunk and Send (Base64)
      const chunkSize = 64 * 1024; // 64KB (More efficient for Bridge Mode over HTTP)
      let offset = 0;
      let lastProgressUpdate = 0;

      const readSlice = (o) => {
          if (this.canceledTransfers.has(transferId)) {
              console.log(`[Bridge] Transfer ${transferId} aborted.`);
              return;
          }
          const slice = file.slice(o, o + chunkSize);
          const reader = new FileReader();
          reader.onload = (e) => {
              const arrayBuffer = e.target.result;
              // Convert to Base64
              let binary = '';
              const bytes = new Uint8Array(arrayBuffer);
              const len = bytes.byteLength;
              for (let i = 0; i < len; i++) {
                  binary += String.fromCharCode(bytes[i]);
              }
              const base64 = btoa(binary);

              // Push chunk
              this.pushEvent("file:bridge_chunk", { metadata: null, chunk: base64 });
              
              offset += chunkSize;
               
              // Progress
              const progress = Math.min(100, Math.round((offset / file.size) * 100));
              const now = Date.now();
              if (now - lastProgressUpdate > 200 || progress === 100) {
                  this.pushEvent("file:progress", { 
                      id: transferId, 
                      progress: progress,
                      state: progress === 100 ? "completed" : "sending"
                  });
                  lastProgressUpdate = now;
              }

              if (offset < file.size) {
                  setTimeout(() => readSlice(offset), 0); // small delay to not block UI
              } else {
                  // Done
                  const endMeta = JSON.stringify({ type: 'file-end', id: transferId, filename: file.name });
                  this.pushEvent("file:bridge_chunk", { metadata: endMeta, chunk: null });
                  console.log("Bridged File Sent");
              }
          };
          reader.readAsArrayBuffer(slice);
      };
      readSlice(0);
  },

  createPeer(peer_id, initiator) {
    let peer;
    try {
        peer = new SimplePeer({
          initiator: initiator,
          trickle: true,
          // Default config includes STUN, but host candidates (mDNS/IP) 
          // will work offline if STUN servers are unreachable.
          config: { iceServers: [{ urls: 'stun:stun.l.google.com:19302' }] } 
        });
    } catch (e) {
        console.error("CRITICAL: P2P Connection failed to initialize. Likely 'Insecure Context' (HTTP).", e);
        this.pushEvent("peer_error", { error: "P2P blocked by browser security. Using Bridge Mode instead." });
        this.pushEvent("bridge:auto_switch", { reason: "insecure_context" });
        return { destroyed: true, on: () => {}, signal: () => {} }; // Dummy peer
    }

    peer.on('signal', signal => {
      this.pushEvent("phx-p2p-signal", { 
        receiver_id: peer_id, 
        signal: signal 
      });
    });

    peer.on('connect', () => {
      console.log(`Connected to peer ${peer_id}`);
      this.pushEvent("peer_connected", { peer_id: peer_id });
      peer.connected = true; // Mark as connected for our logic

      // Flush pending files
      if (this.pendingFiles.length > 0) {
          console.log(`Sending ${this.pendingFiles.length} pending files to ${peer_id}`);
          this.pendingFiles.forEach(({ file, transferId }) => {
              this.sendFile(peer, file, transferId);
          });
          // Clear pending files to avoid duplicate sends
          this.pendingFiles = []; 
      }
    });

    peer.on('data', data => {
      this.handleData(peer_id, data);
    });

    peer.on('error', err => {
      console.error('Peer Error:', err);
      this.pushEvent("peer_error", { error: err.toString() });
      this.pushEvent("bridge:auto_switch", { reason: "error" });
    });
    
    peer.on('close', () => {
        console.log("Peer closed");
        if (this.peers[peer_id]) {
            this.peers[peer_id].destroyed = true;
            delete this.peers[peer_id];
        }
    });

    this.peers[peer_id] = peer;
    return peer;
  },

  sendFile(peer, file, transferId) {
      // 1. Send Start Metadata
      const metadata = JSON.stringify({ 
          type: 'file-start',
          id: transferId,
          filename: file.name, 
          size: file.size, 
          mime: file.type 
      });
      peer.send(metadata);
      
      // Update state to sending
      this.pushEvent("file:progress", { id: transferId, progress: 0, state: "sending" });

      // 2. Chunk and Send
      const chunkSize = 16 * 1024; // 16KB chunks
      let offset = 0;
      let lastProgressUpdate = 0;
      
      const readSlice = (o) => {
          if (this.canceledTransfers.has(transferId)) {
              console.log(`[P2P] Transfer ${transferId} aborted.`);
              return;
          }
          const slice = file.slice(o, o + chunkSize);
          const reader = new FileReader();
          reader.onload = (e) => {
              if (peer.destroyed) return;
              peer.send(e.target.result); // Send ArrayBuffer
              offset += chunkSize;
              
              // Calculate Progress
              const progress = Math.min(100, Math.round((offset / file.size) * 100));
              const now = Date.now();
              
              // Throttle updates to every 200ms
              if (now - lastProgressUpdate > 200 || progress === 100) {
                  this.pushEvent("file:progress", { 
                      id: transferId, 
                      progress: progress,
                      state: progress === 100 ? "completed" : "sending"
                  });
                  lastProgressUpdate = now;
              }

              if (offset < file.size) {
                  // Continue reading
                  setTimeout(() => readSlice(offset), 0);
              } else {
                  // Done
                  peer.send(JSON.stringify({ type: 'file-end', id: transferId, filename: file.name }));
                  console.log("File sent successfully");
              }
          };
          reader.readAsArrayBuffer(slice);
      };

      readSlice(0);
  },

  handleData(peerId, data) {
      try {
          // Check if data is string (Metadata)
          const text = new TextDecoder().decode(data);
          const msg = JSON.parse(text);
          
          if(msg.type === 'file-start') {
             this.currentTransfer = this.currentTransfer || {};
             this.currentTransfer[peerId] = msg.id;
             this.chunks[msg.id] = { chunks: [], meta: msg };
             console.log("Receiving file:", msg.filename);
             
          } else if (msg.type === 'file-end') {
             console.log("File reception complete:", msg.filename);
             // Verify we have the ID, if not fallback to current (should allow multiple if concurrent)
             // For prototype, assume strict order.
             const transferId = msg.id || this.currentTransfer[peerId];
             
             // Notify server we are done (optional, server triggers 'completed' state via progress calc usually)
             // But for receiver, we just wait for user to click save.
          }
      } catch (e) {
          // Binary Data (Chunk)
          const transferId = this.currentTransfer && this.currentTransfer[peerId];
          if(transferId && this.chunks[transferId]) {
              this.chunks[transferId].chunks.push(data);
          }
      }
  }
};
