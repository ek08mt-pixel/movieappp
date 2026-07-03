import SwiftUI

struct GenreMovieView: View {
    let genre: Genre
    @State private var movies: [Movie] = []
    @State private var isLoading = true
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if isLoading {
                ProgressView().tint(.white)
            } else {
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), spacing: 12)], spacing: 16) {
                        ForEach(movies) { movie in
                            NavigationLink(destination: MovieDetailView(movie: movie)) {
                                VStack(spacing: 5) {
                                    AsyncImage(url: movie.posterURL) { phase in
                                        if let image = phase.image {
                                            image.resizable().aspectRatio(contentMode: .fill)
                                        } else {
                                            Rectangle().fill(Color.gray.opacity(0.08))
                                        }
                                    }
                                    .frame(width: 120, height: 180)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    
                                    Text(movie.title)
                                        .font(.system(size: 10)).fontWeight(.medium).foregroundColor(.white)
                                        .lineLimit(2).frame(width: 120)
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle(genre.name.replacingOccurrences(of: "Phim ", with: ""))
        .navigationBarTitleDisplayMode(.inline)
        .task {
            do {
                movies = try await APIService.shared.moviesByGenre(genreId: genre.id)
            } catch {
                movies = []
            }
            isLoading = false
        }
    }
}
