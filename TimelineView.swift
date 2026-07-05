import SwiftUI

struct TimelineView: View {
    @State private var selectedYear: Double = 2024
    @State private var movies: [Movie] = []
    @State private var isLoading = false
    
    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                VStack(spacing: 16) {
                    Text("Movie Timeline")
                        .font(.title2).fontWeight(.bold).foregroundColor(.white)
                    
                    Text("Năm: \(Int(selectedYear))")
                        .font(.headline).foregroundColor(.orange)
                    
                    Slider(value: $selectedYear, in: 1900...2026, step: 1)
                        .tint(.orange).padding(.horizontal)
                        .onChange(of: selectedYear) { _ in Task { await loadMovies() } }
                    
                    if isLoading {
                        ProgressView().tint(.white)
                    }
                    
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 20) {
                            ForEach(movies) { movie in
                                NavigationLink(destination: MovieDetailView(movie: movie)) {
                                    MovieCardView(movie: movie)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                    
                    if movies.isEmpty && !isLoading {
                        Text("Không có phim").foregroundColor(.gray)
                    }
                    Spacer()
                }
                .padding(.top)
            }
        }
        .task { await loadMovies() }
    }
    
    func loadMovies() async {
        isLoading = true
        movies = (try? await APIService.shared.discoverMovies(year: Int(selectedYear))) ?? []
        isLoading = false
    }
}

// MARK: - Movie Card View (Dùng chung cho toàn app)
struct MovieCardView: View {
    let movie: Movie
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            CachedAsyncImage(url: movie.posterURL)
                .aspectRatio(2/3, contentMode: .fill)
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 2)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(movie.title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white)
                    .lineLimit(2)
                
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 9))
                        .foregroundColor(.yellow)
                    Text(movie.ratingText)
                        .font(.system(size: 10))
                        .foregroundColor(.gray)
                }
            }
        }
    }
}