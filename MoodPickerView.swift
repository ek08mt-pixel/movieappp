import SwiftUI

struct MoodPickerView: View {
    @State private var selectedMood: String? = nil
    @State private var movies: [Movie] = []
    @State private var isLoading = false
    @State private var pressedEmoji: String? = nil
    @Environment(\.dismiss) var dismiss
    
    let moods: [(String, Int)] = [
        ("face.smiling", 35),
        ("flame.fill", 28),
        ("heart.fill", 10749),
        ("ghost.fill", 27),
        ("rocket.fill", 878),
        ("magnifyingglass.circle.fill", 9648),
        ("theatermasks.fill", 18),
        ("puzzlepiece.fill", 16)
    ]
    
    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
    private let movieColumns = [GridItem(.flexible(), spacing: 15), GridItem(.flexible(), spacing: 15), GridItem(.flexible(), spacing: 15)]
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            LinearGradient(colors: [Color(white: 0.08), Color(white: 0.02), .black], startPoint: .top, endPoint: .bottom).ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    Text("CHOOSE YOUR VIBE")
                        .font(.system(size: 16, weight: .light, design: .default))
                        .foregroundColor(.white.opacity(0.7))
                        .tracking(4)
                        .padding(.top, 90)
                    
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(moods, id: \.1) { icon, genreId in
                            Button {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) {
                                    pressedEmoji = icon
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                    withAnimation { pressedEmoji = nil }
                                }
                                selectedMood = icon
                                loadMovies(genreId: genreId)
                            } label: {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 22)
                                        .fill(.ultraThinMaterial.opacity(0.35))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 22)
                                                .stroke(LinearGradient(colors: [.white.opacity(0.15), .white.opacity(0.03)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 0.5)
                                        )
                                    
                                    Image(systemName: icon)
                                        .font(.system(size: 34, weight: .light))
                                        .foregroundColor(.white)
                                        .scaleEffect(pressedEmoji == icon ? 1.3 : 1.0)
                                        .shadow(color: .white.opacity(pressedEmoji == icon ? 0.8 : 0.3), radius: pressedEmoji == icon ? 20 : 8)
                                }
                                .frame(height: 90)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    if selectedMood != nil {
                        if isLoading {
                            ProgressView().tint(.white).padding(.top, 20)
                        } else if !movies.isEmpty {
                            LazyVGrid(columns: movieColumns, spacing: 15) {
                                ForEach(movies) { movie in
                                    NavigationLink(destination: MovieDetailView(movie: movie)) {
                                        VStack(spacing: 6) {
                                            CachedAsyncImage(url: movie.posterURL)
                                                .aspectRatio(2/3, contentMode: .fill)
                                                .frame(maxWidth: .infinity)
                                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                                .shadow(color: .black.opacity(0.3), radius: 3)
                                            Text(movie.title).font(.system(size: 9, weight: .medium)).foregroundColor(.white).lineLimit(2)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.bottom, 100)
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