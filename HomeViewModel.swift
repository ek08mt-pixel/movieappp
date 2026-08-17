import Foundation

@MainActor
class HomeViewModel: ObservableObject {
    @Published var trending24h: [Movie] = []
    @Published var trendingTV: [Movie] = []
    @Published var nowPlaying: [Movie] = []
    @Published var upcoming: [Movie] = []
    @Published var topRated: [Movie] = []
    @Published var korean: [Movie] = []
    @Published var japanese: [Movie] = []
    @Published var vietnamese: [Movie] = []
    @Published var usuk: [Movie] = []
    @Published var anime: [Movie] = []
    @Published var genres: [Genre] = []
    @Published var movieOfDay: Movie?
    @Published var isLoading = false
    @Published var trendingAnime: [Movie] = []
    @Published var similarMovies: [Movie] = []
    @Published var newMovies: [Movie] = []
    @Published var usukIcons: [Movie] = []
    
    init() {
        Task { await loadAll() }
    }
    
    func loadAll() async {
        guard !isLoading else { return }
        isLoading = true
        
        // Load tuần tự từng cái để tránh 503
        trending24h = (try? await APIService.shared.trending24hFast()) ?? []
        movieOfDay = trending24h.randomElement()
        
        genres = (try? await APIService.shared.genres()) ?? []
        
        trendingTV = await loadTrendingTVPages()
        
        nowPlaying = (try? await APIService.shared.nowPlaying()) ?? []
        topRated = (try? await APIService.shared.topRated()) ?? []
        
        korean = (try? await APIService.shared.koreanMovies()) ?? []
        usuk = (try? await APIService.shared.usukMovies()) ?? []
        vietnamese = (try? await APIService.shared.vietnameseMovies()) ?? []
        
        japanese = (try? await APIService.shared.japaneseMovies()) ?? []
        anime = (try? await APIService.shared.animeMovies()) ?? []
        trendingAnime = await loadTrendingAnime()
        
        await loadNewMovies()
        await loadUSUKIcons()
        
        isLoading = false
    }
    
    private func loadTrendingTVPages() async -> [Movie] {
        var all: [Movie] = []
        let firstPageURL = "https://api.themoviedb.org/3/trending/tv/day?api_key=b6be36c1c5788565fec6a24811e7cc9b&language=en-US&page=1"
        
        if let url = URL(string: firstPageURL),
           let (data, _) = try? await URLSession.shared.data(from: url) {
            struct TVResponse: Codable { let results: [TVResult] }
            struct TVResult: Codable {
                let id: Int; let name: String?; let overview: String
                let poster_path: String?; let backdrop_path: String?
                let vote_average: Double; let first_air_date: String?
                let genre_ids: [Int]?; let popularity: Double?
                let vote_count: Int?; let original_language: String?
            }
            if let response = try? JSONDecoder().decode(TVResponse.self, from: data) {
                all = response.results.map { tv in
                    Movie(id: tv.id, title: tv.name ?? "Unknown", overview: tv.overview,
                          posterPath: tv.poster_path, backdropPath: tv.backdrop_path,
                          voteAverage: tv.vote_average, releaseDate: tv.first_air_date,
                          genreIds: tv.genre_ids, originalTitle: tv.name,
                          popularity: tv.popularity, voteCount: tv.vote_count,
                          adult: false, originalLanguage: tv.original_language, mediaType: "tv")
                }
            }
        }
        
        if all.count >= 20 {
            for page in 2...5 {
                let urlString = "https://api.themoviedb.org/3/trending/tv/day?api_key=b6be36c1c5788565fec6a24811e7cc9b&language=en-US&page=\(page)"
                guard let url = URL(string: urlString),
                      let (data, _) = try? await URLSession.shared.data(from: url) else { break }
                
                struct TVResponse: Codable { let results: [TVResult] }
                struct TVResult: Codable {
                    let id: Int; let name: String?; let overview: String
                    let poster_path: String?; let backdrop_path: String?
                    let vote_average: Double; let first_air_date: String?
                    let genre_ids: [Int]?; let popularity: Double?
                    let vote_count: Int?; let original_language: String?
                }
                if let response = try? JSONDecoder().decode(TVResponse.self, from: data) {
                    let results = response.results.map { tv in
                        Movie(id: tv.id, title: tv.name ?? "Unknown", overview: tv.overview,
                              posterPath: tv.poster_path, backdropPath: tv.backdrop_path,
                              voteAverage: tv.vote_average, releaseDate: tv.first_air_date,
                              genreIds: tv.genre_ids, originalTitle: tv.name,
                              popularity: tv.popularity, voteCount: tv.vote_count,
                              adult: false, originalLanguage: tv.original_language, mediaType: "tv")
                    }
                    all.append(contentsOf: results)
                    if results.count < 20 { break }
                }
            }
        }
        
        return all
    }
    
    private func loadTrendingAnime() async -> [Movie] {
        var all: [Movie] = []
        for page in 1...5 {
            let urlString = "https://api.themoviedb.org/3/discover/tv?api_key=b6be36c1c5788565fec6a24811e7cc9b&with_genres=16&sort_by=popularity.desc&language=vi-VN&page=\(page)&vote_count.gte=30"
            guard let url = URL(string: urlString) else { break }
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                struct TVResp: Codable { let results: [TVRes] }
                struct TVRes: Codable {
                    let id: Int; let name: String?; let overview: String
                    let poster_path: String?; let backdrop_path: String?
                    let vote_average: Double; let first_air_date: String?
                    let genre_ids: [Int]?; let popularity: Double?
                    let vote_count: Int?; let original_language: String?
                }
                let response = try JSONDecoder().decode(TVResp.self, from: data)
                let results = response.results.filter { !($0.name ?? "").isEmpty }.map { tv in
                    Movie(id: tv.id, title: tv.name ?? "Unknown", overview: tv.overview,
                          posterPath: tv.poster_path, backdropPath: tv.backdrop_path,
                          voteAverage: tv.vote_average, releaseDate: tv.first_air_date,
                          genreIds: tv.genre_ids, originalTitle: tv.name,
                          popularity: tv.popularity, voteCount: tv.vote_count,
                          adult: false, originalLanguage: tv.original_language, mediaType: "tv")
                }
                all.append(contentsOf: results)
                if results.count < 20 { break }
            } catch { break }
        }
        return all
    }
    
    func loadNewMovies() async {
        var all: [Movie] = []
        for page in 1...5 {
            let urlString = "https://api.themoviedb.org/3/discover/movie?api_key=b6be36c1c5788565fec6a24811e7cc9b&language=vi-VN&sort_by=primary_release_date.desc&vote_count.gte=30&primary_release_date.gte=2024-01-01&page=\(page)&with_original_language=en|ko|ja|zh|vi"
            guard let url = URL(string: urlString) else { break }
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                struct Resp: Codable { let results: [MovieResult] }
                struct MovieResult: Codable {
                    let id: Int; let title: String?; let overview: String
                    let poster_path: String?; let backdrop_path: String?
                    let vote_average: Double; let release_date: String?
                    let genre_ids: [Int]?; let popularity: Double?
                    let vote_count: Int?; let original_language: String?
                    let adult: Bool?
                }
                let response = try JSONDecoder().decode(Resp.self, from: data)
                let results = response.results
                    .filter { !($0.adult ?? false) }
                    .map { m in
                        Movie(id: m.id, title: m.title ?? "Unknown", overview: m.overview,
                              posterPath: m.poster_path, backdropPath: m.backdrop_path,
                              voteAverage: m.vote_average, releaseDate: m.release_date,
                              genreIds: m.genre_ids, originalTitle: m.title,
                              popularity: m.popularity, voteCount: m.vote_count,
                              adult: m.adult ?? false, originalLanguage: m.original_language, mediaType: "movie")
                    }
                all.append(contentsOf: results)
                if results.count < 20 { break }
            } catch { break }
        }
        newMovies = all
    }
    
    func loadUSUKIcons() async {
        var allMovies: [Movie] = []
        
        for page in 1...5 {
            let urlString = "https://api.themoviedb.org/3/discover/movie?api_key=b6be36c1c5788565fec6a24811e7cc9b&language=en-US&sort_by=vote_count.desc&with_original_language=en&vote_count.gte=3000&vote_average.gte=7.5&primary_release_date.lte=2020-12-31&without_genres=10749&page=\(page)"
            guard let url = URL(string: urlString) else { break }
            
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                struct Resp: Codable { let results: [MovieResult] }
                struct MovieResult: Codable {
                    let id: Int; let title: String?; let overview: String
                    let poster_path: String?; let backdrop_path: String?
                    let vote_average: Double; let release_date: String?
                    let genre_ids: [Int]?; let popularity: Double?
                    let vote_count: Int?; let original_language: String?
                    let adult: Bool?
                }
                let response = try JSONDecoder().decode(Resp.self, from: data)
                let results = response.results
                    .filter { !($0.adult ?? false) }
                    .map { m in
                        Movie(id: m.id, title: m.title ?? "Unknown", overview: m.overview,
                              posterPath: m.poster_path, backdropPath: m.backdrop_path,
                              voteAverage: m.vote_average, releaseDate: m.release_date,
                              genreIds: m.genre_ids, originalTitle: m.title,
                              popularity: m.popularity, voteCount: m.vote_count,
                              adult: m.adult ?? false, originalLanguage: m.original_language, mediaType: "movie")
                    }
                allMovies.append(contentsOf: results)
                if results.count < 20 { break }
            } catch { break }
        }
        
        usukIcons = allMovies
    }
    
    func loadSimilarForLastWatched(movieId: Int, mediaType: String?) async {
        similarMovies = (try? await APIService.shared.similar(movieId: movieId, mediaType: mediaType)) ?? []
    }
}