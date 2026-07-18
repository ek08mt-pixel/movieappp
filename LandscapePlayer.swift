import SwiftUI
import AVKit

struct LandscapePlayer: UIViewControllerRepresentable {
    let player: AVPlayer
    let pipController: Binding<AVPictureInPictureController?>
    let gravity: VideoGravityMode
    
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let vc = AVPlayerViewController()
        vc.player = player
        vc.showsPlaybackControls = false
        vc.videoGravity = gravity.avGravity
        vc.allowsPictureInPicturePlayback = true
        vc.canStartPictureInPictureAutomaticallyFromInline = true
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback, options: .allowAirPlay)
        try? AVAudioSession.sharedInstance().setActive(true)
        return vc
    }
    
    func updateUIViewController(_ ui: AVPlayerViewController, context: Context) {
        ui.videoGravity = gravity.avGravity
        if pipController.wrappedValue == nil, let layer = ui.view.layer.sublayers?.first as? AVPlayerLayer {
            pipController.wrappedValue = AVPictureInPictureController(playerLayer: layer)
        }
    }
}

struct LandscapeModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .onAppear {
    if let ws = UIApplication.shared.connectedScenes.first as? UIWindowScene {
        ws.requestGeometryUpdate(.iOS(interfaceOrientations: .landscapeRight))
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
        if let ws = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            ws.requestGeometryUpdate(.iOS(interfaceOrientations: .landscapeRight))
        }
    }
}
            .onDisappear {
                if let ws = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                    ws.requestGeometryUpdate(.iOS(interfaceOrientations: .portrait))
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    if let ws = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                        ws.requestGeometryUpdate(.iOS(interfaceOrientations: .portrait))
                    }
                }
            }
    }
}