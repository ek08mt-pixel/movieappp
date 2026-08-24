import Foundation

class Phim1280Extractor {
    static let shared = Phim1280Extractor()
    private let baseURL = "https://film4k.net"
    
    // MARK: - Models 
    struct MovieDetail: Codable {
        let movie: MovieInfo?
        let episodes: [Episode]?
    }
     
    struct MovieInfo: Codable {
        let slug: String?
        let tmdbId: Int?
        let title: TitleInfo?
        let year: Int?
    }
    
    struct TitleInfo: Codable {
        let en: String?
        let vi: String?
    }
    
    struct Episode: Codable {
        let season: Int?
        let episode: Int?
        let title: String?
        let sources: [Source]?
    }
    
    struct Source: Codable {
        let url: String?
        let label: String?
        let kind: String?
    }
    
    enum StreamError: Error, LocalizedError {
        case noStreamAvailable
        case invalidResponse
        case movieNotFound
        
        var errorDescription: String? {
            switch self {
            case .noStreamAvailable: return "Không tìm thấy stream"
            case .invalidResponse: return "Response không hợp lệ"
            case .movieNotFound: return "Không tìm thấy phim"
            }
        }
    }
    
    // MARK: - Public Method
    
    func extractM3U8(
        slug: String,
        season: Int? = nil,
        episode: Int? = nil
    ) async throws -> URL {
        
        // Nếu có season/episode, tạo URL trực tiếp
        if let s = season, let e = episode {
            let urlString = "\(baseURL)/api/hls/tiktok/\(slug)-s\(String(format: "%02d", s))e\(String(format: "%02d", e))/master.m3u8"
            if let url = URL(string: urlString) {
                return url
            }
        }
        
        // Nếu không, lấy từ API watch
        let watchURL = "\(baseURL)/api/watch/\(slug)"
        guard let url = URL(string: watchURL) else { throw StreamError.invalidResponse }
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 15
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X)", forHTTPHeaderField: "User-Agent")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw StreamError.invalidResponse
        }
        
        let detail = try JSONDecoder().decode(MovieDetail.self, from: data)
        
        // Tìm episode phù hợp
        let targetSeason = season ?? 1
        let targetEpisode = episode ?? 1
        
        if let episodes = detail.episodes {
            for ep in episodes {
                if ep.season == targetSeason && ep.episode == targetEpisode {
                    if let sources = ep.sources, let firstSource = sources.first, let sourceURL = firstSource.url {
                        let fullURL = sourceURL.hasPrefix("/") ? "\(baseURL)\(sourceURL)" : sourceURL
                        if let streamURL = URL(string: fullURL) {
                            return streamURL
                        }
                    }
                }
            }
        }
        
        // Fallback: tạo URL trực tiếp
        let directURL = "\(baseURL)/api/hls/tiktok/\(slug)-s\(String(format: "%02d", targetSeason))e\(String(format: "%02d", targetEpisode))/master.m3u8"
        if let url = URL(string: directURL) {
            return url
        }
        
        throw StreamError.noStreamAvailable
    }
    
    // MARK: - Search bằng TMDB ID
    
    func findSlugByTMDBId(_ tmdbId: Int) async throws -> String? {
        // Gọi API để tìm phim theo TMDB ID
        // Có thể dùng /api/home hoặc search
        let urlString = "\(baseURL)/api/home"
        guard let url = URL(string: urlString) else { return nil }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        
        // Parse response tìm phim có tmdbId khớp
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            // Tìm trong các section
            for (_, value) in json {
                if let items = value as? [[String: Any]] {
                    for item in items {
                        if let movie = item["movie"] as? [String: Any],
                           let tmdbID = movie["tmdbId"] as? Int,
                           tmdbID == tmdbId,
                           let slug = movie["slug"] as? String {
                            return slug
                        }
                    }
                }
            }
        }
        
        return nil
    }
    
    // MARK: - Lấy stream cho MoviePlayerView
    
    func fetchStream(
        imdbID: String? = nil,
        tmdbID: Int,
        title: String,
        mediaType: String?,
        season: Int? = nil,
        episode: Int? = nil
    ) async throws -> URL {
        
        // Bước 1: Tìm slug
        var slug: String?
        
        // Thử tìm bằng TMDB ID
        slug = try await findSlugByTMDBId(tmdbID)
        
        // Nếu không tìm thấy, thử search bằng title
        if slug == nil {
            let searchQuery = title.lowercased().replacingOccurrences(of: " ", with: "-")
            slug = searchQuery
        }
        
        guard let movieSlug = slug else { throw StreamError.movieNotFound }
        
        // Bước 2: Lấy m3u8
        return try await extractM3U8(
            slug: movieSlug,
            season: season,
            episode: episode
        )
    }
}