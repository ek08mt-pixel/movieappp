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
        
        do {
            trending = try await APIService.shared.trending()
        } catch {
            print("Trending error: \(error)")
        }
        
        do {
            nowPlaying = try await APIService.shared.nowPlaying()
        } catch {
            print("NowPlaying error: \(error)")
        }
        
        do {
            upcoming = try await APIService.shared.upcoming()
        } catch {
            print("Upcoming error: \(error)")
        }
        
        do {
            topRated = try await APIService.shared.topRated()
        } catch {
            print("TopRated error: \(error)")
        }
        
        do {
            popular = try await APIService.shared.popular()
        } catch {
            print("Popular error: \(error)")
        }
        
        do {
            asian = try await APIService.shared.moviesByGenre(genreId: 28)
        } catch {
            print("Asian error: \(error)")
        }
        
        do {
            usuk = try await APIService.shared.moviesByGenre(genreId: 12)
        } catch {
            print("USUK error: \(error)")
        }
        
        do {
            genres = try await APIService.shared.genres()
        } catch {
            print("Genres error: \(error)")
        }
        
        isLoading = false
    }
}
