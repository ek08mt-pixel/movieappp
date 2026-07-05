import SwiftUI

struct SplashView: View {
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0
    
    var body: some View {
        ZStack {
            // Background poster đẹp + blur + overlay tối
            CachedAsyncImage(url: URL(string: "https://image.tmdb.org/t/p/w780/7RyHsO4yDXtBv1zUU3mTpHeQ0d5.jpg"))
                .aspectRatio(contentMode: .fill)
                .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
                .blur(radius: 25)
                .overlay(Color.black.opacity(0.65))
                .clipped()
                .ignoresSafeArea()
            
            // Logo + Text
            VStack(spacing: 24) {
                // Logo đầu mèo viền
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.4), lineWidth: 2)
                        .frame(width: 80, height: 80)
                    
                    Path { path in
                        path.move(to: CGPoint(x: 20, y: 35))
                        path.addLine(to: CGPoint(x: 10, y: 5))
                        path.addLine(to: CGPoint(x: 35, y: 25))
                    }
                    .stroke(Color.white.opacity(0.4), lineWidth: 2)
                    
                    Path { path in
                        path.move(to: CGPoint(x: 60, y: 35))
                        path.addLine(to: CGPoint(x: 70, y: 5))
                        path.addLine(to: CGPoint(x: 45, y: 25))
                    }
                    .stroke(Color.white.opacity(0.4), lineWidth: 2)
                }
                .shadow(color: .white.opacity(0.2), radius: 15)
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
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                scale = 1.0
            }
            withAnimation(.easeIn(duration: 0.8).delay(0.15)) {
                opacity = 1.0
            }
        }
    }
}