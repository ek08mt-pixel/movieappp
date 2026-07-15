import Foundation

// MARK: - MappingCache
final class MappingCache {
    static let shared = MappingCache()
    
    private let defaults = UserDefaults.standard
    private let nguonCKey = "cache_nguonc_mapping"
    private let vsmovKey = "cache_vsmov_mapping"
    private let stravoKey = "cache_stravo_mapping"
    private let phimapiKey = "cache_phimapi_mapping"
    private let sofaflixKey = "cache_sofaflix_mapping"
    
    private let hardcodedSlugs: [String: String] = [
        "76669_1": "uu-tu-phan-1",
        "76669_2": "uu-tu-phan-2",
        "76669_3": "uu-tu-phan-3",
        "76669_4": "uu-tu-phan-4",
        "76669_5": "uu-tu-phan-5",
        "76669_6": "uu-tu-phan-6",
        "76669_7": "uu-tu-phan-7",
        "76669_8": "uu-tu-phan-8",
    ]
    
    private init() {}
    
    func getNguonCSlug(imdbID: String) -> String? { dict(for: nguonCKey)[imdbID] }
    func setNguonCSlug(imdbID: String, slug: String) { var d = dict(for: nguonCKey); d[imdbID] = slug; save(d, for: nguonCKey) }
    func getVSMOVSlug(imdbID: String) -> String? { dict(for: vsmovKey)[imdbID] }
    func setVSMOVSlug(imdbID: String, slug: String) { var d = dict(for: vsmovKey); d[imdbID] = slug; save(d, for: vsmovKey) }
    func getStravoURL(imdbID: String, season: Int, episode: Int) -> String? { dict(for: stravoKey)["\(imdbID)_S\(season)E\(episode)"] }
    func setStravoURL(imdbID: String, season: Int, episode: Int, url: String) { var d = dict(for: stravoKey); d["\(imdbID)_S\(season)E\(episode)"] = url; save(d, for: stravoKey) }
    func getPhimAPIURL(tmdbID: Int, season: Int, episode: Int) -> String? { dict(for: phimapiKey)["\(tmdbID)_S\(season)E\(episode)"] }
    func setPhimAPIURL(tmdbID: Int, season: Int, episode: Int, url: String) { var d = dict(for: phimapiKey); d["\(tmdbID)_S\(season)E\(episode)"] = url; save(d, for: phimapiKey) }
    func getSofaflixURL(tmdbID: Int, season: Int, episode: Int) -> String? { dict(for: sofaflixKey)["\(tmdbID)_S\(season)E\(episode)"] }
    func setSofaflixURL(tmdbID: Int, season: Int, episode: Int, url: String) { var d = dict(for: sofaflixKey); d["\(tmdbID)_S\(season)E\(episode)"] = url; save(d, for: sofaflixKey) }
    func getHardcodedSlug(tmdbID: Int, season: Int) -> String? { hardcodedSlugs["\(tmdbID)_\(season)"] }
    private func dict(for key: String) -> [String: String] { defaults.dictionary(forKey: key) as? [String: String] ?? [:] }
    private func save(_ dict: [String: String], for key: String) { defaults.set(dict, forKey: key) }
    func clearAll() { defaults.removeObject(forKey: nguonCKey); defaults.removeObject(forKey: vsmovKey); defaults.removeObject(forKey: stravoKey); defaults.removeObject(forKey: phimapiKey); defaults.removeObject(forKey: sofaflixKey) }
}

// ... toàn bộ phần còn lại giữ nguyên (Error, Helpers, NguonCService, StravoService, VSMOVService)

// MARK: - PhimAPI Service (Emew 1)
final class PhimAPIService {
    static let shared = PhimAPIService()
    private let cache = MappingCache.shared
    private let baseURL = "https://phimapi.com"
    private init() {}
    
    func fetchStream(imdbID: String, tmdbID: Int, title: String, mediaType: String?, season: Int? = nil, episode: Int? = nil, completion: @escaping (Result<URL, Error>) -> Void) {
        let s = season ?? 1; let ep = episode ?? 1
        let isSeries = (mediaType == "tv") || (season != nil)
        
        if let cached = cache.getPhimAPIURL(tmdbID: tmdbID, season: s, episode: ep), let url = URL(string: cached) { completion(.success(url)); return }
        
        if isSeries {
            fallbackSearch(title: title, tmdbID: tmdbID, mediaType: mediaType, season: season, episode: episode, completion: completion)
            return
        }
        
        guard let tmdbURL = URL(string: "\(baseURL)/tmdb/movie/\(tmdbID)") else { completion(.failure(StreamServiceError.invalidURL)); return }
        URLSession.shared.dataTask(with: tmdbURL) { [weak self] data, _, error in
            guard let self = self else { return }
            if let error = error { completion(.failure(error)); return }
            guard let data = data else { completion(.failure(StreamServiceError.noData)); return }
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any], json["status"] as? Bool == true, let movie = json["movie"] as? [String: Any] {
                    let phimType = movie["type"] as? String ?? "single"
                    if let streamURL = self.extractStreamURL(from: json, phimType: phimType, season: nil, episode: nil) {
                        self.cache.setPhimAPIURL(tmdbID: tmdbID, season: 0, episode: 0, url: streamURL.absoluteString)
                        completion(.success(streamURL)); return
                    }
                }
                self.fallbackSearch(title: title, tmdbID: tmdbID, mediaType: mediaType, season: season, episode: episode, completion: completion)
            } catch { self.fallbackSearch(title: title, tmdbID: tmdbID, mediaType: mediaType, season: season, episode: episode, completion: completion) }
        }.resume()
    }
    
    private func fallbackSearch(title: String, tmdbID: Int, mediaType: String?, season: Int?, episode: Int?, completion: @escaping (Result<URL, Error>) -> Void) {
        if let slug = cache.getHardcodedSlug(tmdbID: tmdbID, season: season ?? 1) {
            fetchBySlug(slug: slug, season: season, episode: episode, completion: completion)
            return
        }
        guard let query = title.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { completion(.failure(StreamServiceError.invalidURL)); return }
        
        func fetchPage(_ page: Int, accumulatedItems: [[String: Any]], done: @escaping ([[String: Any]]) -> Void) {
            guard let url = URL(string: "\(baseURL)/v1/api/tim-kiem?keyword=\(query)&limit=20&page=\(page)") else {
                done(accumulatedItems)
                return
            }
            URLSession.shared.dataTask(with: url) { data, _, error in
                guard let data = data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      json["status"] as? String == "success",
                      let dataObj = json["data"] as? [String: Any],
                      let items = dataObj["items"] as? [[String: Any]] else {
                    done(accumulatedItems)
                    return
                }
                let allItems = accumulatedItems + items
                let pagination = dataObj["params"] as? [String: Any] ?? dataObj["pagination"] as? [String: Any] ?? [:]
                let totalPages = pagination["totalPages"] as? Int ?? 1
                if page < totalPages {
                    fetchPage(page + 1, accumulatedItems: allItems, done: done)
                } else {
                    done(allItems)
                }
            }.resume()
        }
        
        fetchPage(1, accumulatedItems: []) { [weak self] allItems in
            guard let self = self else { completion(.failure(StreamServiceError.noData)); return }
            let filteredItems = allItems.filter { !isSpinoff($0) }
            let bestMatch = self.findBestMatch(items: filteredItems, tmdbID: tmdbID, title: title, mediaType: mediaType, season: season)
            if let match = bestMatch, let slug = match["slug"] as? String {
                self.fetchBySlug(slug: slug, season: season, episode: episode, completion: completion)
            } else {
                completion(.failure(StreamServiceError.noMatchFound(id: title)))
            }
        }
    }
    
    private func findBestMatch(items: [[String: Any]], tmdbID: Int, title: String, mediaType: String?, season: Int?) -> [String: Any]? {
        let isSeries = (mediaType == "tv") || (season != nil)
        let normalizedTitle = title.lowercased().trimmingCharacters(in: .whitespaces)
        let targetSeason = season ?? 1
        
        if let exact = items.first(where: {
            ($0["tmdb"] as? [String: Any])?["id"] as? Int == tmdbID &&
            extractSeasonFromOriginName($0["origin_name"] as? String ?? "") == targetSeason
        }) { return exact }
        
        if let seasonMatch = items.first(where: {
            guard isSeriesType($0["type"] as? String ?? "") else { return false }
            let origin = ($0["origin_name"] as? String ?? "").lowercased()
            let s = extractSeasonFromOriginName($0["origin_name"] as? String ?? "")
            return s == targetSeason && origin.contains(normalizedTitle)
        }) { return seasonMatch }
        
        if let exact = items.first(where: {
            ($0["tmdb"] as? [String: Any])?["id"] as? Int == tmdbID &&
            ($0["tmdb"] as? [String: Any])?["season"] as? Int == targetSeason
        }) { return exact }
        
        if isSeries {
            let fallbackMatch = items.first(where: {
                guard isSeriesType($0["type"] as? String ?? "") else { return false }
                let origin = ($0["origin_name"] as? String ?? "").lowercased()
                let s = extractSeasonFromOriginName($0["origin_name"] as? String ?? "")
                return (s == 1 || s == nil) && origin.contains(normalizedTitle)
            })
            if let match = fallbackMatch { return match }
        }
        
        if let sameTMDB = items.first(where: {
            ($0["tmdb"] as? [String: Any])?["id"] as? Int == tmdbID
        }) { return sameTMDB }
        
        if isSeries {
            let matched = items.filter { item in
                guard isSeriesType(item["type"] as? String ?? "") else { return false }
                let origin = (item["origin_name"] as? String ?? "").lowercased()
                return origin.contains(normalizedTitle)
            }
            if !matched.isEmpty { return matched.first }
        }
        
        if let exactName = items.first(where: { ($0["origin_name"] as? String ?? "").lowercased() == normalizedTitle }) { return exactName }
        
        if isSeries { return items.first(where: { isSeriesType($0["type"] as? String ?? "") }) }
        return items.first(where: { isSingleType($0["type"] as? String ?? "") })
    }
    
    private func fetchBySlug(slug: String, season: Int?, episode: Int?, completion: @escaping (Result<URL, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/phim/\(slug)") else { completion(.failure(StreamServiceError.invalidURL)); return }
        URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            guard let self = self else { return }
            if let error = error { completion(.failure(error)); return }
            guard let data = data else { completion(.failure(StreamServiceError.noData)); return }
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    let phimType: String = (json["item"] as? [String: Any])?["type"] as? String ?? (json["movie"] as? [String: Any])?["type"] as? String ?? "single"
                    if let streamURL = self.extractStreamURL(from: json, phimType: phimType, season: season, episode: episode) { completion(.success(streamURL)); return }
                    completion(.failure(StreamServiceError.noStreamURL))
                } else { completion(.failure(StreamServiceError.noData)) }
            } catch { completion(.failure(error)) }
        }.resume()
    }
    
    private func extractStreamURL(from json: [String: Any], phimType: String, season: Int?, episode: Int?) -> URL? {
        if isSeriesType(phimType) {
            let targetSeason = season ?? 1
            let ep = episode ?? 1
            if let episodes = json["episodes"] as? [[String: Any]] {
                var totalEpsInFirstServer = 0
                if let firstServer = episodes.first,
                   let serverData = firstServer["server_data"] as? [[String: Any]] {
                    totalEpsInFirstServer = serverData.count
                }
                let effectiveEp = (totalEpsInFirstServer > 100) ? ((targetSeason - 1) * 49 + ep) : ep
                
                for (serverIndex, server) in episodes.enumerated() {
                    let serverSeason = server["season"] as? Int ?? (serverIndex + 1)
                    if serverSeason != targetSeason && totalEpsInFirstServer <= 100 { continue }
                    if let serverData = server["server_data"] as? [[String: Any]] {
                        for epItem in serverData {
                            if let name = epItem["name"] as? String,
                               let linkM3u8 = epItem["link_m3u8"] as? String,
                               let streamURL = URL(string: linkM3u8),
                               matchEpisode(name: name, target: effectiveEp) {
                                return streamURL
                            }
                        }
                    }
                }
                for server in episodes {
                    if let serverData = server["server_data"] as? [[String: Any]] {
                        for epItem in serverData {
                            if let name = epItem["name"] as? String,
                               let linkM3u8 = epItem["link_m3u8"] as? String,
                               let streamURL = URL(string: linkM3u8),
                               matchEpisode(name: name, target: effectiveEp) {
                                return streamURL
                            }
                        }
                    }
                }
            }
        } else {
            if let episodes = json["episodes"] as? [[String: Any]], let firstEp = (episodes.first?["server_data"] as? [[String: Any]])?.first, let linkM3u8 = firstEp["link_m3u8"] as? String, let streamURL = URL(string: linkM3u8) { return streamURL }
            let movie = json["movie"] as? [String: Any] ?? json["item"] as? [String: Any]
            if let m = movie {
                if let linkM3u8 = m["link_m3u8"] as? String, let streamURL = URL(string: linkM3u8) { return streamURL }
                if let urlStr = m["url"] as? String, let streamURL = URL(string: urlStr) { return streamURL }
            }
        }
        return nil
    }
}

// MARK: - Sofaflix Service (Emew 2)
final class SofaflixService {
    static let shared = SofaflixService()
    private let cache = MappingCache.shared
    private let baseURL = "https://sofaflix.baby"
    private init() {}
    
    func fetchStream(imdbID: String, tmdbID: Int, title: String, mediaType: String?, season: Int? = nil, episode: Int? = nil, completion: @escaping (Result<URL, Error>) -> Void) {
        let s = season ?? 1; let ep = episode ?? 1
        let isSeries = (mediaType == "tv") || (season != nil)
        let type = isSeries ? "tv" : "movie"
        
        if let cached = cache.getSofaflixURL(tmdbID: tmdbID, season: s, episode: ep), let url = URL(string: cached) { completion(.success(url)); return }
        
        guard let tmdbURL = URL(string: "\(baseURL)/api/tmdb/\(type)/\(tmdbID)") else { completion(.failure(StreamServiceError.invalidURL)); return }
        URLSession.shared.dataTask(with: tmdbURL) { [weak self] data, _, error in
            guard let self = self else { return }
            if let error = error { completion(.failure(error)); return }
            guard let data = data else { completion(.failure(StreamServiceError.noData)); return }
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any], json["status"] as? Bool == true {
                    let phimType = (json["movie"] as? [String: Any])?["type"] as? String ?? "single"
                    if let streamURL = self.extractStreamURL(from: json, phimType: phimType, season: season, episode: episode) {
                        self.cache.setSofaflixURL(tmdbID: tmdbID, season: s, episode: ep, url: streamURL.absoluteString)
                        completion(.success(streamURL)); return
                    }
                    completion(.failure(StreamServiceError.noStreamURL))
                } else { completion(.failure(StreamServiceError.noData)) }
            } catch { completion(.failure(error)) }
        }.resume()
    }
    
    private func extractStreamURL(from json: [String: Any], phimType: String, season: Int?, episode: Int?) -> URL? {
        if isSeriesType(phimType) {
            let targetSeason = season ?? 1
            let ep = episode ?? 1
            if let episodes = json["episodes"] as? [[String: Any]] {
                for (serverIndex, server) in episodes.enumerated() {
                    let serverSeason = server["season"] as? Int ?? (serverIndex + 1)
                    if serverSeason != targetSeason { continue }
                    if let serverData = server["server_data"] as? [[String: Any]] {
                        for epItem in serverData {
                            if let name = epItem["name"] as? String,
                               let linkM3u8 = epItem["link_m3u8"] as? String,
                               let streamURL = URL(string: linkM3u8),
                               matchEpisode(name: name, target: ep) {
                                return streamURL
                            }
                        }
                    }
                }
                for server in episodes {
                    if let serverData = server["server_data"] as? [[String: Any]] {
                        for epItem in serverData {
                            if let name = epItem["name"] as? String,
                               let linkM3u8 = epItem["link_m3u8"] as? String,
                               let streamURL = URL(string: linkM3u8),
                               matchEpisode(name: name, target: ep) {
                                return streamURL
                            }
                        }
                    }
                }
            }
        } else {
            if let episodes = json["episodes"] as? [[String: Any]], let firstEp = (episodes.first?["server_data"] as? [[String: Any]])?.first, let linkM3u8 = firstEp["link_m3u8"] as? String, let streamURL = URL(string: linkM3u8) { return streamURL }
            let movie = json["movie"] as? [String: Any]
            if let m = movie {
                if let linkM3u8 = m["link_m3u8"] as? String, let streamURL = URL(string: linkM3u8) { return streamURL }
                if let urlStr = m["url"] as? String, let streamURL = URL(string: urlStr) { return streamURL }
            }
        }
        return nil
    }
}