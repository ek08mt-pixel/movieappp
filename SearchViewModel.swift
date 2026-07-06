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
            try? await Task.sleep(nanoseconds: 200_000_000)
            if !Task.isCancelled {
                do {
                    let encoded = q.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? q
                    let urlString = "https://api.themoviedb.org/3/search/multi?api_key=b6be36c1c5788565fec6a24811e7cc9b&language=en-US&query=\(encoded)&page=1"
                    guard let url = URL(string: urlString) else { results = []; return }
                    let (data, _) = try await URLSession.shared.data(from: url)
                    let response = try JSONDecoder().decode(MovieResponse.self, from: data)
                    results = response.results.filter { $0.mediaType == "movie" || $0.mediaType == "tv" }
                } catch {
                    results = []
                }
            }
        }
    }
}