import Foundation

class Phim1280Extractor {
    static let shared = Phim1280Extractor()
    private let baseURL = "https://film4k.net"
    
    struct MovieItem: Codable {
        let slug: String?
        let hlsUrl: String?
        let mediaType: String?
        let title: TitleInfo?
        let tmdbId: Int?
    }
    
    struct TitleInfo: Codable {
        let en: String?
        let vi: String?
    }
    
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
        
        let homeURL = "\(baseURL)/api/home"
        guard let url = URL(string: homeURL) else { throw StreamError.noStreamAvailable }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let list = json["list"] as? [[String: Any]] else {
            throw StreamError.movieNotFound
        }
        
        // Tìm theo TMDB ID trước
        for item in list {
            if let tmdb = item["tmdbId"] as? Int, tmdb == tmdbID {
                if let streamURL = try? buildStreamURL(from: item, season: season, episode: episode) {
                    return streamURL
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
                        return streamURL
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
}