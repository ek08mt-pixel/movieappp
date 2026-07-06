import SwiftUI

struct MoodPickerView: View {
    @State private var selectedMood: String? = nil
    @State private var movies: [Movie] = []
    @State private var isLoading = false
    @Environment(\.dismiss) var dismiss
    
    let moods: [(String, String, Int)] = [
        ("😂", "Hài hước", 35),
        ("🔥", "Hành động", 28),
        ("💕", "Lãng mạn", 10749),
        ("👻", "Kinh dị", 27),
        ("🚀", "Viễn tưởng", 878),
        ("🕵️", "Bí ẩn", 9648),
        ("🎬", "Chính kịch", 18),
        ("👾", "Hoạt hình", 16)
    ]
    
    @Namespace private var animation
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            LinearGradient(colors: [Color(white: 0.08), Color(white: 0.02), .black], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                if selectedMood == nil {
                    VStack(spacing: 20) {
                        Text("Bạn đang có tâm trạng gì?")
                            .font(.title3).fontWeight(.bold).foregroundColor(.white)
                            .padding(.top, 100)
                        
                        LazyVGrid(columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)], spacing: 16) {
                            ForEach(moods, id: \.1) { emoji, name, genreId in
                                Button {
                                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                        selectedMood = name
                                    }
                                    loadMovies(genreId: genreId)
                                } label: {
                                    VStack(spacing: 10) {
                                        Text(emoji).font(.system(size: 40))
                                        Text(name).font(.caption).foregroundColor(.white)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 20)
                                    .background(RoundedRectangle(cornerRadius: 16).fill(.ultraThinMaterial))
                                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.1), lineWidth: 0.5))
                                }
                                .matchedGeometryEffect(id: name, in: animation)
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .transition(.opacity)
                } else {
                    VStack(spacing: 0) {
                        HStack {
                            Text(selectedMood ?? "")
                                .font(.title3).fontWeight(.bold).foregroundColor(.white)
                            Spacer()
                        }
                        .padding(.horizontal)
                        .padding(.top, 80)
                        .padding(.bottom, 12)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(moods, id: \.1) { emoji, name, genreId in
                                    Button {
                                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                            selectedMood = name
                                        }
                                        loadMovies(genreId: genreId)
                                    } label: {
                                        HStack(spacing: 4) {
                                            Text(emoji).font(.system(size: 16))
                                            Text(name).font(.caption).foregroundColor(selectedMood == name ? .white : .gray)
                                        }
                                        .padding(.horizontal, 12).padding(.vertical, 8)
                                        .background(Capsule().fill(selectedMood == name ? AnyShapeStyle(.ultraThinMaterial) : AnyShapeStyle(Color.clear)))
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                        .padding(.bottom, 12)
                    }
                    
                    if isLoading {
                        Spacer()
                        ProgressView().tint(.white)
                        Spacer()
                    } else if movies.isEmpty {
                        Spacer()
                        Text("Không có phim").foregroundColor(.gray)
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 15) {
                                ForEach(movies) { movie in
                                    NavigationLink(destination: MovieDetailView(movie: movie)) {
                                        VStack(spacing: 6) {
                                            if let url = movie.posterURL {
                                                CachedAsyncImage(url: url)
                                                    .aspectRatio(2/3, contentMode: .fill)
                                                    .frame(maxWidth: .infinity)
                                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                                    .shadow(color: .black.opacity(0.3), radius: 3)
                                            } else {
                                                RoundedRectangle(cornerRadius: 8)
                                                    .fill(.ultraThinMaterial)
                                                    .aspectRatio(2/3, contentMode: .fit)
                                                    .frame(maxWidth: .infinity)
                                            }
                                            Text(movie.title)
                                                .font(.system(size: 9, weight: .medium)).foregroundColor(.white).lineLimit(2)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.bottom, 100)
                        }
                        .transition(.opacity)
                    }
                }
            }
            
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                    .padding(14)
                    .background(
                        Circle()
                            .fill(.ultraThinMaterial.opacity(0.3))
                            .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 0.5))
                    )
            }
            .padding(.top, 54)
            .padding(.leading, 20)
        }
        .navigationBarHidden(true)
        .animation(.easeInOut(duration: 0.3), value: selectedMood)
    }
    
    func loadMovies(genreId: Int) {
        isLoading = true
        Task {
            do { movies = try await APIService.shared.moviesByGenre(genreId: genreId) } catch { movies = [] }
            isLoading = false
        }
    }
}