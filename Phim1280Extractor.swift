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
        
        print("🔍 fetchStream bắt đầu: \(title) (tmdb: \(tmdbID)) S\(season ?? -1)E\(episode ?? -1)")
        
        let slug = try await findSlug(tmdbID: tmdbID, title: title)
        print("🔍 Slug: \(slug)")
        let watchURL = "\(baseURL)/api/watch/\(slug)"
        guard let url = URL(string: watchURL) else { throw StreamError.noStreamAvailable }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw StreamError.movieNotFound
        }
        
        // TV show
        if let episodes = json["episodes"] as? [[String: Any]], !episodes.isEmpty {
            let s = season ?? 1
            let ep = episode ?? 1
            for episodeItem in episodes {
                if let epSeason = episodeItem["season"] as? Int, epSeason == s,
                   let epNumber = episodeItem["episode"] as? Int, epNumber == ep,
                   let sources = episodeItem["sources"] as? [[String: Any]],
                   let firstSource = sources.first,
                   let sourceURL = firstSource["url"] as? String,
                   let streamURL = URL(string: sourceURL) {
                    return try await processPlaylist(streamURL)
                }
            }
        }
        
        // Movie
        if let movie = json["movie"] as? [String: Any] {
            if let hlsUrl = movie["hlsUrl"] as? String {
                let fullHlsURL = hlsUrl.hasPrefix("/") ? "\(baseURL)\(hlsUrl)" : hlsUrl
                if let streamURL = URL(string: fullHlsURL) {
                    return try await processPlaylist(streamURL)
                }
            }
            if let sources = movie["sources"] as? [[String: Any]],
               let firstSource = sources.first,
               let sourceURL = firstSource["url"] as? String {
                let fullSourceURL = sourceURL.hasPrefix("/") ? "\(baseURL)\(sourceURL)" : sourceURL
                if let streamURL = URL(string: fullSourceURL) {
                    return try await processPlaylist(streamURL)
                }
            }
        }
        
        if let sources = json["sources"] as? [[String: Any]],
           let firstSource = sources.first,
           let sourceURL = firstSource["url"] as? String {
            let fullSourceURL = sourceURL.hasPrefix("/") ? "\(baseURL)\(sourceURL)" : sourceURL
            if let streamURL = URL(string: fullSourceURL) {
                return try await processPlaylist(streamURL)
            }
        }
        
        throw StreamError.noStreamAvailable
    }
    
    private func processPlaylist(_ playlistURL: URL) async throws -> URL {
        print("🔍 processPlaylist: \(playlistURL.absoluteString.prefix(100))")
        var request = URLRequest(url: playlistURL)
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15", forHTTPHeaderField: "User-Agent")
        request.setValue("https://film4k.net/", forHTTPHeaderField: "Referer")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        guard let content = String(data: data, encoding: .utf8) else {
            throw StreamError.noStreamAvailable
        }
        
        var m3u8Content = content
        if let range = content.range(of: "#EXTM3U") {
            m3u8Content = String(content[range.lowerBound...])
        }
        
        // Nếu là master playlist
        if m3u8Content.contains("#EXT-X-STREAM-INF") {
            return try await processMasterPlaylist(m3u8Content, baseURL: playlistURL)
        }
        
        // Nếu là variant trực tiếp - trả về playlistURL
        print("✅ Variant: \(playlistURL.absoluteString.prefix(80))")
        return playlistURL
    }
    
    private func processMasterPlaylist(_ content: String, baseURL: URL) async throws -> URL {
        print("🔍 Master playlist có \(content.components(separatedBy: .newlines).count) dòng")
        let lines = content.components(separatedBy: .newlines)
        var videoVariantURL: String? = nil
        
        for line in lines {
            if !line.hasPrefix("#") && !line.isEmpty {
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                if !trimmed.hasPrefix("#") && !trimmed.isEmpty {
                    videoVariantURL = trimmed.hasPrefix("http") ? trimmed : "\(baseURL.deletingLastPathComponent().absoluteString)/\(trimmed)"
                }
            }
        }
        
        guard let videoURLString = videoVariantURL, let videoURL = URL(string: videoURLString) else {
            throw StreamError.noStreamAvailable
        }
        
        // Fetch variant content
        var request = URLRequest(url: videoURL)
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15", forHTTPHeaderField: "User-Agent")
        request.setValue("https://film4k.net/", forHTTPHeaderField: "Referer")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        guard let variantContent = String(data: data, encoding: .utf8) else {
            throw StreamError.noStreamAvailable
        }
        
        // Tải tất cả segments về local
        return try await downloadAllSegments(variantContent, baseURL: videoURL)
    }
    
    private func downloadAllSegments(_ content: String, baseURL: URL) async throws -> URL {
        let lines = content.components(separatedBy: .newlines)
        var newLines: [String] = []
        var segmentCount = 0
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if !trimmed.isEmpty && !trimmed.hasPrefix("#") {
                let segmentURLString: String
                if trimmed.hasPrefix("http") {
                    segmentURLString = trimmed
                } else {
                    segmentURLString = "\(baseURL.deletingLastPathComponent().absoluteString)/\(trimmed)"
                }
                
                if let segmentURL = URL(string: segmentURLString) {
                    var request = URLRequest(url: segmentURL)
                    request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15", forHTTPHeaderField: "User-Agent")
                    request.setValue("https://film4k.net/", forHTTPHeaderField: "Referer")
                    
                    do {
                        let (segmentData, _) = try await URLSession.shared.data(for: request)
                        let tempDir = FileManager.default.temporaryDirectory
                        let fileURL = tempDir.appendingPathComponent("seg_\(segmentCount).ts")
                        try segmentData.write(to: fileURL)
                        newLines.append(fileURL.path)
                        segmentCount += 1
                        
                        if segmentCount % 10 == 0 {
                            print("✅ Đã tải \(segmentCount) segments")
                        }
                    } catch {
                        print("⚠️ Lỗi segment \(segmentURLString): \(error)")
                        newLines.append(segmentURLString)
                    }
                }
            } else {
                newLines.append(line)
            }
        }
        
        let localContent = newLines.joined(separator: "\n")
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("film4k_local_\(Date().timeIntervalSince1970).m3u8")
        try localContent.write(to: fileURL, atomically: true, encoding: .utf8)
        
        print("✅ Local m3u8: \(segmentCount) segments")
        return fileURL
    }
    
    private func fetchVariantWithAudio(videoURL: URL, audioURLs: [String], subtitleURLs: [String]) async throws -> URL {
        var request = URLRequest(url: videoURL)
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15", forHTTPHeaderField: "User-Agent")
        request.setValue("https://film4k.net/", forHTTPHeaderField: "Referer")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        guard let videoContent = String(data: data, encoding: .utf8) else {
            throw StreamError.noStreamAvailable
        }
        
        // Tạo local m3u8
        var lines = videoContent.components(separatedBy: .newlines)
        var result: [String] = ["#EXTM3U", "#EXT-X-VERSION:7"]
        
        // Thêm audio tracks
        if !audioURLs.isEmpty {
            for audioURL in audioURLs {
                result.append("#EXT-X-MEDIA:TYPE=AUDIO,GROUP-ID=\"aud\",NAME=\"Audio\",URI=\"\(audioURL)\"")
            }
        }
        
        // Thêm subtitles
        if !subtitleURLs.isEmpty {
            for subtitleURL in subtitleURLs {
                result.append("#EXT-X-MEDIA:TYPE=SUBTITLES,GROUP-ID=\"sub\",NAME=\"Sub\",URI=\"\(subtitleURL)\"")
            }
        }
        
        // Thêm video segments với absolute URLs
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if !trimmed.isEmpty && !trimmed.hasPrefix("#") {
                if trimmed.hasPrefix("http") {
                    result.append(trimmed)
                } else {
                    let base = videoURL.deletingLastPathComponent().absoluteString
                    result.append("\(base)/\(trimmed)")
                }
            } else if trimmed.hasPrefix("#EXTINF") || trimmed.hasPrefix("#EXT-X-MAP") || trimmed.hasPrefix("#EXT-X-TARGETDURATION") || trimmed.hasPrefix("#EXT-X-MEDIA-SEQUENCE") || trimmed.hasPrefix("#EXT-X-PLAYLIST-TYPE") {
                result.append(trimmed)
            }
        }
        
        let localContent = result.joined(separator: "\n")
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("film4k_tiktok_\(Date().timeIntervalSince1970).m3u8")
        try localContent.write(to: fileURL, atomically: true, encoding: .utf8)
        
        print("✅ Tạo local m3u8 với \(audioURLs.count) audio, \(subtitleURLs.count) subtitle")
        return fileURL
    }
    
    private func createLocalVariant(_ content: String, baseURL: URL) async throws -> URL {
        let lines = content.components(separatedBy: .newlines)
        var newLines: [String] = []
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if !trimmed.isEmpty && !trimmed.hasPrefix("#") {
                if trimmed.hasPrefix("http") {
                    newLines.append(trimmed)
                } else {
                    let base = baseURL.deletingLastPathComponent().absoluteString
                    newLines.append("\(base)/\(trimmed)")
                }
            } else {
                newLines.append(line)
            }
        }
        
        // Trả về baseURL trực tiếp
        return baseURL
    }
    
    private func findSlug(tmdbID: Int, title: String) async throws -> String {
        let cleanTitle = removeVietnameseDiacritics(title.lowercased())
        var searchTerms: [String] = [cleanTitle]
        let words = cleanTitle.components(separatedBy: " ")
        if let first = words.first { searchTerms.append(first) }
        if let last = words.last { searchTerms.append(last) }
        searchTerms.append(contentsOf: words.filter { $0.count > 3 })
        
        for term in searchTerms {
            let encoded = term.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            let homeURL = "\(baseURL)/api/home?q=\(encoded)"
            guard let url = URL(string: homeURL) else { continue }
            
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    var allItems: [[String: Any]] = []
                    if let list = json["list"] as? [[String: Any]] { allItems += list }
                    if let hero = json["hero"] as? [[String: Any]] { allItems += hero }
                    if let top = json["top"] as? [[String: Any]] { allItems += top }
                    
                    for item in allItems {
                        if let tmdb = item["tmdbId"] as? Int, tmdb == tmdbID,
                           let slug = item["slug"] as? String { return slug }
                        
                        let enTitle = removeVietnameseDiacritics((item["title"] as? [String: Any])?["en"] as? String ?? "").lowercased()
                        let viTitle = removeVietnameseDiacritics((item["title"] as? [String: Any])?["vi"] as? String ?? "").lowercased()
                        let slug = item["slug"] as? String ?? ""
                        
                        if enTitle.contains(cleanTitle) || cleanTitle.contains(enTitle) ||
                           viTitle.contains(cleanTitle) || cleanTitle.contains(viTitle) {
                            return slug
                        }
                    }
                }
            } catch { continue }
        }
        
        return cleanTitle.replacingOccurrences(of: " ", with: "-")
    }
    
    private func removeVietnameseDiacritics(_ text: String) -> String {
        let diacritics: [Character: String] = [
            "à": "a", "á": "a", "ả": "a", "ã": "a", "ạ": "a",
            "ă": "a", "ằ": "a", "ắ": "a", "ẳ": "a", "ẵ": "a", "ặ": "a",
            "â": "a", "ầ": "a", "ấ": "a", "ẩ": "a", "ẫ": "a", "ậ": "a",
            "è": "e", "é": "e", "ẻ": "e", "ẽ": "e", "ẹ": "e",
            "ê": "e", "ề": "e", "ế": "e", "ể": "e", "ễ": "e", "ệ": "e",
            "ì": "i", "í": "i", "ỉ": "i", "ĩ": "i", "ị": "i",
            "ò": "o", "ó": "o", "ỏ": "o", "õ": "o", "ọ": "o",
            "ô": "o", "ồ": "o", "ố": "o", "ổ": "o", "ỗ": "o", "ộ": "o",
            "ơ": "o", "ờ": "o", "ớ": "o", "ở": "o", "ỡ": "o", "ợ": "o",
            "ù": "u", "ú": "u", "ủ": "u", "ũ": "u", "ụ": "u",
            "ư": "u", "ừ": "u", "ứ": "u", "ử": "u", "ữ": "u", "ự": "u",
            "ỳ": "y", "ý": "y", "ỷ": "y", "ỹ": "y", "ỵ": "y",
            "đ": "d"
        ]
        var result = ""
        for char in text {
            if let replacement = diacritics[char] { result += replacement }
            else { result += String(char) }
        }
        return result
    }
}