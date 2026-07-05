import SwiftUI

struct TimelineView: View {
    @State private var selectedYear: Double = 2024
    @State private var movies: [Movie] = []
    @State private var isLoading = false
    
    private let columns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                VStack(spacing: 12) {
                    Text("Movie Timeline")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Năm: \(Int(selectedYear))")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.orange)
                    
                    Slider(value: $selectedYear, in: 1900...2026, step: 1)
                        .tint(.orange)
                        .padding(.horizontal)
                        .onChange(of: selectedYear) { _ in Task { await loadMovies() } }
                    
                    if isLoading {
                        ProgressView().tint(.white)
                    }
                    
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 8) {
                            ForEach(movies) { movie in
                                NavigationLink(destination: MovieDetailView(movie: movie)) {
                                    CachedAsyncImage(url: movie.posterURL)
                                        .aspectRatio(2/3, contentMode: .fill)
                                        .frame(maxWidth: .infinity)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                            }
                        }
                        .padding(.horizontal, 12)
                    }
                    
                    if movies.isEmpty && !isLoading {
                        Text("Không có phim").foregroundColor(.gray)
                    }
                    Spacer()
                }
                .padding(.top, 12)
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