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
    @Published var genres: [Genre] = []
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
        async let g = APIService.shared.genres()
        
        do {
            let results = try await (d, n, u, tr, p, ko, ja, vi, us, g)
            trending24h = results.0
            nowPlaying = results.1
            upcoming = results.2
            topRated = results.3
            popular = results.4
            korean = results.5.filter { ($0.adult ?? false) == false && $0.voteAverage > 5.0 }
            japanese = results.6.filter { ($0.adult ?? false) == false && $0.voteAverage > 6.0 && $0.popularity ?? 0 > 10 }
            vietnamese = results.7
            usuk = results.8
            genres = results.9
        } catch {
            print("Error: \(error)")
        }
        
        isLoading = false
    }
}