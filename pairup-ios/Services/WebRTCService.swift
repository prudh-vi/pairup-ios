//
//  WebRTCService.swift
//  pairup-ios
//

import Foundation
import WebRTC
import Combine

class WebRTCService: NSObject, ObservableObject {
    static let shared = WebRTCService()
    
    private var peerConnection: RTCPeerConnection?
    private var factory: RTCPeerConnectionFactory!
    private var videoCapturer: RTCCameraVideoCapturer?  // ← RETAINED as property now!
    
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
        config.sdpSemantics = .unifiedPlan  // ← Important for modern WebRTC!
        
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
        let audioSource = factory.audioSource(with: RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil))
        let audioTrack = factory.audioTrack(with: audioSource, trackId: "audio0")
        
        // Video
        let videoSource = factory.videoSource()
        videoCapturer = RTCCameraVideoCapturer(delegate: videoSource)  // ← saved to property!
        
        // Start front camera
        if let frontCamera = RTCCameraVideoCapturer.captureDevices()
            .first(where: { $0.position == .front }) {
            
            // Pick best format
            let formats = RTCCameraVideoCapturer.supportedFormats(for: frontCamera)
            let format = formats.first(where: {
                let dim = CMVideoFormatDescriptionGetDimensions($0.formatDescription)
                return dim.width == 640
            }) ?? formats.last!
            
            // Pick best fps
            let fps = format.videoSupportedFrameRateRanges
                .compactMap { $0.maxFrameRate }
                .filter { $0 <= 30 }
                .max() ?? 30
            
            videoCapturer?.startCapture(
                with: frontCamera,
                format: format,
                fps: Int(fps)
            ) { error in
                if let error = error {
                    print("❌ Camera error: \(error.localizedDescription)")
                } else {
                    print("📷 Camera started!")
                }
            }
        }
        
        let videoTrack = factory.videoTrack(with: videoSource, trackId: "video0")
        
        DispatchQueue.main.async {
            self.localVideoTrack = videoTrack
            print("🎥 Local video track ready!")
        }
        
        // Add tracks
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
            guard let sdp = sdp else {
                print("❌ Offer error: \(error?.localizedDescription ?? "unknown")")
                return
            }
            self.peerConnection?.setLocalDescription(sdp) { error in
                if error == nil {
                    let offer = ["type": "offer", "sdp": sdp.sdp]
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
            guard let sdp = sdp else {
                print("❌ Answer error: \(error?.localizedDescription ?? "unknown")")
                return
            }
            self.peerConnection?.setLocalDescription(sdp) { error in
                if error == nil {
                    let answer = ["type": "answer", "sdp": sdp.sdp]
                    completion(answer)
                    print("📤 Answer created!")
                }
            }
        }
    }
    
    func setRemoteDescription(_ sdpDict: [String: Any]) {
        guard let sdpString = sdpDict["sdp"] as? String,
              let typeString = sdpDict["type"] as? String else {
            print("❌ Invalid SDP dict")
            return
        }
        
        let type: RTCSdpType = typeString == "offer" ? .offer : .answer
        let sdp = RTCSessionDescription(type: type, sdp: sdpString)
        
        peerConnection?.setRemoteDescription(sdp) { error in
            if let error = error {
                print("❌ Remote desc error: \(error.localizedDescription)")
            } else {
                print("✅ Remote description set!")
            }
        }
    }
    
    func addICECandidate(_ candidateDict: [String: Any]) {
        guard let sdp = candidateDict["candidate"] as? String,
              let sdpMid = candidateDict["sdpMid"] as? String,
              let sdpMLineIndex = candidateDict["sdpMLineIndex"] as? Int32 else { return }
        
        let candidate = RTCIceCandidate(sdp: sdp, sdpMLineIndex: sdpMLineIndex, sdpMid: sdpMid)
        peerConnection?.add(candidate) { error in
            if let error = error {
                print("❌ ICE error: \(error.localizedDescription)")
            } else {
                print("✅ ICE candidate added!")
            }
        }
    }
    
    // MARK: - Cleanup
    func cleanup() {
        videoCapturer?.stopCapture()
        videoCapturer = nil
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
            print("🧊 ICE state: \(state.rawValue)")
        }
    }
    
    // Modern method for receiving remote tracks
    func peerConnection(_ peerConnection: RTCPeerConnection, didAdd rtpReceiver: RTCRtpReceiver, streams: [RTCMediaStream]) {
        if let videoTrack = rtpReceiver.track as? RTCVideoTrack {
            DispatchQueue.main.async {
                self.remoteVideoTrack = videoTrack
                print("🎥 Remote video track received!")
            }
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
    
    // Required stubs
    func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream) {}
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove stream: RTCMediaStream) {}
    func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {}
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceGatheringState) {}
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove candidates: [RTCIceCandidate]) {}
    func peerConnection(_ peerConnection: RTCPeerConnection, didOpen dataChannel: RTCDataChannel) {}
}
