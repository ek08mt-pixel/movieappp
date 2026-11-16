import Foundation

// MARK: - PhimAPI Episode Counter
final class PhimEpisodeCounter {
    static let shared = PhimEpisodeCounter()
    private init() {}
    
    func fetchEpisodeCount(slug: String, season: Int) async -> Int? {
        guard let url = URL(string: "https://phimapi.com/phim/\(slug)") else { return nil }
        do {
            let (data, _) = try await URLSession.streamSession.data(from: url)
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let episodes = json["episodes"] as? [[String: Any]] else { return nil }
            // Đếm số tập từ server đầu tiên (server thường đủ nhất)
            guard let first = episodes.first,
                  let serverData = first["server_data"] as? [[String: Any]] else { return nil }
            return serverData.count
        } catch { return nil }
    }
}

// MARK: - NguonC Episode Counter
final class NguonCEpisodeCounter {
    static let shared = NguonCEpisodeCounter()
    private init() {}
    
    func fetchEpisodeCount(slug: String, season: Int) async -> Int? {
        guard let url = URL(string: "https://phim.nguonc.com/api/film/\(slug)") else { return nil }
        do {
            let (data, _) = try await URLSession.streamSession.data(from: url)
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let movie = json["movie"] as? [String: Any],
                  let episodes = movie["episodes"] as? [[String: Any]] else { return nil }
            // NguonC trả episodes là mảng server, mỗi server có items
            var maxCount = 0
            for server in episodes {
                if let serverSeason = server["season"] as? Int, serverSeason != season { continue }
                if let seasonName = server["season_name"] as? String {
                    if !seasonName.contains("\(season)") && !seasonName.lowercased().contains("season \(season)") {
                        continue
                    }
                }
                if let items = server["items"] as? [[String: Any]] {
                    if items.count > maxCount { maxCount = items.count }
                }
            }
            return maxCount > 0 ? maxCount : nil
        } catch { return nil }
    }
}

// MARK: - VSMOV Episode Counter
final class VSMOVEEpisodeCounter {
    static let shared = VSMOVEEpisodeCounter()
    private init() {}
    
    func fetchEpisodeCount(slug: String, season: Int) async -> Int? {
        guard let url = URL(string: "https://vsmov.com/api/phim/\(slug)") else { return nil }
        do {
            let (data, _) = try await URLSession.streamSession.data(from: url)
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let episodes = json["episodes"] as? [[String: Any]] else { return nil }
            var maxCount = 0
            for server in episodes {
                if let serverData = server["server_data"] as? [[String: Any]] {
                    if serverData.count > maxCount { maxCount = serverData.count }
                }
            }
            return maxCount > 0 ? maxCount : nil
        } catch { return nil }
    }
}