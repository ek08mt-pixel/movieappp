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
        } catch {
            print("ERROR: \(error.localizedDescription)")
            trending = []
        }
        isLoading = false
    }
}
