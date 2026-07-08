// ============================================================
// MARK: - MappingCache.swift
// ============================================================
import Foundation

final class MappingCache {
    static let shared = MappingCache()
    
    private let defaults = UserDefaults.standard
    private let nguonCKey = "cache_nguonc_mapping"
    private let vsmovKey = "cache_vsmov_mapping"
    private let stravoKey = "cache_stravo_mapping"
    
    private init() {}
    
    // MARK: NguonC
    func getNguonCSlug(imdbID: String) -> String? {
        dict(for: nguonCKey)[imdbID]
    }
    func setNguonCSlug(imdbID: String, slug: String) {
        var d = dict(for: nguonCKey); d[imdbID] = slug; save(d, for: nguonCKey)
    }
    
    // MARK: VSMOV
    func getVSMOVSlug(imdbID: String) -> String? {
        dict(for: vsmovKey)[imdbID]
    }
    func setVSMOVSlug(imdbID: String, slug: String) {
        var d = dict(for: vsmovKey); d[imdbID] = slug; save(d, for: vsmovKey)
    }
    
    // MARK: Stravo
    func getStravoURL(imdbID: String, season: Int, episode: Int) -> String? {
        dict(for: stravoKey)["\(imdbID)_S\(season)E\(episode)"]
    }
    func setStravoURL(imdbID: String, season: Int, episode: Int, url: String) {
        var d = dict(for: stravoKey)
        d["\(imdbID)_S\(season)E\(episode)"] = url
        save(d, for: stravoKey)
    }
    
    // MARK: Helpers
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

// ============================================================
// MARK: - NguonCService.swift
// ============================================================
import Foundation

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
        searchFilms(keyword: title) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let films):
                if let matched = films.first(where: { $0.imdbID == imdbID }) {
                    self.cache.setNguonCSlug(imdbID: imdbID, slug: matched.slug)
                    self.fetchMovieDetail(slug: matched.slug, imdbID: imdbID, season: season, episode: episode, completion: completion)
                } else {
                    completion(.failure(NguonCError.noMatchFound(imdbID: imdbID)))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func searchFilms(keyword: String, completion: @escaping (Result<[NguonCSearchResult], Error>) -> Void) {
        guard let query = keyword.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(baseSearchURL)?keyword=\(query)") else {
            completion(.failure(NguonCError.invalidURL)); return
        }
        URLSession.shared.dataTask(with: url) { data, _, error in
            if let error = error { completion(.failure(error)); return }
            guard let data = data else { completion(.failure(NguonCError.noData)); return }
            do {
                let decoded = try JSONDecoder().decode(NguonCSearchResponse.self, from: data)
                completion(.success(decoded.items ?? []))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    private func fetchMovieDetail(
        slug: String, imdbID: String, season: Int?, episode: Int?,
        completion: @escaping (Result<URL, Error>) -> Void
    ) {
        guard let url = URL(string: "https://phim.nguonc.com/api/films/\(slug)") else {
            completion(.failure(NguonCError.invalidURL)); return
        }
        URLSession.shared.dataTask(with: url) { data, _, error in
            if let error = error { completion(.failure(error)); return }
            guard let data = data else { completion(.failure(NguonCError.noData)); return }
            do {
                let detail = try JSONDecoder().decode(NguonCFilmDetail.self, from: data)
                guard detail.imdbID == imdbID else {
                    completion(.failure(NguonCError.imdbIDMismatch(expected: imdbID, got: detail.imdbID ?? "nil")))
                    return
                }
                if let s = season, let e = episode {
                    let target = String(format: "S%02dE%02d", s, e)
                    if let ep = detail.episodes?.first(where: { $0.name == target }),
                       let streamURL = URL(string: ep.url) {
                        completion(.success(streamURL))
                    } else {
                        completion(.failure(NguonCError.episodeNotFound(ep: target)))
                    }
                } else {
                    if let streamURL = URL(string: detail.streamURL ?? detail.url ?? "") {
                        completion(.success(streamURL))
                    } else {
                        completion(.failure(NguonCError.noStreamURL))
                    }
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}

// MARK: NguonC Models & Error
enum NguonCError: LocalizedError {
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

struct NguonCSearchResponse: Codable {
    let items: [NguonCSearchResult]?
}

struct NguonCSearchResult: Codable {
    let slug: String
    let name: String
    let imdbID: String?
    enum CodingKeys: String, CodingKey {
        case slug, name, imdbID = "imdb_id"
    }
}

struct NguonCFilmDetail: Codable {
    let imdbID: String?
    let streamURL: String?
    let url: String?
    let episodes: [NguonCEpisode]?
    enum CodingKeys: String, CodingKey {
        case imdbID = "imdb_id", streamURL = "stream_url", url, episodes
    }
}

struct NguonCEpisode: Codable {
    let name: String
    let url: String
}

// ============================================================
// MARK: - StravoService.swift
// ============================================================
import Foundation

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
            urlString = "https://stravo.com/auto/stream/series/\(imdbID):\(s):\(e).json"
            if let cached = cache.getStravoURL(imdbID: imdbID, season: s, episode: e),
               let url = URL(string: cached) {
                completion(.success(url)); return
            }
        } else {
            urlString = "https://stravo.com/auto/stream/movie/\(imdbID).json"
        }
        guard let url = URL(string: urlString) else {
            completion(.failure(NguonCError.invalidURL)); return
        }
        URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            guard let self = self else { return }
            if let error = error { completion(.failure(error)); return }
            guard let data = data else { completion(.failure(NguonCError.noData)); return }
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let streamURLString = json["url"] as? String ?? json["stream_url"] as? String,
                   let streamURL = URL(string: streamURLString) {
                    if let s = season, let e = episode {
                        self.cache.setStravoURL(imdbID: imdbID, season: s, episode: e, url: streamURLString)
                    }
                    completion(.success(streamURL))
                } else {
                    completion(.failure(NguonCError.noStreamURL))
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}

// ============================================================
// MARK: - VSMOVService.swift
// ============================================================
import Foundation

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
            completion(.failure(NguonCError.invalidURL)); return
        }
        URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            guard let self = self else { return }
            if let error = error { completion(.failure(error)); return }
            guard let data = data else { completion(.failure(NguonCError.noData)); return }
            do {
                let decoded = try JSONDecoder().decode(VSMOVSearchResponse.self, from: data)
                if let matched = decoded.items?.first(where: { $0.imdbID == imdbID }) {
                    self.cache.setVSMOVSlug(imdbID: imdbID, slug: matched.slug)
                    self.fetchVSMOVDetail(slug: matched.slug, imdbID: imdbID, season: season, episode: episode, completion: completion)
                } else {
                    completion(.failure(NguonCError.noMatchFound(imdbID: imdbID)))
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    private func fetchVSMOVDetail(
        slug: String, imdbID: String, season: Int?, episode: Int?,
        completion: @escaping (Result<URL, Error>) -> Void
    ) {
        guard let url = URL(string: "https://vsmov.com/api/film/\(slug)") else {
            completion(.failure(NguonCError.invalidURL)); return
        }
        URLSession.shared.dataTask(with: url) { data, _, error in
            if let error = error { completion(.failure(error)); return }
            guard let data = data else { completion(.failure(NguonCError.noData)); return }
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let streamURLString = json["url"] as? String ?? json["m3u8"] as? String,
                   let streamURL = URL(string: streamURLString) {
                    completion(.success(streamURL))
                } else {
                    completion(.failure(NguonCError.noStreamURL))
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}

struct VSMOVSearchResponse: Codable {
    let items: [VSMOVSearchResult]?
}

struct VSMOVSearchResult: Codable {
    let slug: String
    let name: String
    let imdbID: String?
    enum CodingKeys: String, CodingKey {
        case slug, name, imdbID = "imdb_id"
    }
}

// ============================================================
// MARK: - Unified Stream Resolver (dùng trong MoviePlayerView)
// ============================================================
import Foundation

final class StreamResolver {
    static let shared = StreamResolver()
    private init() {}
    
    func resolve(
        imdbID: String,
        title: String,
        season: Int? = nil,
        episode: Int? = nil,
        completion: @escaping (Result<URL, Error>) -> Void
    ) {
        // Ưu tiên 1: NguonC
        NguonCService.shared.fetchStream(imdbID: imdbID, title: title, season: season, episode: episode) { result in
            switch result {
            case .success(let url):
                completion(.success(url))
            case .failure:
                // Fallback 2: Stravo
                StravoService.shared.fetchStream(imdbID: imdbID, season: season, episode: episode) { result in
                    switch result {
                    case .success(let url):
                        completion(.success(url))
                    case .failure:
                        // Fallback 3: VSMOV
                        VSMOVService.shared.fetchStream(imdbID: imdbID, title: title, season: season, episode: episode, completion: completion)
                    }
                }
            }
        }
    }
}

// ============================================================
// MARK: - Usage in MoviePlayerView.swift
// ============================================================
/*
 Trong MoviePlayerView, khi cần load stream:

 func loadStream() {
     guard let movie = viewModel.movie else { return }
     
     // Lấy IMDB ID từ TMDB
     APIService.shared.fetchExternalIDs(movieID: movie.id, mediaType: movie.mediaType) { [weak self] result in
         switch result {
         case .success(let externalIDs):
             guard let imdbID = externalIDs.imdbID else {
                 self?.showError("Không tìm thấy IMDB ID")
                 return
             }
             StreamResolver.shared.resolve(
                 imdbID: imdbID,
                 title: movie.title,
                 season: self?.viewModel.selectedSeason,
                 episode: self?.viewModel.selectedEpisode
             ) { result in
                 DispatchQueue.main.async {
                     switch result {
                     case .success(let url):
                         self?.player.replaceCurrentItem(with: AVPlayerItem(url: url))
                     case .failure(let error):
                         self?.showError(error.localizedDescription)
                     }
                 }
             }
         case .failure(let error):
             self?.showError(error.localizedDescription)
         }
     }
 }
 */