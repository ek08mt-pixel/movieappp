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
            
            let lines = content.components(separatedBy: .newlines)
            var streamPath: String?
            
            for line in lines {
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                if !trimmed.hasPrefix("#") && !trimmed.isEmpty && !trimmed.hasPrefix("http") {
                    streamPath = trimmed
                    break
                }
                if trimmed.hasPrefix("http") {
                    streamPath = trimmed
                    break
                }
            }
            
            if let path = streamPath {
                let streamURL: URL
                if path.hasPrefix("http") {
                    streamURL = URL(string: path)!
                } else {
                    var baseURL = url.deletingLastPathComponent()
                    streamURL = baseURL.appendingPathComponent(path)
                }
                
                alertMessage += "\n\nStream URL: \(streamURL.absoluteString)"
                showAlert = true
                
                let asset = AVURLAsset(url: streamURL)
                player = AVPlayer(playerItem: AVPlayerItem(asset: asset))
            } else {
                alertMessage += "\n\nNo stream path found"
                showAlert = true
            }
        } catch {
            alertMessage = "Error: \(error.localizedDescription)"
            showAlert = true
        }
    }
}