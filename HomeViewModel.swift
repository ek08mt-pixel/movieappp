import Foundation

@MainActor
class HomeViewModel: ObservableObject {
    @Published var trending24h: [Movie] = []
    @Published var nowPlaying: [Movie] = []
    @Published var upcoming: [Movie] = []
    @Published var topRated: [Movie] = []
    @Published var popular: [Movie] = []
    @Published var korean: [Movie] = []
    @Published var japanese: [Movie] = []
    @Published var vietnamese: [Movie] = []
    @Published var usuk: [Movie] = []
    @Published var anime: [Movie] = []
    @Published var genres: [Genre] = []
    @Published var movieOfDay: Movie?
    @Published var isLoading = true
    
    func loadAll() async {
        isLoading = true
        
        async let d = APIService.shared.trending24h()
        async let n = APIService.shared.nowPlaying()
        async let u = APIService.shared.upcoming()
        async let tr = APIService.shared.topRated()
        async let p = APIService.shared.popular()
        async let ko = APIService.shared.koreanMovies()
        async let ja = APIService.shared.japaneseMovies()
        async let vi = APIService.shared.vietnameseMovies()
        async let us = APIService.shared.usukMovies()
        async let an = APIService.shared.animeMovies()
        async let g = APIService.shared.genres()
        
        do {
            let results = try await (d, n, u, tr, p, ko, ja, vi, us, an, g)
            trending24h = results.0.filter { !($0.adult ?? false) }
            nowPlaying = results.1.filter { !($0.adult ?? false) }
            upcoming = results.2.filter { !($0.adult ?? false) }
            topRated = results.3.filter { !($0.adult ?? false) }
            popular = results.4.filter { !($0.adult ?? false) }
            korean = results.5.filter { !($0.adult ?? false) && $0.voteAverage > 5.0 && !($0.overview.lowercased().contains("sex")) && !($0.title.lowercased().contains("av")) }
            japanese = results.6.filter { !($0.adult ?? false) && $0.voteAverage > 6.0 && ($0.popularity ?? 0) > 10 && !($0.overview.lowercased().contains("sex")) && !($0.title.lowercased().contains("av")) }
            vietnamese = results.7.filter { !($0.adult ?? false) }
            usuk = results.8.filter { !($0.adult ?? false) }
            anime = results.9.filter { !($0.adult ?? false) }
            genres = results.10
            
            if !trending24h.isEmpty {
                let day = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
                movieOfDay = trending24h[day % trending24h.count]
            }
        } catch {
            print("Error: \(error)")
        }
        
        isLoading = false
    }
}