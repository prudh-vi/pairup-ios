import SwiftUI

struct ChatView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var socket = SocketService.shared
    @State private var message = ""
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                
                // Header
                HStack {
                    Text("Chat")
                        .font(.headline)
                        .foregroundColor(.white)
                    Spacer()
                    Button("Done") { dismiss() }
                        .foregroundColor(.gray)
                }
                .padding()
                
                Divider()
                    .background(Color.gray.opacity(0.3))
                
                // Messages
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(socket.messages) { msg in
                                HStack {
                                    if msg.isMe { Spacer() }
                                    
                                    Text(msg.text)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 10)
                                        .background(
                                            msg.isMe ?
                                            Color.white :
                                            Color.white.opacity(0.1)
                                        )
                                        .foregroundColor(
                                            msg.isMe ? .black : .white
                                        )
                                        .cornerRadius(18)
                                        .frame(maxWidth: 250, alignment: msg.isMe ? .trailing : .leading)
                                    
                                    if !msg.isMe { Spacer() }
                                }
                                .id(msg.id)
                            }
                        }
                        .padding()
                    }
                    .onChange(of: socket.messages.count) { _ in
                        if let last = socket.messages.last {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
                
                Divider()
                    .background(Color.gray.opacity(0.3))
                
                // Input
                HStack(spacing: 12) {
                    TextField("Message...", text: $message)
                        .padding(12)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(20)
                        .foregroundColor(.white)
                    
                    Button(action: sendMessage) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(message.isEmpty ? .gray : .white)
                    }
                    .disabled(message.isEmpty)
                }
                .padding()
            }
        }
    }
    
    private func sendMessage() {
        guard !message.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        socket.sendMessage(message)
        message = ""
    }
}
