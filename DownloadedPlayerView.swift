import SwiftUI
import AVKit

struct DownloadedPlayerView: View {
    let url: URL
    let title: String
    @Environment(\.dismiss) var dismiss
    @State private var player: AVPlayer?
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            if let player = player {
                VideoPlayer(player: player)
                    .ignoresSafeArea()
                    .onAppear { player.play() }
                    .onDisappear { player.pause() }
            }
            VStack {
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.left").font(.system(size: 16, weight: .semibold)).foregroundColor(.white).padding(10).background(Circle().fill(.ultraThinMaterial.opacity(0.4)))
                    }
                    Spacer()
                    Text(title).font(.caption).foregroundColor(.white).lineLimit(1)
                    Spacer()
                    Circle().fill(.clear).frame(width: 36)
                }.padding(.horizontal, 16).padding(.top, 50)
                Spacer()
            }
        }
        .onAppear {
            playFromLocalM3U8()
        }
    }
    
    private func playFromLocalM3U8() {
        do {
            let content = try String(contentsOf: url, encoding: .utf8)
            let lines = content.components(separatedBy: .newlines)
            var streamPath: String?
            
            for line in lines {
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                if !trimmed.hasPrefix("#") && !trimmed.isEmpty {
                    streamPath = trimmed
                    break
                }
            }
            
            guard let path = streamPath else {
                print("No stream path found")
                return
            }
            
            // Dùng original URL từ DownloadedMovie để tạo base
            let originalURLString = UserDefaults.standard.string(forKey: "originalURL_\(url.lastPathComponent)") ?? ""
            
            if !originalURLString.isEmpty, let originalURL = URL(string: originalURLString) {
                var baseURL = originalURL.deletingLastPathComponent()
                let streamURL = baseURL.appendingPathComponent(path)
                print("✅ Stream URL: \(streamURL)")
                let asset = AVURLAsset(url: streamURL)
                player = AVPlayer(playerItem: AVPlayerItem(asset: asset))
            } else {
                // Fallback: tìm trong downloadedMovies
                if let movie = DownloadManager.shared.downloadedMovies.first(where: { $0.localURL == url.absoluteString }),
                   let origURL = URL(string: movie.originalURL) {
                    var baseURL = origURL.deletingLastPathComponent()
                    let streamURL = baseURL.appendingPathComponent(path)
                    let asset = AVURLAsset(url: streamURL)
                    player = AVPlayer(playerItem: AVPlayerItem(asset: asset))
                }
            }
        } catch {
            print("Error: \(error)")
        }
    }
}