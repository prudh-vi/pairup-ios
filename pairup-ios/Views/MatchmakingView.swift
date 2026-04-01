import SwiftUI
import Combine

struct MatchmakingView: View {
    @StateObject private var socket = SocketService.shared
    @State private var dots = ""
    let timer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 40) {
                
                // Animated circle
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.1), lineWidth: 2)
                        .frame(width: 120, height: 120)
                    
                    Circle()
                        .trim(from: 0, to: 0.7)
                        .stroke(Color.white, lineWidth: 2)
                        .frame(width: 120, height: 120)
                        .rotationEffect(.degrees(Double(dots.count) * 45))
                        .animation(.linear(duration: 0.5), value: dots)
                    
                    Image(systemName: "person.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.white)
                }
                
                // Status text
                VStack(spacing: 8) {
                    Text("Finding someone\(dots)")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Text(socket.isConnected ? "Connected to server..." : "Connecting...")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                // Cancel button
                Button(action: {
                    socket.disconnect()
                }) {
                    Text("Cancel")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .padding(.horizontal, 30)
                        .padding(.vertical, 12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.gray.opacity(0.4), lineWidth: 1)
                        )
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            // Connect and start finding match!
            socket.connect()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                socket.startChat()
            }
        }
        .onReceive(timer) { _ in
            if dots.count >= 3 {
                dots = ""
            } else {
                dots += "."
            }
        }
        .navigationDestination(isPresented: $socket.isMatched) {
            CallView()
        }
    }
}
