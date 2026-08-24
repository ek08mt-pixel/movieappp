import Foundation

class Phim1280Extractor {
    static let shared = Phim1280Extractor()
    private let baseURL = "https://film4k.net"
    
    struct MovieItem: Codable {
        let slug: String?
        let hlsUrl: String?
        let mediaType: String?
        let title: TitleInfo?
    }
    
    struct TitleInfo: Codable {
        let en: String?
        let vi: String?
    }
    
    struct HomeResponse: Codable {
        let list: [MovieItem]?
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
        
        // Bước 1: Lấy danh sách phim từ /api/home
        let homeURL = "\(baseURL)/api/home"
        guard let url = URL(string: homeURL) else { throw StreamError.noStreamAvailable }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        
        // Parse JSON
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let list = json["list"] as? [[String: Any]] else {
            throw StreamError.movieNotFound
        }
        
        // Tìm phim theo title
        let normalizedTitle = title.lowercased().trimmingCharacters(in: .whitespaces)
        
        for item in list {
            if let titleObj = item["title"] as? [String: Any] {
                let enTitle = (titleObj["en"] as? String ?? "").lowercased()
                let viTitle = (titleObj["vi"] as? String ?? "").lowercased()
                
                if enTitle.contains(normalizedTitle) || normalizedTitle.contains(enTitle) ||
                   viTitle.contains(normalizedTitle) || normalizedTitle.contains(viTitle) {
                    
                    let slug = item["slug"] as? String ?? ""
                    let mediaType = item["mediaType"] as? String ?? "movie"
                    
                    // Tạo URL m3u8
                    var urlString: String
                    if mediaType == "tv" || season != nil {
                        let s = season ?? 1
                        let ep = episode ?? 1
                        urlString = "\(baseURL)/api/hls/tiktok/\(slug)-s\(String(format: "%02d", s))e\(String(format: "%02d", ep))/master.m3u8"
                    } else {
                        // Movie - dùng hlsUrl từ response nếu có
                        if let hlsUrl = item["hlsUrl"] as? String {
                            urlString = hlsUrl.hasPrefix("/") ? "\(baseURL)\(hlsUrl)" : hlsUrl
                        } else {
                            urlString = "\(baseURL)/api/hls/tiktok/\(slug)/master.m3u8"
                        }
                    }
                    
                    if let streamURL = URL(string: urlString) {
                        return streamURL
                    }
                }
            }
        }
        
        throw StreamError.movieNotFound
    }
}