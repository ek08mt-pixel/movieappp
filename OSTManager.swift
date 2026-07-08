import SwiftUI
import AVKit

class OSTManager: ObservableObject {
    static let shared = OSTManager()
    @Published var isPlaying = false
    @Published var currentTrack: String = ""
    @Published var currentMovie: String = ""
    @Published var currentPoster: String? = nil
    @Published var audioPlayer: AVPlayer?
    
    var togglePlayback: (() -> Void)?
    var stopPlayback: (() -> Void)?
}