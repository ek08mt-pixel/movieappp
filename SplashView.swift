import SwiftUI

struct SplashView: View {
    @State private var isAnimating = false
    @State private var scale: CGFloat = 0.7
    @State private var opacity: Double = 0
    
    let posters: [String] = [
        "/n6bUvigpBOqisP4apFP3FbhqEfA.jpg",
        "/udDclJoHjfjb8Ekgsd4FDteOkCU.jpg",
        "/qJ2tW6WMUDux911B6EMThhKzGYV.jpg",
        "/7IiTTgloJzvGI1TAYymCfbfl3vT.jpg",
        "/pB8BM7pdSp6B6Ih7QZ4DrQ3PmJK.jpg",
        "/d5iIlFn5s0ImszYzBPb8JPIfbXD.jpg",
        "/f89U3ADr1oiB1s9GkdPOEpXUk5H.jpg",
        "/8ZTVqvKDQ8emSGUEMjsS4yHAwrp.jpg",
        "/rAiYTfKGqDCRIIqo664sY9XZIvQ.jpg",
    ]
    
    private let columns = [
        GridItem(.flexible(), spacing: 0),
        GridItem(.flexible(), spacing: 0),
        GridItem(.flexible(), spacing: 0)
    ]
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            // Lưới poster mờ mạnh, opacity thấp
            LazyVGrid(columns: columns, spacing: 0) {
                ForEach(posters, id: \.self) { poster in
                    CachedAsyncImage(url: URL(string: "https://image.tmdb.org/t/p/w300\(poster)"))
                        .aspectRatio(2/3, contentMode: .fill)
                        .frame(height: UIScreen.main.bounds.width / 3 * 1.5)
                        .clipped()
                }
            }
            .blur(radius: 25)
            .opacity(0.25)
            .ignoresSafeArea()
            
            // Logo + Text
            VStack(spacing: 24) {
                // Logo đầu mèo viền
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.5), lineWidth: 2)
                        .frame(width: 80, height: 80)
                    
                    // Tai mèo trái
                    Path { path in
                        path.move(to: CGPoint(x: 20, y: 35))
                        path.addLine(to: CGPoint(x: 10, y: 5))
                        path.addLine(to: CGPoint(x: 35, y: 25))
                    }
                    .stroke(Color.gray.opacity(0.5), lineWidth: 2)
                    
                    // Tai mèo phải
                    Path { path in
                        path.move(to: CGPoint(x: 60, y: 35))
                        path.addLine(to: CGPoint(x: 70, y: 5))
                        path.addLine(to: CGPoint(x: 45, y: 25))
                    }
                    .stroke(Color.gray.opacity(0.5), lineWidth: 2)
                }
                .shadow(color: .gray.opacity(0.3), radius: 10)
                .scaleEffect(scale)
                
                VStack(spacing: 8) {
                    Text("EMCC")
                        .font(.system(size: 38, weight: .bold, design: .default))
                        .foregroundColor(.white)
                        .tracking(2)
                    
                    Text("Khám phá điện ảnh")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                        .tracking(1)
                }
                .opacity(opacity)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                scale = 1.0
            }
            withAnimation(.easeIn(duration: 1.0).delay(0.2)) {
                opacity = 1.0
            }
        }
    }
}