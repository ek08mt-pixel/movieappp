import SwiftUI

struct SplashView: View {
    @State private var opacity: Double = 0
    
    var body: some View {
        ZStack {
            // Background poster + blur + overlay
            CachedAsyncImage(url: URL(string: "https://image.tmdb.org/t/p/w780/7RyHsO4yDXtBv1zUU3mTpHeQ0d5.jpg"))
                .aspectRatio(contentMode: .fill)
                .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
                .blur(radius: 25)
                .overlay(Color.black.opacity(0.65))
                .clipped()
                .ignoresSafeArea()
            
            // Logo + Text - căn giữa tuyệt đối
            VStack(spacing: 20) {
                // Logo đầu mèo viền
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.4), lineWidth: 2)
                        .frame(width: 90, height: 90)
                    
                    // Tai trái
                    Path { path in
                        path.move(to: CGPoint(x: 24, y: 38))
                        path.addLine(to: CGPoint(x: 14, y: 8))
                        path.addLine(to: CGPoint(x: 38, y: 28))
                    }
                    .stroke(Color.white.opacity(0.4), lineWidth: 2)
                    
                    // Tai phải
                    Path { path in
                        path.move(to: CGPoint(x: 66, y: 38))
                        path.addLine(to: CGPoint(x: 76, y: 8))
                        path.addLine(to: CGPoint(x: 52, y: 28))
                    }
                    .stroke(Color.white.opacity(0.4), lineWidth: 2)
                }
                .frame(width: 100, height: 100)
                .shadow(color: .white.opacity(0.15), radius: 15)
                
                // Text
                VStack(spacing: 6) {
                    Text("EMCC")
                        .font(.system(size: 36, weight: .bold, design: .default))
                        .foregroundColor(.white)
                        .tracking(2.5)
                    
                    Text("Khám phá điện ảnh")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                        .tracking(1)
                }
                .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .padding(.bottom, 40)
            .opacity(opacity)
        }
        .onAppear {
            withAnimation(.easeIn(duration: 0.8).delay(0.1)) {
                opacity = 1.0
            }
        }
    }
}