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
            trending = try await APIService.shared.trending()
            nowPlaying = try await APIService.shared.nowPlaying()
            upcoming = try await APIService.shared.upcoming()
            topRated = try await APIService.shared.topRated()
            popular = try await APIService.shared.popular()
            genres = try await APIService.shared.genres()
        } catch {
            print("Error: \(error)")
        }
        isLoading = false
    }
}
