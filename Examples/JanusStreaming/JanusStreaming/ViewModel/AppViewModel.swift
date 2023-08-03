import Janus
import SwiftUI
import WebRTC

class AppViewModel: ObservableObject {
    @Published var sessionId: Int? {
        didSet {
            startKeepAliveTimer()
        }
    }

    @Published var handleId: Int?
    @Published var streams: [StreamInfo] = []
    @Published var selectedStream: StreamInfo?
    @Published var started = false
    @Published var remoteVideoTrack: RTCVideoTrack?

    let session = JanusAPI(baseUrl: URL(string: "https://janus.conf.meetecho.com/janus")!)
    let webRTCClient = WebRTCClient()

    private var timer: DispatchSourceTimer?
    
//    private lazy var timer: DispatchSourceTimer = {
//        let timer = DispatchSource.makeTimerSource()
//        timer.schedule(deadline: .now() + .seconds(50), repeating: .seconds(50))
//        timer.setEventHandler { [weak self] in
//            guard let self = self else { return }
//            self.session.keepAlive(sessionId: self.sessionId!)
//        }
//        return timer
//    }()

    init() {
        webRTCClient.delegate = self
    }

    func setup() {
        session.createSession { [unowned self] sessionId in
            DispatchQueue.main.async {
                self.sessionId = sessionId
            }
            self.session.attachPlugin(sessionId: sessionId, plugin: .streaming) { [unowned self] handleId in
                DispatchQueue.main.async {
                    self.handleId = handleId
                }
                self.session.list(sessionId: sessionId, handleId: handleId) { [unowned self] streams in
                    DispatchQueue.main.async {
                        self.streams = streams
                    }
                }
            }
        }
    }

    private func startKeepAliveTimer() {
        self.timer?.setEventHandler {}
        self.timer?.cancel()
        self.timer = nil

        let timer = DispatchSource.makeTimerSource()
        timer.schedule(deadline: .now() + .seconds(50), repeating: .seconds(50))
        timer.setEventHandler { [weak self] in
            guard let self = self else { return }
            guard let sessionId = self.sessionId else { return }
            self.session.keepAlive(sessionId: sessionId)
        }
        timer.resume()

        self.timer = timer
    }

    func watch() {
        guard let sessionId = sessionId else { return }
        guard let handleId = handleId else { return }
        guard let streamId = selectedStream?.id else { return }
        session.watch(sessionId: sessionId, handleId: handleId, streamId: streamId) { [unowned self] remoteSdp in
            self.webRTCClient.answer(remoteSdp: remoteSdp) { [unowned self] localSdp in
                self.session.start(sessionId: sessionId, handleId: handleId, sdp: localSdp) { [unowned self] in
                    DispatchQueue.main.async {
                        self.started = true
                    }
                }
            }
        }
    }

    func endWatch() {
        guard started else { return }

        selectedStream = nil
        started = false
    }
}

extension AppViewModel: WebRTCClientDelegate {
    func webRTCClient(_ client: WebRTCClient, didDiscoverLocalCandidate candidate: RTCIceCandidate) {
        guard let sessionId = sessionId else { return }
        guard let handleId = handleId else { return }
        session.trickle(sessionId: sessionId,
                        handleId: handleId,
                        candidate: candidate.sdp,
                        sdpMLineIndex: candidate.sdpMLineIndex,
                        sdpMid: candidate.sdpMid)
    }

    func webRTCClient(_ client: WebRTCClient, didSetRemoteVideoTrack remoteVideoTrack: RTCVideoTrack) {
        DispatchQueue.main.async {
            self.remoteVideoTrack = remoteVideoTrack
        }
    }
}
