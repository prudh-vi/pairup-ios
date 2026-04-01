//
//  SocketService.swift
//  pairup-ios
//
//  Created by Prudhvii on 01/04/26.
//

import Foundation
import SocketIO
import Combine
struct ChatMessage: Identifiable {
    let id = UUID()
    let text: String
    let isMe: Bool
}

class SocketService: ObservableObject {
    static let shared = SocketService()
    
    private var manager: SocketManager!
    private var socket: SocketIOClient!
    
    @Published var isConnected = false
    @Published var isMatched = false
    @Published var roomId = ""
    @Published var role = ""
    @Published var partnerLeft = false
    @Published var messages: [ChatMessage] = []
    @Published var mySocketId = ""
    
    init() {
        manager = SocketManager(
            socketURL: URL(string: "https://backxpairup.zrxprudhvi.tech")!,
            config: [.log(false), .compress, .forceWebsockets(true)]
        )
        socket = manager.defaultSocket
        setupHandlers()
    }
    
    // MARK: - Setup
    private func setupHandlers() {
        
        socket.on(clientEvent: .connect) { _, _ in
            DispatchQueue.main.async {
                self.isConnected = true
                self.mySocketId = self.socket.sid ?? ""
                print("✅ Connected! ID: \(self.mySocketId)")
            }
        }
        
        socket.on(clientEvent: .disconnect) { _, _ in
            DispatchQueue.main.async {
                self.isConnected = false
                print("❌ Disconnected!")
            }
        }
        
        socket.on("server:matched") { data, _ in
            guard let dict = data[0] as? [String: Any],
                  let roomId = dict["roomId"] as? String,
                  let role = dict["role"] as? String else { return }
            
            DispatchQueue.main.async {
                self.roomId = roomId
                self.role = role
                self.isMatched = true
                print("🎯 Matched! Room: \(roomId) Role: \(role)")
                
                // Setup WebRTC immediately!
                WebRTCService.shared.setupPeerConnection()
                
                // If caller → create offer!
                if role == "caller" {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        WebRTCService.shared.createOffer { offer in
                            SocketService.shared.sendOffer(offer: offer)
                        }
                    }
                }
            }
        }
        
        socket.on("server:partner_left") { _, _ in
            DispatchQueue.main.async {
                self.partnerLeft = true
                self.isMatched = false
                print("👋 Partner left!")
            }
        }
        
        socket.on("server:new_message") { data, _ in
            guard let dict = data[0] as? [String: Any],
                  let message = dict["message"] as? String,
                  let sender = dict["sender"] as? String else { return }
            
            DispatchQueue.main.async {
                // Only add if from PARTNER!
                if sender != self.socket.sid {
                    self.messages.append(ChatMessage(text: message, isMe: false))
                }
            }
        }
        
        // Add these inside setupHandlers()

        socket.on("webrtc:offer") { data, _ in
            guard let dict = data[0] as? [String: Any],
                  let offer = dict["offer"] as? [String: Any] else { return }
            
            print("📥 Got offer!")
            WebRTCService.shared.setRemoteDescription(offer)
            WebRTCService.shared.createAnswer { answer in
                SocketService.shared.sendAnswer(answer: answer)
            }
        }

        socket.on("webrtc:answer") { data, _ in
            guard let dict = data[0] as? [String: Any],
                  let answer = dict["answer"] as? [String: Any] else { return }
            
            print("📥 Got answer!")
            WebRTCService.shared.setRemoteDescription(answer)
        }

        socket.on("webrtc:ice") { data, _ in
            guard let dict = data[0] as? [String: Any],
                  let candidate = dict["candidate"] as? [String: Any] else { return }
            
            print("📥 Got ICE!")
            WebRTCService.shared.addICECandidate(candidate)
        }
    }
    
    // MARK: - Actions
    func connect() {
        socket.connect()
    }
    
    func disconnect() {
        socket.disconnect()
    }
    
    func startChat() {
        socket.emit("client:start_chat")
        print("🚀 Looking for match...")
    }
    
    func skip() {
        socket.emit("client:skip", ["roomId": roomId])
        isMatched = false
        roomId = ""
        print("⏭️ Skipped!")
    }
    func sendMessage(_ text: String) {
        socket.emit("client:send_message", ["roomId": roomId, "message": text])
        // Add locally immediately!
        DispatchQueue.main.async {
            self.messages.append(ChatMessage(text: text, isMe: true))
        }
    }
    
    // MARK: - WebRTC Signaling
    func sendOffer(offer: [String: Any]) {
        socket.emit("webrtc:offer", ["roomId": roomId, "offer": offer])
        print("📤 Sent offer")
    }
    
    func sendAnswer(answer: [String: Any]) {
        socket.emit("webrtc:answer", ["roomId": roomId, "answer": answer])
        print("📤 Sent answer")
    }
    
    func sendICE(candidate: [String: Any]) {
        socket.emit("webrtc:ice", ["roomId": roomId, "candidate": candidate])
        print("📡 Sent ICE")
    }
    
    func onOffer(completion: @escaping ([String: Any]) -> Void) {
        socket.on("webrtc:offer") { data, _ in
            guard let dict = data[0] as? [String: Any],
                  let offer = dict["offer"] as? [String: Any] else { return }
            completion(offer)
        }
    }
    
    func onAnswer(completion: @escaping ([String: Any]) -> Void) {
        socket.on("webrtc:answer") { data, _ in
            guard let dict = data[0] as? [String: Any],
                  let answer = dict["answer"] as? [String: Any] else { return }
            completion(answer)
        }
    }
    
    func onICE(completion: @escaping ([String: Any]) -> Void) {
        socket.on("webrtc:ice") { data, _ in
            guard let dict = data[0] as? [String: Any],
                  let candidate = dict["candidate"] as? [String: Any] else { return }
            completion(candidate)
        }
    }
}
