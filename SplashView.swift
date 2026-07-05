import SwiftUI

struct SplashView: View {
    @State private var isAnimating = false
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0
    
    // Poster tông tối (horror/thriller)
    let darkPosters: [String] = [
        "/n6bUvigpBOqisP4apFP3FbhqEfA.jpg",  // Joker
        "/udDclJoHjfjb8Ekgsd4FDteOkCU.jpg",  // Joker 2
        "/qJ2tW6WMUDux911B6EMThhKzGYV.jpg",  // The Dark Knight
        "/7IiTTgloJzvGI1TAYymCfbfl3vT.jpg",  // Parasite
        "/pB8BM7pdSp6B6Ih7QZ4DrQ3PmJK.jpg",  // Fight Club
        "/d5iIlFn5s0ImszYzBPb8JPIfbXD.jpg",  // Pulp Fiction
        "/f89U3ADr1oiB1s9GkdPOEpXUk5H.jpg",  // The Matrix
        "/8ZTVqvKDQ8emSGUEMjsS4yHAwrp.jpg",  // Inception
        "/rAiYTfKGqDCRIIqo664sY9XZIvQ.jpg",  // Interstellar
        "/gEU2QniE6E77NI6lCU6MxlNBvIx.jpg",  // Interstellar 2
        "/7fn624j5lj3xTme2SgiLCeuedmO.jpg",  // Whiplash
        "/aKuFiU82s5ISJDxRkETp9cZNkWV.jpg",  // GoodFellas
    ]
    
    private let columns = [
        GridItem(.flexible(), spacing: 6),
        GridItem(.flexible(), spacing: 6),
        GridItem(.flexible(), spacing: 6)
    ]
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            // Background lưới ảnh mờ + nghiêng
            GeometryReader { geo in
                LazyVGrid(columns: columns, spacing: 6) {
                    ForEach(darkPosters, id: \.self) { poster in
                        CachedAsyncImage(url: URL(string: "https://image.tmdb.org/t/p/w300\(poster)"))
                            .aspectRatio(2/3, contentMode: .fill)
                            .frame(height: geo.size.width / 3 * 1.5)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                }
                .blur(radius: 10)
                .rotation3DEffect(.degrees(18), axis: (x: 0, y: 1, z: 0))
                .scaleEffect(1.4)
                .offset(x: -30)
                .opacity(0.5)
            }
            .ignoresSafeArea()
            
            // Gradient overlay
            LinearGradient(
                colors: [
                    .black.opacity(0.6),
                    .black.opacity(0.85),
                    .black.opacity(0.95)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            // Logo + Text trung tâm
            VStack(spacing: 20) {
                // Icon mèo
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 100, height: 100)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                    
                    Image(systemName: "cat.fill")
                        .font(.system(size: 45))
                        .foregroundColor(.white.opacity(0.9))
                }
                .scaleEffect(isAnimating ? 1.1 : 1.0)
                .animation(
                    .easeInOut(duration: 2).repeatForever(autoreverses: true),
                    value: isAnimating
                )
                
                // Text EMCC
                Text("EMCC")
                    .font(.system(size: 40, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                    .tracking(6)
                    .shadow(color: .white.opacity(0.3), radius: 10)
                
                // Subtitle
                Text("Khám phá điện ảnh")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.gray.opacity(0.7))
                    .tracking(2)
            }
            .scaleEffect(scale)
            .opacity(opacity)
        }
        .onAppear {
            // Logo thở
            isAnimating = true
            
            // Hiệu ứng xuất hiện
            withAnimation(.easeInOut(duration: 1.2)) {
                scale = 1.0
                opacity = 1.0
            }
        }
    }
}