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
            "Origin": "https://film4k.net",
            "Accept": "application/vnd.apple.mpegurl,*/*"
        ]
        session = URLSession(configuration: config)
    }
    
    func fetchPlaylistURL(from url: URL) async throws -> URL {
        let content = try await fetchContent(url: url)
        print("🔍 Content type: \(content.prefix(100))")
        
        if content.hasPrefix("#EXTM3U") {
            return try await createLocalPlaylist(from: content, baseURL: url)
        }
        
        throw NSError(domain: "Film4K", code: 1, userInfo: [NSLocalizedDescriptionKey: "Không tìm thấy m3u8"])
    }
    
    private func fetchContent(url: URL) async throws -> String {
        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1", forHTTPHeaderField: "User-Agent")
        request.setValue("https://film4k.net/", forHTTPHeaderField: "Referer")
        request.setValue("https://film4k.net", forHTTPHeaderField: "Origin")
        request.setValue("application/vnd.apple.mpegurl,*/*", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 15
        
        let (data, response) = try await session.data(for: request)
        
        guard let content = String(data: data, encoding: .utf8) else {
            throw NSError(domain: "Film4K", code: 2, userInfo: [NSLocalizedDescriptionKey: "Không đọc được content"])
        }
        
        return content
    }
    
    private func createLocalPlaylist(from m3u8Content: String, baseURL: URL) async throws -> URL {
        // Tìm video variant đầu tiên
        var lines = m3u8Content.components(separatedBy: .newlines)
        
        var videoVariantURL: String? = nil
        
        for i in 0..<lines.count {
            if lines[i].hasPrefix("#EXT-X-STREAM-INF") {
                // URL variant là dòng tiếp theo
                if i + 1 < lines.count {
                    let nextLine = lines[i + 1].trimmingCharacters(in: .whitespaces)
                    if !nextLine.isEmpty && !nextLine.hasPrefix("#") {
                        videoVariantURL = nextLine
                        print("🎯 Video variant: \(nextLine)")
                        break
                    }
                }
            }
        }
        
        guard let variantPath = videoVariantURL else {
            throw NSError(domain: "Film4K", code: 3, userInfo: [NSLocalizedDescriptionKey: "Không tìm thấy variant"])
        }
        
        let variantFullURL = variantPath.hasPrefix("http") ? variantPath : "https://film4k.net\(variantPath)"
        guard let variantURL = URL(string: variantFullURL) else {
            throw NSError(domain: "Film4K", code: 4, userInfo: [NSLocalizedDescriptionKey: "URL variant lỗi"])
        }
        
        // Fetch variant m3u8 (chứa segments)
        let variantContent = try await fetchContent(url: variantURL)
        print("🔍 Variant content: \(variantContent.prefix(200))")
        
        // Tải tất cả segments về local
        var variantLines = variantContent.components(separatedBy: .newlines)
        var segmentMap: [String: URL] = [:]  // [segmentName: localURL]
        
        for i in 0..<variantLines.count {
            let line = variantLines[i].trimmingCharacters(in: .whitespaces)
            if !line.isEmpty && !line.hasPrefix("#") {
                // Đây là segment URL
                let segmentURL = line.hasPrefix("http") ? line : "https://film4k.net\(line)"
                
                if let url = URL(string: segmentURL) {
                    do {
                        let localURL = try await downloadSegment(from: url)
                        let segmentName = (line as NSString).lastPathComponent
                        segmentMap[segmentName] = localURL
                        print("✅ Tải segment: \(segmentName)")
                    } catch {
                        print("⚠️ Lỗi tải segment: \(line)")
                    }
                }
            }
        }
        
        // Tạo m3u8 local với segments local
        var localLines = variantLines
        
        for i in 0..<localLines.count {
            let line = localLines[i].trimmingCharacters(in: .whitespaces)
            if !line.isEmpty && !line.hasPrefix("#") {
                let segmentName = (line as NSString).lastPathComponent
                if let localURL = segmentMap[segmentName] {
                    localLines[i] = localURL.path
                }
            }
        }
        
        let localContent = localLines.joined(separator: "\n")
        
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("film4k_playlist_\(Date().timeIntervalSince1970).m3u8")
        try localContent.write(to: fileURL, atomically: true, encoding: .utf8)
        
        return fileURL
    }
    
    private func downloadSegment(from url: URL) async throws -> URL {
        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1", forHTTPHeaderField: "User-Agent")
        request.setValue("https://film4k.net/", forHTTPHeaderField: "Referer")
        
        let (data, _) = try await session.data(for: request)
        
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = (url.lastPathComponent).replacingOccurrences(of: ":", with: "_")
        let fileURL = tempDir.appendingPathComponent(fileName)
        try data.write(to: fileURL)
        
        return fileURL
    }
}