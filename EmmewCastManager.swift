import Foundation
import AVKit

// MARK: - Emmew Cast Manager
final class EmmewCastManager: NSObject, ObservableObject {
    static let shared = EmmewCastManager()
    
    @Published var isConnected = false
    @Published var connectedDeviceName = ""
    @Published var isPlaying = false
    @Published var streamDuration: Double = 0
    @Published var currentTime: Double = 0
    
    private var player: AVPlayer?
    private var timeObserver: Any?
    
    private override init() {
        super.init()
    }
    
    // MARK: - AirPlay
    func showAirPlayPicker() -> AVRoutePickerView {
        let view = AVRoutePickerView(frame: CGRect(x: 0, y: 0, width: 44, height: 44))
        view.activeTintColor = .white
        view.tintColor = .white
        view.prioritizesVideoDevices = true
        return view
    }
    
    // MARK: - Cast Control
    func startCasting(with player: AVPlayer?, deviceName: String) {
        self.player = player
        self.connectedDeviceName = deviceName
        self.isConnected = true
        self.isPlaying = true
        
        if let player = player {
            player.allowsExternalPlayback = true
            player.usesExternalPlaybackWhileExternalScreenIsActive = true
        }
        
        startTimeObserver()
    }
    
    func stopCasting() {
        self.isConnected = false
        self.isPlaying = false
        self.connectedDeviceName = ""
        self.streamDuration = 0
        self.currentTime = 0
        stopTimeObserver()
    }
    
    func play() {
        player?.play()
        isPlaying = true
    }
    
    func pause() {
        player?.pause()
        isPlaying = false
    }
    
    func seek(to time: Double) {
        player?.seek(to: CMTime(seconds: time, preferredTimescale: 600))
        currentTime = time
    }
    
    func skipForward(_ seconds: Double = 10) {
        let newTime = min(currentTime + seconds, streamDuration)
        seek(to: newTime)
    }
    
    func skipBackward(_ seconds: Double = 10) {
        let newTime = max(currentTime - seconds, 0)
        seek(to: newTime)
    }
    
    // MARK: - Time Observer
    private func startTimeObserver() {
        guard let player = player else { return }
        
        timeObserver = player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.5, preferredTimescale: 600),
            queue: .main
        ) { [weak self] time in
            guard let self = self else { return }
            self.currentTime = time.seconds
            
            if let duration = player.currentItem?.duration, duration.isNumeric {
                self.streamDuration = duration.seconds
            }
        }
    }
    
    private func stopTimeObserver() {
        if let observer = timeObserver, let player = player {
            player.removeTimeObserver(observer)
        }
        timeObserver = nil
    }
    
    deinit {
        stopTimeObserver()
    }
}

// MARK: - Web Receiver Helper
extension EmmewCastManager {
    /// Tạo URL cho Web Receiver (dùng cho laptop, console, Android phone...)
    func webReceiverURL() -> URL? {
        // TODO: Thay bằng URL thật của web receiver app
        return URL(string: "https://emmew.app/receiver")
    }
    
    /// Kiểm tra thiết bị có hỗ trợ AirPlay không
    func isAirPlayAvailable() -> Bool {
        let routeDetector = AVRouteDetector()
        routeDetector.isRouteDetectionEnabled = true
        return routeDetector.multipleRoutesDetected
    }
}

// MARK: - AirPlay Picker Wrapper (SwiftUI)
import SwiftUI

struct AirPlayPicker: UIViewRepresentable {
    func makeUIView(context: Context) -> AVRoutePickerView {
        let view = AVRoutePickerView()
        view.activeTintColor = .white
        view.tintColor = .white.withAlphaComponent(0.8)
        view.prioritizesVideoDevices = true
        return view
    }
    
    func updateUIView(_ uiView: AVRoutePickerView, context: Context) {}
}