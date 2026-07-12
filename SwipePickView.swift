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
    
    var nextMovie: Movie? {
        guard currentIndex + 1 < movies.count else { return nil }
        return movies[currentIndex + 1]
    }
    
    var body: some View {
        GeometryReader { geo in
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
                } else {
                    VStack(spacing: 0) {
                        // Header
                        HStack {
                            Button { dismiss() } label: {
                                Image(systemName: "xmark").font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white).padding(10)
                                    .background(Circle().fill(.ultraThinMaterial.opacity(0.4)))
                            }
                            Spacer()
                            Text("Movie Pick").font(.system(size: 15, weight: .bold)).foregroundColor(.white)
                            Spacer()
                            Button { showLikedList = true } label: {
                                Image(systemName: "heart.fill").font(.system(size: 14))
                                    .foregroundColor(.pink).padding(10)
                                    .background(Circle().fill(.ultraThinMaterial.opacity(0.4)))
                            }
                        }
                        .padding(.horizontal, 20).padding(.top, 50)
                        
                        Spacer()
                        
                        // Card stack
                        ZStack {
                            if let next = nextMovie {
                                cardView(movie: next, geo: geo)
                                    .scaleEffect(0.92)
                                    .offset(y: 10)
                                    .opacity(0.4)
                            }
                            
                            cardView(movie: currentMovie!, geo: geo)
                                .offset(x: offset.width)
                                .rotationEffect(.degrees(Double(offset.width / 20)))
                                .gesture(
                                    DragGesture()
                                        .onChanged { offset = $0.translation }
                                        .onEnded {
                                            if $0.translation.width > 100 { swipeRight() }
                                            else if $0.translation.width < -100 { swipeLeft() }
                                            else { withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { offset = .zero } }
                                        }
                                )
                        }
                        
                        Spacer()
                        
                        // Buttons
                        HStack(spacing: 40) {
                            Button { swipeLeft() } label: {
                                Image(systemName: "xmark").font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.red).padding(16)
                                    .background(Circle().fill(.ultraThinMaterial.opacity(0.5)))
                                    .overlay(Circle().stroke(.red.opacity(0.3), lineWidth: 1))
                            }
                            NavigationLink(destination: MovieDetailView(movie: currentMovie!)) {
                                Image(systemName: "info.circle.fill").font(.system(size: 20))
                                    .foregroundColor(.blue).padding(16)
                                    .background(Circle().fill(.ultraThinMaterial.opacity(0.5)))
                                    .overlay(Circle().stroke(.blue.opacity(0.3), lineWidth: 1))
                            }
                            Button { swipeRight() } label: {
                                Image(systemName: "heart.fill").font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.green).padding(16)
                                    .background(Circle().fill(.ultraThinMaterial.opacity(0.5)))
                                    .overlay(Circle().stroke(.green.opacity(0.3), lineWidth: 1))
                            }
                        }
                        
                        Spacer()
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .toolbar(.hidden, for: .tabBar)
        .task { await loadMovies() }
        .fullScreenCover(isPresented: $showLikedList) { LikedMoviesView(movies: likedMovies) }
    }
    
    func cardView(movie: Movie, geo: GeometryProxy) -> some View {
        ZStack(alignment: .bottom) {
            CachedAsyncImage(url: movie.posterURL)
                .aspectRatio(2/3, contentMode: .fill)
                .frame(width: geo.size.width - 56, height: geo.size.height * 0.45)
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .shadow(color: .black.opacity(0.5), radius: 20, y: 10)
            
            VStack(alignment: .leading, spacing: 0) {
                Spacer()
                LinearGradient(colors: [.clear, .black.opacity(0.9)], startPoint: .center, endPoint: .bottom)
                    .frame(height: 110)
                    .overlay(alignment: .bottomLeading) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(movie.title).font(.system(size: 16, weight: .bold)).foregroundColor(.white).lineLimit(2)
                            HStack(spacing: 6) {
                                HStack(spacing: 3) {
                                    Image(systemName: "star.fill").font(.system(size: 10)).foregroundColor(.yellow)
                                    Text(movie.ratingText).font(.system(size: 11, weight: .bold)).foregroundColor(.white)
                                }
                                Text(movie.yearText).font(.system(size: 10)).foregroundColor(.white.opacity(0.7))
                            }
                            Text(movie.overview).font(.system(size: 10)).foregroundColor(.white.opacity(0.6)).lineLimit(2)
                        }
                        .padding(.horizontal, 14).padding(.bottom, 12)
                    }
            }
            .clipShape(RoundedRectangle(cornerRadius: 24))
        }
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