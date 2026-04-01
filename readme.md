# PairUp iOS 📱
### Real-Time Random Video Chat — Native iOS App

> Meet strangers. Have real conversations. Built with WebRTC, Swift, and SwiftUI.



---

## 🔗 Related

- **Backend Server** → [github.com/prudh-vi/pairup-server](https://github.com/prudh-vi/pairup-server)
- **Web App** → [pairup-frontend.vercel.app](https://pairup-frontend.vercel.app)

---

## ⚡ Features

- 🎯 **Random Matchmaking** — Instantly paired with a stranger worldwide
- 📹 **Real P2P Video** — WebRTC powered, no middleman for media
- 💬 **In-App Chat** — Real-time messaging during video calls
- ⏭️ **Skip System** — Skip and find a new match instantly
- 🔄 **Auto Reconnect** — Seamless recovery from network drops
- 🌐 **Cross-Platform** — iOS app talks to web users on the same backend
- 🔒 **Secure** — WSS + SSL via Let's Encrypt

---

## 🏗️ Architecture

```
┌─────────────────────────────────────┐
│           iOS App (Swift)           │
│                                     │
│  HomeView → MatchmakingView → CallView │
│         SwiftUI + MVVM             │
└──────────────┬──────────────────────┘
               │ WSS (Socket.IO)
               ▼
┌─────────────────────────────────────┐
│     Signaling Server (GCP VM)       │
│   Hono + Socket.IO + TypeScript     │
│      NGINX + SSL (Let's Encrypt)    │
└──────────────┬──────────────────────┘
               │ WebRTC P2P
               ▼
┌─────────────────────────────────────┐
│         STUN / TURN Server          │
│  STUN → discover public IP          │
│  TURN → relay for strict NAT        │
│  (Jio, Airtel, corporate networks)  │
└─────────────────────────────────────┘
```

---

## 🔬 How It Works

1. User opens app → connects to signaling server via Socket.IO over WSS
2. Emits `client:start_chat` → enters matchmaking queue
3. Server pairs two users → assigns `caller` and `receiver` roles
4. **Caller** creates SDP offer → sent via Socket.IO → **Receiver** creates answer
5. Both exchange ICE candidates through signaling server
6. ICE finds best path → STUN (direct P2P) or TURN (relay fallback)
7. WebRTC connection established → video/audio flows peer to peer
8. Socket.IO steps back — only used for chat and control events

---

## 🛠️ Tech Stack

| Layer | Technology |
|---|---|
| Language | Swift 5.9 |
| UI Framework | SwiftUI |
| Architecture | MVVM |
| Video Rendering | RTCMTLVideoView (UIViewRepresentable) |
| Real-time | Socket.IO Swift Client |
| P2P Video | WebRTC (stasel/WebRTC 146.0.0) |
| State Management | ObservableObject + @Published |
| Backend | TypeScript, Hono, Socket.IO |
| Deployment | Google Cloud VM, NGINX, SSL |
| NAT Traversal | STUN + TURN (Coturn) |

---

## 📁 Project Structure

```
pairup-ios/
├── Models/
├── Services/
│   ├── SocketService.swift     # Socket.IO signaling
│   └── WebRTCService.swift     # WebRTC peer connection
├── ViewModels/
├── Views/
│   ├── HomeView.swift          # Landing screen
│   ├── MatchmakingView.swift   # Finding match
│   ├── CallView.swift          # Video call screen
│   └── ChatView.swift          # In-call chat
└── ContentView.swift
```

---

## 🚀 Getting Started

### Prerequisites
- Xcode 15+
- iOS 16+
- macOS Ventura or later
- Apple Developer Account (for real device testing)

### Installation

```bash
# Clone the repo
git clone https://github.com/prudh-vi/pairup-ios

# Open in Xcode
open pairup-ios.xcodeproj
```

### Package Dependencies
Xcode will auto-resolve these →
- [socket.io-client-swift](https://github.com/socketio/socket.io-client-swift)
- [WebRTC](https://github.com/stasel/WebRTC)

### Permissions Required
Add to `Info.plist` →
```xml
<key>NSCameraUsageDescription</key>
<string>PairUp needs camera for video calls</string>

<key>NSMicrophoneUsageDescription</key>
<string>PairUp needs microphone for audio calls</string>
```

### Run
```
CMD + R → Build and run on simulator or real device
```

> ⚠️ Camera and microphone only work on real iPhone — simulator shows black video feed

---

## 🌐 Backend

The signaling server is open source →

👉 [github.com/prudh-vi/pairup-server](https://github.com/prudh-vi/pairup-server)

> Production URLs and TURN credentials 
> are configured via environment variables.
> See backend repo for setup instructions.

---

## 📡 Socket Events

| Event | Direction | Description |
|---|---|---|
| `client:start_chat` | Client → Server | Join matchmaking queue |
| `server:matched` | Server → Client | Match found, room assigned |
| `webrtc:offer` | Client → Server | SDP offer |
| `webrtc:answer` | Client → Server | SDP answer |
| `webrtc:ice` | Client → Server | ICE candidate |
| `client:send_message` | Client → Server | Chat message |
| `server:new_message` | Server → Client | Incoming chat message |
| `client:skip` | Client → Server | Skip current partner |
| `server:partner_left` | Server → Client | Partner disconnected |

