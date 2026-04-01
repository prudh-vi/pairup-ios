import SwiftUI
import WebRTC

struct CallView: View {
    @StateObject private var socket = SocketService.shared
    @StateObject private var webrtc = WebRTCService.shared
    @State private var showChat = false
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            // Remote video
            ZStack {
                if webrtc.remoteVideoTrack != nil {
                    RTCVideoViewRepresentable(videoTrack: webrtc.remoteVideoTrack)
                        .ignoresSafeArea()
                } else {
                    Color(white: 0.08).ignoresSafeArea()
                    VStack(spacing: 12) {
                        Image(systemName: "person.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.gray.opacity(0.3))
                        Text("Connecting...")
                            .foregroundColor(.gray)
                            .font(.caption)
                    }
                }
            }
            
            // Local video PIP
            VStack {
                HStack {
                    Spacer()
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(white: 0.15))
                            .frame(width: 100, height: 140)
                        
                        if webrtc.localVideoTrack != nil {
                            RTCVideoViewRepresentable(videoTrack: webrtc.localVideoTrack)
                                .frame(width: 100, height: 140)
                                .cornerRadius(12)
                        } else {
                            Image(systemName: "person.fill")
                                .font(.system(size: 30))
                                .foregroundColor(.gray.opacity(0.5))
                        }
                    }
                    .padding(.top, 60)
                    .padding(.trailing, 20)
                }
                Spacer()
            }
            
            // Controls
            VStack {
                Spacer()
                HStack(spacing: 25) {
                    
                    // End Call
                    Button(action: {
                        webrtc.cleanup()
                        socket.disconnect()
                        dismiss()
                    }) {
                        VStack(spacing: 8) {
                            Image(systemName: "phone.down.fill")
                                .font(.system(size: 22))
                                .foregroundColor(.white)
                                .frame(width: 60, height: 60)
                                .background(Color.red)
                                .clipShape(Circle())
                            Text("End")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    
                    // Skip
                    Button(action: {
                        webrtc.cleanup()
                        socket.skip()
                        socket.startChat()
                        dismiss()
                    }) {
                        VStack(spacing: 8) {
                            Image(systemName: "forward.fill")
                                .font(.system(size: 22))
                                .foregroundColor(.white)
                                .frame(width: 70, height: 70)
                                .background(Color.orange)
                                .clipShape(Circle())
                            Text("Skip")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    
                    // Chat
                    Button(action: { showChat = true }) {
                        VStack(spacing: 8) {
                            Image(systemName: "bubble.left.fill")
                                .font(.system(size: 22))
                                .foregroundColor(.white)
                                .frame(width: 60, height: 60)
                                .background(Color.white.opacity(0.15))
                                .clipShape(Circle())
                            Text("Chat")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(.bottom, 50)
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showChat) {
            ChatView()
        }
        .onChange(of: socket.partnerLeft) { left in
            if left {
                webrtc.cleanup()
                dismiss()
            }
        }
    }
}

// MARK: - RTCVideoView wrapper for SwiftUI
struct RTCVideoViewRepresentable: UIViewRepresentable {
    var videoTrack: RTCVideoTrack?
    
    func makeUIView(context: Context) -> RTCMTLVideoView {
        let view = RTCMTLVideoView()
        view.videoContentMode = .scaleAspectFill
        return view
    }
    
    func updateUIView(_ uiView: RTCMTLVideoView, context: Context) {
        if let track = videoTrack {
            track.add(uiView)
        }
    }
}
