import SwiftUI

struct MoodPickerView: View {
    @State private var selectedMood: String? = nil
    @State private var movies: [Movie] = []
    @State private var isLoading = false
    @Environment(\.dismiss) var dismiss
    
    let moods: [(String, String, Int)] = [
        ("😂", "Hài hước", 35), ("🔥", "Hành động", 28), ("💕", "Lãng mạn", 10749),
        ("👻", "Kinh dị", 27), ("🚀", "Viễn tưởng", 878), ("🕵️", "Bí ẩn", 9648),
        ("🎬", "Chính kịch", 18), ("👾", "Hoạt hình", 16)
    ]
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            LinearGradient(colors: [Color(white: 0.08), Color(white: 0.02), .black], startPoint: .top, endPoint: .bottom).ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 16) {
                    Text("Bạn đang có tâm trạng gì?").font(.title3).fontWeight(.bold).foregroundColor(.white).padding(.top, 90)
                    
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                        ForEach(moods, id: \.1) { emoji, name, genreId in
                            Button {
                                selectedMood = name
                                loadMovies(genreId: genreId)
                            } label: {
                                VStack(spacing: 6) {
                                    Text(emoji).font(.system(size: 28))
                                    Text(name).font(.caption2).foregroundColor(.white)
                                }
                                .frame(maxWidth: .infinity).padding(.vertical, 14)
                                .background(RoundedRectangle(cornerRadius: 14).fill(.ultraThinMaterial))
                                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.1), lineWidth: 0.5))
                            }
                        }
                    }.padding(.horizontal, 16)
                    
                    if selectedMood != nil {
                        if isLoading { ProgressView().tint(.white).padding(.top, 20) }
                        else if !movies.isEmpty {
                            LazyVGrid(columns: [GridItem(.flexible(), spacing: 15), GridItem(.flexible(), spacing: 15), GridItem(.flexible(), spacing: 15)], spacing: 15) {
                                ForEach(movies) { movie in
                                    NavigationLink(destination: MovieDetailView(movie: movie)) {
                                        VStack(spacing: 6) {
                                            CachedAsyncImage(url: movie.posterURL).aspectRatio(2/3, contentMode: .fill).frame(maxWidth: .infinity).clipShape(RoundedRectangle(cornerRadius: 8)).shadow(color: .black.opacity(0.3), radius: 3)
                                                .overlay(RoundedRectangle(cornerRadius: 8).fill(Color(white: 0.12)).opacity(movie.posterURL == nil ? 1 : 0))
                                            Text(movie.title).font(.system(size: 9, weight: .medium)).foregroundColor(.white).lineLimit(2)
                                        }
                                    }
                                }
                            }.padding(.horizontal, 16).padding(.bottom, 100)
                        }
                    }
                }
            }
            
            Button { dismiss() } label: {
                Image(systemName: "chevron.left").font(.system(size: 24, weight: .bold)).foregroundColor(.white).padding(14)
                    .background(Circle().fill(.ultraThinMaterial.opacity(0.3)).overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 0.5)))
            }.padding(.top, 54).padding(.leading, 20)
        }
        .navigationBarHidden(true)
    }
    
    func loadMovies(genreId: Int) { isLoading = true; Task { do { movies = try await APIService.shared.moviesByGenre(genreId: genreId) } catch { movies = [] }; isLoading = false } }
}