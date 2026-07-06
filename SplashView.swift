import SwiftUI

struct SplashView: View {
    @State private var isActive = false
    @State private var catOffsetX: CGFloat = -100
    @State private var catOffsetY: CGFloat = 0
    @State private var catScale: CGFloat = 0.3
    @State private var catOpacity: Double = 0
    @State private var catRotation: Double = -15
    @State private var particles: [Particle] = []
    @State private var glowOpacity: Double = 0
    
    let timer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()
    let catColor = Color(hex: "#CCFF00")
    
    var body: some View {
        if isActive {
            MainTabView()
                .transition(.opacity.animation(.easeInOut(duration: 0.6)))
        } else {
            ZStack {
                LinearGradient(colors: [Color(hex: "#121212"), Color(hex: "#05100F")], startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
                
                ScanlinesView()
                    .opacity(0.12)
                    .blendMode(.overlay)
                    .ignoresSafeArea()
                
                ForEach(particles) { particle in
                    Rectangle()
                        .fill(catColor.opacity(particle.opacity))
                        .frame(width: particle.size, height: particle.size)
                        .position(x: particle.x, y: particle.y)
                        .blur(radius: 1)
                }
                
                ZStack {
                    CatPixelView()
                        .fill(catColor.opacity(0.5))
                        .blur(radius: 15)
                        .frame(width: 60, height: 60)
                        .offset(x: catOffsetX + 2, y: catOffsetY)
                    
                    CatPixelView()
                        .fill(catColor)
                        .frame(width: 60, height: 60)
                        .offset(x: catOffsetX, y: catOffsetY)
                }
                .scaleEffect(catScale)
                .rotationEffect(.degrees(catRotation))
                .opacity(catOpacity)
                .shadow(color: catColor.opacity(glowOpacity * 0.8), radius: 25, x: 0, y: 0)
                
                RoundedRectangle(cornerRadius: 36)
                    .stroke(catColor.opacity(0.3), lineWidth: 2)
                    .frame(width: 170, height: 170)
                    .scaleEffect(catOpacity > 0.5 ? 1.0 : 1.2)
                    .opacity(catOpacity * 0.6)
                
                Text("EMCC")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .tracking(12)
                    .opacity(catOpacity * 0.8)
                    .offset(y: 120)
                    .shadow(color: catColor.opacity(0.4), radius: 10)
                
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
        let screenW = UIScreen.main.bounds.width
        let screenH = UIScreen.main.bounds.height
        let centerY = screenH / 2
        
        catOffsetX = -60
        catOffsetY = centerY
        catScale = 0.3
        catOpacity = 0
        
        withAnimation(.easeOut(duration: 0.3)) {
            catOpacity = 1
            catScale = 0.5
            glowOpacity = 0.6
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeInOut(duration: 0.8)) {
                catOffsetX = screenW + 60
                catScale = 0.7
                catRotation = 5
            }
            for _ in 0..<20 {
                spawnParticle(at: CGPoint(x: catOffsetX, y: centerY))
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeInOut(duration: 0.8)) {
                catOffsetX = -100
                catScale = 0.6
                catRotation = -10
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                catOffsetX = 0
                catOffsetY = -60
                catScale = 0.9
                catRotation = 0
                glowOpacity = 1.0
            }
        }
        
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
    
    func spawnParticle(at point: CGPoint) {
        for _ in 0..<5 {
            let p = Particle(
                x: point.x + CGFloat.random(in: -10...10),
                y: point.y + CGFloat.random(in: -10...10),
                size: CGFloat.random(in: 2...5),
                opacity: Double.random(in: 0.3...0.7),
                vx: CGFloat.random(in: -4...(-1)),
                vy: CGFloat.random(in: -2...2)
            )
            particles.append(p)
        }
    }
}

struct CatPixelView: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        let cx = w / 2
        let cy = h / 2
        
        path.addEllipse(in: CGRect(x: cx - 22, y: cy - 18, width: 44, height: 36))
        path.move(to: CGPoint(x: cx - 16, y: cy - 12))
        path.addLine(to: CGPoint(x: cx - 14, y: cy - 28))
        path.addLine(to: CGPoint(x: cx - 4, y: cy - 14))
        path.move(to: CGPoint(x: cx + 16, y: cy - 12))
        path.addLine(to: CGPoint(x: cx + 14, y: cy - 28))
        path.addLine(to: CGPoint(x: cx + 4, y: cy - 14))
        path.move(to: CGPoint(x: cx - 18, y: cy + 2))
        path.addLine(to: CGPoint(x: cx - 32, y: cy - 2))
        path.move(to: CGPoint(x: cx - 18, y: cy + 8))
        path.addLine(to: CGPoint(x: cx - 32, y: cy + 8))
        path.move(to: CGPoint(x: cx + 18, y: cy + 2))
        path.addLine(to: CGPoint(x: cx + 32, y: cy - 2))
        path.move(to: CGPoint(x: cx + 18, y: cy + 8))
        path.addLine(to: CGPoint(x: cx + 32, y: cy + 8))
        
        return path
    }
}

struct Particle: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var size: CGFloat
    var opacity: Double
    var vx: CGFloat
    var vy: CGFloat
}

struct ScanlinesView: View {
    var body: some View {
        Canvas { context, size in
            for y in stride(from: 0, to: size.height, by: 3) {
                context.fill(
                    Path(CGRect(x: 0, y: y, width: size.width, height: 1)),
                    with: .color(.black.opacity(0.5))
                )
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