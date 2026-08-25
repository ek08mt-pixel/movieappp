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
        
        // Nếu có season/episode, dùng API /api/watch
        if let s = season, let ep = episode {
            return try await fetchEpisodeStream(
                tmdbID: tmdbID,
                title: title,
                season: s,
                episode: ep
            )
        }
        
        // Movie
        return try await fetchMovieStream(tmdbID: tmdbID, title: title)
    }
    
    // MARK: - Fetch Movie Stream
    
    private func fetchMovieStream(tmdbID: Int, title: String) async throws -> URL {
    // Danh sách slug cần thử
    var slugs: [String] = []
    
    // Slug từ title tiếng Anh
    let enSlug = title.lowercased()
        .replacingOccurrences(of: " ", with: "-")
        .replacingOccurrences(of: ":", with: "")
        .replacingOccurrences(of: "&", with: "and")
        .replacingOccurrences(of: "'", with: "")
        .replacingOccurrences(of: ",", with: "")
        .replacingOccurrences(of: ".", with: "")
    slugs.append(enSlug)
    
    // Slug ngắn (từ cuối)
    if let lastWord = title.components(separatedBy: " ").last {
        let lastSlug = lastWord.lowercased()
            .replacingOccurrences(of: ":", with: "")
            .replacingOccurrences(of: "&", with: "and")
        slugs.append(lastSlug)
    }
    
    // Slug bỏ từ "The"
    if title.lowercased().hasPrefix("the ") {
        let noThe = String(title.dropFirst(4)).lowercased()
            .replacingOccurrences(of: " ", with: "-")
            .replacingOccurrences(of: ":", with: "")
            .replacingOccurrences(of: "&", with: "and")
        slugs.append(noThe)
    }
    
    for slug in slugs {
        print("🔍 Thử slug: \(slug)")
        
        let watchURL = "\(baseURL)/api/watch/\(slug)"
        guard let url = URL(string: watchURL) else { continue }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            if let httpResponse = response as? HTTPURLResponse,
               httpResponse.statusCode == 200,
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               json["movie"] != nil {
                
                print("✅ Tìm thấy movie với slug: \(slug)")
                
                // Lấy sources
                if let movie = json["movie"] as? [String: Any],
                   let sources = movie["sources"] as? [[String: Any]],
                   let firstSource = sources.first,
                   let sourceURL = firstSource["url"] as? String,
                   let streamURL = URL(string: sourceURL) {
                    return try await processMasterPlaylist(streamURL)
                }
                
                if let sources = json["sources"] as? [[String: Any]],
                   let firstSource = sources.first,
                   let sourceURL = firstSource["url"] as? String,
                   let streamURL = URL(string: sourceURL) {
                    return try await processMasterPlaylist(streamURL)
                }
            }
        } catch {
            continue
        }
    }
    
    throw StreamError.movieNotFound
}

private func fetchStreamBySlug(_ slug: String) async throws -> URL {
    let watchURL = "\(baseURL)/api/watch/\(slug)"
    guard let url = URL(string: watchURL) else { throw StreamError.noStreamAvailable }
    
    let (data, _) = try await URLSession.shared.data(from: url)
    
    guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
        throw StreamError.movieNotFound
    }
    
    // Lấy sources từ movie hoặc root
    if let movie = json["movie"] as? [String: Any],
       let sources = movie["sources"] as? [[String: Any]],
       let firstSource = sources.first,
       let sourceURL = firstSource["url"] as? String,
       let streamURL = URL(string: sourceURL) {
        return try await processMasterPlaylist(streamURL)
    }
    
    if let sources = json["sources"] as? [[String: Any]],
       let firstSource = sources.first,
       let sourceURL = firstSource["url"] as? String,
       let streamURL = URL(string: sourceURL) {
        return try await processMasterPlaylist(streamURL)
    }
    
    throw StreamError.noStreamAvailable
}
    
    // MARK: - Fetch Episode Stream
    
    private func fetchEpisodeStream(
        tmdbID: Int,
        title: String,
        season: Int,
        episode: Int
    ) async throws -> URL {
        
        let slug = try await findSlug(tmdbID: tmdbID, title: title)
        
        let watchURL = "\(baseURL)/api/watch/\(slug)"
        guard let url = URL(string: watchURL) else { throw StreamError.noStreamAvailable }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let episodes = json["episodes"] as? [[String: Any]] else {
            throw StreamError.movieNotFound
        }
        
        for ep in episodes {
            if let epSeason = ep["season"] as? Int, epSeason == season,
               let epNumber = ep["episode"] as? Int, epNumber == episode,
               let sources = ep["sources"] as? [[String: Any]],
               let firstSource = sources.first,
               let sourceURL = firstSource["url"] as? String,
               let streamURL = URL(string: sourceURL) {
                print("✅ Episode stream: \(sourceURL.prefix(100))")
                return try await processMasterPlaylist(streamURL)
            }
        }
        
        throw StreamError.movieNotFound
    }
    
    // MARK: - Find Slug
    
    private func findSlug(tmdbID: Int, title: String) async throws -> String {
        let fallbackSlug = title.lowercased()
            .replacingOccurrences(of: " ", with: "-")
            .replacingOccurrences(of: ":", with: "")
            .replacingOccurrences(of: "&", with: "and")
            .replacingOccurrences(of: "'", with: "")
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: ".", with: "")
        
        print("🔍 Fallback slug: \(fallbackSlug)")
        return fallbackSlug
    }
    
    // MARK: - Extract Stream URL
    
    private func extractStreamURL(from item: [String: Any]) async throws -> URL {
        
        if let hlsUrl = item["hlsUrl"] as? String,
           hlsUrl.hasPrefix("http"),
           !hlsUrl.contains("/api/hls/tiktok") {
            print("🔍 CDN hlsUrl: \(hlsUrl.prefix(100))")
            if let url = URL(string: hlsUrl) {
                return try await processMasterPlaylist(url)
            }
        }
        
        if let sources = item["sources"] as? [[String: Any]],
           let firstSource = sources.first,
           let sourceURL = firstSource["url"] as? String,
           sourceURL.hasPrefix("http"),
           !sourceURL.contains("/api/hls/tiktok") {
            print("🔍 CDN source: \(sourceURL.prefix(100))")
            if let url = URL(string: sourceURL) {
                return try await processMasterPlaylist(url)
            }
        }
        
        let slug = item["slug"] as? String ?? ""
        let urlString = "\(baseURL)/api/hls/tiktok/\(slug)/master.m3u8"
        guard let url = URL(string: urlString) else {
            throw StreamError.noStreamAvailable
        }
        
        return try await processMasterPlaylist(url)
    }
    
    // MARK: - Process Master Playlist
    
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
                let variantURLString: String
                if trimmed.hasPrefix("http") {
                    variantURLString = trimmed
                } else {
                    let base = masterURL.deletingLastPathComponent().absoluteString
                    variantURLString = "\(base)/\(trimmed)"
                }
                
                if let url = URL(string: variantURLString) {
                    print("🎯 Variant URL: \(variantURLString)")
                    return try await processVariantPlaylist(url)
                }
            }
        }
        
        throw StreamError.noStreamAvailable
    }
    
    // MARK: - Process Variant Playlist
    
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
                        .replacingOccurrences(of: "//", with: "/")
                        .replacingOccurrences(of: "https:/", with: "https://")
                        .replacingOccurrences(of: "http:/", with: "http://")
                } else {
                    let base = variantURL.deletingLastPathComponent().absoluteString
                    let cleanBase = base.hasSuffix("/") ? String(base.dropLast()) : base
                    let cleanPath = trimmed.hasPrefix("/") ? String(trimmed.dropFirst()) : trimmed
                    absoluteURL = "\(cleanBase)/\(cleanPath)"
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