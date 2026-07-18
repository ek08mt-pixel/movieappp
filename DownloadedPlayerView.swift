import SwiftUI
import AVKit

struct DownloadedPlayerView: View {
    let url: URL
    let title: String
    @Environment(\.dismiss) var dismiss
    @State private var player: AVPlayer?
    @State private var isLoading = true
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            if isLoading {
                ProgressView("Đang tải...").foregroundColor(.white)
            } else if let player = player {
                VideoPlayer(player: player)
                    .ignoresSafeArea()
                    .onAppear { player.play() }
                    .onDisappear {
                        player.pause()
                        LocalHTTPServer.shared.stop()
                    }
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
            startServerAndPlay()
        }
    }
    
    private func startServerAndPlay() {
        DispatchQueue.global().async {
            let folderURL = url.deletingLastPathComponent()
            let started = LocalHTTPServer.shared.start(baseDirectory: folderURL, port: 8080)
            
            DispatchQueue.main.async {
                if started, let serverURL = LocalHTTPServer.shared.serverURL {
                    let playlistURL = serverURL.appendingPathComponent("sub.m3u8")
                    print("🎬 Playing: \(playlistURL.absoluteString)")
                    let asset = AVURLAsset(url: playlistURL)
                    player = AVPlayer(playerItem: AVPlayerItem(asset: asset))
                }
                isLoading = false
            }
        }
    }
}