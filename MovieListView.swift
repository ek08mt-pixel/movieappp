import SwiftUI

struct MovieListView: View {
    let title: String; let movies: [Movie]; var fixedQuery: String = ""
    @State private var allMovies: [Movie] = []; @State private var page = 1; @State private var isLoading = false; @State private var hasMore = true
    @Environment(\.dismiss) var dismiss
    
    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
    
    var isYearQuery: Bool {
        Int(fixedQuery) != nil
    }
    
    var isCountryQuery: Bool {
        let countries = ["usuk", "korean", "japanese", "vietnamese", "china", "india", "thailand", "france", "uk", "australia", "mexico", "spain", "brazil", "russia", "germany", "italy", "canada", "sweden"]
        return countries.contains(fixedQuery.lowercased())
    }
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            LinearGradient(colors: [Color(white: 0.08), Color(white: 0.02), .black], startPoint: .top, endPoint: .bottom).ignoresSafeArea()
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(allMovies) { movie in
                        NavigationLink(destination: MovieDetailView(movie: movie)) {
                            VStack(spacing: 6) {
                                CachedAsyncImage(url: movie.posterURL).aspectRatio(2/3, contentMode: .fill).frame(maxWidth: .infinity).clipShape(RoundedRectangle(cornerRadius: 8)).shadow(color: .black.opacity(0.3), radius: 4, y: 2)
                                Text(movie.title).font(.system(size: 9, weight: .medium)).foregroundColor(.white).lineLimit(2)
                                HStack(spacing: 2) { Image(systemName: "star.fill").font(.system(size: 7)).foregroundColor(.yellow); Text(movie.ratingText).font(.system(size: 8)).foregroundColor(.gray) }
                            }.padding(6).background(RoundedRectangle(cornerRadius: 10).fill(.ultraThinMaterial.opacity(0.2)))
                        }.onAppear { if movie == allMovies.last && hasMore && !isLoading { Task { await loadMore() } } }
                    }
                    if isLoading { ProgressView().tint(.white).frame(maxWidth: .infinity).padding() }
                }.padding(.horizontal, 16).padding(.top, 90).padding(.bottom, 100)
            }
            Button { dismiss() } label: { Image(systemName: "chevron.left").font(.system(size: 24, weight: .bold)).foregroundColor(.white).padding(14).background(Circle().fill(.ultraThinMaterial.opacity(0.3)).overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 0.5))).padding(.top, 54).padding(.leading, 20) }
        }.navigationBarHidden(true).task {
            allMovies = movies.filter { !($0.adult ?? false) }
            if allMovies.isEmpty { await loadMore() }
        }
    }
    
    func loadMore() async {
        isLoading = true
        defer { isLoading = false }
        
        let newMovies: [Movie]?
        
        if isYearQuery, let year = Int(fixedQuery) {
            newMovies = try? await APIService.shared.searchMovies(query: "\(year)", page: page)
        } else if isCountryQuery {
            let countryNames: [String: String] = [
                "usuk": "American", "korean": "Korean", "japanese": "Japanese",
                "vietnamese": "Vietnamese", "china": "Chinese", "india": "Indian",
                "thailand": "Thai", "france": "French", "uk": "British",
                "australia": "Australian", "mexico": "Mexican", "spain": "Spanish",
                "brazil": "Brazilian", "russia": "Russian", "germany": "German",
                "italy": "Italian", "canada": "Canadian", "sweden": "Swedish"
            ]
            let keyword = countryNames[fixedQuery.lowercased()] ?? fixedQuery
            newMovies = try? await APIService.shared.searchMovies(query: keyword, page: page)
        } else {
            let q = fixedQuery.isEmpty ? title : fixedQuery
            newMovies = try? await APIService.shared.searchMovies(query: q, page: page)
        }
        
        if let new = newMovies, !new.isEmpty {
            let filtered = new.filter { !($0.adult ?? false) }
            if filtered.isEmpty { hasMore = false }
            else { allMovies.append(contentsOf: filtered); page += 1 }
        } else {
            hasMore = false
        }
    }
}