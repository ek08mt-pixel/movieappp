import Foundation

@MainActor
class SearchViewModel: ObservableObject {
    @Published var query = ""
    @Published var results: [Movie] = []
    @Published var trending: [Movie] = []
    private var task: Task<Void, Never>?
    
    func loadTrending() async {
        async let movies = APIService.shared.trending24h()
        async let tvShows = APIService.shared.trendingTV()
        let m = (try? await movies) ?? []
        let t = (try? await tvShows) ?? []
        trending = (m + t).sorted { ($0.popularity ?? 0) > ($1.popularity ?? 0) }
    }
    
    func search() async {
        task?.cancel()
        let q = query.trimmingCharacters(in: .whitespaces)
        if q.isEmpty { results = []; return }
        task = Task {
            try? await Task.sleep(nanoseconds: 100_000_000)
            if !Task.isCancelled {
                async let movies = APIService.shared.searchMovies(query: q)
                async let tvShows = APIService.shared.searchTVShows(query: q)
                let m = (try? await movies) ?? []
                let t = (try? await tvShows) ?? []
                results = (m + t).sorted { ($0.popularity ?? 0) > ($1.popularity ?? 0) }
            }
        }
    }
}