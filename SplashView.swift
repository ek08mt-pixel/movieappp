import SwiftUI

struct SplashView: View {
    @State private var scale: CGFloat = 0.6
    @State private var opacity: Double = 0
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            HStack(spacing: 8) {
                ForEach(0..<3) { _ in
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial)
                        .frame(width: 90, height: 135)
                }
            }
            .blur(radius: 20)
            .opacity(0.4)
            
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.3), lineWidth: 2)
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: "cat.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.white.opacity(0.8))
                }
                .scaleEffect(scale)
                
                Text("EMCC")
                    .font(.system(size: 36, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                    .tracking(4)
                
                Text("Tìm Phim with Em Mew ")
                    .font(.system(size: 14))
                    .foregroundColor(.gray.opacity(0.6))
            }
            .opacity(opacity)
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) { scale = 1.0 }
            withAnimation(.easeIn(duration: 0.8).delay(0.3)) { opacity = 1.0 }
        }
    }
}
