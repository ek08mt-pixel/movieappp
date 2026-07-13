import Foundation

struct SkipSegment: Codable {
    let segment: [Double]
    let category: String
    let videoDuration: Double
}

class SponsorBlockService {
    static let shared = SponsorBlockService()
    private let baseURL = "https://sponsor.ajay.app/api/skipSegments"
    
    private var cache: [String: (intro: SkipSegment?, sponsors: [SkipSegment], timestamp: Date)] = [:]
    
    func fetchSegments(imdbID: String, duration: Double) async -> (intro: SkipSegment?, sponsors: [SkipSegment]) {
        if let cached = cache[imdbID], Date().timeIntervalSince(cached.timestamp) < 86400 {
            return (cached.intro, cached.sponsors)
        }
        
        guard let youtubeID = await findYouTubeID(imdbID: imdbID) else {
            print("[SponsorBlock] Không tìm thấy YouTube ID cho \(imdbID)")
            return (nil, [])
        }
        
        print("[SponsorBlock] Tìm thấy YouTube ID: \(youtubeID) cho \(imdbID)")
        
        let urlStr = "\(baseURL)?videoID=\(youtubeID)&categories=[\"sponsor\",\"intro\",\"outro\",\"selfpromo\"]"
        guard let url = URL(string: urlStr) else { return (nil, []) }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let segments = try JSONDecoder().decode([SkipSegment].self, from: data)
            print("[SponsorBlock] Tìm thấy \(segments.count) segments cho \(imdbID)")
            
            let intro = segments.first { $0.category == "intro" }
            let sponsors = segments.filter { $0.category == "sponsor" || $0.category == "selfpromo" }
            
            cache[imdbID] = (intro, sponsors, Date())
            return (intro, sponsors)
        } catch {
            print("[SponsorBlock] Lỗi decode: \(error)")
            return (nil, [])
        }
    }
    
    private func findYouTubeID(imdbID: String) async -> String? {
        // Cách 1: Thử noembed
        if let id = await searchViaNoEmbed(imdbID: imdbID) {
            return id
        }
        
        // Cách 2: Search YouTube bằng tên phim từ IMDB
        if let id = await searchViaYouTubeAPI(imdbID: imdbID) {
            return id
        }
        
        return nil
    }
    
    private func searchViaNoEmbed(imdbID: String) async -> String? {
        guard let url = URL(string: "https://noembed.com/embed?url=https://www.imdb.com/title/\(imdbID)/") else { return nil }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let html = json["html"] as? String {
                // Tìm youtube.com/embed/XXXXX
                if let range = html.range(of: "youtube.com/embed/") {
                    let start = range.upperBound
                    let remaining = String(html[start...])
                    let id = remaining.components(separatedBy: CharacterSet(charactersIn: "?&\""))[0]
                    if id.count == 11 {
                        print("[SponsorBlock] noembed tìm thấy: \(id)")
                        return id
                    }
                }
                // Tìm youtube.com/watch?v=XXXXX
                if let range = html.range(of: "youtube.com/watch?v=") {
                    let start = range.upperBound
                    let remaining = String(html[start...])
                    let id = remaining.components(separatedBy: CharacterSet(charactersIn: "&\""))[0]
                    if id.count == 11 {
                        print("[SponsorBlock] noembed tìm thấy (watch): \(id)")
                        return id
                    }
                }
            }
        } catch {
            print("[SponsorBlock] noembed lỗi: \(error)")
        }
        return nil
    }
    
    private func searchViaYouTubeAPI(imdbID: String) async -> String? {
        // Lấy tên phim từ IMDB để search
        guard let title = await fetchTitleFromIMDB(imdbID: imdbID) else { return nil }
        
        let query = "\(title) official trailer"
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlStr = "https://www.googleapis.com/youtube/v3/search?part=id&q=\(encodedQuery)&type=video&maxResults=5&key=AIzaSyA8eiZmM1FaDVjRy-df2KTyQ_xPjRvMlBg"
        
        guard let url = URL(string: urlStr) else { return nil }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            struct YTResponse: Codable {
                struct Item: Codable {
                    struct ID: Codable { let videoId: String? }
                    let id: ID
                }
                let items: [Item]
            }
            let response = try JSONDecoder().decode(YTResponse.self, from: data)
            if let videoId = response.items.first?.id.videoId {
                print("[SponsorBlock] YouTube API tìm thấy: \(videoId)")
                return videoId
            }
        } catch {
            print("[SponsorBlock] YouTube API lỗi: \(error)")
        }
        return nil
    }
    
    private func fetchTitleFromIMDB(imdbID: String) async -> String? {
        guard let url = URL(string: "https://www.omdbapi.com/?i=\(imdbID)&apikey=8b2f8c0") else { return nil }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let title = json["Title"] as? String {
                return title
            }
        } catch {}
        return nil
    }
}