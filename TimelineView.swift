import SwiftUI

struct TimelineView: View {
    @State private var selectedYear: Double = 2024
    @State private var movies: [Movie] = []
    @State private var isLoading = false
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 14), count: 4)
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                VStack(spacing: 16) {
                    Text("Movie Timeline").font(.title2).fontWeight(.bold).foregroundColor(.white)
                    Text("Năm: \(Int(selectedYear))").font(.headline).foregroundColor(.orange)
                    Slider(value: $selectedYear, in: 1900...2026, step: 1).tint(.orange).padding(.horizontal)
                        .onChange(of: selectedYear) { _ in Task { await loadMovies() } }
                    
                    if isLoading { ProgressView().tint(.white) }
                    
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 20) {
                            ForEach(movies) { movie in
                                NavigationLink(destination: MovieDetailView(movie: movie)) {
                                    VStack(alignment: .leading, spacing: 8) {
                                        CachedAsyncImage(url: movie.posterURL)
                                            .aspectRatio(2/3, contentMode: .fill)
                                            .frame(height: 160)
                                            .clipShape(RoundedRectangle(cornerRadius: 10))
                                        Text(movie.title)
                                            .font(.system(size: 10)).foregroundColor(.white).lineLimit(2)
                                            .frame(height: 28)
                                        HStack(spacing: 2) {
                                            Image(systemName: "star.fill").font(.system(size: 7)).foregroundColor(.yellow)
                                            Text(movie.ratingText).font(.system(size: 8)).foregroundColor(.gray)
                                        }
                                    }
                                }
                            }
                        }.padding(.horizontal, 16)
                    }
                    
                    if movies.isEmpty && !isLoading { Text("Không có phim").foregroundColor(.gray) }
                    Spacer()
                }.padding(.top)
            }
        }.task { await loadMovies() }
    }
    
    func loadMovies() async {
        isLoading = true
        movies = (try? await APIService.shared.discoverMovies(year: Int(selectedYear))) ?? []
        isLoading = false
    }
}