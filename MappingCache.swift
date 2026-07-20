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
    
    static let animeSlugs: [Int: String] = [
        37854: "dao-hai-tac",
        23868: "doraemon-tuyen-tap-moi-nhat",
        14091: "tham-tu-lung-danh-conan",
        46261: "hoi-phap-su-phan-1",
        57041: "linh-hon-bac-phan-1",
    ]
    
    static let directSlugs: [String: String] = [
        "111110_1": "dao-hai-tac-live-action-phan-1",
        "111110_2": "dao-hai-tac-live-action-phan-2",
        "222624_1": "gintama-thay-ginpachi-o-lop-3z",
"46261_1": "hoi-phap-su-phan-1",
"46261_2": "hoi-phap-su-phan-1",
"46261_3": "hoi-phap-su-phan-1",
"46261_4": "hoi-phap-su-phan-1",
"46261_5": "hoi-phap-su-phan-2",
"46261_6": "hoi-phap-su-phan-3",
"46261_7": "hoi-phap-su-phan-3",
"46261_8": "hoi-phap-su-phan-4",
        "4607_1": "mat-tich-phan-1",
"4607_2": "mat-tich-phan-2",
"4607_3": "mat-tich-phan-3",
"4607_4": "mat-tich-phan-4",
"4607_5": "mat-tich-phan-5",
"4607_6": "mat-tich-phan-6",
"18165_1": "nhat-ky-ma-ca-rong-phan-1",
"18165_2": "nhat-ky-ma-ca-rong-phan-2",
"18165_3": "nhat-ky-ma-ca-rong-phan-3",
"18165_4": "nhat-ky-ma-ca-rong-phan-4",
"18165_5": "nhat-ky-ma-ca-rong-phan-5",
"18165_6": "nhat-ky-ma-ca-rong-phan-6",
"18165_7": "nhat-ky-ma-ca-rong-phan-7",
"18165_8": "nhat-ky-ma-ca-rong-phan-8",
"124364_1": "thi-tran-ac-mong-hoi-chuong-la-phan-1",
"124364_2": "thi-tran-ac-mong-hoi-chuong-la-phan-2",
"124364_3": "thi-tran-ac-mong-hoi-chuong-la-phan-3",
"124364_4": "thi-tran-ac-mong-hoi-chuong-la-phan-4",
"1668_1": "nhung-nguoi-ban-phan-1",
"1668_2": "nhung-nguoi-ban-phan-2",
"1668_3": "nhung-nguoi-ban-phan-3",
"1668_4": "nhung-nguoi-ban-phan-4",
"1668_5": "nhung-nguoi-ban-phan-5",
"1668_6": "nhung-nguoi-ban-phan-6",
"1668_7": "nhung-nguoi-ban-phan-7",
"1668_8": "nhung-nguoi-ban-phan-8",
"1668_9": "nhung-nguoi-ban-phan-9",
"1668_10": "nhung-nguoi-ban-phan-10",
"103411_1": "mau-va-nuoc-phan-1",
"103411_2": "mau-va-nuoc-phan-2",
"103411_3": "mau-va-nuoc-phan-3",
"103411_4": "mau-va-nuoc-phan-4",
"57041_1": "linh-hon-bac-phan-1",
"57041_2": "linh-hon-bac-phan-1",
"57041_3": "linh-hon-bac-phan-1",
"57041_4": "linh-hon-bac-phan-1",
"57041_5": "linh-hon-bac-phan-5",
"2942_1": "vuong-trieu-tudors-phan-1",
"2942_2": "vuong-trieu-tudors-phan-2",
"2942_3": "vuong-trieu-tudors-phan-3",
"2942_4": "vuong-trieu-tudors-phan-4",
    ]
    
    static func getAnimeSlug(tmdbID: Int) -> String? { animeSlugs[tmdbID] }
    static func getDirectSlug(tmdbID: Int, season: Int = 1) -> String? { directSlugs["\(tmdbID)_\(season)"] }
    static func isLongRunningAnime(tmdbID: Int) -> Bool { animeSlugs[tmdbID] != nil }
    static func hasDirectSlug(tmdbID: Int, season: Int = 1) -> Bool { directSlugs["\(tmdbID)_\(season)"] != nil }
    
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
    func dict(for key: String) -> [String: String] { defaults.dictionary(forKey: key) as? [String: String] ?? [:] }
    func save(_ dict: [String: String], for key: String) { defaults.set(dict, forKey: key) }
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

private func isSpinoff(_ item: [String: Any]) -> Bool {
    let origin = (item["origin_name"] as? String ?? "").lowercased()
    let name = (item["name"] as? String ?? "").lowercased()
    let spinoffKeywords = ["ginpachi", "3-z", "3z", "spin-off", "spinoff", "movie", "live action"]
    for kw in spinoffKeywords { if origin.contains(kw) || name.contains(kw) { return true } }
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
                
                var embedURL: URL?
                
                if let s = season, let e = episode {
                    if let episodes = movie["episodes"] as? [[String: Any]] {
                        for server in episodes {
                            if let items = server["items"] as? [[String: Any]] {
                                for item in items {
                                    if let name = item["name"] as? String, let embed = item["embed"] as? String, (name.lowercased() == "full" || Int(name) == e) {
                                        embedURL = URL(string: embed)
                                        break
                                    }
                                }
                            }
                        }
                    }
                } else {
                    if let embed = movie["embed"] as? String { embedURL = URL(string: embed) }
                }
                
                guard let embed = embedURL else { completion(.failure(StreamServiceError.noStreamURL)); return }
                
                // Dùng WebView extractor (ổn định hơn)
                DispatchQueue.main.async {
                    let extractor = StreamExtractorWebView()
                    extractor.extract(from: embed) { streamURL in
                        if let url = streamURL { completion(.success(URL(string: proxyStreamURL(url.absoluteString))!)) }
                        } else {
                            completion(.success(URL(string: proxyStreamURL(embed.absoluteString))!))
                        }
                    }
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
                                            if let streamURL = URL(string: proxyStreamURL(m3u8)) { completion(.success(streamURL)); return }
                                        }
                                    }
                                }
                            }
                        }
                        completion(.failure(StreamServiceError.episodeNotFound(ep: "S\(s)E\(e)")))
                    } else {
                        if let urlStr = json["url"] as? String, let streamURL = URL(string: proxyStreamURL(urlStr)) { completion(.success(streamURL)) }
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
    
    func fetchStream(imdbID: String, tmdbID: Int, title: String, mediaType: String?, season: Int? = nil, episode: Int? = nil, serverIndex: Int = 0, completion: @escaping (Result<(URL, [String]), Error>) -> Void) {
        let s = season ?? 1; let ep = episode ?? 1
        let isSeries = (mediaType == "tv") || (season != nil)
        let cacheKey = "\(tmdbID)_S\(s)E\(ep)_server\(serverIndex)"
        
        if !MappingCache.hasDirectSlug(tmdbID: tmdbID, season: s),
           let cached = cache.dict(for: "phimapi_stream_cache")[cacheKey],
           let url = URL(string: cached) {
            completion(.success((url, [])))
            return
        }
        
        if isSeries {
            fallbackSearch(title: title, tmdbID: tmdbID, mediaType: mediaType, season: s, episode: ep, serverIndex: serverIndex, completion: completion)
            return
        }
        
        guard let tmdbURL = URL(string: "\(baseURL)/tmdb/movie/\(tmdbID)") else { completion(.failure(StreamServiceError.invalidURL)); return }
        URLSession.shared.dataTask(with: tmdbURL) { [weak self] data, _, error in
            guard let self = self else { return }
            if let error = error { completion(.failure(error)); return }
            guard let data = data else { completion(.failure(StreamServiceError.noData)); return }
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any], json["status"] as? Bool == true {
                    let phimType = (json["movie"] as? [String: Any])?["type"] as? String ?? "single"
                    let result = self.extractStreamURLWithServers(from: json, phimType: phimType, season: nil, episode: nil, serverIndex: serverIndex, tmdbID: tmdbID)
                    if let streamURL = result.url {
                        self.cache.save(["\(cacheKey)": streamURL.absoluteString], for: "phimapi_stream_cache")
                        completion(.success((streamURL, result.servers)))
                        return
                    }
                }
                self.fallbackSearch(title: title, tmdbID: tmdbID, mediaType: mediaType, season: s, episode: ep, serverIndex: serverIndex, completion: completion)
            } catch { self.fallbackSearch(title: title, tmdbID: tmdbID, mediaType: mediaType, season: s, episode: ep, serverIndex: serverIndex, completion: completion) }
        }.resume()
    }
    
    private func fallbackSearch(title: String, tmdbID: Int, mediaType: String?, season: Int?, episode: Int?, serverIndex: Int, completion: @escaping (Result<(URL, [String]), Error>) -> Void) {
        if let directSlug = MappingCache.getDirectSlug(tmdbID: tmdbID, season: season ?? 1) {
            fetchBySlug(slug: directSlug, season: season, episode: episode, serverIndex: serverIndex, tmdbID: tmdbID, completion: completion)
            return
        }
        
        if MappingCache.isLongRunningAnime(tmdbID: tmdbID), let animeSlug = MappingCache.getAnimeSlug(tmdbID: tmdbID) {
            fetchBySlug(slug: animeSlug, season: season, episode: episode, serverIndex: serverIndex, tmdbID: tmdbID, completion: completion)
            return
        }
        
        if let slug = cache.getHardcodedSlug(tmdbID: tmdbID, season: season ?? 1) {
            fetchBySlug(slug: slug, season: season, episode: episode, serverIndex: serverIndex, tmdbID: tmdbID, completion: completion)
            return
        }
        
        guard let query = title.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { completion(.failure(StreamServiceError.invalidURL)); return }
        
        func fetchPage(_ page: Int, accumulatedItems: [[String: Any]], done: @escaping ([[String: Any]]) -> Void) {
            guard let url = URL(string: "\(baseURL)/v1/api/tim-kiem?keyword=\(query)&limit=20&page=\(page)") else { done(accumulatedItems); return }
            URLSession.shared.dataTask(with: url) { data, _, error in
                guard let data = data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      json["status"] as? String == "success",
                      let dataObj = json["data"] as? [String: Any],
                      let items = dataObj["items"] as? [[String: Any]] else { done(accumulatedItems); return }
                let all = accumulatedItems + items
                let pagination = dataObj["params"] as? [String: Any] ?? dataObj["pagination"] as? [String: Any] ?? [:]
                let totalPages = pagination["totalPages"] as? Int ?? 1
                if page < totalPages { fetchPage(page + 1, accumulatedItems: all, done: done) }
                else { done(all) }
            }.resume()
        }
        
        fetchPage(1, accumulatedItems: []) { [weak self] allItems in
            guard let self = self else { completion(.failure(StreamServiceError.noData)); return }
            let filtered = allItems.filter { !isSpinoff($0) }
            let bestMatch = self.findBestMatch(items: filtered, tmdbID: tmdbID, title: title, mediaType: mediaType, season: season)
            if let match = bestMatch, let slug = match["slug"] as? String {
                self.fetchBySlug(slug: slug, season: season, episode: episode, serverIndex: serverIndex, tmdbID: tmdbID, completion: completion)
            } else {
                completion(.failure(StreamServiceError.noMatchFound(id: title)))
            }
        }
    }
    
    private func fetchBySlug(slug: String, season: Int?, episode: Int?, serverIndex: Int, tmdbID: Int, completion: @escaping (Result<(URL, [String]), Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/phim/\(slug)") else { completion(.failure(StreamServiceError.invalidURL)); return }
        URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            guard let self = self else { return }
            if let error = error { completion(.failure(error)); return }
            guard let data = data else { completion(.failure(StreamServiceError.noData)); return }
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    let phimType: String = (json["item"] as? [String: Any])?["type"] as? String ?? (json["movie"] as? [String: Any])?["type"] as? String ?? "single"
                    let result = self.extractStreamURLWithServers(from: json, phimType: phimType, season: season, episode: episode, serverIndex: serverIndex, tmdbID: tmdbID)
                    if let streamURL = result.url {
                        completion(.success((streamURL, result.servers)))
                    } else {
                        completion(.failure(StreamServiceError.noStreamURL))
                    }
                } else { completion(.failure(StreamServiceError.noData)) }
            } catch { completion(.failure(error)) }
        }.resume()
    }
    
    private func extractStreamURLWithServers(from json: [String: Any], phimType: String, season: Int?, episode: Int?, serverIndex: Int, tmdbID: Int = 0) -> (url: URL?, servers: [String]) {
        var serverNames: [String] = []
        if let episodes = json["episodes"] as? [[String: Any]] {
            for server in episodes {
                if let name = server["server_name"] as? String { serverNames.append(name) }
            }
        }
        
        if isSeriesType(phimType) {
            let targetSeason = season ?? 1
            let ep = episode ?? 1
            if let episodes = json["episodes"] as? [[String: Any]] {
                var totalEpsInFirstServer = 0
                if let firstServer = episodes.first, let serverData = firstServer["server_data"] as? [[String: Any]] { totalEpsInFirstServer = serverData.count }
                
                var effectiveEp: Int
                if MappingCache.isLongRunningAnime(tmdbID: tmdbID) {
                    effectiveEp = ep
                    if tmdbID == 46261 {
    switch targetSeason {
    case 1: effectiveEp = ep
    case 2: effectiveEp = 48 + ep
    case 3: effectiveEp = 96 + ep
    case 4: effectiveEp = 150 + ep
    default: effectiveEp = ep
    }
}
    if tmdbID == 57041 {
    switch targetSeason {
    case 2: effectiveEp = 49 + ep
    case 3: effectiveEp = 99 + ep
    case 4: effectiveEp = 150 + ep
    default: effectiveEp = ep
    }
}
                } else {
                    effectiveEp = (totalEpsInFirstServer > 100) ? ((targetSeason - 1) * 49 + ep) : ep
                }
                
                for server in episodes {
                    if let serverData = server["server_data"] as? [[String: Any]] {
                        for epItem in serverData {
                            if let name = epItem["name"] as? String, let linkM3u8 = epItem["link_m3u8"] as? String, let streamURL = URL(string: linkM3u8), matchEpisode(name: name, target: effectiveEp) {
                                return (streamURL, serverNames)
                            }
                        }
                    }
                }
            }
        } else {
            if let episodes = json["episodes"] as? [[String: Any]], let firstEp = (episodes.first?["server_data"] as? [[String: Any]])?.first, let linkM3u8 = firstEp["link_m3u8"] as? String, let streamURL = URL(string: linkM3u8) { return (streamURL, serverNames) }
            let movie = json["movie"] as? [String: Any] ?? json["item"] as? [String: Any]
            if let m = movie {
                if let linkM3u8 = epItem["link_m3u8"] as? String, let streamURL = URL(string: proxyStreamURL(linkM3u8))
                if let urlStr = m["url"] as? String, let streamURL = URL(string: urlStr) { return (streamURL, serverNames) }
            }
        }
        return (nil, serverNames)
    }
    
    private func findBestMatch(items: [[String: Any]], tmdbID: Int, title: String, mediaType: String?, season: Int?) -> [String: Any]? {
        let isSeries = (mediaType == "tv") || (season != nil)
        let normalizedTitle = title.lowercased().trimmingCharacters(in: .whitespaces)
        let targetSeason = season ?? 1
        let isLongAnime = MappingCache.isLongRunningAnime(tmdbID: tmdbID)
        
        var searchItems = items
        if isLongAnime {
            let filtered = items.filter { ($0["type"] as? String) == "hoathinh" }
            if !filtered.isEmpty { searchItems = filtered }
        }
        
        if let exact = searchItems.first(where: { ($0["tmdb"] as? [String: Any])?["id"] as? Int == tmdbID && extractSeasonFromOriginName($0["origin_name"] as? String ?? "") == targetSeason }) { return exact }
        if let seasonMatch = searchItems.first(where: { guard isSeriesType($0["type"] as? String ?? "") else { return false }; return extractSeasonFromOriginName($0["origin_name"] as? String ?? "") == targetSeason && ($0["origin_name"] as? String ?? "").lowercased().contains(normalizedTitle) }) { return seasonMatch }
        if let exact = searchItems.first(where: { ($0["tmdb"] as? [String: Any])?["id"] as? Int == tmdbID && ($0["tmdb"] as? [String: Any])?["season"] as? Int == targetSeason }) { return exact }
        if let sameTMDB = searchItems.first(where: { ($0["tmdb"] as? [String: Any])?["id"] as? Int == tmdbID }) { return sameTMDB }
        if let exactName = searchItems.first(where: { ($0["origin_name"] as? String ?? "").lowercased() == normalizedTitle }) { return exactName }
        if isSeries { return searchItems.first(where: { isSeriesType($0["type"] as? String ?? "") }) }
        return searchItems.first(where: { isSingleType($0["type"] as? String ?? "") })
    }
}

// MARK: - Ophim Service (New)
final class OphimService {
    static let shared = OphimService()
    private let baseURL = "https://ophim1.com/v1/api"
    private init() {}
    
    func fetchStream(title: String, season: Int?, episode: Int?, completion: @escaping (Result<URL, Error>) -> Void) {
        let ep = episode ?? 1
        let searchQuery = title.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? title
        guard let searchURL = URL(string: "\(baseURL)/tim-kiem?keyword=\(searchQuery)") else { completion(.failure(StreamServiceError.invalidURL)); return }
        URLSession.shared.dataTask(with: searchURL) { [weak self] data, _, error in
            guard let self = self else { return }
            if let error = error { completion(.failure(error)); return }
            guard let data = data else { completion(.failure(StreamServiceError.noData)); return }
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let status = json["status"] as? String, status == "success",
                   let dataObj = json["data"] as? [String: Any],
                   let items = dataObj["items"] as? [[String: Any]] {
                    var bestMatch: [String: Any]?
                    let lowerTitle = title.lowercased().trimmingCharacters(in: .whitespaces)
                    for item in items {
                        let name = (item["name"] as? String ?? "").lowercased().trimmingCharacters(in: .whitespaces)
                        let origin = (item["origin_name"] as? String ?? "").lowercased().trimmingCharacters(in: .whitespaces)
                        if origin == lowerTitle || name == lowerTitle { bestMatch = item; break }
                    }
                    if bestMatch == nil {
                        for item in items {
                            let name = (item["name"] as? String ?? "").lowercased()
                            let origin = (item["origin_name"] as? String ?? "").lowercased()
                            if origin.contains(lowerTitle) || name.contains(lowerTitle) || lowerTitle.contains(origin) { bestMatch = item; break }
                        }
                    }
                    if let slug = bestMatch?["slug"] as? String {
                        self.fetchDetail(slug: slug, episode: ep, completion: completion)
                    } else {
                        completion(.failure(StreamServiceError.noMatchFound(id: title)))
                    }
                } else {
                    completion(.failure(StreamServiceError.noMatchFound(id: title)))
                }
            } catch { completion(.failure(error)) }
        }.resume()
    }
    
    private func fetchDetail(slug: String, episode: Int, completion: @escaping (Result<URL, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/phim/\(slug)") else { completion(.failure(StreamServiceError.invalidURL)); return }
        URLSession.shared.dataTask(with: url) { data, _, error in
            if let error = error { completion(.failure(error)); return }
            guard let data = data else { completion(.failure(StreamServiceError.noData)); return }
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   json["status"] as? String == "success",
                   let movie = json["data"] as? [String: Any],
                   let episodes = movie["episodes"] as? [[String: Any]] {
                    for server in episodes {
                        if let serverData = server["server_data"] as? [[String: Any]] {
                            for epItem in serverData {
                                if let name = epItem["name"] as? String,
   let linkM3u8 = epItem["link_m3u8"] as? String,
   let streamURL = URL(string: proxyStreamURL(linkM3u8)),
   matchEpisode(name: name, target: episode) {
                                    completion(.success(streamURL))
                                    return
                                }
                            }
                        }
                    }
                    completion(.failure(StreamServiceError.episodeNotFound(ep: "\(episode)")))
                } else {
                    completion(.failure(StreamServiceError.noData))
                }
            } catch { completion(.failure(error)) }
        }.resume()
    }
}
// MARK: - Stream Proxy
func proxyStreamURL(_ originalURL: String) -> String {
    return "https://emmewchamchi.pnbhan99.workers.dev/?url=\(originalURL.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? originalURL)"
}