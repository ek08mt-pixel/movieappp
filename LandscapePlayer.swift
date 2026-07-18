import SwiftUI
import AVKit

class LandscapeViewController: AVPlayerViewController {
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscapeRight
    }
    
    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return .landscapeRight
    }
}

struct LandscapePlayer: UIViewControllerRepresentable {
    let player: AVPlayer
    let pipController: Binding<AVPictureInPictureController?>
    let gravity: VideoGravityMode
    
    func makeUIViewController(context: Context) -> LandscapeViewController {
        let vc = LandscapeViewController()
        vc.player = player
        vc.showsPlaybackControls = false
        vc.videoGravity = gravity.avGravity
        vc.allowsPictureInPicturePlayback = true
        vc.canStartPictureInPictureAutomaticallyFromInline = true
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback, options: .allowAirPlay)
        try? AVAudioSession.sharedInstance().setActive(true)
        return vc
    }
    
    func updateUIViewController(_ ui: LandscapeViewController, context: Context) {
        ui.videoGravity = gravity.avGravity
        if pipController.wrappedValue == nil, let layer = ui.view.layer.sublayers?.first as? AVPlayerLayer {
            pipController.wrappedValue = AVPictureInPictureController(playerLayer: layer)
        }
    }
}