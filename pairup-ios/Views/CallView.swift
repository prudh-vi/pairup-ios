//
//  CallView.swift
//  pairup-ios
//
//  Created by Prudhvii on 01/04/26.
//

import SwiftUI

struct CallView: View {
    @State private var isMuted = false
    @State private var isCameraOff = false
    @State private var isDisconnected = false
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            // Remote video (full screen)
            ZStack {
                Color(white: 0.1)
                    .ignoresSafeArea()
                
                Image(systemName: "person.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.gray.opacity(0.5))
            }
            
            // Local video (picture in picture)
            VStack {
                HStack {
                    Spacer()
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(white: 0.2))
                            .frame(width: 100, height: 140)
                        
                        Image(systemName: "person.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 60)
                    .padding(.trailing, 20)
                }
                Spacer()
            }
            
            // Controls at bottom
            VStack {
                Spacer()
                
                HStack(spacing: 30) {
                    
                    // Mute button
                    Button(action: {
                        isMuted.toggle()
                    }) {
                        VStack(spacing: 8) {
                            Image(systemName: isMuted ? "mic.slash.fill" : "mic.fill")
                                .font(.system(size: 22))
                                .foregroundColor(isMuted ? .red : .white)
                                .frame(width: 60, height: 60)
                                .background(Color.white.opacity(0.15))
                                .clipShape(Circle())
                            
                            Text(isMuted ? "Unmute" : "Mute")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    
                    // Skip button
                    Button(action: {
                        isDisconnected = true
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
                    
                    // Camera button
                    Button(action: {
                        isCameraOff.toggle()
                    }) {
                        VStack(spacing: 8) {
                            Image(systemName: isCameraOff ? "video.slash.fill" : "video.fill")
                                .font(.system(size: 22))
                                .foregroundColor(isCameraOff ? .red : .white)
                                .frame(width: 60, height: 60)
                                .background(Color.white.opacity(0.15))
                                .clipShape(Circle())
                            
                            Text(isCameraOff ? "Show" : "Hide")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(.bottom, 50)
            }
        }
        .navigationBarHidden(true)
        .alert("Call Ended", isPresented: $isDisconnected) {
            Button("Find New Match") { }
            Button("Go Home", role: .cancel) { }
        }
    }
}
