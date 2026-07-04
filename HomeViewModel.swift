import Foundation

@MainActor
class HomeViewModel: ObservableObject {
    @Published var trending: [Movie] = []
    @Published var nowPlaying: [Movie] = []
    @Published var upcoming: [Movie] = []
    @Published var topRated: [Movie] = []
    @Published var popular: [Movie] = []
    @Published var genres: [Genre] = []
    @Published var isLoading = true
    
    func loadAll() async {
        isLoading = true
        do {
            let t = try await APIService.shared.trending()
            trending = t
        } catch {
            print("TRENDING ERROR: \(error)")
            trending = []
        }
        
        do {
            let n = try await APIService.shared.nowPlaying()
            nowPlaying = n
        } catch {
            print("NOWPLAYING ERROR: \(error)")
            nowPlaying = []
        }
        
        do {
            let g = try await APIService.shared.genres()
            genres = g
        } catch {
            print("GENRES ERROR: \(error)")
            genres = []
        }
        
        upcoming = trending
        topRated = trending
        popular = trending
        isLoading = false
    }
}
