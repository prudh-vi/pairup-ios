//
//  WebRTCService.swift.swift
//  pairup-ios
//
//  Created by Prudhvii on 01/04/26.
//

import Foundation
import WebRTC
import Combine

class WebRTCService: NSObject, ObservableObject {
    static let shared = WebRTCService()
    
    private var peerConnection: RTCPeerConnection?
    private var localStream: RTCMediaStream?
    private var factory: RTCPeerConnectionFactory!
    
    @Published var isConnected = false
    @Published var localVideoTrack: RTCVideoTrack?
    @Published var remoteVideoTrack: RTCVideoTrack?
    
    private let iceServers = [
        RTCIceServer(urlStrings: ["stun:stun.l.google.com:19302"]),
        RTCIceServer(
            urlStrings: [
                "turn:34.126.207.137:3478",
                "turn:34.126.207.137:3478?transport=tcp"
            ],
            username: "pairup_333dfc31",
            credential: "62d0f87b0181fa1e7b70289ed0587d3a"
        )
    ]
    
    override init() {
        RTCInitializeSSL()
        let encoderFactory = RTCDefaultVideoEncoderFactory()
        let decoderFactory = RTCDefaultVideoDecoderFactory()
        factory = RTCPeerConnectionFactory(
            encoderFactory: encoderFactory,
            decoderFactory: decoderFactory
        )
        super.init()
    }
    
    // MARK: - Setup Peer Connection
    func setupPeerConnection() {
        let config = RTCConfiguration()
        config.iceServers = iceServers
        config.bundlePolicy = .maxBundle
        config.rtcpMuxPolicy = .require
        config.iceCandidatePoolSize = 10
        
        let constraints = RTCMediaConstraints(
            mandatoryConstraints: nil,
            optionalConstraints: nil
        )
        
        peerConnection = factory.peerConnection(
            with: config,
            constraints: constraints,
            delegate: self
        )
        
        setupLocalMedia()
        print("✅ Peer connection created!")
    }
    
    // MARK: - Local Media
    private func setupLocalMedia() {
        let streamId = "pairup_stream"
        
        // Audio
        let audioConstraints = RTCMediaConstraints(
            mandatoryConstraints: nil,
            optionalConstraints: nil
        )
        let audioSource = factory.audioSource(with: audioConstraints)
        let audioTrack = factory.audioTrack(with: audioSource, trackId: "audio0")
        
        // Video
        let videoSource = factory.videoSource()
        let videoCapturer = RTCCameraVideoCapturer(delegate: videoSource)
        
        // Start front camera
        if let frontCamera = RTCCameraVideoCapturer.captureDevices()
            .first(where: { $0.position == .front }),
           let format = RTCCameraVideoCapturer.supportedFormats(for: frontCamera).last {
            videoCapturer.startCapture(
                with: frontCamera,
                format: format,
                fps: 30
            )
        }
        
        let videoTrack = factory.videoTrack(with: videoSource, trackId: "video0")
        
        DispatchQueue.main.async {
            self.localVideoTrack = videoTrack
        }
        
        // Add tracks to peer connection
        peerConnection?.add(audioTrack, streamIds: [streamId])
        peerConnection?.add(videoTrack, streamIds: [streamId])
        
        print("✅ Local media setup complete!")
    }
    
    // MARK: - Offer/Answer
    func createOffer(completion: @escaping ([String: Any]) -> Void) {
        let constraints = RTCMediaConstraints(
            mandatoryConstraints: [
                "OfferToReceiveVideo": "true",
                "OfferToReceiveAudio": "true"
            ],
            optionalConstraints: nil
        )
        
        peerConnection?.offer(for: constraints) { sdp, error in
            guard let sdp = sdp else { return }
            self.peerConnection?.setLocalDescription(sdp) { error in
                if error == nil {
                    let offer = ["type": sdp.type.rawValue, "sdp": sdp.sdp]
                    completion(offer)
                    print("📤 Offer created!")
                }
            }
        }
    }
    
    func createAnswer(completion: @escaping ([String: Any]) -> Void) {
        let constraints = RTCMediaConstraints(
            mandatoryConstraints: [
                "OfferToReceiveVideo": "true",
                "OfferToReceiveAudio": "true"
            ],
            optionalConstraints: nil
        )
        
        peerConnection?.answer(for: constraints) { sdp, error in
            guard let sdp = sdp else { return }
            self.peerConnection?.setLocalDescription(sdp) { error in
                if error == nil {
                    let answer = ["type": sdp.type.rawValue, "sdp": sdp.sdp]
                    completion(answer)
                    print("📤 Answer created!")
                }
            }
        }
    }
    
    func setRemoteDescription(_ sdpDict: [String: Any]) {
        guard let sdpString = sdpDict["sdp"] as? String,
              let typeString = sdpDict["type"] as? String else { return }
        
        let type: RTCSdpType = typeString == "offer" ? .offer : .answer
        let sdp = RTCSessionDescription(type: type, sdp: sdpString)
        
        peerConnection?.setRemoteDescription(sdp) { error in
            if error == nil {
                print("✅ Remote description set!")
            }
        }
    }
    
    func addICECandidate(_ candidateDict: [String: Any]) {
        guard let sdp = candidateDict["candidate"] as? String,
              let sdpMid = candidateDict["sdpMid"] as? String,
              let sdpMLineIndex = candidateDict["sdpMLineIndex"] as? Int32 else { return }
        
        let candidate = RTCIceCandidate(
            sdp: sdp,
            sdpMLineIndex: sdpMLineIndex,
            sdpMid: sdpMid
        )
        peerConnection?.add(candidate) { error in
            if let error {
                print("❌ Failed to add ICE candidate: \(error.localizedDescription)")
                return
            }
            print("✅ ICE candidate added!")
        }
    }
    
    // MARK: - Cleanup
    func cleanup() {
        localVideoTrack = nil
        remoteVideoTrack = nil
        peerConnection?.close()
        peerConnection = nil
        isConnected = false
        print("🧹 WebRTC cleaned up!")
    }
}

// MARK: - RTCPeerConnectionDelegate
extension WebRTCService: RTCPeerConnectionDelegate {
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange state: RTCIceConnectionState) {
        DispatchQueue.main.async {
            self.isConnected = state == .connected || state == .completed
            print("🧊 ICE: \(state.rawValue)")
        }
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream) {
        DispatchQueue.main.async {
            self.remoteVideoTrack = stream.videoTracks.first
            print("🎥 Remote stream received!")
        }
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {
        let candidateDict: [String: Any] = [
            "candidate": candidate.sdp,
            "sdpMid": candidate.sdpMid ?? "",
            "sdpMLineIndex": candidate.sdpMLineIndex
        ]
        SocketService.shared.sendICE(candidate: candidateDict)
        print("📡 ICE candidate sent!")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange stateChanged: RTCSignalingState) {
        print("📶 Signaling: \(stateChanged.rawValue)")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove stream: RTCMediaStream) {}
    func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {}
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceGatheringState) {}
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove candidates: [RTCIceCandidate]) {}
    func peerConnection(_ peerConnection: RTCPeerConnection, didOpen dataChannel: RTCDataChannel) {}
}
