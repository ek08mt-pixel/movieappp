import Foundation

@MainActor
class HomeViewModel: ObservableObject {
    @Published var trending: [Movie] = []
    @Published var nowPlaying: [Movie] = []
    @Published var upcoming: [Movie] = []
    @Published var topRated: [Movie] = []
    @Published var popular: [Movie] = []
    @Published var asian: [Movie] = []
    @Published var usuk: [Movie] = []
    @Published var genres: [Genre] = []
    @Published var isLoading = true
    
    func loadAll() async {
        isLoading = true
        
        async let t = APIService.shared.trending()
        async let n = APIService.shared.nowPlaying()
        async let u = APIService.shared.upcoming()
        async let tr = APIService.shared.topRated()
        async let p = APIService.shared.popular()
        async let a = APIService.shared.moviesByGenre(genreId: 28)
        async let us = APIService.shared.moviesByGenre(genreId: 12)
        async let g = APIService.shared.genres()
        
        do {
            let results = try await (t, n, u, tr, p, a, us, g)
            trending = results.0
            nowPlaying = results.1
            upcoming = results.2
            topRated = results.3
            popular = results.4
            asian = results.5
            usuk = results.6
            genres = results.7
        } catch {
            print("Error: \(error)")
        }
        
        isLoading = false
    }
}
