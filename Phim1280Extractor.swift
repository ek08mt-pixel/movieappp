import Foundation

class Phim1280Extractor {
    static let shared = Phim1280Extractor()
    private let baseURL = "https://film4k.net"
    
    enum StreamError: Error, LocalizedError {
        case noStreamAvailable
        case movieNotFound
        
        var errorDescription: String? {
            switch self {
            case .noStreamAvailable: return "Không tìm thấy stream"
            case .movieNotFound: return "Không tìm thấy phim"
            }
        }
    }
    
    func fetchStream(
        tmdbID: Int,
        title: String,
        mediaType: String?,
        season: Int? = nil,
        episode: Int? = nil
    ) async throws -> URL {
        
        let query = title.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let homeURL = "\(baseURL)/api/home?q=\(query)"
        guard let url = URL(string: homeURL) else { throw StreamError.noStreamAvailable }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let list = json["list"] as? [[String: Any]] else {
            throw StreamError.movieNotFound
        }
        
        for item in list {
            if let tmdb = item["tmdbId"] as? Int, tmdb == tmdbID {
                print("✅ Tìm thấy theo TMDB ID: \(tmdbID)")
                return try await extractStreamURL(from: item)
            }
        }
        
        let normalizedTitle = title.lowercased()
            .replacingOccurrences(of: ":", with: "")
            .replacingOccurrences(of: "&", with: "and")
            .trimmingCharacters(in: .whitespaces)
        
        for item in list {
            if let titleObj = item["title"] as? [String: Any] {
                let enTitle = (titleObj["en"] as? String ?? "").lowercased()
                let viTitle = (titleObj["vi"] as? String ?? "").lowercased()
                
                if enTitle.contains(normalizedTitle) || normalizedTitle.contains(enTitle) ||
                   viTitle.contains(normalizedTitle) || normalizedTitle.contains(viTitle) {
                    print("✅ Tìm thấy theo title: \(title)")
                    return try await extractStreamURL(from: item)
                }
            }
        }
        
        throw StreamError.movieNotFound
    }
    
    private func extractStreamURL(from item: [String: Any]) async throws -> URL {
        
        // Ưu tiên 1: hlsUrl CDN
        if let hlsUrl = item["hlsUrl"] as? String,
           hlsUrl.hasPrefix("http") {
            print("🔍 CDN hlsUrl: \(hlsUrl.prefix(100))")
            if let url = URL(string: hlsUrl) {
                return try await processMasterPlaylist(url)
            }
        }
        
        // Ưu tiên 2: sources[].url CDN
        if let sources = item["sources"] as? [[String: Any]],
           let firstSource = sources.first,
           let sourceURL = firstSource["url"] as? String,
           sourceURL.hasPrefix("http") {
            print("🔍 CDN source: \(sourceURL.prefix(100))")
            if let url = URL(string: sourceURL) {
                return try await processMasterPlaylist(url)
            }
        }
        
        // Ưu tiên 3: /api/hls/tiktok
        let slug = item["slug"] as? String ?? ""
        let urlString = "\(baseURL)/api/hls/tiktok/\(slug)/master.m3u8"
        guard let url = URL(string: urlString) else {
            throw StreamError.noStreamAvailable
        }
        
        print("⚠️ Dùng API hls: \(urlString)")
        return try await processMasterPlaylist(url)
    }
    
    private func processMasterPlaylist(_ masterURL: URL) async throws -> URL {
        var request = URLRequest(url: masterURL)
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X)", forHTTPHeaderField: "User-Agent")
        request.setValue("https://film4k.net/", forHTTPHeaderField: "Referer")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        guard let content = String(data: data, encoding: .utf8) else {
            throw StreamError.noStreamAvailable
        }
        
        print("📄 Master m3u8: \(content.prefix(300))")
        
        let lines = content.components(separatedBy: .newlines)
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if !trimmed.isEmpty && !trimmed.hasPrefix("#") {
                let variantURL: String
                if trimmed.hasPrefix("http") {
                    variantURL = trimmed
                } else {
                    let base = masterURL.deletingLastPathComponent().absoluteString
                    variantURL = "\(base)/\(trimmed)"
                }
                
                if let url = URL(string: variantURL) {
                    print("🎯 Variant URL: \(variantURL)")
                    return try await processVariantPlaylist(url)
                }
            }
        }
        
        throw StreamError.noStreamAvailable
    }
    
    private func processVariantPlaylist(_ variantURL: URL) async throws -> URL {
        var request = URLRequest(url: variantURL)
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X)", forHTTPHeaderField: "User-Agent")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        guard let content = String(data: data, encoding: .utf8) else {
            throw StreamError.noStreamAvailable
        }
        
        print("📄 Variant m3u8 (first 300): \(content.prefix(300))")
        
        let lines = content.components(separatedBy: .newlines)
        var newLines: [String] = []
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if !trimmed.isEmpty && !trimmed.hasPrefix("#") {
                let absoluteURL: String
                if trimmed.hasPrefix("http") {
                    absoluteURL = trimmed
                } else {
                    let base = variantURL.deletingLastPathComponent().absoluteString
                    absoluteURL = "\(base)/\(trimmed)"
                }
                newLines.append(absoluteURL)
            } else {
                newLines.append(line)
            }
        }
        
        let localContent = newLines.joined(separator: "\n")
        
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("film4k_variant_\(Date().timeIntervalSince1970).m3u8")
        try localContent.write(to: fileURL, atomically: true, encoding: .utf8)
        
        print("✅ Local variant saved: \(fileURL)")
        
        return fileURL
    }
}