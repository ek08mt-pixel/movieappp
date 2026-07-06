import SwiftUI

struct SplashView: View {
    @State private var isActive = false
    @State private var catX: CGFloat = -100
    @State private var catY: CGFloat = 0
    @State private var catScale: CGFloat = 0.5
    @State private var catOpacity: Double = 1
    @State private var particles: [ParticleData] = []
    @State private var glowRadius: CGFloat = 10
    @State private var bgOpacity: Double = 0
    
    let timer = Timer.publish(every: 0.03, on: .main, in: .common).autoconnect()
    
    var body: some View {
        if isActive {
            MainTabView()
                .transition(.opacity.animation(.easeInOut(duration: 0.5)))
        } else {
            ZStack {
                // Background liquid glass
                ZStack {
                    Color(hex: "#0C0C14")
                    
                    Circle()
                        .fill(LinearGradient(colors: [Color(hex: "#2D2D44").opacity(0.6), .clear], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 300, height: 300)
                        .blur(radius: 60)
                        .offset(x: -80, y: -200)
                    
                    Circle()
                        .fill(LinearGradient(colors: [Color(hex: "#1E1E38").opacity(0.5), .clear], startPoint: .bottomTrailing, endPoint: .topLeading))
                        .frame(width: 250, height: 250)
                        .blur(radius: 50)
                        .offset(x: 100, y: 150)
                    
                    Circle()
                        .fill(LinearGradient(colors: [Color(hex: "#252540").opacity(0.4), .clear], startPoint: .top, endPoint: .bottom))
                        .frame(width: 280, height: 280)
                        .blur(radius: 55)
                        .offset(x: 50, y: -50)
                }
                .ignoresSafeArea()
                .opacity(bgOpacity)
                
                // Scanlines
                ScanlinesView()
                    .opacity(0.05)
                    .ignoresSafeArea()
                
                // Particles
                ForEach(particles) { p in
                    Rectangle()
                        .fill(.white.opacity(p.opacity))
                        .frame(width: p.size, height: p.size)
                        .position(x: p.x, y: p.y)
                }
                
                // Cat shadow
                FullCatView()
                    .fill(.white.opacity(0.08))
                    .blur(radius: 20)
                    .frame(width: 80, height: 60)
                    .offset(x: catX + 3, y: catY + 3)
                    .scaleEffect(catScale)
                
                // Cat body
                FullCatView()
                    .fill(.white)
                    .frame(width: 80, height: 60)
                    .offset(x: catX, y: catY)
                    .scaleEffect(catScale)
                    .shadow(color: .white.opacity(0.5), radius: glowRadius, x: 0, y: 0)
                    .opacity(catOpacity)
                
                // Glass frame
                RoundedRectangle(cornerRadius: 36)
                    .fill(.ultraThinMaterial.opacity(0.3))
                    .frame(width: 180, height: 180)
                    .overlay(
                        RoundedRectangle(cornerRadius: 36)
                            .stroke(LinearGradient(colors: [.white.opacity(0.3), .white.opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1.5)
                    )
                    .opacity(catOpacity)
                
                Text("EMCC")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .tracking(14)
                    .opacity(catOpacity)
                    .offset(y: 125)
                
                Text("© 2026 Emmew, Inc. All Rights Reserved.")
                    .font(.system(size: 9, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.25))
                    .offset(y: UIScreen.main.bounds.height / 2 - 20)
                    .opacity(catOpacity)
            }
            .onReceive(timer) { _ in
                for i in particles.indices {
                    particles[i].x += particles[i].vx
                    particles[i].y += particles[i].vy
                    particles[i].opacity -= 0.025
                }
                particles = particles.filter { $0.opacity > 0 }
            }
            .onAppear {
                withAnimation(.easeOut(duration: 1.0)) { bgOpacity = 1.0 }
                startAnimation()
            }
        }
    }
    
    func startAnimation() {
        // Bắt đầu ngoài khung bên trái
        catX = -120
        catY = 0
        catScale = 0.5
        
        // Chạy vào giữa
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            catX = 0
            catScale = 0.8
            glowRadius = 18
        }
        spawnParticles()
        
        // Nhảy lên
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                catY = -25
                catScale = 0.9
                glowRadius = 22
            }
        }
        
        // Chạy sang phải
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
            withAnimation(.easeInOut(duration: 0.5)) {
                catX = 100
                catY = -10
                catScale = 0.75
            }
            spawnParticles()
        }
        
        // Quay về giữa
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                catX = 0
                catY = 0
                catScale = 0.85
                glowRadius = 20
            }
        }
        
        // Thu nhỏ biến mất
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.8) {
            withAnimation(.easeIn(duration: 0.4)) {
                catScale = 0.05
                catOpacity = 0
                glowRadius = 0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.easeInOut(duration: 0.5)) { isActive = true }
            }
        }
    }
    
    func spawnParticles() {
        for _ in 0..<12 {
            let p = ParticleData(
                x: catX + CGFloat.random(in: -40...40),
                y: catY + CGFloat.random(in: -25...25),
                size: CGFloat.random(in: 2...5),
                opacity: Double.random(in: 0.6...1.0),
                vx: CGFloat.random(in: -4...4),
                vy: CGFloat.random(in: -4...4)
            )
            particles.append(p)
        }
    }
}

// MARK: - Full Cat Shape (thấy rõ 4 chân, body, đầu, tai, đuôi)
struct FullCatView: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        let cx = w / 2
        let by = h - 12 // body bottom
        
        // Đuôi
        path.move(to: CGPoint(x: cx + 32, y: by - 6))
        path.addCurve(to: CGPoint(x: cx + 48, y: by - 16), control1: CGPoint(x: cx + 42, y: by - 8), control2: CGPoint(x: cx + 48, y: by - 12))
        
        // Body
        path.addEllipse(in: CGRect(x: cx - 20, y: by - 22, width: 52, height: 22))
        
        // Chân trước trái
        path.addRect(CGRect(x: cx - 16, y: by - 2, width: 8, height: 14))
        // Chân trước phải
        path.addRect(CGRect(x: cx + 4, y: by - 2, width: 8, height: 14))
        // Chân sau trái
        path.addRect(CGRect(x: cx - 22, y: by - 2, width: 8, height: 12))
        // Chân sau phải
        path.addRect(CGRect(x: cx + 18, y: by - 2, width: 8, height: 12))
        
        // Đầu
        path.addEllipse(in: CGRect(x: cx - 14, y: by - 38, width: 28, height: 22))
        
        // Tai trái
        path.move(to: CGPoint(x: cx - 10, y: by - 36))
        path.addLine(to: CGPoint(x: cx - 16, y: by - 48))
        path.addLine(to: CGPoint(x: cx - 2, y: by - 38))
        // Tai phải
        path.move(to: CGPoint(x: cx + 10, y: by - 36))
        path.addLine(to: CGPoint(x: cx + 16, y: by - 48))
        path.addLine(to: CGPoint(x: cx + 2, y: by - 38))
        
        // Râu trái
        path.move(to: CGPoint(x: cx - 12, y: by - 28))
        path.addLine(to: CGPoint(x: cx - 24, y: by - 32))
        path.move(to: CGPoint(x: cx - 12, y: by - 25))
        path.addLine(to: CGPoint(x: cx - 24, y: by - 24))
        
        // Râu phải
        path.move(to: CGPoint(x: cx + 12, y: by - 28))
        path.addLine(to: CGPoint(x: cx + 24, y: by - 32))
        path.move(to: CGPoint(x: cx + 12, y: by - 25))
        path.addLine(to: CGPoint(x: cx + 24, y: by - 24))
        
        // Mắt
        path.addRect(CGRect(x: cx - 10, y: by - 34, width: 4, height: 3))
        path.addRect(CGRect(x: cx + 6, y: by - 34, width: 4, height: 3))
        
        // Mũi
        path.addRect(CGRect(x: cx - 1, y: by - 30, width: 2, height: 1.5))
        
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