import SwiftUI

struct MoodPickerView: View {
    @State private var selectedMood: String?
    @State private var movies: [Movie] = []
    @State private var isLoading = false
    
    let moods: [(String, String, String, Int)] = [
        ("😢", "Buồn", "Drama", 18),
        ("❤️", "Lãng mạn", "Romance", 10749),
        ("🔪", "Kinh dị", "Horror", 27),
        ("🤯", "Kịch tính", "Thriller", 53),
        ("😂", "Hài hước", "Comedy", 35),
        ("🧘", "Thư giãn", "Chill", 99),
        ("💥", "Hành động", "Action", 28),
        ("🚀", "Viễn tưởng", "Sci-Fi", 878),
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Hôm nay bạn muốn xem gì?")
                            .font(.title2).fontWeight(.bold).foregroundColor(.white)
                            .padding(.horizontal)
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            ForEach(moods, id: \.0) { emoji, name, _, genreId in
                                Button {
                                    selectedMood = name
                                    Task {
                                        isLoading = true
                                        do {
                                            movies = try await APIService.shared.discoverMovies(genreId: genreId)
                                        } catch {
                                            movies = []
                                        }
                                        isLoading = false
                                    }
                                } label: {
                                    VStack(spacing: 8) {
                                        Text(emoji).font(.system(size: 40))
                                        Text(name).font(.caption).fontWeight(.medium).foregroundColor(.white)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 14)
                                            .fill(selectedMood == name ? Color.blue.opacity(0.3) : .ultraThinMaterial)
                                    )
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        if isLoading {
                            ProgressView().tint(.white).frame(maxWidth: .infinity)
                        }
                        
                        if !movies.isEmpty {
                            Text(selectedMood ?? "")
                                .font(.headline).foregroundColor(.white).padding(.horizontal)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(movies.prefix(10)) { movie in
                                        NavigationLink(destination: MovieDetailView(movie: movie)) {
                                            VStack(spacing: 5) {
                                                CachedAsyncImage(url: movie.posterURL)
                                                    .frame(width: 120, height: 180)
                                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                                Text(movie.title)
                                                    .font(.system(size: 10)).foregroundColor(.white).lineLimit(1).frame(width: 120)
                                            }
                                        }
                                    }
                                }.padding(.horizontal)
                            }
                        }
                        
                        Spacer().frame(height: 100)
                    }
                }
            }
            .navigationTitle("Chọn Mood")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}