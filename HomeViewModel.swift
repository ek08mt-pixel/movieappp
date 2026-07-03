import Foundation

@MainActor
class HomeViewModel: ObservableObject {
    @Published var trending: [Movie] = []
    @Published var isLoading = true
    
    func loadAll() async {
        isLoading = true
        do {
            trending = try await APIService.shared.trending()
        } catch {
            trending = []
        }
        isLoading = false
    }
}
