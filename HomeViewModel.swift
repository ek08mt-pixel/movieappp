import Foundation

@MainActor
class HomeViewModel: ObservableObject {
    @Published var trending24h: [Movie] = []
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
    @Published var isLoading = true
    
    func loadAll() async {
        isLoading = true
        
        async let trendingTask = APIService.shared.trendingAll()
        async let nowPlayingTask = APIService.shared.nowPlaying()
        async let upcomingTask = APIService.shared.upcoming()
        async let topRatedTask = APIService.shared.topRated()
        async let koreanTask = APIService.shared.koreanMovies()
        async let japaneseTask = APIService.shared.japaneseMovies()
        async let vietnameseTask = APIService.shared.vietnameseMovies()
        async let usukTask = APIService.shared.usukMovies()
        async let animeTask = APIService.shared.animeMovies()
        async let genresTask = APIService.shared.genres()
        
        trending24h = (try? await trendingTask) ?? []
        nowPlaying = (try? await nowPlayingTask) ?? []
        upcoming = (try? await upcomingTask) ?? []
        topRated = (try? await topRatedTask) ?? []
        korean = (try? await koreanTask) ?? []
        japanese = (try? await japaneseTask) ?? []
        vietnamese = (try? await vietnameseTask) ?? []
        usuk = (try? await usukTask) ?? []
        anime = (try? await animeTask) ?? []
        genres = (try? await genresTask) ?? []
        movieOfDay = trending24h.randomElement()
        
        isLoading = false
    }
}