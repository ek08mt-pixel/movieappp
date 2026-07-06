import SwiftUI

struct SplashView: View {
    @State private var isActive = false
    @State private var catOffsetX: CGFloat = -80
    @State private var catOffsetY: CGFloat = 0
    @State private var catScale: CGFloat = 0.5
    @State private var catOpacity: Double = 0
    @State private var catRotation: Double = -5
    @State private var particles: [ParticleData] = []
    @State private var glowOpacity: Double = 0
    @State private var frameScale: CGFloat = 0.9
    
    let timer = Timer.publish(every: 0.03, on: .main, in: .common).autoconnect()
    
    var body: some View {
        if isActive {
            MainTabView()
                .transition(.opacity.animation(.easeInOut(duration: 0.5)))
        } else {
            ZStack {
                // Background 3 màu gradient
                LinearGradient(
                    colors: [
                        Color(hex: "#1A1A2E"),
                        Color(hex: "#0D0D1A"),
                        Color(hex: "#050508")
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                // Lớp blur overlay
                Color.black.opacity(0.3)
                    .blur(radius: 40)
                    .ignoresSafeArea()
                
                // Lớp trắng nhẹ ở giữa
                RadialGradient(colors: [.white.opacity(0.05), .clear], center: .center, startRadius: 50, endRadius: 300)
                    .ignoresSafeArea()
                
                // Scanlines
                ScanlinesView()
                    .opacity(0.06)
                    .blendMode(.overlay)
                    .ignoresSafeArea()
                
                // Pixel dust particles
                ForEach(particles) { p in
                    Rectangle()
                        .fill(.white.opacity(p.opacity))
                        .frame(width: p.size, height: p.size)
                        .position(x: p.x, y: p.y)
                }
                
                // Khung viền liquid glass
                RoundedRectangle(cornerRadius: 36)
                    .stroke(
                        LinearGradient(colors: [.white.opacity(0.4), .white.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing),
                        lineWidth: 2
                    )
                    .frame(width: 180, height: 180)
                    .scaleEffect(frameScale)
                    .opacity(catOpacity * 0.8)
                
                // Glow sau mèo
                CatPixelView()
                    .fill(.white.opacity(0.15))
                    .blur(radius: 18)
                    .frame(width: 60, height: 55)
                    .offset(x: catOffsetX, y: catOffsetY)
                    .scaleEffect(catScale)
                    .opacity(catOpacity)
                
                // Mèo pixel trắng
                CatPixelView()
                    .fill(.white)
                    .frame(width: 60, height: 55)
                    .offset(x: catOffsetX, y: catOffsetY)
                    .scaleEffect(catScale)
                    .rotationEffect(.degrees(catRotation))
                    .opacity(catOpacity)
                    .shadow(color: .white.opacity(glowOpacity * 0.7), radius: 25, x: 0, y: 0)
                
                // Chữ EMCC
                Text("EMCC")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .tracking(14)
                    .opacity(catOpacity * 0.9)
                    .offset(y: 125)
                
                // Footer
                Text("© 2026 Emmew, Inc. All Rights Reserved.")
                    .font(.system(size: 9, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.3))
                    .offset(y: UIScreen.main.bounds.height / 2 - 30)
                    .opacity(catOpacity)
            }
            .onReceive(timer) { _ in
                for i in particles.indices {
                    particles[i].x += particles[i].vx
                    particles[i].y += particles[i].vy
                    particles[i].opacity -= 0.02
                }
                particles = particles.filter { $0.opacity > 0 }
            }
            .onAppear {
                startAnimation()
            }
        }
    }
    
    func startAnimation() {
        catOffsetX = -80
        catOffsetY = 0
        catScale = 0.5
        catOpacity = 0
        catRotation = -5
        
        // Xuất hiện từ trái
        withAnimation(.easeOut(duration: 0.4)) {
            catOpacity = 1
            catScale = 0.7
            glowOpacity = 0.6
            frameScale = 1.0
        }
        for _ in 0..<15 { spawnParticle(x: catOffsetX, y: catOffsetY) }
        
        // Chạy sang phải
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeInOut(duration: 0.7)) {
                catOffsetX = 90
                catRotation = 3
                catScale = 0.8
                glowOpacity = 0.8
            }
            for _ in 0..<25 { spawnParticle(x: catOffsetX, y: catOffsetY) }
        }
        
        // Lượn nhẹ
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
            withAnimation(.easeInOut(duration: 0.5)) {
                catOffsetX = 60
                catOffsetY = -10
                catRotation = -3
            }
        }
        
        // Chạy ngược về trái, ra sau khung
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.9) {
            withAnimation(.easeInOut(duration: 0.7)) {
                catOffsetX = -100
                catOffsetY = 5
                catRotation = -8
                catScale = 0.6
            }
            for _ in 0..<30 { spawnParticle(x: catOffsetX, y: catOffsetY) }
        }
        
        // Nhảy vào giữa khung
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.7) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.5)) {
                catOffsetX = 0
                catOffsetY = 0
                catScale = 0.85
                catRotation = 0
                glowOpacity = 1.0
            }
            for _ in 0..<20 { spawnParticle(x: 0, y: 0) }
        }
        
        // Thu nhỏ, biến mất
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
            withAnimation(.easeIn(duration: 0.4)) {
                catScale = 0.05
                catOpacity = 0
                glowOpacity = 0
                frameScale = 0.8
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.easeInOut(duration: 0.5)) {
                    isActive = true
                }
            }
        }
    }
    
    func spawnParticle(x: CGFloat, y: CGFloat) {
        for _ in 0..<4 {
            let p = ParticleData(
                x: x + CGFloat.random(in: -35...35),
                y: y + CGFloat.random(in: -35...35),
                size: CGFloat.random(in: 2...5),
                opacity: Double.random(in: 0.5...1.0),
                vx: CGFloat.random(in: -3...3),
                vy: CGFloat.random(in: -3...3)
            )
            particles.append(p)
        }
    }
}

// MARK: - Cat Pixel View (nguyên con mèo dễ thương)
struct CatPixelView: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        let cx = w / 2
        let cy = h / 2
        
        // Tai trái
        path.addRect(CGRect(x: cx - 24, y: cy - 24, width: 8, height: 8))
        // Tai phải
        path.addRect(CGRect(x: cx + 16, y: cy - 24, width: 8, height: 8))
        
        // Đỉnh đầu
        path.addRect(CGRect(x: cx - 16, y: cy - 18, width: 8, height: 4))
        path.addRect(CGRect(x: cx - 8, y: cy - 18, width: 16, height: 4))
        
        // Mặt trên
        path.addRect(CGRect(x: cx - 24, y: cy - 14, width: 8, height: 6))
        path.addRect(CGRect(x: cx - 16, y: cy - 14, width: 12, height: 6))
        path.addRect(CGRect(x: cx - 4, y: cy - 14, width: 12, height: 6))
        path.addRect(CGRect(x: cx + 8, y: cy - 14, width: 12, height: 6))
        path.addRect(CGRect(x: cx + 20, y: cy - 14, width: 4, height: 6))
        
        // Mắt
        path.addRect(CGRect(x: cx - 16, y: cy - 8, width: 6, height: 4))
        path.addRect(CGRect(x: cx + 10, y: cy - 8, width: 6, height: 4))
        
        // Mũi
        path.addRect(CGRect(x: cx - 2, y: cy - 4, width: 4, height: 2))
        
        // Má
        path.addRect(CGRect(x: cx - 22, y: cy - 2, width: 8, height: 8))
        path.addRect(CGRect(x: cx - 14, y: cy - 2, width: 8, height: 8))
        path.addRect(CGRect(x: cx - 6, y: cy - 2, width: 12, height: 8))
        path.addRect(CGRect(x: cx + 6, y: cy - 2, width: 8, height: 8))
        path.addRect(CGRect(x: cx + 14, y: cy - 2, width: 8, height: 8))
        
        // Cằm
        path.addRect(CGRect(x: cx - 10, y: cy + 6, width: 20, height: 6))
        
        // Râu trái
        path.addRect(CGRect(x: cx - 34, y: cy, width: 12, height: 3))
        path.addRect(CGRect(x: cx - 34, y: cy + 5, width: 10, height: 3))
        
        // Râu phải
        path.addRect(CGRect(x: cx + 22, y: cy, width: 12, height: 3))
        path.addRect(CGRect(x: cx + 24, y: cy + 5, width: 10, height: 3))
        
        return path
    }
}

// MARK: - Particle
struct ParticleData: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var size: CGFloat
    var opacity: Double
    var vx: CGFloat
    var vy: CGFloat
}

// MARK: - Scanlines
struct ScanlinesView: View {
    var body: some View {
        Canvas { context, size in
            for y in stride(from: 0, to: size.height, by: 3) {
                context.fill(Path(CGRect(x: 0, y: y, width: size.width, height: 1)), with: .color(.black.opacity(0.4)))
            }
        }
    }
}

// MARK: - Color Hex
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