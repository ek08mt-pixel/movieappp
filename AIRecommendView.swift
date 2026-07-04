import SwiftUI

struct AIRecommendView: View {
    @EnvironmentObject var appState: AppState
    @State private var recommendations: [Movie] = []
    @State private var isLoading = true
    @State private var selectedMood = ""
    let moods = ["🎬 Tất cả", "😄 Vui vẻ", "😢 Buồn", "😱 Hồi hộp", "❤️ Lãng mạn", "💥 Hành động", "😂 Hài hước"]
    let genreMap = ["😄 Vui vẻ": 35, "😢 Buồn": 18, "😱 Hồi hộp": 53, "❤️ Lãng mạn": 10749, "💥 Hành động": 28, "😂 Hài hước": 35]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Gợi ý cho bạn").font(.largeTitle).fontWeight(.bold).foregroundColor(.white).padding(.top)
                        Text("Dựa trên lịch sử xem của bạn").foregroundColor(.gray).font(.subheadline)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(moods, id: \.self) { m in
                                    Button { selectedMood = m; Task { await loadForMood(m) } } label: {
                                        Text(m).font(.caption).fontWeight(.medium).foregroundColor(.white).padding(.horizontal, 16).padding(.vertical, 8)
                                            .background(Capsule().stroke(selectedMood == m ? Color.white.opacity(0.5) : Color.clear, lineWidth: 1))
                                    }
                                }
                            }.padding(.horizontal)
                        }
                        if isLoading { ProgressView().tint(.white).frame(maxWidth: .infinity).padding(.top, 40) }
                        if !recommendations.isEmpty {
                            Text(selectedMood.isEmpty ? "Phim dành cho bạn" : selectedMood).font(.headline).foregroundColor(.white)
                            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 16) {
                                ForEach(recommendations.prefix(12)) { movie in
                                    NavigationLink(destination: MovieDetailView(movie: movie)) {
                                        VStack(spacing: 4) { CachedAsyncImage(url: movie.posterURL).aspectRatio(2/3, contentMode: .fill).frame(height: 160).clipShape(RoundedRectangle(cornerRadius: 10)); Text(movie.title).font(.system(size: 9)).foregroundColor(.white).lineLimit(2) }
                                    }
                                }
                            }
                        }
                        Spacer().frame(height: 100)
                    }.padding(.horizontal)
                }
            }
        }.task { await loadForMood("🎬 Tất cả") }
    }
    
    func loadForMood(_ mood: String) async {
        isLoading = true; selectedMood = mood
        do {
            if mood == "🎬 Tất cả" {
                if let last = appState.watchHistory.last { recommendations = try await APIService.shared.similar(movieId: last.id) }
                else { recommendations = try await APIService.shared.popular() }
            } else if let genreId = genreMap[mood] { recommendations = try await APIService.shared.discoverMovies(genreId: genreId) }
        } catch { recommendations = [] }
        isLoading = false
    }
}