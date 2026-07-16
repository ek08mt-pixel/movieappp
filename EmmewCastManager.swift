import Foundation
import GoogleCast

final class EmmewCastManager: NSObject, ObservableObject {
    static let shared = EmmewCastManager()
    
    @Published var devices: [CastDevice] = []
    @Published var isScanning = false
    @Published var connectedDevice: CastDevice?
    @Published var isConnected = false
    @Published var isPlaying = false
    @Published var streamDuration: Double = 0
    
    private var sessionManager: GCKSessionManager
    private var discoveryManager: GCKDiscoveryManager
    private var castSession: GCKCastSession?
    private var remoteMediaClient: GCKRemoteMediaClient?
    private var mediaInfo: GCKMediaInformation?
    
    override init() {
        // Khởi tạo Cast Context
        let options = GCKCastOptions(receiverApplicationID: kDefaultCastReceiverApplicationID)
        GCKCastContext.setSharedInstanceWith(options)
        
        sessionManager = GCKCastContext.sharedInstance().sessionManager
        discoveryManager = GCKCastContext.sharedInstance().discoveryManager
        
        super.init()
        
        // Cấu hình logging
        GCKLogger.sharedInstance().delegate = self
        
        // Listener
        sessionManager.add(self)
        discoveryManager.add(self)
        discoveryManager.passiveScan = true
        discoveryManager.startDiscovery()
    }
    
    func startScanning() {
        isScanning = true
        devices.removeAll()
        discoveryManager.startDiscovery()
    }
    
    func stopScanning() {
        isScanning = false
        discoveryManager.stopDiscovery()
    }
    
    func connect(to device: GCKDevice) {
        sessionManager.startSession(with: device)
    }
    
    func disconnect() {
        sessionManager.endSession()
    }
    
    func castVideo(url: URL, title: String, imageURL: String?, duration: TimeInterval = 0) {
        guard let remoteMediaClient = sessionManager.currentCastSession?.remoteMediaClient else { return }
        
        let metadata = GCKMediaMetadata(metadataType: .movie)
        metadata.setString(title, forKey: kGCKMetadataKeyTitle)
        if let imageURL = imageURL {
            metadata.addImage(GCKImage(url: URL(string: imageURL)!, width: 480, height: 720))
        }
        
        let mediaInfoBuilder = GCKMediaInformationBuilder(contentURL: url)
        mediaInfoBuilder.streamType = .buffered
        mediaInfoBuilder.contentType = "video/mp4"
        mediaInfoBuilder.metadata = metadata
        if duration > 0 {
            mediaInfoBuilder.streamDuration = duration
        }
        
        mediaInfo = mediaInfoBuilder.build()
        
        let options = GCKMediaLoadOptions()
        options.autoplay = true
        options.playPosition = 0
        
        remoteMediaClient.loadMedia(mediaInfo!, with: options)
        
        DispatchQueue.main.async {
            self.isConnected = true
            self.isPlaying = true
            self.streamDuration = duration
        }
    }
    
    func play() {
        remoteMediaClient?.play()
        isPlaying = true
    }
    
    func pause() {
        remoteMediaClient?.pause()
        isPlaying = false
    }
    
    func seek(to time: TimeInterval) {
        let options = GCKMediaSeekOptions()
        options.interval = time
        options.resumeState = .play
        remoteMediaClient?.seek(with: options)
    }
    
    func stop() {
        remoteMediaClient?.stop()
        isPlaying = false
    }
    
    func setVolume(_ volume: Float) {
        remoteMediaClient?.setStreamVolume(volume)
    }
    
    deinit {
        discoveryManager.remove(self)
        sessionManager.remove(self)
    }
}

// MARK: - GCKDiscoveryManagerListener
extension EmmewCastManager: GCKDiscoveryManagerListener {
    func didStartDiscoveryForDeviceCategory(_ deviceCategory: String) {
        isScanning = true
    }
    
    func didUpdateDeviceList() {
        let gckDevices = discoveryManager.devices()
        DispatchQueue.main.async {
            self.devices = gckDevices.map { gckDevice in
                CastDevice(
                    id: UUID(),
                    name: gckDevice.friendlyName ?? "Unknown",
                    icon: self.iconForDevice(gckDevice),
                    type: self.typeForDevice(gckDevice),
                    isConnected: gckDevice.isConnected,
                    signalStrength: gckDevice.signalStrength ?? 3
                )
            }
        }
    }
    
    func didInsert(_ device: GCKDevice, at index: UInt) {
        DispatchQueue.main.async {
            self.devices.insert(
                CastDevice(
                    id: UUID(),
                    name: device.friendlyName ?? "Unknown",
                    icon: self.iconForDevice(device),
                    type: self.typeForDevice(device),
                    isConnected: device.isConnected,
                    signalStrength: device.signalStrength ?? 3
                ),
                at: Int(index)
            )
        }
    }
    
    func iconForDevice(_ device: GCKDevice) -> String {
        let model = device.modelName?.lowercased() ?? ""
        let name = (device.friendlyName ?? "").lowercased()
        
        if model.contains("chromecast") || name.contains("chromecast") {
            return "rectangle.connected.to.line.below"
        } else if model.contains("nexus") || model.contains("shield") {
            return "tv.and.hifispeaker.fill"
        } else if name.contains("apple tv") {
            return "appletv.fill"
        } else if name.contains("playstation") || name.contains("xbox") {
            return "gamecontroller.fill"
        } else if model.contains("tv") || name.contains("tv") {
            return "tv.fill"
        } else if name.contains("macbook") || name.contains("laptop") {
            return "laptopcomputer"
        } else {
            return "airplayvideo"
        }
    }
    
    func typeForDevice(_ device: GCKDevice) -> CastDeviceType {
        let model = device.modelName?.lowercased() ?? ""
        let name = (device.friendlyName ?? "").lowercased()
        
        if name.contains("apple tv") {
            return .airplay
        } else if model.contains("chromecast") || name.contains("chromecast") {
            return .chromecast
        } else {
            return .smartTV
        }
    }
}

// MARK: - GCKSessionManagerListener
extension EmmewCastManager: GCKSessionManagerListener {
    func sessionManager(_ sessionManager: GCKSessionManager, didStart session: GCKSession) {
        castSession = session as? GCKCastSession
        remoteMediaClient = castSession?.remoteMediaClient
        DispatchQueue.main.async {
            self.isConnected = true
            self.connectedDevice = CastDevice(
                id: UUID(),
                name: session.device.friendlyName ?? "Unknown",
                icon: self.iconForDevice(session.device),
                type: self.typeForDevice(session.device),
                isConnected: true,
                signalStrength: 4
            )
        }
    }
    
    func sessionManager(_ sessionManager: GCKSessionManager, didEnd session: GCKSession, withError error: Error?) {
        DispatchQueue.main.async {
            self.isConnected = false
            self.isPlaying = false
            self.connectedDevice = nil
        }
    }
    
    func sessionManager(_ sessionManager: GCKSessionManager, didFailToStart session: GCKSession, withError error: Error) {
        print("Cast: Failed to start session - \(error.localizedDescription)")
    }
}

// MARK: - GCKLoggerDelegate
extension EmmewCastManager: GCKLoggerDelegate {
    func logMessage(_ message: String, at level: GCKLoggerLevel, fromFunction function: String, location: String) {
        print("Cast Log [\(level)]: \(message)")
    }
}