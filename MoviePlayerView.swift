import SwiftUI
import AVKit

struct MoviePlayerView: View {
    let movieId: Int
    let movieTitle: String
    @Environment(\.dismiss) var dismiss
    @State private var streamURL: URL?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var player: AVPlayer?
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28)).foregroundColor(.white)
                    }
                    Spacer()
                    Text(movieTitle).font(.headline).foregroundColor(.white).lineLimit(1)
                    Spacer()
                }.padding()
                
                if isLoading {
                    VStack(spacing: 16) {
                        ProgressView().tint(.white).scaleEffect(1.5)
                        Text("Đang trích xuất link phim...").foregroundColor(.gray).font(.caption)
                    }.frame(maxHeight: .infinity)
                } else if let errorMessage = errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle.fill").font(.system(size: 50)).foregroundColor(.gray)
                        Text(errorMessage).foregroundColor(.gray).multilineTextAlignment(.center).padding()
                        Button("Thử lại") { Task { await extractStream() } }
                            .foregroundColor(.white).padding(.horizontal, 20).padding(.vertical, 10)
                            .background(Capsule().fill(.ultraThinMaterial))
                    }.frame(maxHeight: .infinity)
                } else if let player = player {
                    VideoPlayer(player: player)
                        .onAppear { player.play() }
                        .onDisappear { player.pause() }
                }
            }
        }
        .task { await extractStream() }
    }
    
    // MARK: - Trích xuất link stream .m3u8
    private func extractStream() async {
        isLoading = true; errorMessage = nil
        
        do {
            // Bước 1: Lấy link stream từ multiembed
            let embedURL = "https://multiembed.mov/directstream.php?video_id=\(movieId)&tmdb=1"
            let streamLink = try await fetchStreamLink(from: embedURL)
            
            // Bước 2: Lấy link .m3u8 từ response
            let m3u8Link = try await extractM3U8(from: streamLink)
            
            await MainActor.run {
                if let url = URL(string: m3u8Link) {
                    self.player = AVPlayer(url: url)
                } else {
                    self.errorMessage = "Link stream không hợp lệ"
                }
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Lỗi: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
    
    // Lấy HTML/JSON từ embed page
    private func fetchStreamLink(from urlString: String) async throws -> String {
        guard let url = URL(string: urlString) else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "URL không hợp lệ"])
        }
        
        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15", forHTTPHeaderField: "User-Agent")
        request.setValue("https://multiembed.mov", forHTTPHeaderField: "Referer")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        return String(data: data, encoding: .utf8) ?? ""
    }
    
    // Tìm link .m3u8 trong HTML
    private func extractM3U8(from html: String) async throws -> String {
        print("📄 HTML Response: \(html.prefix(1000))")
        
        // Tìm link .m3u8 bằng Regex
        let patterns = [
            #"https?://[^"'\s]+\.m3u8[^"'\s]*"#,
            #"https?://[^"'\s]+\.mp4[^"'\s]*"#,
            #""file"\s*:\s*"([^"]+)"#,
            #"source\s*src\s*=\s*"([^"]+)"#,
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
               let match = regex.firstMatch(in: html, range: NSRange(html.startIndex..., in: html)) {
                if let range = Range(match.range(at: 0), in: html) {
                    let link = String(html[range])
                    print("✅ Tìm thấy link: \(link)")
                    return link
                }
            }
        }
        
        // Fallback: Dùng nguồn khác
        print("⚠️ Không tìm thấy .m3u8 trong HTML, thử nguồn dự phòng...")
        return try await fetchFromBackupSource()
    }
    
    // Nguồn dự phòng
    private func fetchFromBackupSource() async throws -> String {
        let backupURLs = [
            "https://api.2embed.cc/embed/\(movieId)",
            "https://vidlink.pro/movie/\(movieId)",
        ]
        
        for urlString in backupURLs {
            do {
                let html = try await fetchStreamLink(from: urlString)
                // Tìm iframe source
                if let regex = try? NSRegularExpression(pattern: #"src\s*=\s*"([^"]+)""#, options: .caseInsensitive),
                   let match = regex.firstMatch(in: html, range: NSRange(html.startIndex..., in: html)),
                   let range = Range(match.range(at: 1), in: html) {
                    let iframeURL = String(html[range])
                    let iframeHTML = try await fetchStreamLink(from: iframeURL)
                    return try await extractM3U8(from: iframeHTML)
                }
            } catch {
                continue
            }
        }
        
        throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Không thể trích xuất link từ các nguồn"])
    }
}