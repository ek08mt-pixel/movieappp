import SwiftUI
import AVKit

class OSTManager: ObservableObject {
    static let shared = OSTManager()
    @Published var isPlaying = false
    @Published var currentTrack: String = ""
    @Published var currentMovie: String = ""
    @Published var currentPoster: String? = nil
    @Published var showOSTView = false
    @Published var miniMode: MiniMode = .normal
    @Published var audioPlayer: AVPlayer?
    
    enum MiniMode: Int, CaseIterable {
        case normal = 0
        case bubble = 1
        case dot = 2
    }
    
    var togglePlayback: (() -> Void)?
    var stopPlayback: (() -> Void)?
}