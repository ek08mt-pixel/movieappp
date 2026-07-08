import Foundation

// MARK: - MappingCache
final class MappingCache {
    static let shared = MappingCache()
    
    private let defaults = UserDefaults.standard
    private let nguonCKey = "cache_nguonc_mapping"
    private let vsmovKey = "cache_vsmov_mapping"
    private let stravoKey = "cache_stravo_mapping"
    
    private init() {}
    
    func getNguonCSlug(imdbID: String) -> String? { dict(for: nguonCKey)[imdbID] }
    func setNguonCSlug(imdbID: String, slug: String) {
        var d = dict(for: nguonCKey); d[imdbID] = slug; save(d, for: nguonCKey)
    }
    
    func getVSMOVSlug(imdbID: String) -> String? { dict(for: vsmovKey)[imdbID] }
    func setVSMOVSlug(imdbID: String, slug: String) {
        var d = dict(for: vsmovKey); d[imdbID] = slug; save(d, for: vsmovKey)
    }
    
    func getStravoURL(imdbID: String, season: Int, episode: Int) -> String? {
        dict(for: stravoKey)["\(imdbID)_S\(season)E\(episode)"]
    }
    func setStravoURL(imdbID: String, season: Int, episode: Int, url: String) {
        var d = dict(for: stravoKey)
        d["\(imdbID)_S\(season)E\(episode)"] = url
        save(d, for: stravoKey)
    }
    
    private func dict(for key: String) -> [String: String] {
        defaults.dictionary(forKey: key) as? [String: String] ?? [:]
    }
    private func save(_ dict: [String: String], for key: String) {
        defaults.set(dict, forKey: key)
    }
    func clearAll() {
        defaults.removeObject(forKey: nguonCKey)
        defaults.removeObject(forKey: vsmovKey)
        defaults.removeObject(forKey: stravoKey)
    }
}

// MARK: - Error
enum NguonCServiceError: LocalizedError {
    case invalidURL, noData
    case noMatchFound(imdbID: String)
    case imdbIDMismatch(expected: String, got: String)
    case episodeNotFound(ep: String)
    case noStreamURL
    var errorDescription: String? {
        switch self {
        case .invalidURL: "URL không hợp lệ"
        case .noData: "Không có dữ liệu"
        case .noMatchFound(let id): "Không tìm thấy phim IMDB ID: \(id)"
        case .imdbIDMismatch(let exp, let got): "IMDB ID mismatch: expected \(exp), got \(got)"
        case .episodeNotFound(let ep): "Không tìm thấy tập: \(ep)"
        case .noStreamURL: "Không có stream URL"
        }
    }
}

// MARK: - NguonC Service
final class NguonCService {
    static let shared = NguonCService()
    private let cache = MappingCache.shared
    private let baseSearchURL = "https://phim.nguonc.com/api/films/search"
    private init() {}
    
    func fetchStream(
        imdbID: String,
        title: String,
        season: Int? = nil,
        episode: Int? = nil,
        completion: @escaping (Result<URL, Error>) -> Void
    ) {
        if let cachedSlug = cache.getNguonCSlug(imdbID: imdbID) {
            fetchMovieDetail(slug: cachedSlug, imdbID: imdbID, season: season, episode: episode, completion: completion)
            return
        }
        searchFilms(keyword: title) { [weak self] (result: Result<[NguonCFilm], Error>) in
            guard let self = self else { return }
            switch result {
            case .success(let films):
                // Dùng API search NguonC, lọc bằng IMDB ID từ response gốc
                // Vì NguonCFilm không có imdbID, ta gọi detail từng film để kiểm tra
                self.matchByDetail(films: films, imdbID: imdbID, season: season, episode: episode, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func matchByDetail(
        films: [NguonCFilm],
        imdbID: String,
        season: Int?,
        episode: Int?,
        completion: @escaping (Result<URL, Error>) -> Void
    ) {
        // Thử từng film, gọi API detail để lấy imdb_id
        let group = DispatchGroup()
        var foundURL: URL?
        var foundError: Error?
        
        for film in films.prefix(5) {
            guard let slug = film.slug else { continue }
            group.enter()
            fetchDetailAndCheck(slug: slug, imdbID: imdbID, season: season, episode: episode) { result in
                switch result {
                case .success(let url):
                    foundURL = url
                case .failure(let error):
                    if foundError == nil { foundError = error }
                }
                group.leave()
            }
            if foundURL != nil { break }
        }
        
        group.notify(queue: .main) {
            if let url = foundURL {
                completion(.success(url))
            } else {
                completion(.failure(foundError ?? NguonCServiceError.noMatchFound(imdbID: imdbID)))
            }
        }
    }
    
    private func fetchDetailAndCheck(
        slug: String,
        imdbID: String,
        season: Int?,
        episode: Int?,
        completion: @escaping (Result<URL, Error>) -> Void
    ) {
        guard let url = URL(string: "https://phim.nguonc.com/api/films/\(slug)") else {
            completion(.failure(NguonCServiceError.invalidURL)); return
        }
        URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            guard let self = self else { return }
            if let error = error { completion(.failure(error)); return }
            guard let data = data else { completion(.failure(NguonCServiceError.noData)); return }
            
            do {
                // Parse thủ công để lấy imdb_id (không có trong NguonCFilmDetail)
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    // Kiểm tra imdb_id
                    if let movie = json["movie"] as? [String: Any],
                       let detailImdbID = movie["imdb_id"] as? String,
                       detailImdbID == imdbID {
                        // Cache slug
                        self.cache.setNguonCSlug(imdbID: imdbID, slug: slug)
                        
                        // Lấy stream URL
                        if let s = season, let e = episode {
                            if let episodes = movie["episodes"] as? [[String: Any]] {
                                for epGroup in episodes {
                                    if let items = epGroup["items"] as? [[String: Any]] {
                                        for item in items {
                                            if let name = item["name"] as? String,
                                               let embed = item["embed"] as? String,
                                               let embedURL = URL(string: embed) {
                                                if name.lowercased() == "full" || Int(name) == e {
                                                    completion(.success(embedURL)); return
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            completion(.failure(NguonCServiceError.episodeNotFound(ep: "S\(s)E\(e)")))
                        } else {
                            if let embed = movie["embed"] as? String, let embedURL = URL(string: embed) {
                                completion(.success(embedURL))
                            } else if let streamURL = movie["stream_url"] as? String, let url = URL(string: streamURL) {
                                completion(.success(url))
                            } else {
                                completion(.failure(NguonCServiceError.noStreamURL))
                            }
                        }
                    } else {
                        completion(.failure(NguonCServiceError.imdbIDMismatch(expected: imdbID, got: "nil")))
                    }
                } else {
                    completion(.failure(NguonCServiceError.noData))
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    private func searchFilms(keyword: String, completion: @escaping (Result<[NguonCFilm], Error>) -> Void) {
        guard let query = keyword.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(baseSearchURL)?keyword=\(query)") else {
            completion(.failure(NguonCServiceError.invalidURL)); return
        }
        URLSession.shared.dataTask(with: url) { data, _, error in
            if let error = error { completion(.failure(error)); return }
            guard let data = data else { completion(.failure(NguonCServiceError.noData)); return }
            do {
                let decoded = try JSONDecoder().decode(NguonCSearchResponse.self, from: data)
                completion(.success(decoded.data ?? []))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    private func fetchMovieDetail(slug: String, imdbID: String, season: Int?, episode: Int?, completion: @escaping (Result<URL, Error>) -> Void) {
        fetchDetailAndCheck(slug: slug, imdbID: imdbID, season: season, episode: episode, completion: completion)
    }
}

// MARK: - Stravo Service
final class StravoService {
    static let shared = StravoService()
    private let cache = MappingCache.shared
    private init() {}
    
    func fetchStream(
        imdbID: String,
        season: Int? = nil,
        episode: Int? = nil,
        completion: @escaping (Result<URL, Error>) -> Void
    ) {
        let urlString: String
        if let s = season, let e = episode {
            urlString = "https://stravo-clfk.onrender.com/auto/stream/series/\(imdbID):\(s):\(e).json"
            if let cached = cache.getStravoURL(imdbID: imdbID, season: s, episode: e),
               let url = URL(string: cached) {
                completion(.success(url)); return
            }
        } else {
            urlString = "https://stravo-clfk.onrender.com/auto/stream/movie/\(imdbID).json"
        }
        guard let url = URL(string: urlString) else {
            completion(.failure(NguonCServiceError.invalidURL)); return
        }
        URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            guard let self = self else { return }
            if let error = error { completion(.failure(error)); return }
            guard let data = data else { completion(.failure(NguonCServiceError.noData)); return }
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    // Thử parse streams array
                    if let streams = json["streams"] as? [[String: Any]],
                       let streamURLString = streams.first?["url"] as? String,
                       let streamURL = URL(string: streamURLString) {
                        if let s = season, let e = episode {
                            self.cache.setStravoURL(imdbID: imdbID, season: s, episode: e, url: streamURLString)
                        }
                        completion(.success(streamURL)); return
                    }
                    // Thử parse url trực tiếp
                    if let streamURLString = json["url"] as? String,
                       let streamURL = URL(string: streamURLString) {
                        if let s = season, let e = episode {
                            self.cache.setStravoURL(imdbID: imdbID, season: s, episode: e, url: streamURLString)
                        }
                        completion(.success(streamURL)); return
                    }
                }
                completion(.failure(NguonCServiceError.noStreamURL))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}

// MARK: - VSMOV Service
final class VSMOVService {
    static let shared = VSMOVService()
    private let cache = MappingCache.shared
    private let baseSearchURL = "https://vsmov.com/api/tim-kiem"
    private init() {}
    
    func fetchStream(
        imdbID: String,
        title: String,
        season: Int? = nil,
        episode: Int? = nil,
        completion: @escaping (Result<URL, Error>) -> Void
    ) {
        if let cachedSlug = cache.getVSMOVSlug(imdbID: imdbID) {
            fetchVSMOVDetail(slug: cachedSlug, imdbID: imdbID, season: season, episode: episode, completion: completion)
            return
        }
        guard let query = title.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(baseSearchURL)?keyword=\(query)") else {
            completion(.failure(NguonCServiceError.invalidURL)); return
        }
        URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            guard let self = self else { return }
            if let error = error { completion(.failure(error)); return }
            guard let data = data else { completion(.failure(NguonCServiceError.noData)); return }
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let items = json["items"] as? [[String: Any]] {
                    // Tìm item có imdb_id khớp
                    if let matched = items.first(where: { $0["imdb_id"] as? String == imdbID }),
                       let slug = matched["slug"] as? String {
                        self.cache.setVSMOVSlug(imdbID: imdbID, slug: slug)
                        self.fetchVSMOVDetail(slug: slug, imdbID: imdbID, season: season, episode: episode, completion: completion)
                        return
                    }
                    // Fallback: dùng item đầu tiên
                    if let firstSlug = items.first?["slug"] as? String {
                        self.cache.setVSMOVSlug(imdbID: imdbID, slug: firstSlug)
                        self.fetchVSMOVDetail(slug: firstSlug, imdbID: imdbID, season: season, episode: episode, completion: completion)
                        return
                    }
                }
                completion(.failure(NguonCServiceError.noMatchFound(imdbID: imdbID)))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    private func fetchVSMOVDetail(
        slug: String, imdbID: String, season: Int?, episode: Int?,
        completion: @escaping (Result<URL, Error>) -> Void
    ) {
        guard let url = URL(string: "https://vsmov.com/api/phim/\(slug)") else {
            completion(.failure(NguonCServiceError.invalidURL)); return
        }
        URLSession.shared.dataTask(with: url) { data, _, error in
            if let error = error { completion(.failure(error)); return }
            guard let data = data else { completion(.failure(NguonCServiceError.noData)); return }
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    if let s = season, let e = episode {
                        if let episodes = json["episodes"] as? [[String: Any]] {
                            for server in episodes {
                                if let serverData = server["server_data"] as? [[String: Any]] {
                                    for ep in serverData {
                                        if let name = ep["name"] as? String,
                                           let link = ep["link_embed"] as? String,
                                           (name.lowercased() == "full" || Int(name) == e) {
                                            let m3u8 = link.hasSuffix("/") ? "\(link)master-b2.m3u8" : "\(link)/master-b2.m3u8"
                                            if let streamURL = URL(string: m3u8) {
                                                completion(.success(streamURL)); return
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        completion(.failure(NguonCServiceError.episodeNotFound(ep: "S\(s)E\(e)")))
                    } else {
                        if let urlStr = json["url"] as? String, let streamURL = URL(string: urlStr) {
                            completion(.success(streamURL))
                        } else if let m3u8 = json["m3u8"] as? String, let streamURL = URL(string: m3u8) {
                            completion(.success(streamURL))
                        } else {
                            completion(.failure(NguonCServiceError.noStreamURL))
                        }
                    }
                } else {
                    completion(.failure(NguonCServiceError.noStreamURL))
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}