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
    private func dict(for key: String) -> [String: String] { defaults.dictionary(forKey: key) as? [String: String] ?? [:] }
    private func save(_ dict: [String: String], for key: String) { defaults.set(dict, forKey: key) }
    func clearAll() { defaults.removeObject(forKey: nguonCKey); defaults.removeObject(forKey: vsmovKey); defaults.removeObject(forKey: stravoKey); defaults.removeObject(forKey: phimapiKey); defaults.removeObject(forKey: sofaflixKey) }
}

// MARK: - Error
enum StreamServiceError: LocalizedError {
    case invalidURL, noData, noMatchFound(id: String), imdbIDMismatch(expected: String, got: String), episodeNotFound(ep: String), noStreamURL, notFound(detail: String)
    var errorDescription: String? {
        switch self {
        case .invalidURL: "URL không hợp lệ"
        case .noData: "Không có dữ liệu"
        case .noMatchFound(let id): "Không tìm thấy phim: \(id)"
        case .imdbIDMismatch(let exp, let got): "IMDB ID mismatch: expected \(exp), got \(got)"
        case .episodeNotFound(let ep): "Không tìm thấy tập: \(ep)"
        case .noStreamURL: "Không có stream URL"
        case .notFound(let detail): "Không tìm thấy: \(detail)"
        }
    }
}

// MARK: - Helpers
private func isSeriesType(_ type: String) -> Bool { type == "series" || type == "tv" || type == "hoathinh" }
private func isSingleType(_ type: String) -> Bool { type == "single" || type == "movie" }
private func extractSeasonFromOriginName(_ originName: String) -> Int? {
    for pattern in ["Season (\\d+)", "season (\\d+)", "Phần (\\d+)", "phần (\\d+)"] {
        if let regex = try? NSRegularExpression(pattern: pattern),
           let match = regex.firstMatch(in: originName, range: NSRange(originName.startIndex..., in: originName)),
           let r = Range(match.range(at: 1), in: originName) { return Int(originName[r]) }
    }
    return nil
}

private func matchEpisode(name: String, target: Int) -> Bool {
    let n = name.trimmingCharacters(in: .whitespaces)
    if n == String(format: "Tập %02d", target) { return true }
    if n == String(format: "Tập %d", target) { return true }
    if n == "\(target)" { return true }
    if n.lowercased() == "full" && target == 1 { return true }
    return false
}

// MARK: - NguonC Service
final class NguonCService {
    static let shared = NguonCService()
    private let cache = MappingCache.shared
    private let baseSearchURL = "https://phim.nguonc.com/api/films/search"
    private init() {}
    
    func fetchStream(imdbID: String, title: String, season: Int? = nil, episode: Int? = nil, completion: @escaping (Result<URL, Error>) -> Void) {
        if let cachedSlug = cache.getNguonCSlug(imdbID: imdbID) { fetchDetail(slug: cachedSlug, season: season, episode: episode, completion: completion); return }
        searchFilms(keyword: title) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let films): self.matchByDetail(films: films, imdbID: imdbID, season: season, episode: episode, completion: completion)
            case .failure(let error): completion(.failure(error))
            }
        }
    }
    
    private func matchByDetail(films: [NguonCFilm], imdbID: String, season: Int?, episode: Int?, completion: @escaping (Result<URL, Error>) -> Void) {
        let group = DispatchGroup(); var foundURL: URL?; var foundError: Error?
        for film in films.prefix(5) {
            guard let slug = film.slug else { continue }
            group.enter()
            fetchDetail(slug: slug, season: season, episode: episode) { result in
                switch result { case .success(let url): foundURL = url; case .failure(let error): if foundError == nil { foundError = error } }
                group.leave()
            }
            if foundURL != nil { break }
        }
        group.notify(queue: .main) {
            if let url = foundURL { self.cache.setNguonCSlug(imdbID: imdbID, slug: films.first?.slug ?? ""); completion(.success(url)) }
            else { completion(.failure(foundError ?? StreamServiceError.noMatchFound(id: imdbID))) }
        }
    }
    
    private func fetchDetail(slug: String, season: Int?, episode: Int?, completion: @escaping (Result<URL, Error>) -> Void) {
        guard let url = URL(string: "https://phim.nguonc.com/api/film/\(slug)") else { completion(.failure(StreamServiceError.invalidURL)); return }
        URLSession.shared.dataTask(with: url) { data, _, error in
            if let error = error { completion(.failure(error)); return }
            guard let data = data else { completion(.failure(StreamServiceError.noData)); return }
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any], json["status"] as? String == "success", let movie = json["movie"] as? [String: Any] {
                    if let s = season, let e = episode {
                        if let episodes = movie["episodes"] as? [[String: Any]] {
                            for server in episodes {
                                if let items = server["items"] as? [[String: Any]] {
                                    for item in items {
                                        if let name = item["name"] as? String, let embed = item["embed"] as? String, let embedURL = URL(string: embed), (name.lowercased() == "full" || Int(name) == e) { completion(.success(embedURL)); return }
                                    }
                                }
                            }
                        }
                        completion(.failure(StreamServiceError.episodeNotFound(ep: "S\(s)E\(e)")))
                    } else {
                        if let embed = movie["embed"] as? String, let embedURL = URL(string: embed) { completion(.success(embedURL)) }
                        else { completion(.failure(StreamServiceError.noStreamURL)) }
                    }
                } else { completion(.failure(StreamServiceError.noData)) }
            } catch { completion(.failure(error)) }
        }.resume()
    }
    
    private func searchFilms(keyword: String, completion: @escaping (Result<[NguonCFilm], Error>) -> Void) {
        guard let query = keyword.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed), let url = URL(string: "\(baseSearchURL)?keyword=\(query)") else { completion(.failure(StreamServiceError.invalidURL)); return }
        URLSession.shared.dataTask(with: url) { data, _, error in
            if let error = error { completion(.failure(error)); return }
            guard let data = data else { completion(.failure(StreamServiceError.noData)); return }
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any], let items = json["items"] as? [[String: Any]] {
                    let films = items.compactMap { item -> NguonCFilm? in
                        guard let name = item["name"] as? String, let slug = item["slug"] as? String else { return nil }
                        return NguonCFilm(id: 0, name: name, slug: slug, posterUrl: nil, type: nil)
                    }
                    completion(.success(films))
                } else { completion(.success([])) }
            } catch { completion(.failure(error)) }
        }.resume()
    }
}

// MARK: - Stravo Service
final class StravoService {
    static let shared = StravoService()
    private let cache = MappingCache.shared
    private init() {}
    
    func fetchStream(imdbID: String, season: Int? = nil, episode: Int? = nil, completion: @escaping (Result<URL, Error>) -> Void) {
        let urlString: String
        if let s = season, let e = episode {
            urlString = "https://stravo-clfk.onrender.com/auto/stream/series/\(imdbID):\(s):\(e).json"
            if let cached = cache.getStravoURL(imdbID: imdbID, season: s, episode: e), let url = URL(string: cached) { completion(.success(url)); return }
        } else { urlString = "https://stravo-clfk.onrender.com/auto/stream/movie/\(imdbID).json" }
        guard let url = URL(string: urlString) else { completion(.failure(StreamServiceError.invalidURL)); return }
        URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            guard let self = self else { return }
            if let error = error { completion(.failure(error)); return }
            guard let data = data else { completion(.failure(StreamServiceError.noData)); return }
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    if let detail = json["detail"] as? String { completion(.failure(StreamServiceError.notFound(detail: detail))); return }
                    if let streams = json["streams"] as? [[String: Any]], let streamURLString = streams.first?["url"] as? String, let streamURL = URL(string: streamURLString) {
                        if let s = season, let e = episode { self.cache.setStravoURL(imdbID: imdbID, season: s, episode: e, url: streamURLString) }
                        completion(.success(streamURL)); return
                    }
                    if let streamURLString = json["url"] as? String, let streamURL = URL(string: streamURLString) {
                        if let s = season, let e = episode { self.cache.setStravoURL(imdbID: imdbID, season: s, episode: e, url: streamURLString) }
                        completion(.success(streamURL)); return
                    }
                }
                completion(.failure(StreamServiceError.noStreamURL))
            } catch { completion(.failure(error)) }
        }.resume()
    }
}

// MARK: - VSMOV Service
final class VSMOVService {
    static let shared = VSMOVService()
    private let cache = MappingCache.shared
    private let baseSearchURL = "https://vsmov.com/api/tim-kiem"
    private init() {}
    
    func fetchStream(imdbID: String, title: String, season: Int? = nil, episode: Int? = nil, completion: @escaping (Result<URL, Error>) -> Void) {
        if let cachedSlug = cache.getVSMOVSlug(imdbID: imdbID) { fetchVSMOVDetail(slug: cachedSlug, season: season, episode: episode, completion: completion); return }
        guard let query = title.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed), let url = URL(string: "\(baseSearchURL)?keyword=\(query)") else { completion(.failure(StreamServiceError.invalidURL)); return }
        URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            guard let self = self else { return }
            if let error = error { completion(.failure(error)); return }
            guard let data = data else { completion(.failure(StreamServiceError.noData)); return }
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any], let items = json["items"] as? [[String: Any]] {
                    if let matched = items.first(where: { ($0["imdb"] as? [String: Any])?["id"] as? String == imdbID }), let slug = matched["slug"] as? String {
                        self.cache.setVSMOVSlug(imdbID: imdbID, slug: slug); self.fetchVSMOVDetail(slug: slug, season: season, episode: episode, completion: completion); return
                    }
                    if let firstSlug = items.first?["slug"] as? String { self.cache.setVSMOVSlug(imdbID: imdbID, slug: firstSlug); self.fetchVSMOVDetail(slug: firstSlug, season: season, episode: episode, completion: completion); return }
                }
                completion(.failure(StreamServiceError.noMatchFound(id: imdbID)))
            } catch { completion(.failure(error)) }
        }.resume()
    }
    
    private func fetchVSMOVDetail(slug: String, season: Int?, episode: Int?, completion: @escaping (Result<URL, Error>) -> Void) {
        guard let url = URL(string: "https://vsmov.com/api/phim/\(slug)") else { completion(.failure(StreamServiceError.invalidURL)); return }
        URLSession.shared.dataTask(with: url) { data, _, error in
            if let error = error { completion(.failure(error)); return }
            guard let data = data else { completion(.failure(StreamServiceError.noData)); return }
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    if let s = season, let e = episode {
                        if let episodes = json["episodes"] as? [[String: Any]] {
                            for server in episodes {
                                if let serverData = server["server_data"] as? [[String: Any]] {
                                    for ep in serverData {
                                        if let name = ep["name"] as? String, let link = ep["link_embed"] as? String, matchEpisode(name: name, target: e) {
                                            let m3u8 = link.hasSuffix("/") ? "\(link)master-b2.m3u8" : "\(link)/master-b2.m3u8"
                                            if let streamURL = URL(string: m3u8) { completion(.success(streamURL)); return }
                                        }
                                    }
                                }
                            }
                        }
                        completion(.failure(StreamServiceError.episodeNotFound(ep: "S\(s)E\(e)")))
                    } else {
                        if let urlStr = json["url"] as? String, let streamURL = URL(string: urlStr) { completion(.success(streamURL)) }
                        else if let m3u8 = json["m3u8"] as? String, let streamURL = URL(string: m3u8) { completion(.success(streamURL)) }
                        else { completion(.failure(StreamServiceError.noStreamURL)) }
                    }
                } else { completion(.failure(StreamServiceError.noStreamURL)) }
            } catch { completion(.failure(error)) }
        }.resume()
    }
}

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
        guard let query = title.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed), let url = URL(string: "\(baseURL)/v1/api/tim-kiem?keyword=\(query)&limit=20") else { completion(.failure(StreamServiceError.invalidURL)); return }
        URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            guard let self = self else { return }
            if let error = error { completion(.failure(error)); return }
            guard let data = data else { completion(.failure(StreamServiceError.noData)); return }
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any], json["status"] as? String == "success", let dataObj = json["data"] as? [String: Any], let items = dataObj["items"] as? [[String: Any]] {
                    let bestMatch = self.findBestMatch(items: items, tmdbID: tmdbID, title: title, mediaType: mediaType, season: season)
                    if let match = bestMatch, let slug = match["slug"] as? String { self.fetchBySlug(slug: slug, season: season, episode: episode, completion: completion) }
                    else { completion(.failure(StreamServiceError.noMatchFound(id: title))) }
                } else { completion(.failure(StreamServiceError.noMatchFound(id: title))) }
            } catch { completion(.failure(error)) }
        }.resume()
    }
    
    private func findBestMatch(items: [[String: Any]], tmdbID: Int, title: String, mediaType: String?, season: Int?) -> [String: Any]? {
        let isSeries = (mediaType == "tv") || (season != nil)
        let normalizedTitle = title.lowercased().trimmingCharacters(in: .whitespaces)
        let targetSeason = season ?? 1
        
        if let exact = items.first(where: {
            ($0["tmdb"] as? [String: Any])?["id"] as? Int == tmdbID &&
            ($0["tmdb"] as? [String: Any])?["season"] as? Int == targetSeason
        }) { return exact }
        
        if let same = items.first(where: {
            ($0["tmdb"] as? [String: Any])?["id"] as? Int == tmdbID &&
            extractSeasonFromOriginName($0["origin_name"] as? String ?? "") == targetSeason
        }) { return same }
        
        if isSeries {
            let matched = items.filter { item in
                guard isSeriesType(item["type"] as? String ?? "") else { return false }
                let origin = (item["origin_name"] as? String ?? "").lowercased()
                let s = extractSeasonFromOriginName(item["origin_name"] as? String ?? "")
                return s == targetSeason && origin.contains(normalizedTitle)
            }
            if !matched.isEmpty {
                if let orig = matched.first(where: { ($0["tmdb"] as? [String: Any])?["id"] == nil }) { return orig }
                return matched.first
            }
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
                // SỬA LỖI 2: Lọc server theo season trước khi tìm episode
                for server in episodes {
                    let serverSeason = server["season"] as? Int ?? targetSeason
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
                // Fallback: không lọc season
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
                // SỬA LỖI 2: Lọc server theo season trước khi tìm episode
                for server in episodes {
                    let serverSeason = server["season"] as? Int ?? targetSeason
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
                // Fallback: không lọc season
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