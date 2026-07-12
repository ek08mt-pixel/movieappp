import SwiftUI

struct SwipePickView: View {
    @State private var movies: [Movie] = []
    @State private var currentIndex = 0
    @State private var offset = CGSize.zero
    @State private var likedMovies: [Movie] = []
    @State private var showLikedList = false
    @State private var isLoading = true
    @Environment(\.dismiss) var dismiss
    
    var currentMovie: Movie? {
        guard currentIndex < movies.count else { return nil }
        return movies[currentIndex]
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if isLoading {
                ProgressView().tint(.white)
            } else if currentMovie == nil {
                VStack(spacing: 20) {
                    Image(systemName: "checkmark.circle.fill").font(.system(size: 60)).foregroundColor(.green)
                    Text("Đã xem hết!").font(.title2.bold()).foregroundColor(.white)
                    Text("Đã thích \(likedMovies.count) phim").foregroundColor(.gray)
                    HStack(spacing: 20) {
                        Button { currentIndex = 0; movies.shuffle() } label: {
                            Text("Xem lại").font(.headline).foregroundColor(.white).padding(.horizontal, 30).padding(.vertical, 12).background(Capsule().fill(.ultraThinMaterial))
                        }
                        Button { showLikedList = true } label: {
                            Text("Đã thích").font(.headline).foregroundColor(.pink).padding(.horizontal, 30).padding(.vertical, 12).background(Capsule().fill(.pink.opacity(0.2)))
                        }
                    }
                }
            } else if let movie = currentMovie {
                VStack(spacing: 0) {
                    Spacer().frame(height: 4)
                    
                    HStack {
                        Button { dismiss() } label: {
                            Image(systemName: "xmark").font(.system(size: 14, weight: .bold)).foregroundColor(.white).padding(8).background(Circle().fill(.ultraThinMaterial.opacity(0.5)))
                        }
                        Spacer()
                        Text("Movie Pick").font(.system(size: 14, weight: .bold)).foregroundColor(.white)
                        Spacer()
                        Button { showLikedList = true } label: {
                            Image(systemName: "heart.fill").font(.system(size: 14)).foregroundColor(.pink).padding(8).background(Circle().fill(.ultraThinMaterial.opacity(0.5)))
                        }
                    }
                    .padding(.horizontal, 16)
                    
                    Spacer()
                    
                    ZStack(alignment: .bottom) {
                        if let url = movie.posterURL {
                            AsyncImage(url: URL(string: "https://image.tmdb.org/t/p/w342\(url.absoluteString.components(separatedBy: "/").last ?? "")")) { phase in
                                switch phase {
                                case .success(let image):
                                    image.resizable().aspectRatio(2/3, contentMode: .fill)
                                default:
                                    RoundedRectangle(cornerRadius: 24).fill(.ultraThinMaterial)
                                }
                            }
                        }
                        .frame(width: UIScreen.main.bounds.width - 32, height: UIScreen.main.bounds.height * 0.62)
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                        .shadow(color: .black.opacity(0.5), radius: 20, y: 10)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Spacer()
                            LinearGradient(colors: [.clear, .black.opacity(0.9)], startPoint: .center, endPoint: .bottom)
                                .frame(height: 140)
                                .overlay(alignment: .bottomLeading) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(movie.title)
                                            .font(.system(size: 18, weight: .bold))
                                            .foregroundColor(.white)
                                            .lineLimit(2)
                                        HStack(spacing: 8) {
                                            HStack(spacing: 3) {
                                                Image(systemName: "star.fill").font(.system(size: 10)).foregroundColor(.yellow)
                                                Text(movie.ratingText).font(.system(size: 12, weight: .bold)).foregroundColor(.white)
                                            }
                                            Text(movie.yearText).font(.system(size: 11)).foregroundColor(.white.opacity(0.7))
                                        }
                                        Text(movie.overview)
                                            .font(.system(size: 11))
                                            .foregroundColor(.white.opacity(0.6))
                                            .lineLimit(2)
                                    }
                                    .padding(.horizontal, 14).padding(.bottom, 14)
                                }
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                    }
                    .offset(x: offset.width, y: offset.height * 0.4)
                    .rotationEffect(.degrees(Double(offset.width / 20)))
                    .gesture(
                        DragGesture()
                            .onChanged { gesture in offset = gesture.translation }
                            .onEnded { gesture in
                                if gesture.translation.width > 100 { swipeRight() }
                                else if gesture.translation.width < -100 { swipeLeft() }
                                else { withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { offset = .zero } }
                            }
                    )
                    
                    Spacer()
                    
                    HStack(spacing: 36) {
                        Button { swipeLeft() } label: {
                            Image(systemName: "xmark").font(.system(size: 20, weight: .bold)).foregroundColor(.red).padding(16).background(Circle().fill(.ultraThinMaterial.opacity(0.5))).overlay(Circle().stroke(.red.opacity(0.3), lineWidth: 1))
                        }
                        NavigationLink(destination: MovieDetailView(movie: movie)) {
                            Image(systemName: "info.circle.fill").font(.system(size: 20)).foregroundColor(.blue).padding(16).background(Circle().fill(.ultraThinMaterial.opacity(0.5))).overlay(Circle().stroke(.blue.opacity(0.3), lineWidth: 1))
                        }
                        Button { swipeRight() } label: {
                            Image(systemName: "heart.fill").font(.system(size: 20, weight: .bold)).foregroundColor(.green).padding(16).background(Circle().fill(.ultraThinMaterial.opacity(0.5))).overlay(Circle().stroke(.green.opacity(0.3), lineWidth: 1))
                        }
                    }
                    .padding(.bottom, 20)
                }
            }
        }
        .ignoresSafeArea()
        .navigationBarHidden(true)
        .toolbar(.hidden, for: .tabBar)
        .task { await loadMovies() }
        .fullScreenCover(isPresented: $showLikedList) { LikedMoviesView(movies: likedMovies) }
    }
    
    func loadMovies() async {
        isLoading = true
        let fetched = (try? await APIService.shared.popular()) ?? []
        movies = fetched.filter { !($0.adult ?? false) }.shuffled()
        isLoading = false
    }
    
    func swipeRight() {
        if let movie = currentMovie { likedMovies.append(movie) }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { offset = CGSize(width: 500, height: 0) }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { currentIndex += 1; offset = .zero }
    }
    
    func swipeLeft() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { offset = CGSize(width: -500, height: 0) }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { currentIndex += 1; offset = .zero }
    }
}

struct LikedMoviesView: View {
    let movies: [Movie]
    @Environment(\.dismiss) var dismiss
    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                if movies.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "heart.slash").font(.system(size: 50)).foregroundColor(.gray)
                        Text("Chưa có phim nào").foregroundColor(.gray)
                    }
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(movies) { movie in
                                NavigationLink(destination: MovieDetailView(movie: movie)) {
                                    VStack(spacing: 6) {
                                        CachedAsyncImage(url: movie.posterURL).aspectRatio(2/3, contentMode: .fill).frame(maxWidth: .infinity).clipShape(RoundedRectangle(cornerRadius: 8)).shadow(color: .black.opacity(0.3), radius: 4, y: 2)
                                        Text(movie.title).font(.system(size: 9, weight: .medium)).foregroundColor(.white).lineLimit(2)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 16).padding(.top, 60).padding(.bottom, 100)
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { dismiss() } label: { Image(systemName: "chevron.left").font(.system(size: 16, weight: .semibold)).foregroundColor(.white) }
                }
                ToolbarItem(placement: .principal) { Text("Đã thích (\(movies.count))").font(.headline).foregroundColor(.white) }
            }
        }
    }
}