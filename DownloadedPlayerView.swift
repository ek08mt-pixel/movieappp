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
            playLocalVideo()
        }
        .alert("Debug", isPresented: $showAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
    }
    
    private func playLocalVideo() {
    let folderURL = url.deletingLastPathComponent()
    let fileManager = FileManager.default
    
    do {
        // Đọc master.m3u8
        let content = try String(contentsOf: url, encoding: .utf8)
        let lines = content.components(separatedBy: .newlines)
        var fixedLines: [String] = []
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if !trimmed.hasPrefix("#") && !trimmed.isEmpty && trimmed.hasSuffix(".m3u8") {
                let subURL = folderURL.appendingPathComponent(trimmed)
                
                // Đọc và sửa sub.m3u8
                if let subContent = try? String(contentsOf: subURL, encoding: .utf8) {
                    var subLines = subContent.components(separatedBy: .newlines)
                    var fixedSubLines: [String] = []
                    
                    for subLine in subLines {
                        let subTrimmed = subLine.trimmingCharacters(in: .whitespaces)
                        if !subTrimmed.hasPrefix("#") && !subTrimmed.isEmpty && subTrimmed.hasSuffix(".ts") {
                            let tsURL = folderURL.appendingPathComponent(subTrimmed)
                            fixedSubLines.append(tsURL.path)
                        } else {
                            fixedSubLines.append(subLine)
                        }
                    }
                    
                    let fixedSubContent = fixedSubLines.joined(separator: "\n")
                    let fixedSubURL = folderURL.appendingPathComponent("fixed_sub.m3u8")
                    try fixedSubContent.write(to: fixedSubURL, atomically: true, encoding: .utf8)
                    
                    fixedLines.append(fixedSubURL.path)
                }
            } else {
                fixedLines.append(line)
            }
        }
        
        let fixedContent = fixedLines.joined(separator: "\n")
        let fixedURL = folderURL.appendingPathComponent("fixed_master.m3u8")
        try fixedContent.write(to: fixedURL, atomically: true, encoding: .utf8)
        
        print("✅ Playing: \(fixedURL.path)")
        let asset = AVURLAsset(url: fixedURL)
        player = AVPlayer(playerItem: AVPlayerItem(asset: asset))
        
    } catch {
        print("❌ Error: \(error)")
    }
}

extension URL {
    var fileSizeString: String {
        guard let attr = try? FileManager.default.attributesOfItem(atPath: path),
              let size = attr[.size] as? Int64 else { return "?" }
        return ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
}