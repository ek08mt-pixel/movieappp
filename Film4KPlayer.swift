import Foundation
import AVFoundation

final class Film4KPlayer {
    static let shared = Film4KPlayer()
    
    private let session: URLSession
    
    init() {
        let config = URLSessionConfiguration.default
        config.httpAdditionalHeaders = [
            "User-Agent": "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1",
            "Referer": "https://film4k.net/",
            "Accept": "application/vnd.apple.mpegurl,*/*",
            "Connection": "keep-alive"
        ]
        session = URLSession(configuration: config)
    }
    
    // MARK: - Public Method
    
    func fetchPlaylistURL(from url: URL) async throws -> URL {
        // Bước 1: Fetch URL gốc
        let content = try await fetchContent(url: url)
        
        print("🔍 Content type: \(content.prefix(100))")
        
        // Bước 2: Kiểm tra nếu là m3u8 content
        if content.hasPrefix("#EXTM3U") {
            print("✅ Nhận được m3u8 content!")
            return try await createLocalPlaylist(from: content, baseURL: url)
        }
        
        // Bước 3: Nếu là HTML, tìm link video
        if content.contains("<video") {
            if let videoSrc = extractVideoSource(from: content) {
                print("🔍 Tìm thấy video src: \(videoSrc)")
                let absoluteURL = URL(string: videoSrc, relativeTo: url)?.absoluteURL ?? url
                return try await fetchPlaylistURL(from: absoluteURL)
            }
        }
        
        // Bước 4: Nếu là JSON, tìm sources
        if let data = content.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let sources = json["sources"] as? [[String: Any]],
           let firstSource = sources.first,
           let sourcePath = firstSource["url"] as? String {
            let fullURL = sourcePath.hasPrefix("/") ? "https://film4k.net\(sourcePath)" : sourcePath
            if let sourceURL = URL(string: fullURL) {
                return try await fetchPlaylistURL(from: sourceURL)
            }
        }
        
        throw NSError(domain: "Film4K", code: 1, userInfo: [NSLocalizedDescriptionKey: "Không tìm thấy m3u8"])
    }
    
    // MARK: - Private Methods
    
    private func fetchContent(url: URL) async throws -> String {
        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1", forHTTPHeaderField: "User-Agent")
        request.setValue("https://film4k.net/", forHTTPHeaderField: "Referer")
        request.setValue("application/vnd.apple.mpegurl,*/*", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 15
        
        let (data, response) = try await session.data(for: request)
        
        print("🔍 HTTP status: \((response as? HTTPURLResponse)?.statusCode ?? 0)")
        print("🔍 Final URL: \(response.url?.absoluteString ?? "nil")")
        
        guard let content = String(data: data, encoding: .utf8) else {
            throw NSError(domain: "Film4K", code: 2, userInfo: [NSLocalizedDescriptionKey: "Không đọc được content"])
        }
        
        return content
    }
    
    private func extractVideoSource(from html: String) -> String? {
        let pattern = #"<video[^>]+src=["']([^"']+)["']"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            return nil
        }
        let nsRange = NSRange(html.startIndex..<html.endIndex, in: html)
        if let match = regex.firstMatch(in: html, options: [], range: nsRange),
           let range = Range(match.range(at: 1), in: html) {
            return String(html[range])
        }
        return nil
    }
    
    private func createLocalPlaylist(from m3u8Content: String, baseURL: URL) async throws -> URL {
        var lines = m3u8Content.components(separatedBy: .newlines)
        
        for i in 0..<lines.count {
            let line = lines[i].trimmingCharacters(in: .whitespaces)
            
            // Bỏ qua comment và tags
            if line.isEmpty || line.hasPrefix("#") {
                continue
            }
            
            // Chuyển URL tương đối thành absolute
            if let absoluteURL = URL(string: line, relativeTo: baseURL)?.absoluteString {
                lines[i] = absoluteURL
            }
        }
        
        let modified = lines.joined(separator: "\n")
        
        // Lưu vào temporary directory
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("film4k_playlist_\(Date().timeIntervalSince1970).m3u8")
        
        try modified.write(to: fileURL, atomically: true, encoding: .utf8)
        
        print("✅ Local playlist saved: \(fileURL.absoluteString)")
        
        return fileURL
    }
}