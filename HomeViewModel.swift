import Foundation

@MainActor
class HomeViewModel: ObservableObject {
    @Published var trending: [Movie] = []
    @Published var upcoming: [Movie] = []
    @Published var nowPlaying: [Movie] = []
    @Published var topRated: [Movie] = []
    @Published var genres: [Genre] = []
    @Published var isLoading = false
    
    func loadAll() async {
        // Tạm tắt API để test
        isLoading = false
    }
}
