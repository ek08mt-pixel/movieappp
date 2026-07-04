import Foundation

@MainActor
class HomeViewModel: ObservableObject {
    @Published var trending24h: [Movie] = []
    @Published var trendingWeek: [Movie] = []
    @Published var nowPlaying: [Movie] = []
    @Published var upcoming: [Movie] = []
    @Published var topRated: [Movie] = []
    @Published var popular: [Movie] = []
    @Published var korean: [Movie] = []
    @Published var japanese: [Movie] = []
    @Published var vietnamese: [Movie] = []
    @Published var usuk: [Movie] = []
    @Published var genres: [Genre] = []
    @Published var isLoading = true
    
    func loadAll() async {
        isLoading = true
        
        async let d = APIService.shared.trending24h()
        async let w = APIService.shared.trendingWeek()
        async let n = APIService.shared.nowPlaying()
        async let u = APIService.shared.upcoming()
        async let tr = APIService.shared.topRated()
        async let p = APIService.shared.popular()
        async let ko = APIService.shared.koreanMovies()
        async let ja = APIService.shared.japaneseMovies()
        async let vi = APIService.shared.vietnameseMovies()
        async let us = APIService.shared.usukMovies()
        async let g = APIService.shared.genres()
        
        do {
            let results = try await (d, w, n, u, tr, p, ko, ja, vi, us, g)
            trending24h = results.0
            trendingWeek = results.1
            nowPlaying = results.2
            upcoming = results.3
            topRated = results.4
            popular = results.5
            korean = results.6
            japanese = results.7
            vietnamese = results.8
            usuk = results.9
            genres = results.10
        } catch {
            print("Error: \(error)")
        }
        
        isLoading = false
    }
}
