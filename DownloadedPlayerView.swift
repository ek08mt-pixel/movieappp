import SwiftUI
import AVKit

struct DownloadedPlayerView: View {
    let url: URL
    let title: String
    @Environment(\.dismiss) var dismiss
    @State private var player: AVPlayer?
    @State private var showAlert = false
    @State private var alertMessage = ""
    
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
            playLocalM3U8()
        }
        .alert("Debug", isPresented: $showAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
    }
    
    private func playLocalM3U8() {
        do {
            let content = try String(contentsOf: url, encoding: .utf8)
            alertMessage = "File size: \(content.count) bytes\n\nContent:\n\(String(content.prefix(1000)))"
            showAlert = true
            
            let lines = content.components(separatedBy: .newlines)
            var streamURL: URL?
            
            for line in lines {
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                if trimmed.hasPrefix("http") && trimmed.hasSuffix(".m3u8") {
                    streamURL = URL(string: trimmed)
                    break
                }
                if trimmed.hasPrefix("http") {
                    streamURL = URL(string: trimmed)
                    break
                }
            }
            
            if let streamURL = streamURL {
                let asset = AVURLAsset(url: streamURL)
                player = AVPlayer(playerItem: AVPlayerItem(asset: asset))
            } else {
                let asset = AVURLAsset(url: url)
                player = AVPlayer(playerItem: AVPlayerItem(asset: asset))
            }
        } catch {
            alertMessage = "Error: \(error.localizedDescription)"
            showAlert = true
        }
    }
}