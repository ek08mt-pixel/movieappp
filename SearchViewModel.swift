import Foundation

@MainActor
class SearchViewModel: ObservableObject {
    @Published var query = ""
    @Published var results: [Movie] = []
    @Published var isSearching = false
    
    func search() async {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        isSearching = true
        defer { isSearching = false }
        
        do {
            results = try await APIService.shared.search(query: query)
        } catch {
            results = []
        }
    }
}
