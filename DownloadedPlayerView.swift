import SwiftUI
import AVKit

class LocalAssetLoader: NSObject, AVAssetResourceLoaderDelegate {
    let folderURL: URL
    var masterContent: String = ""
    var subContent: String = ""
    
    init(folderURL: URL) {
        self.folderURL = folderURL
    }
    
    func resourceLoader(_ resourceLoader: AVAssetResourceLoader, shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest) -> Bool {
        guard let url = loadingRequest.request.url else { return false }
        
        let fileName = url.lastPathComponent
        
        if fileName == "master.m3u8" {
            // Đọc master.m3u8 từ folder
            let masterURL = folderURL.appendingPathComponent("master.m3u8")
            if let content = try? String(contentsOf: masterURL, encoding: .utf8) {
                masterContent = content
                var lines = content.components(separatedBy: .newlines)
                var fixedLines: [String] = []
                
                for line in lines {
                    let trimmed = line.trimmingCharacters(in: .whitespaces)
                    if !trimmed.hasPrefix("#") && !trimmed.isEmpty && trimmed.hasSuffix(".m3u8") {
                        fixedLines.append("local-hls://playlist/sub.m3u8")
                    } else {
                        fixedLines.append(line)
                    }
                }
                
                let data = fixedLines.joined(separator: "\n").data(using: .utf8)!
                loadingRequest.dataRequest?.respond(with: data)
                loadingRequest.finishLoading()
                return true
            }
        } else if fileName == "sub.m3u8" {
            let subURL = folderURL.appendingPathComponent("sub.m3u8")
            if let content = try? String(contentsOf: subURL, encoding: .utf8) {
                var lines = content.components(separatedBy: .newlines)
                var fixedLines: [String] = []
                
                for line in lines {
                    let trimmed = line.trimmingCharacters(in: .whitespaces)
                    if !trimmed.hasPrefix("#") && !trimmed.isEmpty && trimmed.hasSuffix(".ts") {
                        let tsURL = folderURL.appendingPathComponent(trimmed)
                        fixedLines.append(tsURL.absoluteString)
                    } else {
                        fixedLines.append(line)
                    }
                }
                
                let data = fixedLines.joined(separator: "\n").data(using: .utf8)!
                loadingRequest.dataRequest?.respond(with: data)
                loadingRequest.finishLoading()
                return true
            }
        }
        
        // Fallback: thử đọc file trực tiếp từ folder
        let fileURL = folderURL.appendingPathComponent(fileName)
        if let data = try? Data(contentsOf: fileURL) {
            loadingRequest.dataRequest?.respond(with: data)
            loadingRequest.finishLoading()
            return true
        }
        
        return false
    }
}

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
            playLocalVideo()
        }
    }
    
    private func playLocalVideo() {
        let folderURL = url.deletingLastPathComponent()
        let customURL = URL(string: "local-hls://playlist/master.m3u8")!
        let asset = AVURLAsset(url: customURL)
        let loader = LocalAssetLoader(folderURL: folderURL)
        asset.resourceLoader.setDelegate(loader, queue: .main)
        player = AVPlayer(playerItem: AVPlayerItem(asset: asset))
    }
}