import SwiftUI

struct MovieListView: View {
    let title: String
    let movies: [Movie]
    var fixedQuery: String = ""
    @State private var allMovies: [Movie] = []
    @State private var page = 1
    @State private var isLoading = false
    @State private var hasMore = true
    
    private let columns = [GridItem(.adaptive(minimum: 110), spacing: 10)]
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            ScrollView {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(allMovies) { movie in
                        NavigationLink(destination: MovieDetailView(movie: movie)) {
                            VStack(spacing: 4) {
                                CachedAsyncImage(url: movie.posterURL)
                                    .frame(height: 165).clipShape(RoundedRectangle(cornerRadius: 10))
                                Text(movie.title)
                                    .font(.system(size: 10)).fontWeight(.medium).foregroundColor(.white)
                                    .lineLimit(2).frame(maxWidth: 110)
                                HStack(spacing: 2) {
                                    Image(systemName: "star.fill").font(.system(size: 7)).foregroundColor(.yellow)
                                    Text(movie.ratingText).font(.system(size: 9)).foregroundColor(.gray)
                                }
                            }
                        }
                        .onAppear {
                            if movie == allMovies.last && hasMore && !isLoading {
                                Task { await loadMore() }
                            }
                        }
                    }
                    
                    if isLoading {
                        ProgressView().tint(.white).frame(maxWidth: .infinity).padding()
                    }
                }.padding()
            }
        }
        .navigationTitle(title).navigationBarTitleDisplayMode(.inline)
        .task {
            allMovies = movies
            if movies.isEmpty { await loadMore() }
        }
    }
    
    func loadMore() async {
        isLoading = true
        page += 1
        do {
            let query = fixedQuery.isEmpty ? title : fixedQuery
            let newMovies = try await APIService.shared.search(query: query, page: page)
            if newMovies.isEmpty {
                hasMore = false
            } else {
                allMovies.append(contentsOf: newMovies)
            }
        } catch {
            hasMore = false
        }
        isLoading = false
    }
}