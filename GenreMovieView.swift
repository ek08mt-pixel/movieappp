import SwiftUI

struct GenreMovieView: View {
    let genre: Genre
    @State private var movies: [Movie] = []
    @State private var isLoading = true
    @Environment(\.dismiss) var dismiss
    
    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.black.ignoresSafeArea()
            
            if isLoading && movies.isEmpty {
                ProgressView().tint(.white)
            } else if movies.isEmpty {
                Text("Không có phim").foregroundColor(.gray)
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(movies) { movie in
                            NavigationLink(destination: MovieDetailView(movie: movie)) {
                                VStack(spacing: 6) {
                                    CachedAsyncImage(url: movie.posterURL)
                                        .aspectRatio(2/3, contentMode: .fill)
                                        .frame(maxWidth: .infinity)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                    Text(movie.title)
                                        .font(.system(size: 9, weight: .medium)).foregroundColor(.white).lineLimit(2)
                                    HStack(spacing: 2) {
                                        Image(systemName: "star.fill").font(.system(size: 7)).foregroundColor(.yellow)
                                        Text(movie.ratingText).font(.system(size: 8)).foregroundColor(.gray)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 80)
                    .padding(.bottom, 100)
                }
            }
            
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                    .padding(12)
                    .background(
                        Circle()
                            .fill(.ultraThinMaterial.opacity(0.3))
                            .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 0.5))
                    )
            }
            .padding(.top, 50)
            .padding(.leading, 16)
        }
        .navigationBarHidden(true)
        .task {
            do { movies = try await APIService.shared.moviesByGenre(genreId: genre.id) } catch { movies = [] }
            isLoading = false
        }
    }
}