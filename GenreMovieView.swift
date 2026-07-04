import SwiftUI

struct GenreMovieView: View {
    let genre: Genre
    @State private var movies: [Movie] = []
    @State private var page = 1
    @State private var isLoading = true
    @State private var hasMore = true
    
    private let columns = [GridItem(.adaptive(minimum: 110), spacing: 10)]
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if isLoading && movies.isEmpty {
                ProgressView().tint(.white)
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(movies) { movie in
                            NavigationLink(destination: MovieDetailView(movie: movie)) {
                                VStack(spacing: 4) {
                                    CachedAsyncImage(url: movie.posterURL)
                                        .frame(height: 165)
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                    Text(movie.title)
                                        .font(.system(size: 10)).fontWeight(.medium).foregroundColor(.white)
                                        .lineLimit(2).frame(maxWidth: 110)
                                }
                            }
                            .onAppear {
                                if movie == movies.last && hasMore && !isLoading {
                                    Task { await loadMore() }
                                }
                            }
                        }
                        
                        if isLoading {
                            ProgressView().tint(.white).frame(maxWidth: .infinity).padding()
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle(genre.name.replacingOccurrences(of: "Phim ", with: ""))
        .navigationBarTitleDisplayMode(.inline)
        .task { await loadMore() }
    }
    
    func loadMore() async {
        isLoading = true
        do {
            let newMovies = try await APIService.shared.moviesByGenre(genreId: genre.id)
            if newMovies.isEmpty {
                hasMore = false
            } else {
                movies.append(contentsOf: newMovies)
            }
            page += 1
        } catch {
            hasMore = false
        }
        isLoading = false
    }
}