import SwiftUI

// MARK: - SwipePickView (Tinder Style)
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
            LinearGradient(colors: [Color(white: 0.08), Color(white: 0.02), .black], startPoint: .top, endPoint: .bottom).ignoresSafeArea()
            
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
                    // Header
                    HStack {
                        Button { dismiss() } label: {
                            Image(systemName: "xmark").font(.system(size: 16, weight: .bold)).foregroundColor(.white).padding(10).background(Circle().fill(.ultraThinMaterial.opacity(0.5)))
                        }
                        Spacer()
                        Text("Movie Pick").font(.headline).foregroundColor(.white)
                        Spacer()
                        Button { showLikedList = true } label: {
                            Image(systemName: "heart.fill").font(.system(size: 16)).foregroundColor(.pink).padding(10).background(Circle().fill(.ultraThinMaterial.opacity(0.5)))
                        }
                    }
                    .padding(.horizontal, 20).padding(.top, 50)
                    
                    Spacer()
                    
                    // Card
                    ZStack(alignment: .bottom) {
                        // Poster
                        CachedAsyncImage(url: movie.posterURL)
                            .aspectRatio(2/3, contentMode: .fill)
                            .frame(width: UIScreen.main.bounds.width - 40, height: UIScreen.main.bounds.height * 0.55)
                            .clipShape(RoundedRectangle(cornerRadius: 24))
                            .shadow(color: .black.opacity(0.5), radius: 20, y: 10)
                        
                        // Gradient + Info
                        VStack(alignment: .leading, spacing: 6) {
                            Spacer()
                            LinearGradient(colors: [.clear, .black.opacity(0.8)], startPoint: .center, endPoint: .bottom)
                                .frame(height: 200)
                                .overlay(alignment: .bottomLeading) {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text(movie.title)
                                            .font(.system(size: 26, weight: .bold))
                                            .foregroundColor(.white)
                                            .lineLimit(2)
                                        HStack(spacing: 12) {
                                            HStack(spacing: 4) {
                                                Image(systemName: "star.fill").font(.system(size: 14)).foregroundColor(.yellow)
                                                Text(movie.ratingText).font(.system(size: 16, weight: .bold)).foregroundColor(.white)
                                            }
                                            Text(movie.yearText).font(.system(size: 14)).foregroundColor(.white.opacity(0.7))
                                            if let lang = movie.originalLanguage {
                                                Text(lang.uppercased()).font(.system(size: 12)).foregroundColor(.white.opacity(0.5)).padding(.horizontal, 8).padding(.vertical, 2).background(Capsule().fill(.white.opacity(0.1)))
                                            }
                                        }
                                        Text(movie.overview)
                                            .font(.system(size: 13))
                                            .foregroundColor(.white.opacity(0.8))
                                            .lineLimit(3)
                                    }
                                    .padding(.horizontal, 20).padding(.bottom, 20)
                                }
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                    }
                    .offset(x: offset.width, y: offset.height * 0.4)
                    .rotationEffect(.degrees(Double(offset.width / 20)))
                    .gesture(
                        DragGesture()
                            .onChanged { gesture in
                                offset = gesture.translation
                            }
                            .onEnded { gesture in
                                let width = gesture.translation.width
                                if width > 100 {
                                    swipeRight()
                                } else if width < -100 {
                                    swipeLeft()
                                } else {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        offset = .zero
                                    }
                                }
                            }
                    )
                    
                    Spacer()
                    
                    // Buttons
                    HStack(spacing: 40) {
                        Button {
                            swipeLeft()
                        } label: {
                            Image(systemName: "xmark").font(.system(size: 22, weight: .bold))
                                .foregroundColor(.red).padding(18)
                                .background(Circle().fill(.ultraThinMaterial.opacity(0.5)))
                                .overlay(Circle().stroke(.red.opacity(0.3), lineWidth: 1))
                        }
                        
                        Button {
                            showLikedList = true
                        } label: {
                            Image(systemName: "list.bullet").font(.system(size: 18, weight: .bold))
                                .foregroundColor(.yellow).padding(16)
                                .background(Circle().fill(.ultraThinMaterial.opacity(0.5)))
                                .overlay(Circle().stroke(.yellow.opacity(0.3), lineWidth: 1))
                        }
                        
                        Button {
                            swipeRight()
                        } label: {
                            Image(systemName: "heart.fill").font(.system(size: 22, weight: .bold))
                                .foregroundColor(.green).padding(18)
                                .background(Circle().fill(.ultraThinMaterial.opacity(0.5)))
                                .overlay(Circle().stroke(.green.opacity(0.3), lineWidth: 1))
                        }
                    }
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationBarHidden(true)
        .task { await loadMovies() }
        .fullScreenCover(isPresented: $showLikedList) {
            LikedMoviesView(movies: likedMovies)
        }
    }
    
    func loadMovies() async {
        isLoading = true
        let fetched = (try? await APIService.shared.popular()) ?? []
        movies = fetched.filter { !($0.adult ?? false) }.shuffled()
        isLoading = false
    }
    
    func swipeRight() {
        if let movie = currentMovie {
            likedMovies.append(movie)
        }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            offset = CGSize(width: 500, height: 0)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            currentIndex += 1
            offset = .zero
        }
    }
    
    func swipeLeft() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            offset = CGSize(width: -500, height: 0)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            currentIndex += 1
            offset = .zero
        }
    }
}

// MARK: - Liked Movies View
struct LikedMoviesView: View {
    let movies: [Movie]
    @Environment(\.dismiss) var dismiss
    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(colors: [Color(white: 0.08), Color(white: 0.02), .black], startPoint: .top, endPoint: .bottom).ignoresSafeArea()
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
                                        HStack(spacing: 2) {
                                            Image(systemName: "star.fill").font(.system(size: 7)).foregroundColor(.yellow)
                                            Text(movie.ratingText).font(.system(size: 8)).foregroundColor(.gray)
                                        }
                                    }
                                    .padding(6).background(RoundedRectangle(cornerRadius: 10).fill(.ultraThinMaterial.opacity(0.2)))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 16).padding(.top, 90).padding(.bottom, 100)
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.left").font(.system(size: 16, weight: .semibold)).foregroundColor(.white).padding(8).background(Circle().fill(.ultraThinMaterial.opacity(0.5)))
                    }
                }
                ToolbarItem(placement: .principal) {
                    Text("Đã thích (\(movies.count))").font(.headline).foregroundColor(.white)
                }
            }
        }
    }
}