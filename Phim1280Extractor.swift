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
        
        // Tìm theo TMDB ID
        for item in list {
            if let tmdb = item["tmdbId"] as? Int, tmdb == tmdbID {
                print("✅ Tìm thấy theo TMDB ID: \(tmdbID)")
                return try extractStreamURL(from: item, season: season, episode: episode)
            }
        }
        
        // Tìm theo title
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
                    return try extractStreamURL(from: item, season: season, episode: episode)
                }
            }
        }
        
        print("❌ Không tìm thấy: \(title)")
        throw StreamError.movieNotFound
    }
    
    private func extractStreamURL(
        from item: [String: Any],
        season: Int?,
        episode: Int?
    ) throws -> URL {
        
        // Ưu tiên 1: hlsUrl trực tiếp CDN
        if let hlsUrl = item["hlsUrl"] as? String,
           hlsUrl.hasPrefix("http"),
           !hlsUrl.contains("/api/hls/tiktok") {
            if let url = URL(string: hlsUrl) {
                print("✅ CDN hlsUrl: \(hlsUrl.prefix(100))")
                return url
            }
        }
        
        // Ưu tiên 2: sources[].url trực tiếp CDN
        if let sources = item["sources"] as? [[String: Any]],
           let firstSource = sources.first,
           let sourceURL = firstSource["url"] as? String,
           sourceURL.hasPrefix("http"),
           !sourceURL.contains("/api/hls/tiktok") {
            if let url = URL(string: sourceURL) {
                print("✅ CDN source: \(sourceURL.prefix(100))")
                return url
            }
        }
        
        // Ưu tiên 3: /api/hls/tiktok (cần xử lý thêm)
        let slug = item["slug"] as? String ?? ""
        let urlString = "\(baseURL)/api/hls/tiktok/\(slug)/master.m3u8"
        
        guard let url = URL(string: urlString) else {
            throw StreamError.noStreamAvailable
        }
        
        print("⚠️ Dùng API hls: \(urlString)")
        return url
    }
}