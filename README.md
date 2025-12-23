# 🧗‍♂️ Wondrop

**Instant, secure, peer-to-peer file sharing directly in your browser.** 🧗‍♂️⚡️👑

[![Elixir Phoenix](https://img.shields.io/badge/Phoenix-1.8.1-red.svg)](https://phoenixframework.org/)
[![WebRTC](https://img.shields.io/badge/WebRTC-P2P-blue.svg)](https://webrtc.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Wondrop is a high-performance, decentralized file transfer platform built with **Elixir Phoenix** and **WebRTC**. It allows users to share files and text across devices on the same local network (or across the internet via Bridge Mode) with zero installation, zero file size limits, and end-to-end encryption.

---

## ✨ Key Features

- 🚀 **Zero Installation**: Runs entirely in the browser. No App Store, no APKs, no friction.
- 🔒 **Privacy First**: Files are transferred via P2P (WebRTC). Data never touches a persistent server.
- 🌉 **Universal Bridge**: Automatically falls back to a secure Relay Server if P2P paths are blocked.
- 📶 **Hotspot & Offline Ready**: Optimized for field-use via mobile hotspots with **Zero-Internet QR generation** and **Conditional STUN bypass**.
- 📱 **Robust PWA**: Installable on iOS and Android with a custom Service Worker that synchronizes fingerprinted assets for 100% offline availability.
- 📋 **Shared Clipboard**: Instant text synchronization across all connected devices.
- 📡 **Live Radar**: Real-time discovery of nearby devices with visual "Live" connectivity badges.

---

## 🛠 Tech Stack

- **Backend**: [Elixir](https://elixir-lang.org/) & [Phoenix Framework](https://www.phoenixframework.org/)
- **Frontend**: [Phoenix LiveView](https://joyofelixir.com/9-phoenix-liveview/) (SSR & Real-time UI)
- **Styling**: [Tailwind CSS](https://tailwindcss.com/) & [Vanilla CSS](https://developer.mozilla.org/en-US/docs/Web/CSS)
- **Real-time**: [Phoenix PubSub](https://hexdocs.pm/phoenix_pubsub/Phoenix.PubSub.html) & [Presence](https://hexdocs.pm/phoenix/Phoenix.Presence.html)
- **P2P Engine**: [Simple-Peer](https://github.com/feross/simple-peer) (WebRTC wrapper)
- **Infrastructure**: [Bandit](https://github.com/mtrudel/bandit) (High-performance HTTP server)

---

## 🚀 Getting Started

### Prerequisites

- Elixir 1.15 or later
- Erlang 26 or later
- Node.js 20 or later
- PostgreSQL

### Installation

1.  **Clone the repository**

    ```bash
    git clone https://github.com/1Bernard/wondrop.git
    cd wondrop
    ```

2.  **Install dependencies**

    ```bash
    mix setup
    ```

3.  **Start the Phoenix server**

    ```bash
    mix phx.server
    ```

4.  **Visit the app**
    Navigate to `http://localhost:4000` in your browser.

---

## 🏗 Architecture Overview

### Handshake Protocol

1. **Room Discovery**: Users join a unique room slug. [Presence](https://hexdocs.pm/phoenix/Phoenix.Presence.html) tracks who is online.
2. **Signaling**: Devices exchange WebRTC SDP offers/answers via Phoenix Channels.
3. **P2P Establishment**: If a direct path exists, data flows directly between browsers.
4. **Relay (Bridge Mode)**: If P2P fails, chunks are streamed through the Phoenix server using binary PubSub messages.

## 🛠 Advanced Features

### Robust PWA Sync

Wondrop uses a custom build-time synchronization script (`assets/pwa-sync.js`) that injects Phoenix's fingerprinted asset paths (e.g., `app-vsn.js`) into the Service Worker. This ensures that the app shell is always cached correctly, even after a deployment.

### Conditional STUN Bypass

To support air-gapped hotspots, Wondrop detects if it's being accessed via a local IP range (192.168.x.x, 10.x.x.x, etc.). In these cases, it skips external STUN server lookups, preventing the 15-20 second connection delay typical of browsers waiting for STUN timeouts in isolated networks.

### Receiver Control

Security is paramount. Senders cannot "push" files to anyone. The receiver must explicitly click "Accept" to initiate the WebRTC data channel transmission, protecting users from unwanted content and saving bandwidth.

---

## 🌍 Deployment

Wondrop is optimized for **Gigalixir**.

### Quick Deploy

```bash
gigalixir create -n your-app-name
gigalixir pg:create --free
git push gigalixir main
gigalixir run mix ecto.migrate
```

Ensure the following environment variables are set in production:

- `PHX_HOST`: Your production domain.
- `SECRET_KEY_BASE`: Generated via `mix phx.gen.secret`.
- `DATABASE_URL`: Your production PostgreSQL URL.

---

## 📜 License

Distributed under the MIT License. See `LICENSE` for more information.

## 🤝 Contributing

Contributions are what make the open-source community such an amazing place to learn, inspire, and create. Any contributions you make are **greatly appreciated**.

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

Built with ❤️ by [1Bernard](https://github.com/1Bernard)
