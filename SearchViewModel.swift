import Foundation

@MainActor
class SearchViewModel: ObservableObject {
    @Published var query = ""
    @Published var results: [Movie] = []
    @Published var trending: [Movie] = []
    private var task: Task<Void, Never>?
    
    func loadTrending() async {
        do {
            trending = try await APIService.shared.trending24h()
        } catch {
            trending = []
        }
    }
    
    func search() async {
        task?.cancel()
        let q = query.trimmingCharacters(in: .whitespaces)
        if q.isEmpty { results = []; return }
        task = Task {
            try? await Task.sleep(nanoseconds: 200_000_000)
            if !Task.isCancelled {
                do { results = try await APIService.shared.search(query: q) } catch { results = [] }
            }
        }
    }
}
