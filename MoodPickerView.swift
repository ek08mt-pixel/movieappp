import SwiftUI

struct MoodPickerView: View {
    @State private var selectedMood: String?
    @State private var movies: [Movie] = []
    @State private var isLoading = false
    
    let moods: [(String, String, Int)] = [
        ("😢", "Buồn", 18),
        ("❤️", "Lãng mạn", 10749),
        ("🔪", "Kinh dị", 27),
        ("🤯", "Kịch tính", 53),
        ("😂", "Hài hước", 35),
        ("🧘", "Thư giãn", 99),
        ("💥", "Hành động", 28),
        ("🚀", "Viễn tưởng", 878),
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Hôm nay bạn muốn xem gì?")
                            .font(.title3).fontWeight(.bold).foregroundColor(.white).padding(.horizontal)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8) {
                            ForEach(moods, id: \.0) { emoji, name, genreId in
                                Button {
                                    selectedMood = name
                                    Task {
                                        isLoading = true
                                        do {
                                            movies = try await APIService.shared.discoverMovies(genreId: genreId)
                                        } catch { movies = [] }
                                        isLoading = false
                                    }
                                } label: {
                                    VStack(spacing: 4) {
                                        Text(emoji).font(.system(size: 24))
                                        Text(name).font(.system(size: 9)).foregroundColor(.white)
                                    }
                                    .frame(maxWidth: .infinity).padding(.vertical, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(selectedMood == name ? AnyShapeStyle(Color.blue.opacity(0.3)) : AnyShapeStyle(.ultraThinMaterial))
                                    )
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        if isLoading {
                            ProgressView().tint(.white).frame(maxWidth: .infinity)
                        }
                        
                        if !movies.isEmpty {
                            Text(selectedMood ?? "").font(.headline).foregroundColor(.white).padding(.horizontal)
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                                ForEach(movies.prefix(12)) { movie in
                                    NavigationLink(destination: MovieDetailView(movie: movie)) {
                                        CachedAsyncImage(url: movie.posterURL)
                                            .frame(height: 150)
                                            .clipShape(RoundedRectangle(cornerRadius: 10))
                                    }
                                }
                            }.padding(.horizontal)
                        }
                        
                        Spacer().frame(height: 100)
                    }
                }
            }
            .navigationTitle("Chọn Mood").navigationBarTitleDisplayMode(.inline)
        }
    }
}