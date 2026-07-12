import SwiftUI

struct SwipePickOverlay: View {
    @Binding var show: Bool
    @State private var movies: [Movie] = []
    @State private var currentIndex = 0
    @State private var offset = CGSize.zero
    @State private var isLoading = true
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.5).ignoresSafeArea().onTapGesture { show = false }
            
            if let movie = currentMovie {
                VStack(spacing: 20) {
                    Spacer()
                    
                    // Card
                    ZStack(alignment: .bottom) {
                        CachedAsyncImage(url: movie.posterURL)
                            .aspectRatio(2/3, contentMode: .fill)
                            .frame(width: UIScreen.main.bounds.width - 60, height: UIScreen.main.bounds.height * 0.5)
                            .clipShape(RoundedRectangle(cornerRadius: 24))
                            .shadow(color: .black.opacity(0.6), radius: 25)
                        
                        VStack(alignment: .leading, spacing: 3) {
                            Spacer()
                            LinearGradient(colors: [.clear, .black.opacity(0.9)], startPoint: .center, endPoint: .bottom)
                                .frame(height: 100)
                                .overlay(alignment: .bottomLeading) {
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(movie.title).font(.system(size: 17, weight: .bold)).foregroundColor(.white).lineLimit(2)
                                        HStack(spacing: 6) {
                                            HStack(spacing: 3) { Image(systemName: "star.fill").font(.system(size: 10)).foregroundColor(.yellow); Text(movie.ratingText).font(.system(size: 11, weight: .bold)).foregroundColor(.white) }
                                            Text(movie.yearText).font(.system(size: 10)).foregroundColor(.white.opacity(0.7))
                                        }
                                    }
                                    .padding(.horizontal, 16).padding(.bottom, 12)
                                }
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                    }
                    .offset(x: offset.width)
                    .rotationEffect(.degrees(Double(offset.width / 20)))
                    .gesture(DragGesture()
                        .onChanged { offset = $0.translation }
                        .onEnded {
                            if $0.translation.width > 100 { swipeRight() }
                            else if $0.translation.width < -100 { swipeLeft() }
                            else { withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { offset = .zero } }
                        }
                    )
                    
                    // Buttons
                    HStack(spacing: 50) {
                        Button { swipeLeft() } label: {
                            Image(systemName: "xmark").font(.system(size: 20, weight: .bold)).foregroundColor(.red).padding(14).background(Circle().fill(.ultraThinMaterial.opacity(0.6))).overlay(Circle().stroke(.red.opacity(0.3), lineWidth: 1))
                        }
                        Button { swipeRight() } label: {
                            Image(systemName: "heart.fill").font(.system(size: 20, weight: .bold)).foregroundColor(.green).padding(14).background(Circle().fill(.ultraThinMaterial.opacity(0.6))).overlay(Circle().stroke(.green.opacity(0.3), lineWidth: 1))
                        }
                    }
                    
                    Spacer()
                }
            }
            
            if isLoading {
                ProgressView().tint(.white)
            }
        }
        .task { await loadMovies() }
    }
    
    var currentMovie: Movie? {
        guard currentIndex < movies.count else { return nil }
        return movies[currentIndex]
    }
    
    func loadMovies() async {
        isLoading = true
        movies = (try? await APIService.shared.popular())?.filter { !($0.adult ?? false) }.shuffled() ?? []
        isLoading = false
    }
    
    func swipeRight() { withAnimation { offset = CGSize(width: 500, height: 0) }; DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { currentIndex += 1; offset = .zero } }
    func swipeLeft() { withAnimation { offset = CGSize(width: -500, height: 0) }; DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { currentIndex += 1; offset = .zero } }
}