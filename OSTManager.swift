import SwiftUI

class OSTManager: ObservableObject {
    static let shared = OSTManager()
    @Published var isPlaying = false
    @Published var currentTrack: String = ""
    @Published var currentMovie: String = ""
}