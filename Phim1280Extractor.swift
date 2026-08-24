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
        
        // Bước 1: Lấy danh sách phim
        let homeURL = "\(baseURL)/api/home"
        guard let url = URL(string: homeURL) else { throw StreamError.noStreamAvailable }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let list = json["list"] as? [[String: Any]] else {
            throw StreamError.movieNotFound
        }
        
        // Tìm theo TMDB ID
        for item in list {
            if let tmdb = item["tmdbId"] as? Int, tmdb == tmdbID {
                if let streamURL = try? buildStreamURL(from: item, season: season, episode: episode) {
                    return try await getRealM3U8URL(streamURL)
                }
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
                
                let enMatched = enTitle.contains(normalizedTitle) || normalizedTitle.contains(enTitle)
                let viMatched = viTitle.contains(normalizedTitle) || normalizedTitle.contains(viTitle)
                
                if enMatched || viMatched {
                    if let streamURL = try? buildStreamURL(from: item, season: season, episode: episode) {
                        return try await getRealM3U8URL(streamURL)
                    }
                }
            }
        }
        
        throw StreamError.movieNotFound
    }
    
    private func buildStreamURL(
        from item: [String: Any],
        season: Int?,
        episode: Int?
    ) throws -> URL {
        
        let slug = item["slug"] as? String ?? ""
        let itemMediaType = item["mediaType"] as? String ?? "movie"
        
        var urlString: String
        
        if itemMediaType == "tv" || season != nil {
            let s = season ?? 1
            let ep = episode ?? 1
            urlString = "\(baseURL)/api/hls/tiktok/\(slug)-s\(String(format: "%02d", s))e\(String(format: "%02d", ep))/master.m3u8"
        } else {
            if let hlsUrl = item["hlsUrl"] as? String, !hlsUrl.isEmpty {
                urlString = hlsUrl.hasPrefix("/") ? "\(baseURL)\(hlsUrl)" : hlsUrl
            } else {
                urlString = "\(baseURL)/api/hls/tiktok/\(slug)/master.m3u8"
            }
        }
        
        guard let url = URL(string: urlString) else {
            throw StreamError.noStreamAvailable
        }
        
        return url
    }
    
    private func getRealM3U8URL(_ url: URL) async throws -> URL {
        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X)", forHTTPHeaderField: "User-Agent")
        request.setValue("https://film4k.net/", forHTTPHeaderField: "Referer")
        request.timeoutInterval = 15
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        print("🔍 [Phim1280] HTTP status: \((response as? HTTPURLResponse)?.statusCode ?? 0)")
        print("🔍 [Phim1280] Response URL: \(response.url?.absoluteString ?? "nil")")
        
        if let text = String(data: data, encoding: .utf8) {
            print("📄 [Phim1280] Response (first 300): \(text.prefix(300))")
        }
        
        // Trả về URL sau redirect (nếu có)
        if let finalURL = response.url {
            return finalURL
        }
        
        return url
    }
}