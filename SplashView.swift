import SwiftUI

struct SplashView: View {
    @State private var isActive = false
    @State private var catOffsetX: CGFloat = 0
    @State private var catOffsetY: CGFloat = 0
    @State private var catScale: CGFloat = 0.4
    @State private var catOpacity: Double = 0
    @State private var catRotation: Double = 0
    @State private var particles: [Particle] = []
    @State private var glowOpacity: Double = 0
    @State private var phase = 0
    
    let timer = Timer.publish(every: 0.04, on: .main, in: .common).autoconnect()
    
    var body: some View {
        if isActive {
            MainTabView()
                .transition(.opacity.animation(.easeInOut(duration: 0.6)))
        } else {
            ZStack {
                // Background Midnight Blue → Deep Black
                LinearGradient(colors: [Color(hex: "#0F172A"), Color(hex: "#020617")], startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
                
                // Scanlines nhẹ
                ScanlinesView()
                    .opacity(0.08)
                    .blendMode(.overlay)
                    .ignoresSafeArea()
                
                // Pixel dust particles
                ForEach(particles) { particle in
                    Rectangle()
                        .fill(.white.opacity(particle.opacity))
                        .frame(width: particle.size, height: particle.size)
                        .position(x: particle.x, y: particle.y)
                }
                
                // Khung viền liquid glass
                RoundedRectangle(cornerRadius: 36)
                    .stroke(.white.opacity(0.3), lineWidth: 2)
                    .frame(width: 180, height: 180)
                    .opacity(catOpacity)
                
                // Glow phía sau mèo
                CatPixelShape()
                    .fill(.white.opacity(0.2))
                    .blur(radius: 16)
                    .frame(width: 70, height: 70)
                    .offset(x: catOffsetX, y: catOffsetY)
                    .scaleEffect(catScale)
                    .opacity(catOpacity)
                
                // Mèo pixel trắng
                CatPixelShape()
                    .fill(.white)
                    .frame(width: 70, height: 70)
                    .offset(x: catOffsetX, y: catOffsetY)
                    .scaleEffect(catScale)
                    .rotationEffect(.degrees(catRotation))
                    .opacity(catOpacity)
                    .shadow(color: .white.opacity(glowOpacity * 0.6), radius: 20, x: 0, y: 0)
                
                // EMCC text
                Text("EMCC")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .tracking(12)
                    .opacity(catOpacity * 0.8)
                    .offset(y: 130)
                    .shadow(color: .white.opacity(0.3), radius: 10)
                
                // Footer
                Text("© 2026 Emmew, Inc. All Rights Reserved.")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.25))
                    .position(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height - 50)
                    .opacity(catOpacity)
            }
            .onReceive(timer) { _ in
                for i in particles.indices {
                    particles[i].x += particles[i].vx
                    particles[i].y += particles[i].vy
                    particles[i].opacity -= 0.015
                }
                particles = particles.filter { $0.opacity > 0 }
            }
            .onAppear {
                startAnimation()
            }
        }
    }
    
    func startAnimation() {
        let screenW = UIScreen.main.bounds.width
        
        // Bắt đầu: trong khung, nhỏ, mờ
        catOffsetX = 0
        catOffsetY = 0
        catScale = 0.4
        catOpacity = 0
        catRotation = 0
        
        // Phase 1: Xuất hiện
        withAnimation(.easeOut(duration: 0.4)) {
            catOpacity = 1
            catScale = 0.6
            glowOpacity = 0.5
        }
        
        // Phase 2: Nhảy ra ngoài (scale to)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.5)) {
                catScale = 1.1
                glowOpacity = 0.9
                catRotation = 10
            }
            for _ in 0..<30 { spawnParticle(x: catOffsetX, y: catOffsetY, count: 8) }
        }
        
        // Phase 3: Lượn sang phải
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation(.easeInOut(duration: 0.7)) {
                catOffsetX = 40
                catRotation = -8
            }
            for _ in 0..<20 { spawnParticle(x: catOffsetX, y: catOffsetY, count: 5, direction: -1) }
        }
        
        // Phase 4: Lượn sang trái
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeInOut(duration: 0.7)) {
                catOffsetX = -40
                catRotation = 8
            }
            for _ in 0..<20 { spawnParticle(x: catOffsetX, y: catOffsetY, count: 5, direction: 1) }
        }
        
        // Phase 5: Về giữa, thu nhỏ
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.8) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                catOffsetX = 0
                catRotation = 0
                catScale = 0.8
                glowOpacity = 0.7
            }
        }
        
        // Phase 6: Chui vào khung, biến mất
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
            withAnimation(.easeIn(duration: 0.5)) {
                catScale = 0.1
                catOpacity = 0
                glowOpacity = 0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                withAnimation(.easeInOut(duration: 0.6)) {
                    isActive = true
                }
            }
        }
    }
    
    func spawnParticle(x: CGFloat, y: CGFloat, count: Int, direction: CGFloat = 0) {
        for _ in 0..<count {
            let p = Particle(
                x: x + CGFloat.random(in: -30...30),
                y: y + CGFloat.random(in: -30...30),
                size: CGFloat.random(in: 2...5),
                opacity: Double.random(in: 0.4...0.9),
                vx: direction != 0 ? direction * CGFloat.random(in: 2...6) : CGFloat.random(in: -4...4),
                vy: CGFloat.random(in: -3...3)
            )
            particles.append(p)
        }
    }
}

// MARK: - Cat Pixel Shape (white, 8-bit style)
struct CatPixelShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        let cx = w / 2
        let cy = h / 2
        
        // Head - pixel vuông
        path.addRect(CGRect(x: cx - 16, y: cy - 14, width: 12, height: 8))
        path.addRect(CGRect(x: cx - 4, y: cy - 14, width: 12, height: 8))
        path.addRect(CGRect(x: cx - 20, y: cy - 6, width: 8, height: 12))
        path.addRect(CGRect(x: cx - 12, y: cy - 6, width: 8, height: 12))
        path.addRect(CGRect(x: cx - 4, y: cy - 6, width: 8, height: 12))
        path.addRect(CGRect(x: cx + 4, y: cy - 6, width: 8, height: 12))
        path.addRect(CGRect(x: cx + 12, y: cy - 6, width: 8, height: 12))
        path.addRect(CGRect(x: cx - 16, y: cy + 6, width: 8, height: 8))
        path.addRect(CGRect(x: cx - 8, y: cy + 6, width: 8, height: 8))
        path.addRect(CGRect(x: cx, y: cy + 6, width: 8, height: 8))
        path.addRect(CGRect(x: cx + 8, y: cy + 6, width: 8, height: 8))
        
        // Ears
        path.addRect(CGRect(x: cx - 20, y: cy - 20, width: 8, height: 8))
        path.addRect(CGRect(x: cx + 12, y: cy - 20, width: 8, height: 8))
        
        // Whiskers
        path.addRect(CGRect(x: cx - 28, y: cy + 2, width: 8, height: 4))
        path.addRect(CGRect(x: cx - 28, y: cy + 8, width: 8, height: 4))
        path.addRect(CGRect(x: cx + 20, y: cy + 2, width: 8, height: 4))
        path.addRect(CGRect(x: cx + 20, y: cy + 8, width: 8, height: 4))
        
        return path
    }
}

// MARK: - Particle Model
struct Particle: Identifiable {
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
                context.fill(
                    Path(CGRect(x: 0, y: y, width: size.width, height: 1)),
                    with: .color(.black.opacity(0.4))
                )
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
        case 6:
            (a, r, g, b) = (255, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = ((int >> 24) & 0xFF, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}