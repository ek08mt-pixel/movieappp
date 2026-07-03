import SwiftUI

struct SplashView: View {
    @State private var scale: CGFloat = 0.6
    @State private var opacity: Double = 0
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 28)
                        .fill(.ultraThinMaterial)
                        .frame(width: 90, height: 90)
                        .overlay(
                            RoundedRectangle(cornerRadius: 28)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                    
                    Image(systemName: "play.rectangle.fill")
                        .font(.system(size: 42))
                        .foregroundColor(.white.opacity(0.8))
                }
                .scaleEffect(scale)
                
                Text("EMCC")
                    .font(.system(size: 36, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                    .tracking(4)
                
                Text("Tìm Phim Cùng Em Mew Nha")
                    .font(.system(size: 14))
                    .foregroundColor(.gray.opacity(0.6))
            }
            .opacity(opacity)
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                scale = 1.0
            }
            withAnimation(.easeIn(duration: 0.8).delay(0.3)) {
                opacity = 1.0
            }
        }
    }
}
