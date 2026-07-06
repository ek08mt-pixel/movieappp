import SwiftUI

struct DirectorView: View {
    let directorName: String
    @State private var movies: [Movie] = []
    @State private var isLoading = true
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if isLoading {
                ProgressView().tint(.white)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text(directorName)
                            .font(.largeTitle).fontWeight(.bold).foregroundColor(.white)
                            .padding(.horizontal)
                        
                        Text("Đạo diễn")
                            .foregroundColor(.gray).padding(.horizontal)
                        
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), spacing: 12)], spacing: 16) {
                            ForEach(movies) { movie in
                                NavigationLink(destination: MovieDetailView(movie: movie)) {
                                    VStack(spacing: 5) {
                                        CachedAsyncImage(url: movie.posterURL)
                                            .frame(width: 120, height: 180)
                                            .clipShape(RoundedRectangle(cornerRadius: 12))
                                        Text(movie.title)
                                            .font(.system(size: 10)).foregroundColor(.white).lineLimit(2).frame(width: 120)
                                    }
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
        }
        .task {
            do { movies = try await APIService.shared.searchMovies(query: directorName) } catch { movies = [] }
            isLoading = false
        }
    }
}