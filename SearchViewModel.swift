import Foundation

@MainActor
class SearchViewModel: ObservableObject {
    @Published var query = ""
    @Published var results: [Movie] = []
    @Published var isSearching = false
    
    private var searchTask: Task<Void, Never>?
    
    func search() async {
        searchTask?.cancel()
        searchTask = Task {
            guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
                results = []
                return
            }
            isSearching = true
            do {
                try await Task.sleep(nanoseconds: 300_000_000)
                if !Task.isCancelled {
                    results = try await APIService.shared.search(query: query)
                }
            } catch {
                if !Task.isCancelled {
                    results = []
                }
            }
            if !Task.isCancelled {
                isSearching = false
            }
        }
    }
}
