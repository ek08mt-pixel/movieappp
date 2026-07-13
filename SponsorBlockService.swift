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
            return (nil, [])
        }
        
        let urlStr = "\(baseURL)?videoID=\(youtubeID)&categories=[\"sponsor\",\"intro\",\"outro\",\"selfpromo\"]"
        guard let url = URL(string: urlStr) else { return (nil, []) }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let segments = try JSONDecoder().decode([SkipSegment].self, from: data)
            
            let intro = segments.first { $0.category == "intro" }
            let sponsors = segments.filter { $0.category == "sponsor" || $0.category == "selfpromo" }
            
            cache[imdbID] = (intro, sponsors, Date())
            return (intro, sponsors)
        } catch {
            return (nil, [])
        }
    }
    
    private func findYouTubeID(imdbID: String) async -> String? {
        guard let url = URL(string: "https://noembed.com/embed?url=https://www.imdb.com/title/\(imdbID)/") else { return nil }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let html = json["html"] as? String,
               html.contains("youtube.com/embed/") {
                let components = html.components(separatedBy: "youtube.com/embed/")
                if components.count > 1 {
                    let idPart = components[1].components(separatedBy: "?")[0]
                    let id = String(idPart.prefix(11))
                    return id.isEmpty ? nil : id
                }
            }
        } catch {}
        
        return nil
    }
}