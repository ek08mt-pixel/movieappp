import Foundation

@MainActor
class HomeViewModel: ObservableObject {
    @Published var trending: [Movie] = []
    @Published var isLoading = true
    
    func loadAll() async {
        isLoading = true
        do {
            let movies = try await APIService.shared.trending()
            trending = movies
        } catch {
            print("API Error: \(error)")
            trending = []
        }
        isLoading = false
    }
}
