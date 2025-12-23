export const Chat = {
  mounted() {
    this.id = this.el.dataset.deviceId;
    this.name = this.el.dataset.deviceName;
    this.messagesContainer = document.getElementById("chat-messages");
    this.form = this.el.querySelector("form");
    this.input = this.el.querySelector("input[name='content']");

    // Handle incoming P2P messages pushed from WebRTC hook
    this.handleEvent("chat:received", (msg) => {
        this.appendMessage(msg);
    });

    // Intercept form submission
    this.form.addEventListener("submit", (e) => {
        const content = this.input.value.trim();
        if (content === "") return;

        const msg = {
            id: crypto.randomUUID(),
            sender_id: this.id,
            sender_name: this.name,
            content: content,
            timestamp: new Date().toISOString(),
            type: "chat"
        };

        // 1. Broadcast via P2P
        window.dispatchEvent(new CustomEvent("p2p:broadcast", { detail: msg }));

        // 2. Optimistic local update
        this.appendMessage(msg);

        // 3. Clear input
        this.input.value = "";
        
        // Let Phoenix handle it if online (it will broadcast to others via PubSub)
        // If we are offline, the phx-submit will just fail silently or we can preventDefault
        // Actually, let's let phx-submit run so the server gets it if it's there.
        // But we need to make sure we don't duplicate if the server broadcasts back.
    });
  },

  appendMessage(msg) {
    if (!this.messagesContainer) return;
    
    // Check if message already exists (to avoid duplication with server broadcast)
    if (document.getElementById(`msg-${msg.id}`)) return;

    const isSelf = msg.sender_id === this.id;
    const msgEl = document.createElement("div");
    msgEl.id = `msg-${msg.id}`;
    msgEl.className = `flex flex-col max-w-[80%] ${isSelf ? 'self-end items-end' : 'self-start items-start'} animate-slide-in`;
    
    const time = new Date(msg.timestamp).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
    
    msgEl.innerHTML = `
      <div class="px-4 py-2 rounded-2xl text-sm shadow-sm break-words ${isSelf ? 'bg-sky-500 text-white rounded-br-none' : 'bg-slate-200 dark:bg-slate-700 text-slate-800 dark:text-slate-100 rounded-bl-none'}">
        ${this.escapeHtml(msg.content)}
      </div>
      <span class="text-[10px] text-slate-400 mt-1 px-1">
        ${this.escapeHtml(msg.sender_name)} • ${time}
      </span>
    `;

    // Remove "No messages" placeholder if it exists
    const placeholder = this.messagesContainer.querySelector(".opacity-60");
    if (placeholder) placeholder.remove();

    this.messagesContainer.appendChild(msgEl);
    this.messagesContainer.scrollTop = this.messagesContainer.scrollHeight;
  },

  escapeHtml(str) {
    const div = document.createElement('div');
    div.textContent = str;
    return div.innerHTML;
  }
};
