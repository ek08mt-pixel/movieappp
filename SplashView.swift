import SwiftUI

struct SplashView: View {
    @State private var isActive = false
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0
    @State private var rotation: Double = 0
    
    var body: some View {
        if isActive {
            MainTabView()
                .transition(.opacity.animation(.easeInOut(duration: 0.6)))
        } else {
            ZStack {
                // Background liquid glass xám đen
                ZStack {
                    Color(hex: "#0D0D0D")
                    
                    Circle()
                        .fill(LinearGradient(colors: [Color(hex: "#2A2A2A"), .clear], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 280, height: 280).blur(radius: 70).offset(x: -60, y: -180).rotationEffect(.degrees(rotation))
                    
                    Circle()
                        .fill(LinearGradient(colors: [Color(hex: "#1F1F1F"), .clear], startPoint: .bottomTrailing, endPoint: .topLeading))
                        .frame(width: 250, height: 250).blur(radius: 60).offset(x: 90, y: 140).rotationEffect(.degrees(-rotation))
                    
                    Circle()
                        .fill(LinearGradient(colors: [Color(hex: "#252525"), .clear], startPoint: .top, endPoint: .bottom))
                        .frame(width: 260, height: 260).blur(radius: 65).offset(x: 30, y: -30).rotationEffect(.degrees(rotation * 0.5))
                }
                .ignoresSafeArea()
                
                // Nội dung trung tâm
                VStack(spacing: 24) {
                    // Logo trong khung kính
                    ZStack {
                        RoundedRectangle(cornerRadius: 34)
                            .fill(.ultraThinMaterial.opacity(0.3))
                            .frame(width: 150, height: 150)
                            .overlay(
                                RoundedRectangle(cornerRadius: 34)
                                    .stroke(LinearGradient(colors: [.white.opacity(0.3), .white.opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1.5)
                            )
                            .shadow(color: .black.opacity(0.5), radius: 30, y: 15)
                        
                        Image(systemName: "play.rectangle.fill")
                            .font(.system(size: 64, weight: .bold))
                            .foregroundColor(.white)
                            .shadow(color: .white.opacity(0.5), radius: 12)
                    }
                    .scaleEffect(scale)
                    .opacity(opacity)
                    
                    Text("EMCC")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .tracking(14)
                        .scaleEffect(scale)
                        .opacity(opacity)
                        .shadow(color: .white.opacity(0.3), radius: 10)
                }
                
                // Footer
                Text("© 2026 Emmew, Inc. All Rights Reserved.")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.25))
                    .position(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height - 50)
                    .opacity(opacity)
            }
            .onAppear {
                withAnimation(.easeOut(duration: 1.5)) {
                    scale = 1.0
                    opacity = 1.0
                }
                withAnimation(.linear(duration: 15).repeatForever(autoreverses: false)) {
                    rotation = 360
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    withAnimation(.easeInOut(duration: 0.6)) {
                        isActive = true
                    }
                }
            }
        }
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6: (a, r, g, b) = (255, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = ((int >> 24) & 0xFF, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}